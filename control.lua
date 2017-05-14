require "config"

-- constant prototypes names
local SENSOR = "item-sensor"

local ASSEMBLER = "assembling-machine"
local FURNACE = "furnace"
local REACTOR = "reactor"
local ROBOPORT = "roboport"
local SILO = "rocket-silo"
local CHEST = "logistic-container" -- requester: type = "logistic-container" && logistic_mode = "requester"
local LOCO = "locomotive"
local WAGON = "cargo-wagon"
local WAGONFLUID = "fluid-wagon"
local CAR = "car"
local TANK = "tank"

local SupportedTypes = {
  [ASSEMBLER] = true,
  [FURNACE] = true,
  [REACTOR] = true,
  [ROBOPORT] = true,
  [SILO] = true,
  [CHEST] = true,
  [CAR] = false,
  [LOCO] = false,
  [WAGON] = false,
  [WAGONFLUID] = false
}
---- Events ----

function onLoad()
	if global.ItemSensors and #global.ItemSensors > 0 then
		script.on_event(defines.events.on_tick, ticker) --subscribe ticker when sensors exist
	end
end

script.on_init(function()
  global.ItemSensors = global.ItemSensors or {}
  onLoad()
end)

script.on_load(function()
  onLoad()
end)

script.on_configuration_changed(function(data)
  global.ItemSensors = global.ItemSensors or {}
  for i=1, #global.ItemSensors do
    local itemSensor = global.ItemSensors[i]
    itemSensor.ID = itemSensor.Sensor.unit_number
    itemSensor.ScanArea = getScanArea(itemSensor.Sensor)
    itemSensor.ConnectedEntity = nil
    itemSensor.Inventory = {}
    setConnectedEntity(itemSensor)
  end
end)

script.on_event(defines.events.on_built_entity, function(event)
	if (event.created_entity.name == "item-sensor") then
		CreateItemSensor(event.created_entity)
	end
end)

script.on_event(defines.events.on_robot_built_entity, function(event)
	if (event.created_entity.name == "item-sensor") then
		CreateItemSensor(event.created_entity)
	end
end)


script.on_event(defines.events.on_preplayer_mined_item, function(event)
  if global.ItemSensors ~= nil and event.entity.name == SENSOR then
    removeItemSensor(event.entity)
  end
end)

script.on_event(defines.events.on_robot_pre_mined, function(event)
  if global.ItemSensors ~= nil and event.entity.name == SENSOR then
    removeItemSensor(event.entity)
  end
end)

script.on_event(defines.events.on_entity_died, function(event)
  if global.ItemSensors ~= nil and event.entity.name == SENSOR then
    removeItemSensor(event.entity)
  end
end)


function ticker(event)
	if global.ItemSensors ~= nil and #global.ItemSensors > 0 then
  local tick = game.tick
		for i=1, #global.ItemSensors do
      local itemSensor = global.ItemSensors[i]
			if not itemSensor.SkipEntityScanning and (i + tick) % find_entity_interval == 0 then
				setConnectedEntity(itemSensor)
			end
			if (i + tick) % update_interval == 0 then
				updateSensor(itemSensor)
			end
		end
	else
		script.on_event(defines.events.on_tick, nil) --unsubscribe if no sensors
	end
end

---- Logic ----

