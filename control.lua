require "defines"
--local wagonsInit = false

-- local isTankerAndNotMoving = fucntion(tanker)
	-- if tanker ~= nil and isValid(tanker.entity) then
		-- local train = entity.train
		-- if isValid(train) then
			-- if train.speed <= 0.001 then
				-- return true
			-- end
		-- end
	-- end
	-- return false
-- end


-- added by Choumiko
remote.add_interface("railtanker",
    {
      getLiquidByWagon = function(wagon)
        local tanker = getTankerFromEntity(global.tankers, wagon)
        local res = {amount = 0, type = nil}
        reattachProxy(tanker)
        if tanker ~= nil and isValid(tanker.entity) and tanker.entity.name == "rail-tanker" then
            if tanker.proxy ~= nil then
                if tanker.proxy.fluidbox[1] ~= nil then
                    res = {amount = tanker.proxy.fluidbox[1].amount, type = tanker.proxy.fluidbox[1].type}
                end
            else
                if tanker.fluidbox ~= nil then
                    res = {amount = tanker.fluidbox.amount, type = tanker.fluidbox.type}
                end
            end
        end
        return res
      end
    }
)


isEntityMoving = function(entity)
	return entity.train.speed ~= 0
end

isTankerMoving = function(tanker)
	return (isEntityMoving(tanker.entity))
end

isTankerValid = function(tanker)
	return(tanker ~= nil and (isValid(tanker.proxy))) --  or (isValid(tanker.entity) and (tanker.entity.state ~= 8 or tanker.entity.state ~= 9))))
end

onTickMain = function(event)
	if global.manualTankers == nil then
		game.on_event(defines.events.on_tick, nil)
	elseif event.tick % 20 == 16 then
		for i,tanker in ipairs(global.manualTankers) do
			if isValid(tanker.entity) then
				if isEntityMoving(tanker.entity) then
					if isValid(tanker.proxy) then
						--global.stoppedTankers = remove_if(function(val) return tanker.entity.equals(val.entity) end, global.stoppedTankers)
						tanker.fluidbox = tanker.proxy.fluidbox[1]
						tanker.proxy.destroy()
						tanker.proxy = nil
					else
						tanker.proxy = bil
					end
				elseif tanker.proxy == nil then
					--table.insert(valueOrNewTable(global.stoppedTanker),tanker)
					tanker.proxy=createProxy(tanker.entity.position, tanker.fluidbox, tanker.entity.surface)
				end
			end
		end
		
		-- global.stoppedTankers = filter(isTankerValid, global.stoppedTankers)
		-- if global.stoppedTankers ~= nil then
			-- for i,tanker in ipairs(global.stoppedTankers) do
				-- tanker.fluidbox = tanker.proxy.fluidbox[1]
			-- end
			-- if #global.stoppedTankers < 1 then
				-- global.stoppedTankers = nil
			-- end
		-- end
		global.manualTankers = nilIfEmptyTable(global.manualTankers)
	end
end

isTankerEntity = function(entity)
	--if isValid(entity) then debugLog(entity.name) end
	return (isValid(entity) and entity.name == "rail-tanker")
	
end

isPumpEntity = function (entity)
	--if isValid(entity) then debugLog(entity.name) end
	return (isValid(entity) and entity.type == "pump")
end


entityRemoved = function (event)
	if isTankerEntity(event.entity) then
		local newFunction = function (val) return val.entity == event.entity end
		local tanker = getTankerFromEntity(global.tankers, event.entity)
		if isTankerValid(tanker) then
			if isValid(tanker.proxy) then
				tanker.proxy.destroy()
				tanker.proxy = nil
			end
			global.tankers = nilIfEmptyTable(remove_if(newFunction, global.tankers))
			global.manualTankers = nilIfEmptyTable(remove_if(newFunction, global.manualTankers)) 
		end
	end
end
-- game.on_event(defines.events.on_tick, function(event)

-- end)

destroyProxyies = function(val)
	if val ~= nil and not isValid(val.tanker) then 
		if isValid(val.proxy) then 
			debugLog("DESTORY!")
			val.proxy.destroy()
		end
		debugLog("REMOVE!")
		return true
	end
	return false
end

script.on_event(defines.events.on_preplayer_mined_item, entityRemoved)
script.on_event(defines.events.on_robot_pre_mined, entityRemoved)
script.on_event(defines.events.on_entity_died, entityRemoved)

