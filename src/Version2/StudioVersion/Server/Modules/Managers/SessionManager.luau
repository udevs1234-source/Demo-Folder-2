local SessionManager = {}

local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local ManagerBase = require(Registry.Shared.Modules.ManagerBase)
SessionManager.__index = SessionManager
setmetatable(SessionManager, { __index = ManagerBase })

--------- Private -----------

local function ModifyMatchData(MatchData)
	return MatchData
end
---------- Public ----------

----- Object Creation
function SessionManager.new()
	local self = ManagerBase.new()
	self:StoreObject("Match", {})
	self:StoreObject("Players", {})
	self:StoreObjects({
		{ "Match", "Data" },
		{ "Match", "Teams" },
		{ "Match", "State" },
		{ "Match", "Round" },
		{ "Match", "Objects" },
		{ "Match", "RoundsHistory" },
	}, nil)
	return setmetatable(self, SessionManager)
end

----- Storage
function SessionManager:StorePlayerState(UserId, stateType, state)
	self:StoreObject({ "Players", UserId, "State", stateType }, state)
end

function SessionManager:GetPlayerState(UserId, stateType)
	return self:GetObject({ "Players", UserId, "State", stateType })
end
function SessionManager:StorePlayerObject(UserId, objectType, objectId, object)
	self:StoreObject({ "Players", UserId, "Objects", objectType, objectId }, object)
end

function SessionManager:StoreMatchObject(objectType, objectId, object)
	self:StoreObject({ "Match", "Objects", objectType, objectId }, object)
end

function SessionManager:GetMatchObject(objectType, objectId)
	return self:GetObject({ "Match", "Objects", objectType, objectId })
end

function SessionManager:StoreMatchData(MatchData)
	self:StoreObject({ "Match", "Data" }, ModifyMatchData(MatchData))
end

----- Validation and Getting Things
function SessionManager:GetPlayerObject(UserId, objectType, objectId)
	return self:GetObject({ "Players", UserId, "Objects", objectType, objectId })
end

function SessionManager:GetPlayerStore(UserId, storeName)
	return self:GetObject({ "Players", UserId, storeName })
end

function SessionManager:CleanupPlayer(UserId)
	local RoundsHistory = self:GetObject({ "Match", "RoundsHistory" })
	for _, roundData in pairs(RoundsHistory) do
		if roundData.Players[UserId] then
			roundData.Players[UserId] = nil
		end
	end
	self:DestroyObject({ "Players", UserId })
end

local SessionManagerObject = SessionManager.new()
return SessionManagerObject
