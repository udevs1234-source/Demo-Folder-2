local ClientSystem = {}

local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local GamemodeService = require(Registry.Client.Modules.GamemodeService)
local ReplicationService = require(Registry.Shared.Modules.ReplicationService)
local ClientPackage = nil
local Gamemode = nil

local function CreateGamemode(Match_Data)
	Gamemode = GamemodeService.CreateGamemode(Match_Data)
end

local function PrepareReport()
	local Report = {}
	Report["Managers"] = {}
	local Managers = Registry.Client.Modules.Managers
	for _, Manager in pairs(Managers:GetChildren()) do
		Report["Managers"][Manager.Name] = require(Manager).Storage
	end
	return Report
end

local function ConnectEvent()
	ReplicationService.OnClientEvent("DataEvent", function(clientPackage)
		CreateGamemode(clientPackage.Context)
		require(Registry.Client.Modules.SessionManager):StorePlayerData(clientPackage.Player)
		ClientPackage = clientPackage
		PrepareReport()
	end)
end

local function LoadScripts()
	local Managers = Registry.Client.Modules.Managers
	for _, Manager in pairs(Managers:GetChildren()) do
		require(Manager)
	end
	ReplicationService.Init()
end

function ClientSystem.Init()
	LoadScripts()
	ConnectEvent()
end

return ClientSystem