-- script.on_event(defines.events.on_entity_died, function(event)
	-- local removeValue
	-- if isTankerEntity(event.entity) and global.tankers ~= nil then
		-- local position = event.entity.position
		-- for i, tanker in pairs(global.tankers) do
			-- if isValid(tanker.proxy) and tanker.proxy.position.x == position.x and tanker.proxy.position.y == position.y then
				-- tanker.proxy.destroy()
			-- end
		-- end
		-- global.tankers = nilIfEmptyTable(remove_if(destroyProxyies, global.tankers))
		-- global.manualTankers = nilIfEmptyTable(remove_if(destroyProxyies, global.manualTankers))
	-- end
-- end)


entityBuilt = function(event)
	debugLog("On build")
	local entity = event.created_entity
	if isTankerEntity(entity) then
		debugLog("entity is tanker")
		local tanker = {entity = entity}
		--table.insert(valueOrNewTable(global.tankers), tanker)
		if not isTankerMoving(tanker) then
			tanker.proxy=createProxy(entity.position, tanker.fluidbox, entity.surface)
			--table.insert(valueOrNewTable(global.stoppedTankers), tanker)
			--game.on_event(defines.events.on_tick, onTickMain)
		end
		global.tankers = valueOrNewTable(global.tankers)
		table.insert(global.tankers, tanker)
		debugLog("new tanker: " .. #global.tankers)
		if entity.train.state == 9 then
			debugLog("Manual Train")
			global.manualTankers = valueOrNewTable(global.manualTankers)
			table.insert(global.manualTankers, tanker)
			debugLog("manual tanker: " .. #global.manualTankers)
			game.on_event(defines.events.on_tick, onTickMain)
		end
	elseif isPumpEntity(entity) then
		local position = entity.position
		local foundEntities = entity.surface.find_entities_filtered{area = {{position.x - 1.5, position.y - 1.5}, {position.x + 1.5, position.y + 1.5}}, name="rail-tanker"}
		for i,entity in ipairs(foundEntities) do
			local tanker = getTankerFromEntity(global.tankers,entity)
			if isTankerValid(tanker) and isValid(tanker.proxy) and tanker.proxy.name == "rail-tanker-proxy-noconnect" then
				tanker.fluidbox = tanker.proxy.fluidbox[1]
				tanker.proxy.destroy()
				tanker.proxy = createProxy(tanker.entity.position, tanker.fluidbox, tanker.entity.surface)
			end
		end
	end
end

script.on_load(function()
	reattachProxies(global.tankers)
	if global.manualTankers ~= nil then
		game.on_event(defines.events.on_tick, onTickMain)
	end
end)

function reattachProxies(tankers)
	if tankers ~= nil then
		for i, tanker in ipairs(tankers) do
			reattachProxy(tanker)
		end
	end
end

function reattachProxy(tanker)
	if isTankerValid(tanker) then
		if tanker.entity.surface == nil then
			tanker.proxy = findProxy(tanker.entity.position, game.get_surface(1))
		else
			tanker.proxy = findProxy(tanker.entity.position, tanker.entity.surface)
		end
	end
end

script.on_event(defines.events.on_built_entity, entityBuilt)
script.on_event(defines.events.on_robot_built_entity, entityBuilt)

  -- -- normal state - following the path
  -- on_the_path = 0,
  -- -- had path and lost it - must stop
  -- path_lost = 1,
  -- -- doesn't have anywhere to go
  -- no_schedule = 2,
  -- -- has no path and is stopped
  -- no_path = 3,
  -- -- braking before the railSignal
  -- arrive_signal = 4,
  -- wait_signal = 5,
  -- -- braking before the station
  -- arrive_station = 6,
  -- wait_station = 7,
  -- -- switched to the manual control and has to stop
  -- manual_control_stop = 8,
  -- -- can move if user explicitly sits in and rides the train
  -- manual_control = 9,
  -- -- train was switched to auto control but it is moving and needs to be stopped
  -- stop_for_auto_control = 10

-- local stateChanges = {0 = function(train)

script.on_event(defines.events.on_train_changed_state, function(event)
	local train = event.train
	local tankers = filter(isTankerEntity, train.carriages)
	for i,entity in ipairs(tankers) do
		--debugLog("Tanker state: " .. train.state)
		
		local tanker = getTankerFromEntity(global.tankers,entity)
		if tanker == nil then
			--debugLog("something went wrong!")
			tanker = {entity = entity}
			global.tankers = valueOrNewTable(global.tankers)
			table.insert(global.tankers, tanker)
		end
		local state = train.state
		if state ~= 8 and state ~= 9 and global.manualTankers ~= nil then -- Remove manual train on state change
			global.manualTankers = remove_if(function (val) return val.entity == entity end, global.manualTankers)
		end
		
		
		if state == 3 or state == 5 or state == 7 then --Stopped
			--debugLog("Train Stopped " .. i)
			--local tanker = {entity = entity, proxy=createProxy(entity.position), fluidbox = tanker.proxy.fluidbox[1][1]}
			tanker.proxy = createProxy(entity.position, tanker.fluidbox, entity.surface)
			--table.insert(valueOrNewTable(global.stoppedTankers), tanker)
			--game.on_event(defines.events.on_tick, onTickMain)
		elseif state == 8 or state == 9 then -- Manual Control, WHY IS THERE ONE TRAIN STATE FOR MANUAL CONTROL? COZ FUCK YOU THATS WHY!
			--debugLog("Train Manual " .. i)
			global.manualTankers = valueOrNewTable(global.manualTankers)
			table.insert(global.manualTankers, tanker)
			game.on_event(defines.events.on_tick, onTickMain)
		else --moving
			--debugLog("Train moving" .. i)
			--global.stoppedTankers = remove_if(function (val) return entity.equals(val.entity) end, global.stoppedTankers)
			if isValid(tanker.proxy) then
				tanker.fluidbox = tanker.proxy.fluidbox[1]
				tanker.proxy.destroy()
				tanker.proxy = nil
			end
		end
	end
end)

function getTankerFromEntity(tankers, entity)
	if tankers == nil then return nil end
	--debugLog("tankers not nil")
	for i,value in ipairs(tankers) do
		if isValid(value.entity) and entity == value.entity then
			return value
		end
	end
end

function createProxy(position, fluidbox, surface)
	--local offsetPosition = {x = position.x, y = position.y}
	--offsetPosition = position
	local pumps = surface.find_entities_filtered{area = {{position.x - 1.5, position.y - 1.5}, {position.x + 1.5, position.y + 1.5}}, type="pump"}
	local proxyName = "rail-tanker-proxy-noconnect"
	if isValid(pumps[1]) then
		--debugLog("foundpump" .. game.tick)
		proxyName = "rail-tanker-proxy"
	end
	local foundProxy = surface.create_entity{name=proxyName, position=position, force=game.players[1].force}
	--local foundProxy = findProxy(position)
	foundProxy.fluidbox[1] = fluidbox
	--debugLog(foundProxy.name .. game.tick)
	return foundProxy
end

function findProxy(position, surface)
	local entities = surface.find_entities{{position.x - 0.5, position.y - 0.5}, {position.x + 0.5, position.y + 0.5}}
	local foundProxies = nil
	for i, entity in ipairs(entities) do
		if isValid(entity) and (entity.name == "rail-tanker-proxy" or entity.name == "rail-tanker-proxy-noconnect") then
			--debugLog("Found entity: " .. entity.name)
			if foundProxies == nil then
				foundProxies = entity
			else
				if isValid(entity) then
					entity.destroy()
				end
			end
		end
	end
	return foundProxies
end



function isValid(entity)
	return(entity ~= nil and entity.valid)
end

function debugLog(message)
	if false then -- set for debug
		for i,player in ipairs(game.players) do
			player.print(message)
		end
	end
end 

function valueOrNewTable(value)
	if value == nil then
		debugLog("NewTable")
		return {}
	else
		return value
	end
end

function nilIfEmptyTable(value)
	if value == nil or #value < 1 then
		return nil
	else 
		return value
	end
end

-- I have no idea what I am doing with these!
--https://en.wikibooks.org/wiki/Lua_Functional_Programming/Functions
function remove_if(func, arr)
  if arr == nil then return nil end
  local new_array = {}
  for _,v in ipairs(arr) do
    if not func(v) then table.insert(new_array, v) end
  end
  return new_array
end
function filter(func, arr)
	if arr == nil then return nil end
	local new_array = {}
	for _,v in ipairs(arr) do
		if func(v) then table.insert(new_array, v) end
	end
	return new_array
end
