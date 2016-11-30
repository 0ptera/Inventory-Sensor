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
  for k, itemSensor in pairs(global.ItemSensors) do
    itemSensor.ID = itemSensor.Sensor.unit_number
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
			if (i + tick) % find_entity_interval == 0 then
				global.ItemSensors[i].ConnectedEntity = getConnectedEntity(global.ItemSensors[i].Sensor)	
			end				
			if (i + tick) % update_interval == 0 then
				setInventory(global.ItemSensors[i])
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
  itemSensor.ConnectedEntity = getConnectedEntity(entity)
  
	table.insert(global.ItemSensors, itemSensor)  
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
    if (entity.valid and (entity.type == "furnace" or entity.type == "assembling-machine" or entity.type == "roboport" 
    or entity.type == "locomotive" or entity.type == "cargo-wagon" or entity.type == "car")) then
      return entity      
    end
  end
  end
end

function setInventory(itemSensor)
	local sensor = itemSensor.Sensor
	local connectedEntity = itemSensor.ConnectedEntity
	
	local inventory = {}
	local signals = {}
	local EntityDetected = false
	
	-- return empty inventory
	if connectedEntity ==nil then
		sensor.get_control_behavior().parameters = nil
		return
	end
	
	if not connectedEntity.valid then
		sensor.get_control_behavior().parameters = nil
		return	
	end

	-- get locomotive inventory
	if connectedEntity.type == "locomotive" then
		if connectedEntity.train.state == defines.train_state.wait_station 
		or connectedEntity.train.state == defines.train_state.wait_signal 
		or connectedEntity.train.state == defines.train_state.manual_control then --keeps showing inventory for find_entity_interval ticks after movement start > neglect able
			EntityDetected = true
			signals[1] = {index=1,signal={type="virtual",name="detected-locomotive"},count=1}
			-- I have yet to see a mod with locomotive cargo inventory
      if connectedEntity.get_inventory(defines.inventory.fuel) then
        inventory = connectedEntity.get_inventory(defines.inventory.fuel).get_contents()
      end
		else -- train is moving > remove connection
			connectedEntity = nil
			sensor.get_control_behavior().parameters = nil
			return
		end
	end
	
	-- get traincar inventory
	if connectedEntity.type == "cargo-wagon" then
		if connectedEntity.train.state == defines.train_state.wait_station or 
		  connectedEntity.train.state == defines.train_state.wait_signal or 
		  connectedEntity.train.state == defines.train_state.manual_control then --keeps showing inventory for find_entity_interval ticks after movement start > neglect able
			EntityDetected = true
			signals[1] = {index=1,signal={type="virtual",name="detected-wagon"},count=1}
			if connectedEntity.get_inventory(defines.inventory.cargo_wagon) then
				inventory = connectedEntity.get_inventory(defines.inventory.cargo_wagon).get_contents()  
			end
		else -- train is moving > remove connection
			connectedEntity = nil
			sensor.get_control_behavior().parameters = nil
			return
		end
	end

	-- get car/tank inventory
	if connectedEntity.type == "car" then
		if tostring(connectedEntity.speed) == "0" then --car isn't moving
			EntityDetected = true
			if connectedEntity.name == "tank" then
				signals[1] = {index=1,signal={type="virtual",name="detected-tank"},count=1}
			else
				signals[1] = {index=1,signal={type="virtual",name="detected-car"},count=1}
			end
			for i=1, 4, 1 do
				if connectedEntity.get_inventory(i) then
					local contentsTable = connectedEntity.get_inventory(i).get_contents()
					for k,v in pairs(contentsTable) do
						inventory = add_detected_items(inventory, k, v)						
					end		  
				end
			end
		else -- car is moving > remove connection
			connectedEntity = nil
			sensor.get_control_behavior().parameters = nil
			return
		end
	end
	
	-- get assembler inventory
	if connectedEntity.type == "assembling-machine" then
		EntityDetected = true
		for i=1, 4, 1 do --should be 2-4, but perhaps there's a burner assembler mod with fuel inventory too
			if connectedEntity.get_inventory(i) then
				local contentsTable = connectedEntity.get_inventory(i).get_contents()
				for k,v in pairs(contentsTable) do
					inventory = add_detected_items(inventory, k, v)						
				end		  
			end
		end
	end
	
	-- get furnace inventory
	if connectedEntity.type == "furnace" then
		EntityDetected = true
		for i=1, 4, 1 do
			if connectedEntity.get_inventory(i) then
				local contentsTable = connectedEntity.get_inventory(i).get_contents()
				for k,v in pairs(contentsTable) do
					inventory = add_detected_items(inventory, k, v)						
				end		  
			end
		end
	end

	-- get roboport inventory
	if connectedEntity.type == "roboport" then
		EntityDetected = true
		if itemSensor.logisticNetwork == nil or not itemSensor.logisticNetwork.valid then
			itemSensor.logisticNetwork = connectedEntity.force.find_logistic_network_by_position(connectedEntity.position,connectedEntity.surface)
		end
		signals[1] = {index=1,signal={type="virtual",name="all-lrobots"},count = itemSensor.logisticNetwork.all_logistic_robots}
		signals[2] = {index=2,signal={type="virtual",name="home-lrobots"},count = itemSensor.logisticNetwork.available_logistic_robots}
		signals[3] = {index=3,signal={type="virtual",name="all-crobots"},count = itemSensor.logisticNetwork.all_construction_robots}
		signals[4] = {index=4,signal={type="virtual",name="home-crobots"},count = itemSensor.logisticNetwork.available_construction_robots}
		
		for i=1, 2, 1 do 
			if connectedEntity.get_inventory(i) then
        --printmsg("Found Roboport inventory at index "..i)
				local contentsTable = connectedEntity.get_inventory(i).get_contents()
				for k,v in pairs(contentsTable) do
					inventory = add_detected_items(inventory, k, v)						
				end		  
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
		for k,v in pairs(inventory) do 			
			--table.insert(ccParameter, {index=signalIndex,signal={type="item",name=k},count=v})
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