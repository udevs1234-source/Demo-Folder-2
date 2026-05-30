local GameRules = {}
local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local GamemodeBase = require(Registry.Server.Modules.GamemodeBase)
local SessionManager = require(Registry.Server.Modules.SessionManager)
local DataService = require(Registry.Server.Modules.DataService)
local ReplicationService = require(Registry.Shared.Modules.ReplicationService)
local HookValidator = require(Registry.Shared.Modules.Middlewares).HookValidator
local PlayerDataManager = require(Registry.Server.Modules.PlayerDataManager)
local GameBehaviours = require(Registry.Server.Modules.GameBehaviours)


GameRules.__index = GameRules
setmetatable(GameRules, { __index = GamemodeBase })
function GameRules.new(MatchData)
	local self = GamemodeBase.new(MatchData)

	return setmetatable(self, GameRules)
end

function GameRules._RegisterGameBehaviours()
	for behaviourName, gameBehaviour in pairs(GameBehaviours) do
		GameRules[behaviourName] = gameBehaviour
	end
end
GameRules._RegisterGameBehaviours()
--------------
-- GameRules - Made up of Services Instructions
--------------

local Player_Service_String = "PlayerService"
local Team_Service_String = "TeamService"
local Weapon_Service_String = "WeaponService"
local Round_Service_String = "RoundService"

function GameRules:_RegisterAllSignalsAndHooks()
	local SignalInfo = {
		{ signalName = "OnRoundStarted", handler = "HandleRoundStart", hookName = "RoundStart" },
		{ signalName = "OnRoundEnded", handler = "HandleRoundEnd", hookName = "RoundEnd" },
		{ signalName = "OnMatchEnded", handler = "HandleMatchEnd", hookName = "MatchEnd" },
		{ signalName = "OnRoundWaitingStarted", handler = "HandleRoundWaitingStarted", hookName = "RoundWaitingStart" },
		{ signalName = "OnPlayerDamage", handler = "HandlePlayerDamage", hookName = "PlayerDamage" },
		{ signalName = "OnPlayerDeath", handler = "HandlePlayerDeath", hookName = "PlayerDeath" },
	}
	local EventInfo = {
		-- Action Events
		{ eventName = "WeaponFireEvent", handler = "HandlePlayerAction" },
		{ eventName = "WeaponActionEvent", handler = "HandlePlayerAction" },
		{ eventName = "PlayerActionEvent", handler = "HandlePlayerAction" },
	}
	for _, Info in pairs({ SignalInfo, EventInfo }) do
		for _, hookInfo in pairs(Info) do
			local signalName, eventName, handler, hookName =
				hookInfo.signalName, hookInfo.eventName, hookInfo.handler, hookInfo.hookName
			local handlerFunction = handler
			if type(handler) == "string" and self[handler] then
				handlerFunction = self[handler]
			end
			if signalName or eventName then
				local executionPipeline = nil
				if hookName then
					for _, hookType in pairs({ "After", "Before" }) do
						if not self[hookType .. hookName] then
							self[hookType .. hookName] = function() end
						end
					end
					executionPipeline = function(...)
						self["Before" .. hookName](...)
						handlerFunction(self,...)
						self["After" .. hookName](...)
					end
				else
					executionPipeline = function(...)
						handlerFunction(self,...)
					end
				end
				if signalName then
					self:ConnectSignal(signalName, function(...)
						executionPipeline(...)
					end)
				end
				if eventName then
					self:ConnectEvent(eventName, function(...)
						executionPipeline(...)
					end)
				end
			end
		end
	end
end

function GameRules:InitializeRuleConnections()
	self:_RegisterAllSignalsAndHooks()
end

function GameRules:HandlePlayerSpawn(player, position)
	local userId = player.UserId
	local PlayerService = self:GetService(Player_Service_String)
	PlayerService.SetPlayerState(userId, "isAlive", true)
	PlayerService.SpawnPlayerAtLocation(player, position)
end

function GameRules.HandlePlayerAction(actionData)
	local actionId, actionInfo = actionData.actionId, actionData.actionInfo
end

