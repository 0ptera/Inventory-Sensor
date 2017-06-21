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


---- Events ----

function init_events()
	log("[IS] OnEntityCreated registered")
	script.on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity}, OnEntityCreated)
	if global.ItemSensors and #global.ItemSensors > 0 then
		log("[IS] OnTick, OnEntityRemoved registered")
		script.on_event(defines.events.on_tick, OnTick)		
		script.on_event({defines.events.on_preplayer_mined_item, defines.events.on_robot_pre_mined, defines.events.on_entity_died}, OnEntityRemoved)
	end
end

script.on_init(function()
  global.ItemSensors = global.ItemSensors or {}
  init_events()
end)

script.on_load(function()
  init_events()
end)

script.on_configuration_changed(function(data)
	global.ItemSensors = global.ItemSensors or {}
	for i=1, #global.ItemSensors do
		local itemSensor = global.ItemSensors[i]
		itemSensor.ID = itemSensor.Sensor.unit_number
		itemSensor.ScanArea = GetScanArea(itemSensor.Sensor)
		itemSensor.ConnectedEntity = nil
		itemSensor.Inventory = {}
		SetConnectedEntity(itemSensor)
	end
	init_events()
end)

function OnEntityCreated(event)
	if (event.created_entity.name == "item-sensor") then
		CreateItemSensor(event.created_entity)
		if #global.ItemSensors == 1 then
			script.on_event(defines.events.on_tick, OnTick)
			script.on_event({defines.events.on_preplayer_mined_item, defines.events.on_robot_pre_mined, defines.events.on_entity_died}, OnEntityRemoved)
			log("[IS] OnTick, OnEntityRemoved registered")
		end	
	end
end

function OnEntityRemoved(event)
-- script.on_event({defines.events.on_preplayer_mined_item, defines.events.on_robot_pre_mined, defines.events.on_entity_died}, function(event)
	if event.entity.name == SENSOR then
		log("[IS] removing Sensor "..event.entity.unit_number)
		RemoveItemSensor(event.entity)
		if #global.ItemSensors == 0 then
			script.on_event(defines.events.on_tick, nil)
			script.on_event({defines.events.on_preplayer_mined_item, defines.events.on_robot_pre_mined, defines.events.on_entity_died}, nil)
			log("[IS] OnTick, OnEntityRemoved unregistered")
		end	
	end
end

function OnTick(event)	
	local tick = game.tick
	for i=1, #global.ItemSensors do
		local itemSensor = global.ItemSensors[i]
		if not itemSensor.SkipEntityScanning and (i + tick) % find_entity_interval == 0 then
			SetConnectedEntity(itemSensor)
		end
		if (i + tick) % update_interval == 0 then
			UpdateSensor(itemSensor)
		end
	end
end


---- Logic ----

function CreateItemSensor(entity)
	global.ItemSensors = global.ItemSensors or {}

	entity.operable = false
	entity.rotatable = false
	local itemSensor = {}
	itemSensor.ID = entity.unit_number
	itemSensor.Sensor = entity
	itemSensor.ScanArea = GetScanArea(entity)
	SetConnectedEntity(itemSensor)

	global.ItemSensors[#global.ItemSensors+1] = itemSensor
end

function RemoveItemSensor(entity)
	for i=#global.ItemSensors, 1, -1 do
		if entity.unit_number == global.ItemSensors[i].ID then
			table.remove(global.ItemSensors,i)
			log("[IS] removed Sensor "..entity.unit_number)
		end
	end
end

function GetScanArea(sensor)
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

function SetInventories(itemSensor, entity)
	itemSensor.Inventory = {}
	local inv = nil
	for i=1, 8 do -- iterate blindly over every possible inventory and store the result so we have to do it only once
		inv = entity.get_inventory(i)
		if inv then
			itemSensor.Inventory[#itemSensor.Inventory+1] = inv
			-- log("adding inventory "..tostring(inv.index))
		end
	end
end

function SetConnectedEntity(itemSensor)
	local connectedEntities = itemSensor.Sensor.surface.find_entities(itemSensor.ScanArea)
	--printmsg("Found "..#connectedEntities.." entities in direction "..sensor.direction)
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
		or connectedEntity.train.state == defines.train_state.manual_control then --keeps showing inventory for find_entity_interval ticks after movement start > neglect able
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
		or connectedEntity.train.state == defines.train_state.manual_control then --keeps showing inventory for find_entity_interval ticks after movement start > neglect able
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
