require "config"

-- Events

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
    itemSensor.ConnectedEntity, itemSensor.SkipEntityScanning = getConnectedEntity(itemSensor.Sensor)
    itemSensor.Inventory = setInventory(itemSensor.ConnectedEntity)
  end
end)

function onLoad()
	if global.ItemSensors and #global.ItemSensors > 0 then
		script.on_event(defines.events.on_tick, ticker) --subscribe ticker when sensors exist
	end
end


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
  if global.ItemSensors ~= nil and event.entity.name == "item-sensor" then
    removeItemSensor(event.entity)
  end
end)

script.on_event(defines.events.on_robot_pre_mined, function(event)
  if global.ItemSensors ~= nil and event.entity.name == "item-sensor" then
    removeItemSensor(event.entity)
  end
end)

script.on_event(defines.events.on_entity_died, function(event)
  if global.ItemSensors ~= nil and event.entity.name == "item-sensor" then
    removeItemSensor(event.entity)
  end
end)


function ticker(event)
	if global.ItemSensors ~= nil and #global.ItemSensors > 0 then
  local tick = game.tick
		for i=1, #global.ItemSensors do
      local itemSensor = global.ItemSensors[i]
			if not itemSensor.SkipEntityScanning and (i + tick) % find_entity_interval == 0 then
				itemSensor.ConnectedEntity, itemSensor.SkipEntityScanning = getConnectedEntity(itemSensor.Sensor)
        itemSensor.Inventory = setInventory(itemSensor.ConnectedEntity)
			end
			if (i + tick) % update_interval == 0 then
				updateSensor(itemSensor)
			end
		end
	else
		script.on_event(defines.events.on_tick, nil) --unsubscribe if no sensors
	end
end

-- Logic

function CreateItemSensor(entity)
	if global.ItemSensors == nil then
		global.ItemSensors = {}
	end
  if #global.ItemSensors == 0 then
    script.on_event(defines.events.on_tick, ticker) --subscribe ticker
  end
	entity.operable = false
	entity.rotatable = true
	local itemSensor = {}
  itemSensor.ID = entity.unit_number
  itemSensor.Sensor = entity
  itemSensor.ConnectedEntity, itemSensor.SkipEntityScanning = getConnectedEntity(entity)
  itemSensor.Inventory = setInventory(itemSensor.ConnectedEntity)

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