function GameRules:HandlePlayerDeath(Info)
	local killedUserId, killerUserId = Info.victim, Info.attacker
	local PlayerService, TeamService = self:GetService(Player_Service_String), self:GetService(Team_Service_String)
	if not PlayerService.GetPlayerState(killedUserId, "isAlive") then
		return
	end
	PlayerService.SetPlayerState(killedUserId, "health", 0)
	PlayerService.SetPlayerState(killedUserId, "isAlive", false)
	TeamService.IncrementTeamState(PlayerService.GetPlayerState(killedUserId, "teamId"), "aliveCount", -1)
	PlayerService.IncrementPlayerState(killedUserId, "deaths", 1)
	PlayerService.IncrementPlayerState(killerUserId, "Kills", 1)
end

function GameRules:HandlePlayerDamage(Info, damage)
	local damagedUserId, damagerUserId = Info.victim, Info.attacker
	local PlayerService = self:GetService(Player_Service_String)
	if not PlayerService.GetPlayerState(damagedUserId, "isAlive") then
		return
	end
	local currentHealth = PlayerService.GetPlayerState(damagedUserId, "health")
	local damageDifference = currentHealth - damage
	if damageDifference <= 0 then
		self:HandlePlayerDeath({ victim = damagedUserId, attacker = damagerUserId })
		self:OnPlayerDeath()
	elseif damageDifference > 0 then
		PlayerService.SetPlayerState(damagedUserId, "health", damageDifference)
	end
	PlayerService.IncrementPlayerState(damagedUserId, "damageTaken", damage)
	PlayerService.IncrementPlayerState(damagerUserId, "damageDone", damage)
end

function GameRules:HandlePlayerLeave(userId)
	local PlayerService, TeamService = self:GetService(Player_Service_String), self:GetService(Team_Service_String)
	TeamService.IncrementTeamState(PlayerService.GetPlayerState(userId, "teamId"), "aliveCount", -1)
	DataService.EndPlayerSession(userId)
	PlayerService.SetPlayerState(userId, nil)
end

function GameRules:HandleWeaponTask(userId, weaponId, taskName)
	local PlayerService = self:GetService(Player_Service_String)
	local isAlive = PlayerService.GetPlayerState(userId, "isAlive") == true
	local isFrozen = PlayerService.GetPlayerState(userId, "isFrozen") == true
	if not isAlive then
		return
	end
	local isWeaponEquippedPreviosly = PlayerService.GetPlayerState(userId, "equippedWeapon") == weaponId
	if taskName == "Equip" then
		if isWeaponEquippedPreviosly then
			return
		else
			PlayerService.SetPlayerState(userId, "equippedWeapon", weaponId)
		end
	end
	if taskName == "Unequip" then
		if isWeaponEquippedPreviosly then
			PlayerService.SetPlayerState(userId, "equippedWeapon", nil)
		else
			return
		end
	end
	if isFrozen and (taskName ~= "Equip" and taskName ~= "Unequip") then
		return
	end
	self:GetService(Weapon_Service_String).ExecuteWeaponTask(userId, weaponId, taskName)
end

function GameRules:HandleRoundStart()
	local PlayerService = self:GetService(Player_Service_String)
	PlayerService.RunFunctionOnAllPlayers(function(player)
		local userId = player.UserId
		PlayerService.SetPlayerState(userId, "isFrozen", false)
	end)
end

function GameRules:HandleRoundWaitingStarted()
	local PlayerService = self:GetService(Player_Service_String)
	PlayerService.RunFunctionOnAllPlayers(function(player)
		local userId = player.UserId
		PlayerService.SpawnPlayerAtLocation(player, nil)
		PlayerService.SetPlayerState(userId, "isFrozen", true)
		self:HandleWeaponTask(userId, PlayerService.GetPlayerState(userId, "defaultWeapon"), "Equip")

	end)

end

function GameRules:StorePlayerPreviousRoundHistory(userId)
	local PlayerService, RoundService = self:GetService(Player_Service_String), self:GetService(Round_Service_String)
	local roundHistory = PlayerService.GetPlayerCurrentRoundState(userId)
	roundHistory.score = RoundService.GetRoundState("score")
	SessionManager:StoreObject(
		{ "Match", "RoundsHistory", RoundService.GetRoundState("currentRound"), "Players", userId },
		roundHistory
	)
end

