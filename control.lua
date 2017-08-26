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

-- initialize variables
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

local floor = math.floor
local ceil = math.ceil


---- MOD SETTINGS ----

local UpdateInterval = settings.global["inv_sensor_update_interval"].value
local ScanInterval = settings.global["inv_sensor_find_entity_interval"].value
local ScanOffset = settings.global["inv_sensor_BBox_offset"].value
local ScanRange = settings.global["inv_sensor_BBox_range"].value

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
end)


---- EVENTS ----

function OnEntityCreated(event)
	if (event.created_entity.name == "item-sensor") then
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
			script.on_event({defines.events.on_preplayer_mined_item, defines.events.on_robot_pre_mined, defines.events.on_entity_died}, OnEntityRemoved)
		end
    
    ResetStride()
	end
end

function OnEntityRemoved(event)
-- script.on_event({defines.events.on_preplayer_mined_item, defines.events.on_robot_pre_mined, defines.events.on_entity_died}, function(event)
	if event.entity.name == SENSOR then
    for i=#global.ItemSensors, 1, -1 do
      if event.entity.unit_number == global.ItemSensors[i].ID then
        table.remove(global.ItemSensors,i)
      end
    end

		if #global.ItemSensors == 0 then
			script.on_event(defines.events.on_tick, nil)
			script.on_event({defines.events.on_preplayer_mined_item, defines.events.on_robot_pre_mined, defines.events.on_entity_died}, nil)
		end
    
    ResetStride()
	end
end


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

  -- reset clock and chest index
  if global.tickCount < UpdateInterval then
    global.tickCount = global.tickCount + 1
  else
    global.tickCount = 1
    global.SensorIndex = 1
  end
end

-- function OnTick(event)
	-- local tick = game.tick
	-- for i=1, #global.ItemSensors do
		-- local itemSensor = global.ItemSensors[i]
		-- if not itemSensor.SkipEntityScanning and (i + tick) % ScanInterval == 0 then
			-- SetConnectedEntity(itemSensor)
		-- end
		-- if (i + tick) % UpdateInterval == 0 then
			-- UpdateSensor(itemSensor)
		-- end
	-- end
-- end

---- LOGIC ----

-- recalculates how many sensors are updated each tick
function ResetStride()
  if #global.ItemSensors > UpdateInterval then
    global.SensorStride =  math.ceil(#global.ItemSensors/UpdateInterval)
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

function SetInventories(itemSensor, entity)
	itemSensor.Inventory = {}
	local inv = nil
	for i=1, 8 do -- iterate blindly over every possible inventory and store the result so we have to do it only once
		inv = entity.get_inventory(i)
		if inv then
			itemSensor.Inventory[#itemSensor.Inventory+1] = inv
			-- log("[IS] adding inventory "..tostring(inv.index))
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
			if entity.valid and SupportedTypes[entity.type] ~= nil and itemSensor.ConnectedEntity ~= entity then
				itemSensor.ConnectedEntity = entity
				itemSensor.SkipEntityScanning = SupportedTypes[entity.type]
				SetInventories(itemSensor, entity)
				return
			end
		end
	end
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
		sensor.get_control_behavior().parameters = nil
		return
	end

	local signals = {}
	local signalIndex = 1

	-- Vehicle signals and movement detection
	if connectedEntity.type == LOCO then
		if connectedEntity.train.state == defines.train_state.wait_station
		or connectedEntity.train.state == defines.train_state.wait_signal
		or connectedEntity.train.state == defines.train_state.manual_control then --keeps showing inventory for ScanInterval ticks after movement start > neglect able
			signals[signalIndex] = {index = signalIndex, signal={type="virtual",name="inv-sensor-detected-locomotive"},count=1}
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
		or connectedEntity.train.state == defines.train_state.manual_control then --keeps showing inventory for ScanInterval ticks after movement start > neglect able
			signals[signalIndex] = {index = signalIndex, signal={type="virtual",name="inv-sensor-detected-wagon"},count=1}
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
				signals[signalIndex] = {index = signalIndex, signal={type="virtual",name="inv-sensor-detected-tank"},count=1}
			else
				signals[signalIndex] = {index = signalIndex, signal={type="virtual",name="inv-sensor-detected-car"},count=1}
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
			signals[signalIndex] = {index = signalIndex, signal = {type = "virtual",name = "inv-sensor-progress"},count = floor(progress*100)}
			signalIndex = signalIndex+1
		end
	end
	if connectedEntity.type == SILO then
		-- rocket inventory is nil when no rocket is ready so we have to constantly grab all possible inventories.
		SetInventories(itemSensor, connectedEntity)

		local parts = connectedEntity.rocket_parts

		if itemSensor.SiloStatus == nil and parts >= 90 then
			itemSensor.SiloStatus = 1 -- rocket built
		elseif itemSensor.SiloStatus == 1 and connectedEntity.get_inventory(defines.inventory.rocket_silo_rocket) then
			itemSensor.SiloStatus = 2 -- rocket ready
		elseif itemSensor.SiloStatus == 2 and not connectedEntity.get_inventory(defines.inventory.rocket_silo_rocket) then
			itemSensor.SiloStatus = nil -- rocket has been launched
		end
		-- log("Silo Status: "..tostring(itemSensor.SiloStatus))
		if itemSensor.SiloStatus and parts < 90 then parts = 100 end

		signals[signalIndex] = {index = signalIndex, signal = {type = "virtual",name = "inv-sensor-progress"},count = parts}
		signalIndex = signalIndex+1
	end
	if connectedEntity.type == REACTOR then
		local temp = connectedEntity.temperature
		if temp then
			-- log("temp: "..tostring(temp))
			signals[signalIndex] = {index = signalIndex, signal = {type = "virtual",name = "inv-sensor-temperature"},count = floor(temp+0.5)}
			signalIndex = signalIndex+1
		end
	end

	-- get all fluids
	for i=1, #connectedEntity.fluidbox, 1 do
		local fluid = connectedEntity.fluidbox[i]
		if fluid then
			signals[signalIndex] = {index = signalIndex, signal = {type = "fluid",name = fluid.type},count = ceil(fluid.amount) }
			signalIndex = signalIndex+1
		end
	end

	-- get items in all inventories
	for _, inv in pairs(itemSensor.Inventory) do
		local contentsTable = inv.get_contents()
		for k,v in pairs(contentsTable) do
			signals[signalIndex] = {index = signalIndex, signal = {type = "item",name = k},count = v }
			signalIndex = signalIndex+1
		end
	end

	sensor.get_control_behavior().parameters = {parameters=signals}
end


---- INIT ----
do
local function init_events()
	script.on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity}, OnEntityCreated)
	if global.ItemSensors and #global.ItemSensors > 0 then
		script.on_event(defines.events.on_tick, OnTick)
		script.on_event({defines.events.on_preplayer_mined_item, defines.events.on_robot_pre_mined, defines.events.on_entity_died}, OnEntityRemoved)
	end
end

script.on_load(function()
  init_events()
end)

script.on_init(function()
  global.ItemSensors = global.ItemSensors or {}
  ResetStride()
  init_events()
end)

script.on_configuration_changed(function(data)
  ResetSensors()
  ResetStride()
	init_events()
  log("[IS] on_config_changed complete.")
end)

end
