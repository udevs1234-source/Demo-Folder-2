local GamemodeBase = {}

local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local SignalBus = require(Registry.Shared.Modules.SignalBus)
local SessionManager = require(Registry.Server.Modules.SessionManager)
local ReplicationService = require(Registry.Shared.Modules.ReplicationService)
local GamemodesConfig = require(Registry.Shared.Modules.GamemodesConfig)
local GamemodeContext = require(Registry.Server.Modules.GamemodeContext)
local Players = game.Players
GamemodeBase.__index = GamemodeBase

function GamemodeBase.new(matchData)
	local self = setmetatable({}, GamemodeBase)
	self.MatchData = matchData
	self.Config = GamemodesConfig[matchData.MatchInfo.Gamemode].Server
	self.Context = GamemodeContext.new({})
	self.Services = {}
	return self
end

-------------------------
-- Initialisation of Gamemode Base
-------------------------

function GamemodeBase:Init()
	self:InitializeContext()
	self:_SendClientsPackage()
	self:_InitializeConnections()
	self:InitializeServices()
	self.IsRunning = true
end

function GamemodeBase:InitializeContext() end

function GamemodeBase:_SendClientsPackage()
	for _, player in pairs(self.MatchData.Players) do
		self:SendClientPackage(player)
	end
end

function GamemodeBase:InitializeServices()
	local Context = self.Context
	self:InitializeService("PlayerService", Context.PlayerContext)
	self:InitializeService("TeamService", Context.TeamContext)
	self:InitializeService("WeaponService", Context.WeaponContext)
	self:InitializeService("RoundService", Context.RoundContext)
end

function GamemodeBase:_InitializeConnections()
	self:_InitializeBaseConnections()
	self:InitializeRuleConnections()
	self:InitializeGamemodeConnections()
end
function GamemodeBase:_InitializeBaseConnections() end
function GamemodeBase:InitializeRuleConnections() end
function GamemodeBase:InitializeGamemodeConnections() end

----------------------
-- Useful functions for Gamemode
----------------------

function GamemodeBase:CreateService(serviceName)
	if self.Services[serviceName] then
		return
	end
	self.Services[serviceName] = require(Registry.Server.Modules[serviceName])
end

function GamemodeBase:GetService(name)
	return self.Services[name]
end

function GamemodeBase:GetContext(name)
	return (self.Context.CustomContext[name] ~= nil) and self.Context.CustomContext[name] or self.Context[name]
end

function GamemodeBase:InitializeService(serviceName, context)
	self:CreateService(serviceName)
	local Service = self:GetService(serviceName)
	Service.Init(context)
end

function GamemodeBase:SendClientPackage(player)
	local clientPackage = self:CreateClientPackage(player.UserId)
	ReplicationService.FireClient("DataEvent", player, clientPackage)
end

--function GamemodeBase:CreateClientPackage(UserId)
--	local clientPackage = {}
--	clientPackage.MatchInfo = self.MatchData.MatchInfo
--	clientPackage.Context = {WeaponContext = self.Context[UserId]}
--	return clientPackage
--end

function GamemodeBase:ConnectSignal(signalName, callbackFunction)
	SignalBus.ConnectSignal(signalName, callbackFunction)
end

function GamemodeBase:FireSignal(signalName, data)
	SignalBus:FireSignal(signalName, data)
end

function GamemodeBase:ConnectEvent(eventName, callbackFunction)
	ReplicationService.OnServerEvent(eventName, callbackFunction)
end

function GamemodeBase:Cleanup()
	self.IsRunning = false
	SessionManager:Cleanup()
	-- Additional cleanup logic can be added here
end

return GamemodeBase
