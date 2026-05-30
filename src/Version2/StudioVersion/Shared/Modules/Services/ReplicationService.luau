local ReplicationService = {}
local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local EventInstances = Registry.Shared.Events
local EncodingService = game:GetService("EncodingService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local NetworkEventsConfig = require(Registry.Shared.Modules.NetworkEventsConfig)
local NetworkEvent = require(Registry.Shared.Modules.NetworkEvent)
local Middlewares = require(Registry.Shared.Modules.Middlewares)
--[[     

-- [ReplicationService] -
     Functions - 
       

     Dependencies - NetworkEvent Object and SessionManager for Storage
     Note - It contains Middlewares and also custom event Object, 
     The Middlewares are the main machines/layers who execute the event . 
]]

----------------- Private --------------------

local isServer = RunService:IsServer()
local isClient = RunService:IsClient()

-----------------------
--- Storage and Creation of NetworkEvent Object
-----------------------

local function _getSessionManager()
	if isServer then
		return require(Registry.Server.Modules.SessionManager)
	end
	if isClient then
		return require(Registry.Client.Modules.SessionManager)
	end

	return nil
end
local SessionManager = _getSessionManager()

local function _StoreNetworkObject(objectType, NetworkObject)
	local objectName = NetworkObject.Name
	if objectType == "Events" then
		SessionManager:StoreMatchObject(objectType, objectName, NetworkObject)
	end
end

local function _GetNetworkObject(objectType, objectName)
	if objectType == "Events" then
		return SessionManager:GetMatchObject(objectType, objectName)
	elseif objectType == "Middlewares" then
		return Middlewares[objectName]
	end
	return nil
end

local function _BuildMiddlewareExecutionFunction(MiddlewaresStack, starterFunction, terminalFunction)
	local chain = terminalFunction
	for i = #MiddlewaresStack, 1, -1 do
		local MiddlewareEntry = MiddlewaresStack[i]
		local lastInChain = chain
		chain = function(context)
			MiddlewareEntry.Object.Process(context, lastInChain, MiddlewareEntry.Config)
		end
	end
	local builtChain = chain
	chain = function(context)
		starterFunction(context, builtChain)
	end
	return chain
end

local function _BuildMiddlewaresPipeline(eventName, MiddlewaresConfig)
	local inboundStack = {}
	local outboundStack = {}
	-- Building inbounds and outboundsList of Middlewares
	for middlewareType, middlewaresConfig in pairs(MiddlewaresConfig) do
		for middlewareName, middlewareConfig in pairs(middlewaresConfig) do
			local middlewareOrder = middlewareConfig.Order
			local Middleware = _GetNetworkObject("Middlewares", middlewareName)
			local function _RegisterMiddlewareEntry(StackType)
				local middlewareEntry = { Order = middlewareOrder, Object = Middleware, Config = middlewareConfig }
				if StackType == "inbound" then
					table.insert(inboundStack, middlewareEntry)
				end
				if StackType == "outbound" then
					table.insert(outboundStack, middlewareEntry)
				end
			end
			if isServer then
				if middlewareType == "ServerInbound" then
					_RegisterMiddlewareEntry("inbound")
				end
				if middlewareType == "ServerOutbound" then
					_RegisterMiddlewareEntry("outbound")
				end
			end
			if isClient then
				if middlewareType == "ClientInbound" then
					_RegisterMiddlewareEntry("inbound")
				end
				if middlewareType == "ClientOutbound" then
					_RegisterMiddlewareEntry("outbound")
				end
			end
		end
	end
	table.sort(inboundStack, function(a, b)
		return a.Order < b.Order
	end)
	table.sort(outboundStack, function(a, b)
		return a.Order < b.Order
	end)
	local inboundTerminal = function(context)
		local listeners = _GetNetworkObject("Events", context.eventName).listeners
		if listeners and not table.isfrozen(listeners) then
			for _, listenerFunction in ipairs(listeners) do
				if isServer then
					listenerFunction(context.sender, context.data)
				end
				if isClient then
					listenerFunction(context.data)
				end
			end
		end
		context.isUsing = false
	end
	local outboundTerminal = function(context)
		local eventInstance = _GetNetworkObject("Events", context.eventName).instance
		local data = nil
		if context.isBatched then
			eventInstance = _GetNetworkObject("Events", "BatcherEvent").instance
			data = context.requests
		else
			data = context.data
		end
		if isServer then
			eventInstance:FireClient(context.target, data)
		end
		if isClient then
			eventInstance:FireServer(data)
		end
		context.isUsing = false
	end
	local starterTerminal = function(context, next)
		if context.eventName == "BatcherEvent" then
			local requests = context.data
			for _, request in ipairs(requests) do
				local eventName = request.eventName
				_GetNetworkObject("Events", eventName).MiddlewaresPipeline.Inbound(request)
			end
		else
			next(context)
		end
	end
	local inboundFunction = _BuildMiddlewareExecutionFunction(inboundStack, starterTerminal, inboundTerminal)
	local outboundFunction = _BuildMiddlewareExecutionFunction(outboundStack, starterTerminal, outboundTerminal)
	return { Inbound = inboundFunction, Outbound = outboundFunction }
end

local function _ModifyNetworkEventConfig(config)
	local modifiedConfig = {}
	modifiedConfig.Name = config.Name
	modifiedConfig.MiddlewaresPipeline = _BuildMiddlewaresPipeline(config.Name, config.Middlewares)
	return modifiedConfig
end

local function _ModifyMiddlewareConfig(args) end

local function _CreateNetworkEvent(config)
	local modifiedConfig = _ModifyNetworkEventConfig(config)
	local NetworkEventObject = NetworkEvent.new(modifiedConfig)
	NetworkEventObject:Init()
	return NetworkEventObject
end

local function _InitializeMiddlewareTasks()
	if isServer then
		RunService.Heartbeat:Connect(function()
			Middlewares.Batcher.ReleaseEvents()
		end)
	end
	if isClient then
		RunService.RenderStepped:Connect(function()
			Middlewares.Batcher:ReleaseEvents()
		end)
	end
end
local function _InitializeNetworkingObjects()
	for _, eventConfig in pairs(NetworkEventsConfig) do
		local NetworkEvent = _CreateNetworkEvent(eventConfig)
		_StoreNetworkObject("Events", NetworkEvent)
	end
end

------------------ Public -------------------

function ReplicationService.Init()
	_InitializeNetworkingObjects()
	_InitializeMiddlewareTasks()
end

function ReplicationService.FireClient(eventName, player, data)
	if not isServer then
		return
	end
	_GetNetworkObject("Events", eventName):Fire({ player }, data)
end

function ReplicationService.FireClients(eventName, clientsList, data)
	if not isServer then
		return
	end
	_GetNetworkObject("Events", eventName):Fire(clientsList, data)
end

function ReplicationService.FireAllClients(eventName, data)
	if not isServer then
		return
	end
	_GetNetworkObject("Events", eventName):Fire("All", data)
end

function ReplicationService.FireServer(eventName, data)
	if not isClient then
		return
	end
	_GetNetworkObject("Events", eventName):Fire(nil, data)
end

function ReplicationService.OnClientEvent(eventName, listenerFunction)
	local NetworkEventObject = _GetNetworkObject("Events", eventName)
	NetworkEventObject:OnFire(listenerFunction)
end

function ReplicationService.OnServerEvent(eventName, listenerFunction)
	local NetworkEventObject = _GetNetworkObject("Events", eventName)
	NetworkEventObject:OnFire(listenerFunction)
end

return ReplicationService
