local Middlewares = {}

local RunService = game:GetService("RunService")

local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
--[[
---- ["Middlewares"] - 
   ----- It is the Path followed by Events . Key considerations to make it efficient - 
    (1) 
     
    ----- What it contains - Middlewares with Process function, Used to process(reject or allow)
     any event request. It contains private helper functions  to make Middleware .

]]

----------- Private -------------

local IsServer = RunService:IsServer()
local IsClient = RunService:IsClient()
local TableUtils = require(Registry.Shared.Modules.TableUtils)
local _Compare = TableUtils.Compare
local _GetValueAtPath = TableUtils.GetValueAtPath
local _SetValueAtPath = TableUtils.SetValueAtPath
local _GetOrSetIfNotAtPath = TableUtils.GetOrSetIfNotAtPath
local _CombineLists = TableUtils.CombineLists

----------------------------
---- State Management
----------------------------

Middlewares._state = {}

local function _GetCorrectStatePath(stateTypes, path)
	local userId, eventName, storeName = path.userId, path.eventName, path.middlewareName
	if not storeName then
		return
	end
	local clientStateType, serverStateType, seriesNumber = stateTypes.client, stateTypes.server, stateTypes.series
	local stateType = nil
	local SERIES_MAP = { [1] = { server = 2, client = 4 }, [2] = { server = 1, client = 3 } }
	if seriesNumber and not serverStateType and not clientStateType then
		local seriesElement = SERIES_MAP[seriesNumber]
		clientStateType, serverStateType = seriesElement.client, seriesElement.server
	end
	if IsServer and serverStateType then
		stateType = serverStateType
	elseif IsClient and clientStateType then
		stateType = clientStateType
	end
	if stateType == 1 and userId and eventName then
		return { storeName, userId, eventName }
	elseif stateType == 2 and userId then
		return { storeName, userId }
	elseif stateType == 3 and eventName then
		return { storeName, eventName }
	elseif stateType == 4 then
		return { storeName }
	else
		return nil
	end
end

local function _GetMiddlewareStore(storeName)
	return _GetOrSetIfNotAtPath(Middlewares._state, { storeName }, {})
end

local function _GetMiddlewareState(stateTypes, path, defaultValue)
	return _GetOrSetIfNotAtPath(Middlewares._state, _GetCorrectStatePath(stateTypes, path), defaultValue)
end

local function _SetMiddlewareState(stateTypes, Path, eventEntry)
	_SetValueAtPath(Middlewares._state, _GetCorrectStatePath(stateTypes, Path), eventEntry)
end

local function _ValidateDataSchema(data, Schema)
	for key, value in pairs(Schema) do
		if not data[key] then
			return false
		end
	end
	return true
end

local function _BuildMiddlewarePath(context, middlewareName)
	local userId = nil
	local eventDirection = context.eventDirection
	if IsServer then
		if eventDirection == "Outbound" then
			userId = context.target
		elseif eventDirection == "Inbound" then
			userId = context.sender.userId
		end
	end
	return { userId = userId or nil, eventName = context.eventName, middlewareName = middlewareName }
end

--------- RateLimiter ---------
local RateLimiter = { _DEFAULTS = { MaxFires = 400, CheckingTime = 1 } }

function RateLimiter.Process(context, next, config)
	local eventDirection = context.eventDirection
	local currentTime = tick()
	local maxFiresConfig = config.MaxFires
	local defaultFires, defaultResetTime, defaultMaxFires =
		0, tick() + RateLimiter._DEFAULTS.CheckingTime, RateLimiter._DEFAULTS.MaxFires
	local state = _GetMiddlewareState({ series = 2 }, _BuildMiddlewarePath(context, "RateLimiter"), {
		Inbound = { currentFires = defaultFires, resetTime = defaultResetTime, maxFires = defaultMaxFires },
		Outbound = { currentFires = defaultFires, resetTime = defaultResetTime, maxFires = defaultMaxFires },
	})
	state = state[eventDirection]
	if currentTime >= state.resetTime then
		RateLimiter._ResetRequestEntry(state)
	end
	local maxFires = maxFiresConfig or state.maxFires
	if state.currentFires <= maxFires then
		state.currentFires += 1
	else
		return
	end
	next(context)
end

function RateLimiter._ResetRequestEntry(state)
	state.currentFires = 0
	state.resetTime = tick() + RateLimiter._DEFAULTS.CheckingTime
end

Middlewares.RateLimiter = RateLimiter

---------- Validator ----------

local Validator = {}

function Validator.Process(context, next, config)
	if not context then
		return
	end
	local schema = config.Schema
	local data = context.data
	for schemaIndex, schemaType in pairs(schema) do
		local dataValue = data[schemaIndex]
		if not (dataValue or type(dataValue) == schemaType) then
			return
		end
	end
	next(context)
