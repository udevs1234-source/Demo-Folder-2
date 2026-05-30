local SessionManager = {}

local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local ManagerBase = require(Registry.Shared.Modules.ManagerBase)
SessionManager.__index = SessionManager
setmetatable(SessionManager, { __index = ManagerBase })

---------- Private -----------

local function ModifyPlayerData(PlayerData)
	local ModifiedData = {}
	ModifiedData.Cache = PlayerData
	ModifiedData.Stats = PlayerData.Stats or {}
	return ModifiedData
end

---------- Public -----------

-- Object Creation
function SessionManager.new()
	local self = ManagerBase.new()
	self:StoreObjects({
		{ "Match" },
		{ "Match", "Objects" },
		{ "Player" },
		{ "Player", "Data" },
		{ "Player", "State" },
		{
			"Player",
			"Objects",
		},
	}, nil)
	self:StoreObject("Weapons", {})
	self:StoreObject("Cache", {})
	return setmetatable(self, SessionManager)
end

function SessionManager:StorePlayerData(PlayerData)
	self:StoreObject({ "Player", "Data" }, ModifyPlayerData(PlayerData))
end

function SessionManager:StorePlayerObject(objectType, objectId, object)
	self:StoreObject({ "Player", "Objects", objectType, objectId }, object)
end

function SessionManager:GetPlayerObject(objectType, objectId)
	return self:GetObject({ "Player", "Objects", objectType, objectId })
end

function SessionManager:StoreMatchObject(objectType, objectId, object)
	self:StoreObject({ "Match", "Objects", objectType, objectId }, object)
end

function SessionManager:GetMatchObject(objectType, objectId, object)
	return self:GetObject({ "Match", "Objects", objectType, objectId })
end

local SessionManagerObject = SessionManager.new()
return SessionManagerObject
