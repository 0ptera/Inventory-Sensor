-- constant prototypes names
local MOD_NAME = "Inventory Sensor"
local SENSOR = "item-sensor"

local ASSEMBLER = "assembling-machine"
local FURNACE = "furnace"
local LAB = "lab"
local REACTOR = "reactor"
local ROBOPORT = "roboport"
local SILO = "rocket-silo"
local ARTILLERY = "artillery-turret"
local CHEST = "logistic-container" -- requester: type = "logistic-container" && logistic_mode = "requester"
local LOCO = "locomotive"
local WAGON = "cargo-wagon"
local WAGONFLUID = "fluid-wagon"
local WAGONARTILLERY = "artillery-wagon"
local CAR = "car"
local TANK = "tank"
local BOILER = "boiler"
local GENERATOR = "generator"
local STORAGE_TANK = "storage-tank"

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
  [CAR] = false,
  [LOCO] = false,
  [WAGON] = false,
  [WAGONFLUID] = false,
  [WAGONARTILLERY] = false,
  [BOILER] = true,
  [GENERATOR] = true,
  [STORAGE_TANK] = true,
}

local parameter_locomotive = {index=1, signal={type="virtual",name="inv-sensor-detected-locomotive"}, count=1}
local parameter_wagon = {index=1, signal={type="virtual",name="inv-sensor-detected-wagon"}, count=1}
local parameter_car = {index=1, signal={type="virtual",name="inv-sensor-detected-car"}, count=1}
local parameter_tank = {index=1, signal={type="virtual",name="inv-sensor-detected-tank"}, count=1}
local signal_progress = {type = "virtual",name = "inv-sensor-progress"}
local signal_temperature = {type = "virtual",name = "inv-sensor-temperature"}
local signal_fuel = {type = "virtual",name = "inv-sensor-fuel"}