end
Middlewares.Validator = Validator

---------- Sanitizer -------------

local Sanitizer = {}

function Sanitizer._CheckRangeOfData(data, range)
	local min, max = range.min, range.max
	if data <= max and data >= min then
		return true
	end
	return false
end

function Sanitizer._CheckPossibilitiesOfData(data, possibleValues)
	for _, possibleValue in pairs(possibleValues) do
		if possibleValue == data then
			return true
		end
	end
	return false
end
function Sanitizer.Process(context, next, config)
	local data = context.data
	for dataField, dataValue in pairs(data) do
		local fieldConfig = config[dataField]
		if fieldConfig then
			local range, possibleValues = fieldConfig.Range, fieldConfig.Possible
			local isInRange, isHasPossibleValues = nil, nil
			if range then
				isInRange = Sanitizer._CheckRangeOfData(dataValue, range)
			end
			if possibleValues then
				isHasPossibleValues = Sanitizer._CheckPossibilitiesOfData(dataValue, possibleValues)
			end
			if range and not isInRange then
				return
			end
			if possibleValues and not isHasPossibleValues then
				return
			end
		end
	end
	next(context)
end

-------- HookValidator ----------

local HookValidator = {}

function HookValidator.RegisterHook(eventName, hookName, hookFunction)
	local eventHooks = _GetMiddlewareState(
		{ server = 3, client = 3 },
		{ eventName = eventName, middlewareName = "HookValidator" },
		{}
	)
	_GetOrSetIfNotAtPath(eventHooks, { eventName, hookName }, hookFunction)
end

function HookValidator.Process(context, next, config)
	local eventName = context.eventName
	local eventHooks = _GetMiddlewareState(
		{ server = 3, client = 3 },
		{ eventName = eventName, middlewareName = "HookValidator" },
		{}
	)
	if not eventHooks then
		return
	end
	for _, hookFunction in pairs(eventHooks) do
		local result = hookFunction(context)
		if not result then
			return
		end
	end
	next(context)
end
Middlewares.HookValidator = HookValidator

--------- AuthGuard ---------

local AuthGuard = {}
function AuthGuard.Process(context, next, config)
	local eventName = context.eventName
	local isHooked = _GetMiddlewareStore("HookValidator")[eventName]
	if not isHooked then
		return
	end
	next(context)
end
Middlewares.AuthGuard = AuthGuard
---------- Sequence Guard ---------

local SequenceGuard = {}

function SequenceGuard.Process(context, next, config)
	local defaultRequestEntry = { outboundSequence = 0, inboundSequence = 0 }
	local state =
		_GetMiddlewareState({ series = 1 }, _BuildMiddlewarePath(context, "SequenceGuard"), defaultRequestEntry)
	local eventDirection = context.eventDirection
	if eventDirection == "Outbound" then
		state.outboundSequence += 1
		context.sequence = state.outboundSequence
		if next then
			next(context)
		end
	end
	if eventDirection == "Inbound" then
		local contextSequence = context.sequence
		local currentSequence = state.inboundSequence
		local incrementSequence = currentSequence + 1
		if contextSequence == incrementSequence then
			context.sequence = nil
			state.inboundSequence += 1
			if next then
				next(context)
			end
		else
			return
		end
	end
end
Middlewares.SequenceGuard = SequenceGuard
---------- Batcher -------------

local Batcher = {}
function Batcher.Process(context, next, config)
	if context.eventDirection == "Inbound" then
		return
	end
	local state = _GetMiddlewareState(
		{ series = 1 },
		_BuildMiddlewarePath(context, "Batcher"),
		{ nextFunction = next, requests = {} }
	)
	if IsServer and not state.target then
		state.target = context.target
	end
	table.insert(state.requests, context)
end

local function ReleasePlayerEvents(state)
	local requests = state.requests
	if not requests then
		return
	end
	if #requests == 0 then
		return
	end
	local next = state.nextFunction
	state.nextFunction = nil
	state.isBatched = true
	for _, request in ipairs(requests) do
		if request.sequence then
			SequenceGuard.Process(request, nil, nil)
		end
	end
	next(state)
end

function Batcher.ReleaseEvents()
	if IsServer then
		local AllPlayersRequests = _GetMiddlewareStore("Batcher")
		for _, state in pairs(AllPlayersRequests) do
			ReleasePlayerEvents(state)
		end
	end
	if IsClient then
		ReleasePlayerEvents(_GetMiddlewareStore("Batcher"))
	end
end
Middlewares.Batcher = Batcher

return Middlewares