function CreateItemSensor(entity)
	if global.ItemSensors == nil then
		global.ItemSensors = {}
	end
  if #global.ItemSensors == 0 then
    script.on_event(defines.events.on_tick, ticker) --subscribe ticker
  end
	entity.operable = false
	entity.rotatable = false
	local itemSensor = {}
  itemSensor.ID = entity.unit_number
  itemSensor.Sensor = entity
  itemSensor.ScanArea = getScanArea(entity)
  setConnectedEntity(itemSensor)

	global.ItemSensors[#global.ItemSensors+1] = itemSensor
end

function removeItemSensor(entity)
  for i=#global.ItemSensors, 1, -1 do
    if entity.unit_number == global.ItemSensors[i].ID then
      table.remove(global.ItemSensors,i)
      return
    end
  end
end

function getScanArea(sensor)
  if sensor.direction == 0 then --south
     return{{sensor.position.x - BBox_offset, sensor.position.y}, {sensor.position.x + BBox_offset, sensor.position.y + BBox_range}}
  elseif sensor.direction == 2 then --west
    return{{sensor.position.x - BBox_range, sensor.position.y - BBox_offset}, {sensor.position.x, sensor.position.y + BBox_offset}}
  elseif sensor.direction == 4 then --north
    return{{sensor.position.x - BBox_offset, sensor.position.y - BBox_range}, {sensor.position.x + BBox_offset, sensor.position.y}}
  elseif sensor.direction == 6 then --east
    return{{sensor.position.x, sensor.position.y - BBox_offset}, {sensor.position.x + BBox_range, sensor.position.y + BBox_offset}}
  end
end

function setConnectedEntity(itemSensor)  
  local connectedEntities = itemSensor.Sensor.surface.find_entities(itemSensor.ScanArea)
  --printmsg("Found "..#connectedEntities.." entities in direction "..sensor.direction)
  if connectedEntities then
    for i=1, #connectedEntities do
      local entity = connectedEntities[i]
      if entity.valid and SupportedTypes[entity.type] ~= nil and itemSensor.ConnectedEntity ~= entity then      
        itemSensor.Inventory = {}
        itemSensor.ConnectedEntity = entity
        itemSensor.SkipEntityScanning = SupportedTypes[entity.type]
        local inv = nil
        for i=1, 8 do -- iterate blindly over every possible inventory and store the result so we have to do it only once
          inv = entity.get_inventory(i)
          if inv then
            itemSensor.Inventory[#itemSensor.Inventory+1] = inv
            log(entity.name.." adding inventory "..i)
          end
        end
        return
      end
    end
  end
end

function updateSensor(itemSensor)
	local sensor = itemSensor.Sensor
	local connectedEntity = itemSensor.ConnectedEntity

	-- clear output of invalid connections
  if not connectedEntity or not connectedEntity.valid or not itemSensor.Inventory then
    itemSensor.ConnectedEntity = nil
    itemSensor.Inventory = {}
    itemSensor.SkipEntityScanning = false
		sensor.get_control_behavior().parameters = nil
		return
	end

	local signals = {}
  local signalIndex = 1

  -- Vehicle signals and movement detection
  if connectedEntity.type == LOCO then
    if connectedEntity.train.state == defines.train_state.wait_station
		or connectedEntity.train.state == defines.train_state.wait_signal
		or connectedEntity.train.state == defines.train_state.manual_control then --keeps showing inventory for find_entity_interval ticks after movement start > neglect able
      signals[signalIndex] = {index = signalIndex, signal={type="virtual",name="detected-locomotive"},count=1}
      signalIndex = signalIndex+1
    else -- train is moving > remove connection
      itemSensor.ConnectedEntity = nil
      itemSensor.Inventory = {}
      itemSensor.SkipEntityScanning = false
			sensor.get_control_behavior().parameters = nil
			return
		end
  elseif connectedEntity.type == WAGON or connectedEntity.type == WAGONFLUID then
    if connectedEntity.train.state == defines.train_state.wait_station
		or connectedEntity.train.state == defines.train_state.wait_signal
		or connectedEntity.train.state == defines.train_state.manual_control then --keeps showing inventory for find_entity_interval ticks after movement start > neglect able
      signals[signalIndex] = {index = signalIndex, signal={type="virtual",name="detected-wagon"},count=1}
      signalIndex = signalIndex+1
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
        signals[signalIndex] = {index = signalIndex, signal={type="virtual",name="detected-tank"},count=1}
      else
        signals[signalIndex] = {index = signalIndex, signal={type="virtual",name="detected-car"},count=1}
      end
      signalIndex = signalIndex+1
    else -- car is moving > remove connection
      itemSensor.ConnectedEntity = nil
      itemSensor.Inventory = {}
      itemSensor.SkipEntityScanning = false
			sensor.get_control_behavior().parameters = nil
			return
    end    
  end

  -- special signals
  if connectedEntity.type == ASSEMBLER or connectedEntity.type == FURNACE then 
    local progress = connectedEntity.crafting_progress
    if progress then
      signals[signalIndex] = {index = signalIndex, signal = {type = "virtual",name = "inv-sensor-progress"},count = math.ceil(progress*100)}
      signalIndex = signalIndex+1
    end
  end
  if connectedEntity.type == SILO then 
    local progress = connectedEntity.rocket_parts
    if progress then
      signals[signalIndex] = {index = signalIndex, signal = {type = "virtual",name = "inv-sensor-progress"},count = progress}
      signalIndex = signalIndex+1
    end
  end
  if connectedEntity.type == REACTOR then
    local temp = connectedEntity.temperature
    if temp then
      signals[signalIndex] = {index = signalIndex, signal = {type = "virtual",name = "inv-sensor-temperature"},count = math.floor(temp+0.5)}
      signalIndex = signalIndex+1
    end
  end
  
  -- get all fluids
  for i=1, #connectedEntity.fluidbox, 1 do
    local fluid = connectedEntity.fluidbox[i]
    if fluid then     
      signals[signalIndex] = {index = signalIndex, signal = {type = "fluid",name = fluid.type},count = math.floor(fluid.amount+0.5) }
      signalIndex = signalIndex+1
    end
  end
  
  -- get items in all inventories
  for _, inv in pairs(itemSensor.Inventory) do
    local contentsTable = inv.get_contents()
    log(connectedEntity.name.." inventories "..#itemSensor.Inventory)
    for k,v in pairs(contentsTable) do
      signals[signalIndex] = {index = signalIndex, signal = {type = "item",name = k},count = v }
      signalIndex = signalIndex+1
    end
  end

	sensor.get_control_behavior().parameters = {parameters=signals}
end