local floor = math.floor
local ceil = math.ceil


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
  if (event.created_entity.name == SENSOR) then
    local entity = event.created_entity
    global.ItemSensors = global.ItemSensors or {}

    entity.operable = false
    entity.rotatable = false
    local itemSensor = {}
    itemSensor.ID = entity.unit_number
    itemSensor.Sensor = entity
    itemSensor.ScanArea = GetScanArea(entity)
    SetConnectedEntity(itemSensor)

    global.ItemSensors[#global.ItemSensors+1] = itemSensor

    if #global.ItemSensors == 1 then
      script.on_event(defines.events.on_tick, OnTick)
      script.on_event({defines.events.on_pre_player_mined_item, defines.events.on_robot_pre_mined, defines.events.on_entity_died}, OnEntityRemoved)
    end

    ResetStride()
  end
end

-- called from on_entity_removed and when entity becomes invalid
function RemoveSensor(sensorID)
  for i=#global.ItemSensors, 1, -1 do
    if global.ItemSensors[i].ID == sensorID then
      table.remove(global.ItemSensors,i)
    end
  end

  if #global.ItemSensors == 0 then
    script.on_event(defines.events.on_tick, nil)
    script.on_event({defines.events.on_pre_player_mined_item, defines.events.on_robot_pre_mined, defines.events.on_entity_died}, nil)
  end

  ResetStride()
end

function OnEntityRemoved(event)
-- script.on_event({defines.events.on_pre_player_mined_item, defines.events.on_robot_pre_mined, defines.events.on_entity_died}, function(event)
  if event.entity.name == SENSOR then
    RemoveSensor(event.entity.unit_number)
  end
end


-- grouped stepping by Optera
-- 91307.27ms on 100k ticks
function OnTick(event)
  global.tickCount = global.tickCount or 1
  global.SensorIndex = global.SensorIndex or 1

  -- only work if index is within bounds
  if global.SensorIndex <= #global.ItemSensors then
    local lastIndex = global.SensorIndex + global.SensorStride - 1
    if lastIndex >= #global.ItemSensors then
      lastIndex = #global.ItemSensors
    end

    -- log("[IS] "..global.tickCount.." / "..game.tick.." updating sensors "..global.SensorIndex.." to "..lastIndex)
    for i=global.SensorIndex, lastIndex do
      local itemSensor = global.ItemSensors[i]
      -- log("[IS] skipScan: "..tostring(itemSensor.SkipEntityScanning).." LastScan: "..tostring(itemSensor.LastScanned).."/"..game.tick)
      if not itemSensor.SkipEntityScanning and (game.tick - itemSensor.LastScanned) >= ScanInterval then
        SetConnectedEntity(itemSensor)
      end

      UpdateSensor(itemSensor)
    end
    global.SensorIndex = lastIndex + 1
  end

  -- reset clock and index
  if global.tickCount < UpdateInterval then
    global.tickCount = global.tickCount + 1
  else
    global.tickCount = 1
    global.SensorIndex = 1
  end
end

-- stepping from tick modulo with stride by eradicator
-- 93048.58ms on 100k ticks: 1.9% slower than grouped stepping
-- function OnTick(event)
  -- local offset = event.tick % UpdateInterval
  -- for i=#global.ItemSensors - offset, 1, -1 * UpdateInterval do
    -- local itemSensor = global.ItemSensors[i]
    -- if not itemSensor.SkipEntityScanning and (event.tick - itemSensor.LastScanned) >= ScanInterval then
      -- SetConnectedEntity(itemSensor)
    -- end
    -- UpdateSensor(itemSensor)
  -- end
-- end

---- LOGIC ----

-- recalculates how many sensors are updated each tick
function ResetStride()
  if #global.ItemSensors > UpdateInterval then
    global.SensorStride =  ceil(#global.ItemSensors/UpdateInterval)
  else
    global.SensorStride = 1
  end
  -- log("[IS] stride set to "..global.SensorStride)
end


function ResetSensors()
  global.ItemSensors = global.ItemSensors or {}
  for i=1, #global.ItemSensors do
    local itemSensor = global.ItemSensors[i]
    itemSensor.ID = itemSensor.Sensor.unit_number
    itemSensor.ScanArea = GetScanArea(itemSensor.Sensor)
    itemSensor.ConnectedEntity = nil
    itemSensor.Inventory = {}
    SetConnectedEntity(itemSensor)
  end
end

function GetScanArea(sensor)
  if sensor.direction == 0 then --south
     return{{sensor.position.x - ScanOffset, sensor.position.y}, {sensor.position.x + ScanOffset, sensor.position.y + ScanRange}}
  elseif sensor.direction == 2 then --west
    return{{sensor.position.x - ScanRange, sensor.position.y - ScanOffset}, {sensor.position.x, sensor.position.y + ScanOffset}}
  elseif sensor.direction == 4 then --north
    return{{sensor.position.x - ScanOffset, sensor.position.y - ScanRange}, {sensor.position.x + ScanOffset, sensor.position.y}}
  elseif sensor.direction == 6 then --east
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
  local connectedEntities = itemSensor.Sensor.surface.find_entities(itemSensor.ScanArea)
  --printmsg("[IS] Found "..#connectedEntities.." entities in direction "..sensor.direction)
  if connectedEntities then
    for i=1, #connectedEntities do
      local entity = connectedEntities[i]
      if entity.valid and SupportedTypes[entity.type] ~= nil then
        -- log("[IS] Sensor "..itemSensor.Sensor.unit_number.." found entity "..tostring(entity.type))
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
  -- log("[IS] Sensor "..itemSensor.Sensor.unit_number.." no entity found")
  itemSensor.ConnectedEntity = nil
  itemSensor.SkipEntityScanning = false
  itemSensor.Inventory = {}
end


function UpdateSensor(itemSensor)
  local sensor = itemSensor.Sensor
  local connectedEntity = itemSensor.ConnectedEntity

  -- remove invalidated sensors
  if not sensor.valid then
    RemoveSensor(itemSensor.ID)
    return
  end

  -- clear output of invalid connections
  if not connectedEntity or not connectedEntity.valid or not itemSensor.Inventory then
    itemSensor.ConnectedEntity = nil
    itemSensor.Inventory = {}
    itemSensor.SkipEntityScanning = false
    itemSensor.SiloStatus = nil
    sensor.get_control_behavior().parameters = nil
    return
  end

  local burner = connectedEntity.burner -- caching burner makes no difference in performance
  local remaining_fuel = 0
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
      sensor.get_control_behavior().parameters = nil
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
      sensor.get_control_behavior().parameters = nil
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
      sensor.get_control_behavior().parameters = nil
      return
    end

  -- special signals
  elseif connectedEntity.type == ASSEMBLER or connectedEntity.type == FURNACE then
    local progress = connectedEntity.crafting_progress
    if progress then
      signals[signalIndex] = {index = signalIndex, signal = signal_progress, count = floor(progress*100)}
      signalIndex = signalIndex+1
    end

 elseif connectedEntity.type == LAB then
    local progress = connectedEntity.force.research_progress
    if progress then
      signals[signalIndex] = {index = signalIndex, signal = signal_progress, count = floor(progress*100)}
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

    signals[signalIndex] = {index = signalIndex, signal = signal_progress, count = parts}
    signalIndex = signalIndex+1

  end

  --get temperature
  local temp = connectedEntity.temperature
  if temp then
    signals[signalIndex] = {index = signalIndex, signal = signal_temperature ,count = floor(temp+0.5)}
    signalIndex = signalIndex+1
  end

  -- get all fluids
  for i=1, #connectedEntity.fluidbox, 1 do
    local fluid = connectedEntity.fluidbox[i]
    if fluid then
      signals[signalIndex] = { index = signalIndex, signal = {type = "fluid",name = fluid.name}, count = ceil(fluid.amount) }
      signalIndex = signalIndex+1
    end
  end

  -- get items in all inventories
  for inv_index, inv in pairs(itemSensor.Inventory) do
    local contentsTable = inv.get_contents()
    for k,v in pairs(contentsTable) do
      signals[signalIndex] = { index = signalIndex, signal = {type = "item",name = k}, count = v }
      signalIndex = signalIndex+1
      -- add fuel values for items in fuel inventory
      if burner and inv_index == defines.inventory.fuel then
        remaining_fuel = remaining_fuel + (global.fuel_values[k] * v)
      end
    end
  end

  -- get remaining fuel from burner
  if burner then
    if burner.remaining_burning_fuel > 0 then -- remaining_burning_fuel can be negative for some reason
      remaining_fuel = remaining_fuel + burner.remaining_burning_fuel / 1000000 -- game reports J we use MJ
    end

    signals[signalIndex] = {index = signalIndex, signal = signal_fuel ,count = floor(remaining_fuel + 0.5)}
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
      signals[signalIndex] = { index = signalIndex, signal = {type = "item",name = k}, count = v }
      signalIndex = signalIndex+1
    end
  end

  sensor.get_control_behavior().parameters = {parameters=signals}
end

---- INIT ----
do

local function init_globals()
  -- use MJ instead of J, won't run into int overflow as easily and is in line with fuel tooltip
  global.fuel_values = {}
  for name, item in pairs(game.item_prototypes) do
    if item.fuel_category then
      global.fuel_values[name] = item.fuel_value / 1000000
    end
  end
end

local function init_events()
  script.on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity}, OnEntityCreated)
  if global.ItemSensors and #global.ItemSensors > 0 then
    script.on_event(defines.events.on_tick, OnTick)
    script.on_event({defines.events.on_pre_player_mined_item, defines.events.on_robot_pre_mined, defines.events.on_entity_died}, OnEntityRemoved)
  end
end

script.on_load(function()
  init_events()
end)

script.on_init(function()
  global.ItemSensors = global.ItemSensors or {}
  init_globals()
  ResetStride()
  init_events()
  log(MOD_NAME.." "..tostring(game.active_mods[MOD_NAME]).." initialized.")
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
