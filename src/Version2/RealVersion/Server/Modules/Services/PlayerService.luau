local PlayerService = {}

local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local SessionManager = require(Registry.Server.Modules.SessionManager)
local PlayerDataManager = require(Registry.Server.Modules.PlayerDataManager)
local TableUtils = require(Registry.Shared.Modules.TableUtils)
local Players = game:GetService("Players")

local function GetSpawnLocations()
	return game.Workspace.SpawnLocations
end
--------- State Handling
local DEFAULT_PLAYER_STATE = {
	isAlive = true,
	health = 100,
	isFrozen = true,
	equippedWeapon = nil,
	deaths = 0,
	kills = 0,
	assits = 0,
	damageDone = 0,
	damageTaken = 0,
	roundsWon = 0,
	matchWon = false,
	spawnLocation = 1,
}
local NOT_ROUND_RESET_STATE_KEYS = { "roundsWon" }
local ROUND_SPECIFIC_STATE_KEYS = { "deaths", "kills", "assits", "damageDone", "damageTaken" }

function PlayerService.SetPlayerState(userId, stateName, value)
	if stateName then
		SessionManager:StorePlayerState(userId, stateName, value)
	else
		SessionManager:StoreObject({ "Players", userId, "State" }, value)
	end
end

function PlayerService.GetPlayerState(userId, stateName)
	local State = nil
	if stateName then
		State = SessionManager:GetPlayerState(userId, stateName)
	else
		State = SessionManager:GetObject({ "Players", userId, "State" })
	end
	return State
end

function PlayerService.IncrementPlayerState(userId, stateType, incrementValue)
	local State = SessionManager:GetObject({ "Players", userId, "State" })
	if State and State[stateType] then
		State[stateType] = State[stateType] + incrementValue
	end
end

function PlayerService.ResetPlayerState(userId)
	local CorrectValues = table.clone(DEFAULT_PLAYER_STATE)
	for _, exceptionKey in pairs(NOT_ROUND_RESET_STATE_KEYS) do
		CorrectValues[exceptionKey] = PlayerService.GetPlayerState(userId, exceptionKey)
	end
	PlayerService.SetPlayerState(userId, nil, CorrectValues)
end

function PlayerService.GetPlayerCurrentRoundState(userId)
	local RoundState = {}
	for _, roundSpecificKeys in pairs(ROUND_SPECIFIC_STATE_KEYS) do
		RoundState[roundSpecificKeys] = PlayerService.GetPlayerState(userId, roundSpecificKeys)
	end
	return RoundState
end

--------- Stats Handling

function PlayerService.UpdatePlayerStat(userId, statType, value)
	local Stats = PlayerDataManager:GetPlayerData(userId).Stats
	if Stats and Stats[statType] then
		Stats[statType] = value
	end
end

function PlayerService.IncrementPlayerStat(userId, statType, incrementValue)
	local Stats = PlayerDataManager:GetPlayerData(userId).Stats
	if Stats and Stats[statType] then
		Stats[statType] = Stats[statType] + incrementValue
	end
end

function PlayerService.GetPlayerStat(userId, statType)
	return PlayerDataManager:GetPlayerData(userId).Stats[statType]
end

--------- Spawning

function PlayerService.SpawnPlayerAtLocation(player: Player, position)
	local character = player.Character
	local correctPosition = nil
	local SpawnLocations = GetSpawnLocations()
	local currentLocation =
		SpawnLocations[tostring(PlayerService.GetPlayerState(player.UserId, "spawnLocation"))].CFrame
	if position then
		correctPosition = position
	else
		correctPosition = currentLocation
	end
	if not character then
		return
	end
	character:PivotTo(correctPosition)
end

--------- Validation

function PlayerService.GetAllPlayers()
	local PlayersState = SessionManager:GetObject("Players")
	local requiredPlayers = {}
	for userId, _ in pairs(PlayersState) do
		local Player = Players:GetPlayerByUserId(userId)
		if not Player then
			continue
		end
		table.insert(requiredPlayers, Player)
	end
	return requiredPlayers
end

function PlayerService.RunFunctionOnAllPlayers(callback)
	local PlayersState = SessionManager:GetObject("Players")
	for userId, _ in pairs(PlayersState) do
		callback(Players:GetPlayerByUserId(userId))
	end
end
----------------------------
-- Initialisation
----------------------------

function PlayerService.InitializePlayerState(userId, state)
	local updatedState = TableUtils.CombineDefaultWithNew(DEFAULT_PLAYER_STATE, state)
	SessionManager:StoreObject({ "Players", userId, "State" }, updatedState)
end

function PlayerService.Init(context)
	for userId, state in pairs(context) do
		PlayerService.InitializePlayerState(userId, state)
	end
end

return PlayerService
