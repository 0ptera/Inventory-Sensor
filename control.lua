require "config"

-- constant prototypes names
local SENSOR = "item-sensor"

local ASSEMBLER = "assembling-machine"
local FURNACE = "furnace"
local ROBOPORT = "roboport"
local LOCO = "locomotive"
local WAGON = "cargo-wagon"
local CAR = "car"
local TANK = "tank"
local CHEST = "logistic-container" -- requester: type = "logistic-container" && logistic_mode = "requester"

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
  itemSensor.Inventory = itemSensor.Inventory or {}
  local connectedEntities = itemSensor.Sensor.surface.find_entities(itemSensor.ScanArea)
  --printmsg("Found "..#connectedEntities.." entities in direction "..sensor.direction)
  if connectedEntities then
    for i=1, #connectedEntities do
      local entity = connectedEntities[i]
      if entity.valid then
        if entity.type == FURNACE or entity.type == ASSEMBLER or entity.type == ROBOPORT then
          itemSensor.ConnectedEntity = entity
          itemSensor.SkipEntityScanning = true
          itemSensor.Inventory[1] = entity.get_inventory(1)
          itemSensor.Inventory[2] = entity.get_inventory(2)
          itemSensor.Inventory[3] = entity.get_inventory(3)
          itemSensor.Inventory[4] = entity.get_inventory(4)
          return
        elseif entity.type == CHEST and entity.prototype.logistic_mode == "requester" then
          itemSensor.ConnectedEntity = entity
          itemSensor.SkipEntityScanning = true
          itemSensor.Inventory[1] = entity.get_inventory(defines.inventory.chest)
          itemSensor.Inventory[2] = nil
          itemSensor.Inventory[3] = nil
          itemSensor.Inventory[4] = nil
          return
        elseif entity.type == LOCO then
          itemSensor.ConnectedEntity = entity
          itemSensor.SkipEntityScanning = false
          itemSensor.Inventory[1] = entity.get_inventory(defines.inventory.fuel)
          itemSensor.Inventory[2] = nil
          itemSensor.Inventory[3] = nil
          itemSensor.Inventory[4] = nil
          return
        elseif entity.type == WAGON then
          itemSensor.ConnectedEntity = entity
          itemSensor.SkipEntityScanning = false
          itemSensor.Inventory[1] = entity.get_inventory(defines.inventory.cargo_wagon)
          itemSensor.Inventory[2] = nil
          itemSensor.Inventory[3] = nil
          itemSensor.Inventory[4] = nil
          return
        elseif entity.type == CAR then
          itemSensor.ConnectedEntity = entity
          itemSensor.SkipEntityScanning = false
          itemSensor.Inventory[1] = entity.get_inventory(1)
          itemSensor.Inventory[2] = entity.get_inventory(2)
          itemSensor.Inventory[3] = entity.get_inventory(3)
          itemSensor.Inventory[4] = entity.get_inventory(4)
          return
        end
      end
    end
  end
end

function updateSensor(itemSensor)
	local sensor = itemSensor.Sensor
	local connectedEntity = itemSensor.ConnectedEntity

	-- clear output of invalid connections
	if not connectedEntity or not connectedEntity.valid or not itemSensor.Inventory or #itemSensor.Inventory < 1 then
    itemSensor.ConnectedEntity = nil
    itemSensor.Inventory = {}
    itemSensor.SkipEntityScanning = false
		sensor.get_control_behavior().parameters = nil
		return
	end

	local signals = {}
  local signalIndex = 1

	-- get assembler inventory
	if connectedEntity.type == ASSEMBLER then
		EntityDetected = true
    for i=1, #connectedEntity.fluidbox, 1 do
      local fluid = connectedEntity.fluidbox[i]
      if fluid then
        --fluids = Merge2Table(fluids, fluid.type, fluid.amount)
        signals[signalIndex] = {index = signalIndex, signal = {type = "fluid",name = fluid.type},count = math.floor(fluid.amount+0.5) }
        signalIndex = signalIndex+1
      end
    end
    for i, inv in pairs(itemSensor.Inventory) do
      local contentsTable = inv.get_contents()
      for k,v in pairs(contentsTable) do
        --items = Merge2Table(items, k, v)
        signals[signalIndex] = {index = signalIndex, signal = {type = "item",name = k},count = v }
        signalIndex = signalIndex+1
      end
		end

	-- get furnace inventory
	elseif connectedEntity.type == FURNACE then
		for i, inv in pairs(itemSensor.Inventory) do
      local contentsTable = inv.get_contents()
      for k,v in pairs(contentsTable) do
        --items = Merge2Table(items, k, v)
        signals[signalIndex] = {index = signalIndex, signal = {type = "item",name = k},count = v }
        signalIndex = signalIndex+1
      end
		end

	-- get roboport inventory
	elseif connectedEntity.type == ROBOPORT then
		for i, inv in pairs(itemSensor.Inventory) do
      local contentsTable = inv.get_contents()
      for k,v in pairs(contentsTable) do
        --items = Merge2Table(items, k, v)
        signals[signalIndex] = {index = signalIndex, signal = {type = "item",name = k},count = v }
        signalIndex = signalIndex+1
      end
		end

  	-- get requester chest inventory
	elseif connectedEntity.type == CHEST and connectedEntity.prototype.logistic_mode == "requester" then
    local contentsTable = itemSensor.Inventory[1].get_contents()
    for k,v in pairs(contentsTable) do
      signals[signalIndex] = {index = signalIndex, signal = {type = "item",name = k},count = v }
      signalIndex = signalIndex+1
    end

    -- get locomotive inventory
	elseif connectedEntity.type == LOCO then
		if connectedEntity.train.state == defines.train_state.wait_station
		or connectedEntity.train.state == defines.train_state.wait_signal
		or connectedEntity.train.state == defines.train_state.manual_control then --keeps showing inventory for find_entity_interval ticks after movement start > neglect able
			signals[1] = {index=1,signal={type="virtual",name="detected-locomotive"},count=1}
      signalIndex = 2
			local contentsTable = itemSensor.Inventory[1].get_contents()
      for k,v in pairs(contentsTable) do
        signals[signalIndex] = {index = signalIndex, signal = {type = "item",name = k},count = v }
        signalIndex = signalIndex+1
      end
		else -- train is moving > remove connection
      itemSensor.ConnectedEntity = nil
      itemSensor.Inventory = {}
      itemSensor.SkipEntityScanning = false
			sensor.get_control_behavior().parameters = nil
			return
		end

	-- get traincar inventory
	elseif connectedEntity.type == WAGON then
		if connectedEntity.train.state == defines.train_state.wait_station or
		  connectedEntity.train.state == defines.train_state.wait_signal or
		  connectedEntity.train.state == defines.train_state.manual_control then --keeps showing inventory for find_entity_interval ticks after movement start > neglect able
			signals[1] = {index=1,signal={type="virtual",name="detected-wagon"},count=1}
      signalIndex = 2
      local contentsTable = itemSensor.Inventory[1].get_contents()
      for k,v in pairs(contentsTable) do
        signals[signalIndex] = {index = signalIndex, signal = {type = "item",name = k},count = v }
        signalIndex = signalIndex+1
      end
		else -- train is moving > remove connection
      itemSensor.ConnectedEntity = nil
      itemSensor.Inventory = {}
      itemSensor.SkipEntityScanning = false
			sensor.get_control_behavior().parameters = nil
			return
		end

	-- get car/tank inventory
	elseif connectedEntity.type == CAR then
		if tostring(connectedEntity.speed) == "0" then --car isn't moving
			if connectedEntity.name == TANK then
				signals[1] = {index=1,signal={type="virtual",name="detected-tank"},count=1}
			else
				signals[1] = {index=1,signal={type="virtual",name="detected-car"},count=1}
			end
      signalIndex = 2
			for i, inv in pairs(itemSensor.Inventory) do
        local contentsTable = inv.get_contents()
        for k,v in pairs(contentsTable) do
          signals[signalIndex] = {index = signalIndex, signal = {type = "item",name = k},count = v }
          signalIndex = signalIndex+1
        end
			end
		else -- car is moving > remove connection
      itemSensor.ConnectedEntity = nil
      itemSensor.Inventory = {}
      itemSensor.SkipEntityScanning = false
			sensor.get_control_behavior().parameters = nil
			return
		end
  end
	sensor.get_control_behavior().parameters = {parameters=signals}
end
