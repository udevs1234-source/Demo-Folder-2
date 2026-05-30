local Registry = {}
local ReplicatedStorage = game.ReplicatedStorage
local RunService = game:GetService("RunService")
-- Registry Path :- local Registry =
--require(game.ReplicatedStorage.Shared.Modules.Registry)
local isServer = RunService:IsServer()
local isClient = RunService:IsClient()
local IsStoredReferences = false

function Registry.IsObjectisReferenced(Name)
	local Object = Registry[Name]
	if Object then
		return true
	end
	return false
end

function Registry.StoreAllReferences(StoreName,Folders)
	Registry[StoreName] = {}
	for _, Folder in pairs(Folders) do
		Registry[StoreName][Folder.Name] = {}
		for _,Object in pairs(Folder:GetDescendants()) do	
			   Registry[StoreName][Folder.Name][Object.Name] = Object
		end
	end
end

function Registry.StoreGameReferences()
	local SharedFolder = ReplicatedStorage.Shared
	local Shared = {SharedFolder.Modules,SharedFolder.Events,SharedFolder.Assets}
	if isServer then
		for StoreName, Folders in pairs({Shared = Shared,Server = {game.ServerScriptService.Server.Modules,game.ServerStorage.Assets}})   do
			Registry.StoreAllReferences(StoreName,Folders)
		end
	end
	if isClient then
		for StoreName, Folders in pairs({Shared = Shared,Client = {game.StarterGui,game.StarterPlayer.StarterPlayerScripts.Client.Modules}}) do
			Registry.StoreAllReferences(StoreName,Folders)
		end
	end
end

function Registry:WaitForChild(Name)
	return Registry[Name]
end

if not IsStoredReferences then
	Registry.StoreGameReferences()
	IsStoredReferences = true
end

function Registry.GetServerOrClientInstance(instanceType,instanceName)
	if isServer then
		return Registry.Server[instanceType][instanceName]
	elseif isClient then
		return Registry.Client[instanceType][instanceName]
	end
	return nil
end

return Registry
