-- constant prototypes names
local MOD_NAME = "Inventory Sensor"
local SENSOR = "item-sensor"
local EVENT_FILTER = {{ filter="name", name=SENSOR }}

local ASSEMBLER = "assembling-machine"
local FURNACE = "furnace"
local LAB = "lab"
local REACTOR = "reactor"
local ROBOPORT = "roboport"
local SILO = "rocket-silo"
local ARTILLERY = "artillery-turret"
local CHEST = "logistic-container" -- requester: type = "logistic-container" && logistic_mode = "requester"
local LINKEDCHEST = "linked-container" -- linked-container is used for example in the mod Space-Exploration. ("Arcolink Storage")
local LOCO = "locomotive"
local WAGON = "cargo-wagon"
local WAGONFLUID = "fluid-wagon"
local WAGONARTILLERY = "artillery-wagon"
local CAR = "car"
local TANK = "tank"
local SPIDER = "spider-vehicle"
local BOILER = "boiler"
local GENERATOR = "generator"
local STORAGE_TANK = "storage-tank"
local CARGO_LANDING_PAD = 'cargo-landing-pad'

-- initialize variables
local SupportedTypes = {
  [ASSEMBLER] = true,
  [FURNACE] = true,
  [LAB] = true,
  [REACTOR] = true,
  [ROBOPORT] = true,
  [SILO] = true,
  [ARTILLERY] = true,
  [CHEST] = true,
  [LINKEDCHEST] = true,
  [CAR] = false,
  [SPIDER] = false,
  [LOCO] = false,
  [WAGON] = false,
  [WAGONFLUID] = false,
  [WAGONARTILLERY] = false,
  [BOILER] = true,
  [GENERATOR] = true,
  [STORAGE_TANK] = true,
  [CARGO_LANDING_PAD] = true,
}

local Entity_Blacklist = {
  -- filter helper entities from helicopters
  ["heli-flying-collision-entity-_-"] = true,
  ["heli-landed-collision-side-entity-_-"] = true,
  ["heli-landed-collision-end-entity-_-"] = true,
  ["heli-body-entity-_-"] = true,
  ["heli-shadow-entity-_-"] = true,
  ["heli-burner-entity-_-"] = true,
  ["heli-floodlight-entity-_-"] = true,
  ["rotor-entity-_-"] = true,
  ["rotor-shadow-entity-_-"] = true,
}

---@type LogisticFilter
local parameter_locomotive = {value={type="virtual",name="inv-sensor-detected-locomotive", quality='normal'}, min=1}
---@type LogisticFilter
local parameter_wagon = {value={type="virtual",name="inv-sensor-detected-wagon", quality='normal'}, min=1}
---@type LogisticFilter
local parameter_car = {value={type="virtual",name="inv-sensor-detected-car", quality='normal'}, min=1}
---@type LogisticFilter
local parameter_tank = {value={type="virtual",name="inv-sensor-detected-tank", quality='normal'}, min=1}
---@type LogisticFilter
local parameter_spider = {value={type="virtual",name="inv-sensor-detected-spider", quality='normal'}, min=1}
---@type SignalFilter
local signal_progress = {type = "virtual",name = "inv-sensor-progress", quality='normal'}
---@type SignalFilter
local signal_temperature = {type = "virtual",name = "inv-sensor-temperature", quality='normal'}
---@type SignalFilter
local signal_fuel = {type = "virtual",name = "inv-sensor-fuel", quality='normal'}

local floor = math.floor
local ceil = math.ceil
local min = math.min
local max = math.max


---- MOD SETTINGS ----

local UpdateInterval = settings.global["inv_sensor_update_interval"].value
local ScanInterval = settings.global["inv_sensor_find_entity_interval"].value
local ScanOffset = settings.global["inv_sensor_BBox_offset"].value
local ScanRange = settings.global["inv_sensor_BBox_range"].value
local Read_Grid = settings.global["inv_sensor_read_grid"].value

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  if event.setting == "inv_sensor_update_interval" then
    UpdateInterval = settings.global["inv_sensor_update_interval"].value
    ResetStride()
  end
  if event.setting == "inv_sensor_find_entity_interval" then
    ScanInterval = settings.global["inv_sensor_find_entity_interval"].value
  end
  if event.setting == "inv_sensor_BBox_offset" then
    ScanOffset = settings.global["inv_sensor_BBox_offset"].value
    ResetSensors()
  end
  if event.setting == "inv_sensor_BBox_range" then
    ScanRange = settings.global["inv_sensor_BBox_range"].value
    ResetSensors()
  end
  if event.setting == "inv_sensor_read_grid" then
    Read_Grid = settings.global["inv_sensor_read_grid"].value
  end
