local PlayerDataManager = {}

local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local ManagerBase = require(Registry.Shared.Modules.ManagerBase)
PlayerDataManager.__index = PlayerDataManager
setmetatable(PlayerDataManager, { __index = ManagerBase })

--------- Private ---------

----- Data Modification
local function ModifyPlayerData(PlayerData)
	local ModifiedData = {}
	ModifiedData.Cache = table.clone(PlayerData)
	ModifiedData.Stats = PlayerData.Stats or {}
	return ModifiedData
end

--------- Public --------

------ Object Creation
function PlayerDataManager.new()
	local self = ManagerBase.new()
	return setmetatable(self, PlayerDataManager)
end

function PlayerDataManager:GetPlayerData(UserId)
	return self:GetObject({ UserId })
end

function PlayerDataManager:StorePlayerData(UserId, PlayerData)
	self:StoreObject({ UserId }, ModifyPlayerData(PlayerData))
end

function PlayerDataManager:CleanupPlayer(userId)
	self:StoreObject({ userId }, nil)
end

local PlayerDataManagerObject = PlayerDataManager.new()
return PlayerDataManagerObject
