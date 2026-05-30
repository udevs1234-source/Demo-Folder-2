local DeathMatch = {}

local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local GameRules = require(Registry.Server.Modules.GameRules)
local PlayerDataManager = require(Registry.Server.Modules.PlayerDataManager)
local WeaponService = require(Registry.Server.Modules.WeaponService)
local Players = game:GetService("Players")
DeathMatch.__index = DeathMatch
setmetatable(DeathMatch, { __index = GameRules })

function DeathMatch.new(MatchData)
	local self = GameRules.new(MatchData)

	return setmetatable(self, DeathMatch)
end

--------------------
-- Initialising Gamemode
--------------------

local Player_Service_String = "PlayerService"
local Team_Service_String = "TeamService"
local Weapon_Service_String = "WeaponService"
local Round_Service_String = "RoundService"

function DeathMatch:InitializeContext()
	self.Context = self:CreateCustomContext(self.MatchData)
end

function DeathMatch:CreateClientPackage(UserId)
	local ModifiedContext = {}
	local WeaponContext = self.Context.WeaponContext[UserId]
	ModifiedContext.WeaponContext = table.clone(WeaponContext)
	ModifiedContext.InputContext = table.clone(PlayerDataManager:GetPlayerData(UserId).Cache.Controls)
	ModifiedContext["MatchContext"] = self.MatchData
	return { Context = ModifiedContext, Player = PlayerDataManager:GetPlayerData(UserId) }
end

function DeathMatch:AfterPlayerDeath(Info)
	local victimUserId = Info.victim
	local PlayerService, TeamService = self:GetService(Player_Service_String), self:GetService(Team_Service_String)
	local currentAlivePlayers =
		TeamService.GetTeamState(PlayerService.GetPlayerState(victimUserId, "teamId"), "aliveCount")
	if currentAlivePlayers ~= 0 then
		self:SetRespawnTimer(victimUserId)
	end
	self:WinMatchWhenAllKilledInTeam(Info)
end

------------------
-- Gamemode Related Features
------------------

return DeathMatch
