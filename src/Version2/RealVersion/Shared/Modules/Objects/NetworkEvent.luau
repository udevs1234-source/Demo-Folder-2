local NetworkEvent = {}

local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local EventInstances = Registry.Shared.Events
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

------------ Private ---------------

local isServer = RunService:IsServer()
local isClient = RunService:IsClient()
local MAX_CONTEXT_STORAGE = 64

NetworkEvent.__index = NetworkEvent
function NetworkEvent:_MakeContextEntry()
	local defaultContext = { eventName = nil, data = nil, isUsing = false }
	table.insert(self._contexts, defaultContext)
end

function NetworkEvent:_CreateContextStorage()
	for i = 1, MAX_CONTEXT_STORAGE do
		self:_MakeContextEntry()
	end
end

function NetworkEvent:_GetInactiveContext()
	for _, context in ipairs(self._contexts) do
		if not context.isUsing then
			return context
		end
	end
	self:_CreateContextStorage()
	return self:_GetInactiveContext()
end

function NetworkEvent:_BuildInboundContext(sender, data)
	local context = self:_GetInactiveContext()
	context.isUsing = true
	context.sender, context.data, context.timestamp, context.eventDirection, context.eventName =
		sender, data, tick(), "Inbound", self.Name
	return context
end

function NetworkEvent:_BuildOutboundContext(target, data)
	local context = self:_GetInactiveContext()
	context.target, context.data, context.timestamp, context.eventDirection, context.eventName =
		target, data, tick(), "Outbound", self.Name
	context.isUsing = true
	return context
end

function NetworkEvent:_InitializeInboundConnection()
	local eventInstance = self.instance
	local InboundFunction = self.MiddlewaresPipeline["Inbound"]
	if not InboundFunction then
		return
	end
	if isServer then
		eventInstance.OnServerEvent:Connect(function(player, data)
			InboundFunction(self:_BuildInboundContext(player, data))
		end)
	end
	if isClient then
		eventInstance.OnClientEvent:Connect(function(data)
			InboundFunction(self:_BuildInboundContext(nil, data))
		end)
	end
end

----------- Public -----------------

function NetworkEvent.new(config)
	local self = setmetatable({}, NetworkEvent)
	self._stats = {}
	self._isAlive = true
	self._contexts = {}

	self.listeners = {}
	self.Name = config.Name
	self.instance = EventInstances[self.Name]
	self.MiddlewaresPipeline = config.MiddlewaresPipeline
	return self
end

function NetworkEvent:Init()
	self:_CreateContextStorage()
	self:_InitializeInboundConnection()
end

function NetworkEvent:Fire(targets, data)
	if not self._isAlive then
		return
	end
	local OutboundFunction = self.MiddlewaresPipeline["Outbound"]
	if not OutboundFunction then
		return
	end
	if isServer then
		if targets == "All" then
			targets = Players:GetPlayers()
		end
		local NumberOfTargets = #targets
		if NumberOfTargets == 1 then
			OutboundFunction(self:_BuildOutboundContext(targets[1], data))
		elseif NumberOfTargets > 1 then
			for _, target in pairs(targets) do
				OutboundFunction(self:_BuildOutboundContext(target, data))
			end
		end
	end
	if isClient then
		self.MiddlewaresPipeline["Outbound"](self:_BuildOutboundContext(nil, data))
	end
end

function NetworkEvent:OnFire(listenerFunction)
	table.insert(self.listeners, listenerFunction)
end

return NetworkEvent