function GameRules:HandleRoundEnd()
	local PlayerService, RoundService = self:GetService(Player_Service_String), self:GetService(Round_Service_String)
	if RoundService.GetRoundState("phase") == "Active" then
		RoundService.ForceEndRound()
	end
	self:OnRoundEnd()
	PlayerService.RunFunctionOnAllPlayers(function(player)
		local userId = player.UserId
		PlayerService.SetPlayerState(userId, "isFrozen", true)
		self:StorePlayerPreviousRoundHistory(userId)
		self:HandleWeaponTask(userId, PlayerService.GetPlayerState(userId, "equippedWeapon"), "Unequip")
		PlayerService.ResetPlayerState(userId)
	end)
end

function GameRules:HandleMatchWaitingStarted() end

function GameRules:HandleMatchEnd()
	local PlayerService = self:GetService(Player_Service_String)
	PlayerService.RunFunctionOnAllPlayers(function(player)
		local userId = player.UserId
		PlayerService.SetPlayerState(userId, "isFrozen", true)
		self:HandleWeaponTask(userId, PlayerService.GetPlayerState(userId, "defaultWeapon"), "Unequip")
		DataService.EndPlayerSession(userId)
	end)
	SessionManager:Cleanup()
end

function GameRules:HandleMatchWin(winnerTeamId)
	local TeamService, PlayerService = self:GetService(Team_Service_String), self:GetService(Player_Service_String)
	for _, player in pairs(TeamService.GetTeamState(winnerTeamId, "Players")) do
		local userId = player.UserId
		PlayerService.SetPlayerState(userId, "matchWon", true)
	end
	SessionManager:StoreObject({ "Match", "WinnedTeam" }, winnerTeamId)
end

function GameRules:HandleRoundWin(winnerTeamId)
	local TeamService, PlayerService, RoundService =
		self:GetService(Team_Service_String),
		self:GetService(Player_Service_String),
		self:GetService(Round_Service_String)
	TeamService.IncrementTeamState(winnerTeamId, "roundsWon", 1)
	local winnerTeam = TeamService.GetTeam(winnerTeamId)
	for _, userId in pairs(winnerTeam.Players) do
		PlayerService.IncrementPlayerState(userId, "roundsWon", 1)
	end
	SessionManager:StoreObject(
		{ "Match", "RoundsHistory", RoundService.GetRoundState("currentRound"), "Players", "winner" },
		winnerTeamId
	)
end

function GameRules:SwitchTeams(teamId1, teamId2)
	local TeamService, PlayerService = self:GetService(Team_Service_String), self:GetService(Player_Service_String)
	local team1State, team2State = TeamService.GetTeam(teamId1), TeamService.GetTeam(teamId2)
	local team1Players, team2Players = team1State.Players, team2State.Players
	team1State.Players, team2State.Players = team2Players, team1Players
	for _, userId in pairs(team1Players) do
		PlayerService.SetPlayerState(userId, "teamId", teamId2)
	end
	for _, userId in pairs(team2Players) do
		PlayerService.SetPlayerState(userId, "teamId", teamId1)
	end
end

function GameRules:CreateCustomContext(matchData)
	local CustomContext = {}
	local matchPlayers = matchData.Players
	CustomContext.RoundContext = self.Config.Round
	CustomContext.TeamContext = { [1] = { Players = matchPlayers, teamColor = "Blue" } }
	CustomContext.WeaponContext = {}
	CustomContext.PlayerContext = {}
	
	for _, Player in pairs(matchPlayers) do
		local UserId = Player.UserId
		local PlayerData = PlayerDataManager:GetPlayerData(UserId)
		local Weapons = PlayerData.Cache.Inventory.Weapons or nil
		CustomContext.WeaponContext[UserId] = Weapons
	end
	for _, player in matchPlayers do
		local userId = player.UserId
		CustomContext.PlayerContext[userId] = { teamId = 1, spawnLocation = 1, defaultWeapon = 1 }
	end
	return CustomContext
end

function GameRules:ValidateWeaponChange()
	HookValidator.RegisterHook("WeaponTask", "ValidateWeaponChange", function(context)
		local PlayerService = self:GetService(Player_Service_String)
		if not (PlayerService.GetPlayerState(context.sender.userId, "equippedWeapon") == context.data) then
			return false
		end
		return true
	end)
end

return GameRules
