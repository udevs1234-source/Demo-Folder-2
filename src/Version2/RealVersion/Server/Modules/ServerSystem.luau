local ServerSystem = {}
local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local DataService = require(Registry.Server.Modules.DataService)
local GamemodeService = require(Registry.Server.Modules.GamemodeService)
local Players = game:GetService("Players")

local Players_Arrived = 0
local Gamemode = nil
local Start_Time = tick()
local Max_Waiting_Time = 10
local WaitingPlayers = {}
local IsLoaded = false

-------------------------
-- Player Connection Handling
-------------------------

local function GetGameReport()
	local Report = {}
	local Managers = Registry.Server.Modules.Managers
	Report["Managers"] = {}
	for _, module in pairs(Managers:GetChildren()) do
		Report["Managers"][module.Name] = require(module).Storage
	end
	return Report
end

function ServerSystem.OnPlayerAdded()
	Players.PlayerAdded:Connect(function(player)
		local MatchData =
			{ MatchInfo = { Gamemode = "DeathMatch" }, Players = { Players:GetPlayerByUserId(9675970218) } }
		local TotalPlayers = #MatchData.Players

		-- Store player in waiting list
		WaitingPlayers[player.UserId] = player
		Players_Arrived = Players_Arrived + 1

		if not IsLoaded then
			DataService.InitProfileStore()
			DataService.StartMatchSession(MatchData)
			IsLoaded = true
		end
		print("Hello")
		DataService.StartPlayerSession(player.UserId)
		-- Check if all players have arrived or timeout reached
		local CurrentTime = tick()
		if Players_Arrived >= TotalPlayers and (CurrentTime - Start_Time) <= Max_Waiting_Time then
			-- Create gamemode instance
			print("Game Created")
			Gamemode = GamemodeService.CreateGamemode(MatchData)

			WaitingPlayers = {}
			Players_Arrived = 0
		end
	end)
end

function ServerSystem.OnPlayerRemoving()
	Players.PlayerRemoving:Connect(function(player)
		-- Save player data
		DataService.EndPlayerSession(player.UserId)
	end)
end

function ServerSystem.OnBindToClose()
	for _, player in pairs(Players:GetPlayers()) do
		DataService.EndPlayerSession(player.UserId)
	end
	DataService.EndMatchSession()
end
--------------------
-- Loader of some scripts
--------------------

function ServerSystem.LoadScripts()
	local Managers = Registry.Server.Modules.Managers
	for _, Manager in pairs(Managers:GetChildren()) do
		require(Manager)
	end
	require(Registry.Shared.Modules.ReplicationService).Init()
end

------------------------
-- Initialisation
------------------------

function ServerSystem.Init()
	ServerSystem.LoadScripts()
	ServerSystem.OnPlayerAdded()
	ServerSystem.OnPlayerRemoving()
	ServerSystem.OnBindToClose()
end

-------------------------
-- Cleanup
-------------------------

function ServerSystem.Cleanup()
	-- Clean up active gamemode

	DataService.EndMatchSession()
end

return ServerSystem
