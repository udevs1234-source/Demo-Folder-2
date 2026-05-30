local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GamemodeBase = {}

local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local SignalBus = require(Registry.Shared.Modules.SignalBus)
local Services = Registry.Client.Modules.Services
local GamemodeContext = require(Registry.Client.Modules.GamemodeContext)
local GamemodesConfig = require(Registry.Shared.Modules.GamemodesConfig)
local SessionManager = require(Registry.Client.Modules.SessionManager)
local ReplicationService = require(Registry.Shared.Modules.ReplicationService)
local Players = game.Players
GamemodeBase.__index = GamemodeBase

function GamemodeBase.new(Context)
	local self = setmetatable({}, GamemodeBase)
	self.Config = GamemodesConfig[Context.MatchContext.MatchInfo.Gamemode].Client
	self.Context = GamemodeContext.new(Context)
	self.Services = {}
	self.Connections = {}
	return self
end

-------------------------
-- Initialisation of Gamemode Base
-------------------------

function GamemodeBase:Init()
	self:InitializeBaseConnections()
	self:InitializeConnections()
	self:InitializeServices()
	self.IsRunning = true
end

function GamemodeBase:InitializeServices()
	local Context = self.Context
	self:InitializeService("WeaponService", Context.WeaponContext)
	print(Context)
	self:InitializeService("InputService", Context.InputContext)
	print(Context.InputContext)
	self:InitializeService("UIService",{})
end

function GamemodeBase:InitializeBaseConnections()
	
end

----------------------
-- Useful functions for Gamemode
----------------------

function GamemodeBase:CreateService(serviceName)
	if self.Services[serviceName] then
		return
	end
	self.Services[serviceName] = Registry.Client.Modules[serviceName]
end

function GamemodeBase:GetService(name)
	return require(self.Services[name])
end

function GamemodeBase:GetContext(name)
	return (self.Context.CustomContext[name] ~= nil) and self.Context.CustomContext[name] or self.Context[name]
end

function GamemodeBase:InitializeService(serviceName, context)
	self:CreateService(serviceName)
	local Service = self:GetService(serviceName)
	Service.Init(context)
end

function GamemodeBase:ConnectSignal(signalName, callbackFunction)
	SignalBus.ConnectSignal(signalName, callbackFunction)
end

function GamemodeBase:ConnectEvent(eventName, callbackFunction)
	print("connecting Event", eventName)
	ReplicationService.OnClientEvent(eventName, callbackFunction)
end

function GamemodeBase:DisconnectSignals()
	for _, Connection in ipairs(self.Connections) do
		Connection:Disconnect()
	end
	self.Connections = {}
end

function GamemodeBase:Cleanup()
	self.IsRunning = false
	SessionManager:Cleanup()
	-- Additional cleanup logic can be added here
end

return GamemodeBase
