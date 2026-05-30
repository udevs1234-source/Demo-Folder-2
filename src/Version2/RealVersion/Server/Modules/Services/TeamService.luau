local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeamService = {}

local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local SessionManager = require(Registry.Server.Modules.SessionManager)
local TableUtils = require(Registry.Shared.Modules.TableUtils)

function TeamService.GetTeam(teamId)
	return SessionManager:GetObject({ "Match", "Teams", teamId })
end

function TeamService.CreateTeam(teamId, teamInfo)
	local Teams = SessionManager:GetObject({ "Match", "Teams" })
	local defaultState = { score = 0, roundsWon = 0, aliveCount = #teamInfo.Players }
	Teams[teamId] = TableUtils.CombineDefaultWithNew(defaultState, teamInfo)
end

function TeamService.CreateTeams(teams)
	for teamId, teamInfo in pairs(teams) do
		TeamService.CreateTeam(teamId, teamInfo)
	end
end

function TeamService.GetTeamState(teamId, stateName, updatedScore)
	return SessionManager:GetObject({ "Match", "Teams", teamId })
end

function TeamService.IncrementTeamState(teamId, stateName, incrementState)
	local state = SessionManager:GetObject({ "Match", "Teams", teamId })
	state[stateName] = state[stateName] + incrementState
end

----------- Initialization

function TeamService.Init(context)
	TeamService.CreateTeams(context)
end

return TeamService