-- returns first found connectable entity
function getConnectedEntity(sensor)
  local connectedEntities = {}
  if sensor.direction == 0 then --south
     connectedEntities = sensor.surface.find_entities({{sensor.position.x - BBox_offset, sensor.position.y}, {sensor.position.x + BBox_offset, sensor.position.y + BBox_range}})
  elseif sensor.direction == 2 then --west
    connectedEntities = sensor.surface.find_entities({{sensor.position.x - BBox_range, sensor.position.y - BBox_offset}, {sensor.position.x, sensor.position.y + BBox_offset}})
  elseif sensor.direction == 4 then --north
    connectedEntities = sensor.surface.find_entities({{sensor.position.x - BBox_offset, sensor.position.y - BBox_range}, {sensor.position.x + BBox_offset, sensor.position.y}})
  elseif sensor.direction == 6 then --east
    connectedEntities = sensor.surface.find_entities({{sensor.position.x, sensor.position.y - BBox_offset}, {sensor.position.x + BBox_range, sensor.position.y + BBox_offset}})
  end
  --printmsg("Found "..#connectedEntities.." entities in direction "..sensor.direction)
  if connectedEntities then
  for i=1, #connectedEntities do
    local entity = connectedEntities[i]
    if entity.valid then
      if entity.type == "furnace" or entity.type == "assembling-machine" or entity.type == "roboport" then
        return entity, true
      elseif entity.type == "locomotive" or entity.type == "cargo-wagon" or entity.type == "car" then
        return entity, false
      end
    end
  end
  end
end

-- returns array of inventories
function setInventory(entity)
  local inventory = {}
  if entity and entity.valid then
    if entity.type == "locomotive" then
      inventory[1] = entity.get_inventory(defines.inventory.fuel)
    elseif entity.type == "cargo-wagon" then
      inventory[1] = entity.get_inventory(defines.inventory.cargo_wagon)
    elseif entity.type == "car" then
      for i=1, 4, 1 do
        local tempInv = entity.get_inventory(i)
        if tempInv then
          inventory[#inventory+1] = tempInv
        end
      end
    elseif entity.type == "assembling-machine" then
      for i=1, 4, 1 do
        local tempInv = entity.get_inventory(i)
        if tempInv then
          inventory[#inventory+1] = tempInv
        end
      end
    elseif entity.type == "furnace" then
      for i=1, 4, 1 do
        local tempInv = entity.get_inventory(i)
        if tempInv then
          inventory[#inventory+1] = tempInv
        end
      end
    elseif entity.type == "roboport" then
      for i=1, 2, 1 do
        local tempInv = entity.get_inventory(i)
        if tempInv then
          inventory[#inventory+1] = tempInv
        end
      end
    end
  end
  return inventory
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

	local contents = {}
	local signals = {}
	local EntityDetected = false

	-- get locomotive inventory
	if connectedEntity.type == "locomotive" then
		if connectedEntity.train.state == defines.train_state.wait_station
		or connectedEntity.train.state == defines.train_state.wait_signal
		or connectedEntity.train.state == defines.train_state.manual_control then --keeps showing inventory for find_entity_interval ticks after movement start > neglect able
			EntityDetected = true
			signals[1] = {index=1,signal={type="virtual",name="detected-locomotive"},count=1}
			contents = itemSensor.Inventory[1].get_contents()
		else -- train is moving > remove connection
      itemSensor.ConnectedEntity = nil
      itemSensor.Inventory = {}
      itemSensor.SkipEntityScanning = false
			sensor.get_control_behavior().parameters = nil
			return
		end

	-- get traincar inventory
	elseif connectedEntity.type == "cargo-wagon" then
		if connectedEntity.train.state == defines.train_state.wait_station or
		  connectedEntity.train.state == defines.train_state.wait_signal or
		  connectedEntity.train.state == defines.train_state.manual_control then --keeps showing inventory for find_entity_interval ticks after movement start > neglect able
			EntityDetected = true
			signals[1] = {index=1,signal={type="virtual",name="detected-wagon"},count=1}
      contents = itemSensor.Inventory[1].get_contents()
		else -- train is moving > remove connection
      itemSensor.ConnectedEntity = nil
      itemSensor.Inventory = {}
      itemSensor.SkipEntityScanning = false
			sensor.get_control_behavior().parameters = nil
			return
		end

	-- get car/tank inventory
	elseif connectedEntity.type == "car" then
		if tostring(connectedEntity.speed) == "0" then --car isn't moving
			EntityDetected = true
			if connectedEntity.name == "tank" then
				signals[1] = {index=1,signal={type="virtual",name="detected-tank"},count=1}
			else
				signals[1] = {index=1,signal={type="virtual",name="detected-car"},count=1}
			end
			for i=1, #itemSensor.Inventory, 1 do
        local contentsTable = itemSensor.Inventory[i].get_contents()
        for k,v in pairs(contentsTable) do
          contents = add_detected_items(contents, k, v)
        end
			end
		else -- car is moving > remove connection
      itemSensor.ConnectedEntity = nil
      itemSensor.Inventory = {}
      itemSensor.SkipEntityScanning = false
			sensor.get_control_behavior().parameters = nil
			return
		end

	-- get assembler inventory
	elseif connectedEntity.type == "assembling-machine" then
		EntityDetected = true
    for i=1, #itemSensor.Inventory, 1 do
      local contentsTable = itemSensor.Inventory[i].get_contents()
      for k,v in pairs(contentsTable) do
        contents = add_detected_items(contents, k, v)
      end
		end

	-- get furnace inventory
	elseif connectedEntity.type == "furnace" then
		EntityDetected = true
    for i=1, #itemSensor.Inventory, 1 do
      local contentsTable = itemSensor.Inventory[i].get_contents()
      for k,v in pairs(contentsTable) do
        contents = add_detected_items(contents, k, v)
      end
		end

	-- get roboport inventory
	elseif connectedEntity.type == "roboport" then
		EntityDetected = true
		itemSensor.logisticNetwork = connectedEntity.force.find_logistic_network_by_position(connectedEntity.position,connectedEntity.surface)		
    if itemSensor.logisticNetwork and itemSensor.logisticNetwork.valid then --logisticNetwork is nil when roboport is out of power
      signals[1] = {index=1,signal={type="virtual",name="all-lrobots"},count = itemSensor.logisticNetwork.all_logistic_robots}
      signals[2] = {index=2,signal={type="virtual",name="home-lrobots"},count = itemSensor.logisticNetwork.available_logistic_robots}
      signals[3] = {index=3,signal={type="virtual",name="all-crobots"},count = itemSensor.logisticNetwork.all_construction_robots}
      signals[4] = {index=4,signal={type="virtual",name="home-crobots"},count = itemSensor.logisticNetwork.available_construction_robots}
		end

    for i=1, #itemSensor.Inventory, 1 do
      local contentsTable = itemSensor.Inventory[i].get_contents()
      for k,v in pairs(contentsTable) do
        contents = add_detected_items(contents, k, v)
      end
		end
	end

	-- copy inventory to constant combinator parameters
	local ccParameter={}
	local signalIndex=1
	if EntityDetected then
		if signals ~= nil then
			--copy virtual-signals
			for i=1, #signals, 1 do
				ccParameter[signalIndex] = signals[i]
        signalIndex = signalIndex+1
			end
		end

		--copy inventory
		for k,v in pairs(contents) do
      ccParameter[signalIndex] = {index=signalIndex,signal={type="item",name=k},count=v}
      signalIndex = signalIndex+1
		end
	end
	sensor.get_control_behavior().parameters = {parameters=ccParameter}
end

function add_detected_items(inv, itemName, itemCount)
	local existing = inv[itemName]
	if existing == nil then
		inv[itemName] = itemCount
	else
		inv[itemName] = existing + itemCount
	end
	return inv
end

function printmsg(msg)
  for i,player in pairs(game.players) do
    player.print(msg)
  end
end