end)


---- EVENTS ----

function OnEntityCreated(event)
  local entity = event.created_entity or event.entity or event.destination
  if entity and entity.valid and entity.name == SENSOR then
    storage.ItemSensors = storage.ItemSensors or {}

    entity.operable = false
    entity.rotatable = true
    local itemSensor = {}
    itemSensor.ID = entity.unit_number
    itemSensor.Sensor = entity
    itemSensor.ScanArea = GetScanArea(entity)
    SetConnectedEntity(itemSensor)

    storage.ItemSensors[#storage.ItemSensors+1] = itemSensor

    if #storage.ItemSensors > 0 then
      script.on_event( defines.events.on_tick, OnTick )
    end

    ResetStride()
  end
end

-- called from on_entity_removed and when entity becomes invalid
function RemoveSensor(sensorID)
  for i=#storage.ItemSensors, 1, -1 do
    if storage.ItemSensors[i].ID == sensorID then
      table.remove(storage.ItemSensors,i)
    end
  end

  if #storage.ItemSensors == 0 then
    script.on_event( defines.events.on_tick, nil )
  end

  ResetStride()
end

function OnEntityRemoved(event)
  local entity = event.entity
  if entity and entity.valid and entity.name == SENSOR then
    RemoveSensor(entity.unit_number)
  end
end

function OnEntityRotated(event)
  local entity = event.entity
  if entity and entity.valid and entity.name == SENSOR then
    storage.ItemSensors = storage.ItemSensors or {}
    for i=1, #storage.ItemSensors do
      local itemSensor = storage.ItemSensors[i]
      if itemSensor.ID == event.entity.unit_number then
        itemSensor.ScanArea = GetScanArea(itemSensor.Sensor)
        itemSensor.ConnectedEntity = nil
        itemSensor.Inventory = {}
        SetConnectedEntity(itemSensor)
      end
    end
  end
end  


-- grouped stepping by Optera
-- 91307.27ms on 100k ticks
function OnTick(event)
  storage.tickCount = storage.tickCount or 1
  storage.SensorIndex = storage.SensorIndex or 1

  -- only work if index is within bounds
  if storage.SensorIndex <= #storage.ItemSensors then
    local lastIndex = storage.SensorIndex + storage.SensorStride - 1
    if lastIndex >= #storage.ItemSensors then
      lastIndex = #storage.ItemSensors
    end

    -- log("[IS] "..storage.tickCount.." / "..game.tick.." updating sensors "..storage.SensorIndex.." to "..lastIndex)
    for i=storage.SensorIndex, lastIndex do
      local itemSensor = storage.ItemSensors[i]
      -- log("[IS] skipScan: "..tostring(itemSensor.SkipEntityScanning).." LastScan: "..tostring(itemSensor.LastScanned).."/"..game.tick)

      if not itemSensor.Sensor.valid then
          RemoveSensor(itemSensor.ID) -- remove invalidated sensors
      else
        if not itemSensor.SkipEntityScanning and (game.tick - itemSensor.LastScanned) >= ScanInterval then
          SetConnectedEntity(itemSensor)
        end
        UpdateSensor(itemSensor)
      end
    end
    storage.SensorIndex = lastIndex + 1
  end

  -- reset clock and index
  if storage.tickCount < UpdateInterval then
    storage.tickCount = storage.tickCount + 1
  else
    storage.tickCount = 1
    storage.SensorIndex = 1
  end
end

-- stepping from tick modulo with stride by eradicator
-- 93048.58ms on 100k ticks: 1.9% slower than grouped stepping
-- function OnTick(event)
  -- local offset = event.tick % UpdateInterval
  -- for i=#storage.ItemSensors - offset, 1, -1 * UpdateInterval do
    -- local itemSensor = storage.ItemSensors[i]
    -- if not itemSensor.SkipEntityScanning and (event.tick - itemSensor.LastScanned) >= ScanInterval then
      -- SetConnectedEntity(itemSensor)
    -- end
    -- UpdateSensor(itemSensor)
  -- end
-- end

---- LOGIC ----

-- recalculates how many sensors are updated each tick
function ResetStride()
  if #storage.ItemSensors > UpdateInterval then
    storage.SensorStride =  ceil(#storage.ItemSensors/UpdateInterval)
  else
    storage.SensorStride = 1
  end
  -- log("[IS] stride set to "..storage.SensorStride)
end


function ResetSensors()
  storage.ItemSensors = storage.ItemSensors or {}
  for i=1, #storage.ItemSensors do
    local itemSensor = storage.ItemSensors[i]
    itemSensor.ID = itemSensor.Sensor.unit_number
    itemSensor.ScanArea = GetScanArea(itemSensor.Sensor)
    itemSensor.SkipEntityScanning = false
    itemSensor.ConnectedEntity = nil
    itemSensor.Inventory = {}
    SetConnectedEntity(itemSensor)
  end
end

function GetScanArea(sensor)
  if sensor.direction == defines.direction.north then
    return{{sensor.position.x - ScanOffset, sensor.position.y}, {sensor.position.x + ScanOffset, sensor.position.y + ScanRange}}
  elseif sensor.direction == defines.direction.east then
    return{{sensor.position.x - ScanRange, sensor.position.y - ScanOffset}, {sensor.position.x, sensor.position.y + ScanOffset}}
  elseif sensor.direction == defines.direction.south then
    return{{sensor.position.x - ScanOffset, sensor.position.y - ScanRange}, {sensor.position.x + ScanOffset, sensor.position.y}}
  elseif sensor.direction == defines.direction.west then
    return{{sensor.position.x, sensor.position.y - ScanOffset}, {sensor.position.x + ScanRange, sensor.position.y + ScanOffset}}
  end
end

-- cache inventories, keep inventory index
function SetInventories(itemSensor, entity)
  itemSensor.Inventory = {}
  local inv = nil
  for i=1, 8 do -- iterate blindly over every possible inventory and store the result so we have to do it only once
    inv = entity.get_inventory(i)
    if inv then
      itemSensor.Inventory[i] = inv
    end
  end
end

function SetConnectedEntity(itemSensor)
  itemSensor.LastScanned = game.tick
--   rendering.draw_rectangle {
--     color = {r=1},
--     surface = itemSensor.Sensor.surface,
--     left_top = itemSensor.ScanArea[1],
--     right_bottom = itemSensor.ScanArea[2],
--     time_to_live = 10,
--   }
  local connectedEntities = itemSensor.Sensor.surface.find_entities(itemSensor.ScanArea)
  -- log("DEBUG: Found "..#connectedEntities.." entities in direction "..itemSensor.Sensor.direction)
  if connectedEntities then
    for i=1, #connectedEntities do
      local entity = connectedEntities[i]
      if entity.valid and SupportedTypes[entity.type] ~= nil and not Entity_Blacklist[entity.name] then
        -- log("DEBUG: Sensor "..itemSensor.Sensor.unit_number.." found entity "..tostring(entity.type).." "..tostring(entity.name))
        if itemSensor.ConnectedEntity ~= entity then
          SetInventories(itemSensor, entity)
        end
        itemSensor.ConnectedEntity = entity
        itemSensor.SkipEntityScanning = SupportedTypes[entity.type]
        return
      end
    end
  end
  -- if no entity was found remove stored data
  -- log("DEBUG: Sensor "..itemSensor.Sensor.unit_number.." no entity found")
  itemSensor.ConnectedEntity = nil
  itemSensor.SkipEntityScanning = false
  itemSensor.Inventory = {}
end


function UpdateSensor(itemSensor)
  local sensor = itemSensor.Sensor
  local connectedEntity = itemSensor.ConnectedEntity

  -- clear output of invalid connections
  if not connectedEntity or not connectedEntity.valid or not itemSensor.Inventory then
    itemSensor.ConnectedEntity = nil
    itemSensor.Inventory = {}
    itemSensor.SkipEntityScanning = false
    itemSensor.SiloStatus = nil
    local control_behavior = sensor.get_control_behavior() --[[@as LuaConstantCombinatorControlBehavior ]]
    local section = control_behavior.get_section(1)
    section.filters = {}
    return
  end

  local burner = connectedEntity.burner -- caching burner makes no difference in performance
  local remaining_fuel = 0
  ---@type LogisticFilter[]
  local signals = {}
  local signalIndex = 1

  -- Vehicle signals and movement detection
  if connectedEntity.type == LOCO then
    if connectedEntity.train.state == defines.train_state.wait_station
    or connectedEntity.train.state == defines.train_state.wait_signal
    or connectedEntity.train.state == defines.train_state.manual_control then --keeps showing inventory for ScanInterval ticks after movement start > neglect able
      signals[signalIndex] = parameter_locomotive
      signalIndex = 2
    else -- train is moving > remove connection
      itemSensor.ConnectedEntity = nil
      itemSensor.Inventory = {}
      itemSensor.SkipEntityScanning = false
      local control_behavior = sensor.get_control_behavior() --[[@as LuaConstantCombinatorControlBehavior ]]
      local section = control_behavior.get_section(1)
      section.filters = {}
        return
    end

  elseif connectedEntity.type == WAGON or connectedEntity.type == WAGONFLUID or connectedEntity.type == WAGONARTILLERY then
    if connectedEntity.train.state == defines.train_state.wait_station
    or connectedEntity.train.state == defines.train_state.wait_signal
    or connectedEntity.train.state == defines.train_state.manual_control then --keeps showing inventory for ScanInterval ticks after movement start > neglect able
      signals[signalIndex] = parameter_wagon
      signalIndex = 2
    else -- train is moving > remove connection
      itemSensor.ConnectedEntity = nil
      itemSensor.Inventory = {}
      itemSensor.SkipEntityScanning = false
      local control_behavior = sensor.get_control_behavior() --[[@as LuaConstantCombinatorControlBehavior ]]
      local section = control_behavior.get_section(1)
      section.filters = {}
      return
    end

  elseif connectedEntity.type == CAR then
    if tostring(connectedEntity.speed) == "0" then --car isn't moving
      if connectedEntity.name == TANK then
        signals[signalIndex] = parameter_tank
      else
        signals[signalIndex] = parameter_car
      end
      signalIndex = 2
    else -- car is moving > remove connection
      itemSensor.ConnectedEntity = nil
      itemSensor.Inventory = {}
      itemSensor.SkipEntityScanning = false
      local control_behavior = sensor.get_control_behavior() --[[@as LuaConstantCombinatorControlBehavior ]]
      local section = control_behavior.get_section(1)
      section.filters = {}
      return
    end

  elseif connectedEntity.type == SPIDER then
    -- in 1.0 spidertron doesn't have speed exposed
    if tostring(connectedEntity.speed) == "0" then
      signals[signalIndex] = parameter_spider
      signalIndex = 2
    else -- car is moving > remove connection
      itemSensor.ConnectedEntity = nil
      itemSensor.Inventory = {}
      itemSensor.SkipEntityScanning = false
      local control_behavior = sensor.get_control_behavior() --[[@as LuaConstantCombinatorControlBehavior ]]
      local section = control_behavior.get_section(1)
      section.filters = {}
      return
    end

  -- special signals
  elseif connectedEntity.type == ASSEMBLER or connectedEntity.type == FURNACE then
    local progress = connectedEntity.crafting_progress
    if progress then
      signals[signalIndex] = {value = signal_progress, min = floor(progress*100)}
      signalIndex = signalIndex+1
    end

  elseif connectedEntity.type == LAB then
    local progress = connectedEntity.force.research_progress
    if progress then
      signals[signalIndex] = {value = signal_progress, min = floor(progress*100)}
      signalIndex = signalIndex+1
    end

  elseif connectedEntity.type == SILO then
    -- rocket inventory is nil when no rocket is ready so we have to constantly grab all possible inventories.
    SetInventories(itemSensor, connectedEntity)

    local parts = connectedEntity.rocket_parts
    -- rocket_parts becomes 0 when a rocket is built and lifted up for launch
    -- we display 100 until it takes off
    if itemSensor.SiloStatus == nil and parts > 0 then
      itemSensor.SiloStatus = 1 -- building rocket
    elseif itemSensor.SiloStatus == 1 and connectedEntity.get_inventory(defines.inventory.rocket_silo_rocket) then
      itemSensor.SiloStatus = 2 -- rocket ready
    elseif itemSensor.SiloStatus == 2 and not connectedEntity.get_inventory(defines.inventory.rocket_silo_rocket) then
      itemSensor.SiloStatus = nil -- rocket has been launched
    end
    if itemSensor.SiloStatus and parts == 0 then parts = 100 end

    signals[signalIndex] = {value = signal_progress, min = parts}
    signalIndex = signalIndex+1

  end

  --get temperature
  local temp = connectedEntity.temperature
  if temp then
    signals[signalIndex] = {value = signal_temperature ,min = floor(temp+0.5)}
    signalIndex = signalIndex+1
  end

  -- get all fluids
  
  for i=1, connectedEntity.fluids_count, 1 do
    local fluid = connectedEntity.get_fluid(i)
    if fluid then
      signals[signalIndex] = { value = {type = "fluid", name = fluid.name, quality='normal' }, min = ceil(fluid.amount) }
      signalIndex = signalIndex+1
    end
  end

  -- get items in all inventories
  for inv_index, inv in pairs(itemSensor.Inventory) do
    local contentsTable = inv.get_contents()
    for _, entry in pairs(contentsTable) do
      signals[signalIndex] = { value = {type = "item", name = entry.name, quality = entry.quality }, min = entry.count }
      signalIndex = signalIndex+1
      -- add fuel values for items in fuel inventory
      if burner and inv_index == defines.inventory.fuel then
        remaining_fuel = remaining_fuel + (storage.fuel_values[entry.name] * entry.count)
      end
    end
  end

  -- get remaining fuel from burner
  if burner then
    if burner.remaining_burning_fuel > 0 then -- remaining_burning_fuel can be negative for some reason
      remaining_fuel = remaining_fuel + burner.remaining_burning_fuel / 1000000 -- game reports J we use MJ
    end

    signals[signalIndex] = {value = signal_fuel ,min = min(floor(remaining_fuel + 0.5), 2147483647)}
    signalIndex = signalIndex+1
  end

  -- get equipment grids if available
  if Read_Grid and connectedEntity.grid then
    -- grid.get_contents() returns equipment.name while signal needs item.name
    local grid_equipment = connectedEntity.grid.equipment
    local items = {}
    for _, equipment in pairs(grid_equipment) do
      local name = equipment.prototype.take_result.name
      items[name] = (items[name] or 0) + 1
    end
    for k, v in pairs(items) do
      signals[signalIndex] = { value = {type = "item",name = k}, min = v }
      signalIndex = signalIndex+1
    end
  end

  local control_behavior = sensor.get_control_behavior() --[[@as LuaConstantCombinatorControlBehavior ]]
  local section = control_behavior.get_section(1)
  assert(section)
  section.filters = {}
  for idx, signal in pairs(signals) do
    section.set_slot(idx, signal)
  end
end

---- INIT ----
do

local function init_globals()
  -- use MJ instead of J, won't run into int overflow as easily and is in line with fuel tooltip
  storage.fuel_values = {}
  for name, item in pairs(prototypes.item) do
    if item.fuel_category then
      storage.fuel_values[name] = item.fuel_value / 1000000
    end
  end
end

local function init_events()
  script.on_event( defines.events.on_built_entity, OnEntityCreated, EVENT_FILTER )
  script.on_event( defines.events.on_robot_built_entity, OnEntityCreated, EVENT_FILTER )
  script.on_event( defines.events.on_entity_cloned, OnEntityCreated, EVENT_FILTER )
  script.on_event( {defines.events.script_raised_built, defines.events.script_raised_revive}, OnEntityCreated )

  script.on_event( defines.events.on_pre_player_mined_item, OnEntityRemoved, EVENT_FILTER )
  script.on_event( defines.events.on_robot_pre_mined, OnEntityRemoved, EVENT_FILTER )
  script.on_event( defines.events.on_entity_died, OnEntityRemoved, EVENT_FILTER )
  script.on_event( defines.events.script_raised_destroy, OnEntityRemoved )

  script.on_event( defines.events.on_player_rotated_entity, OnEntityRotated )

  if storage.ItemSensors and #storage.ItemSensors > 0 then
    script.on_event( defines.events.on_tick, OnTick )
  end
end

script.on_load(function()
  init_events()
end)

script.on_init(function()
  storage.ItemSensors = storage.ItemSensors or {}
  init_globals()
  ResetStride()
  init_events()
  log(MOD_NAME.." "..tostring(script.active_mods[MOD_NAME]).." initialized.")
end)

script.on_configuration_changed(function(data)
  init_globals()
  ResetSensors()
  ResetStride()
  init_events()
  if data.mod_changes[MOD_NAME] then
    log(MOD_NAME.." migration from "..tostring(data.mod_changes[MOD_NAME].old_version).." to "..tostring(data.mod_changes[MOD_NAME].new_version).." complete.")
  end
end)

end
