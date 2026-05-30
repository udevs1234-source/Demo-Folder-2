local AssetManager = {}

local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local ManagerBase = require(Registry.Shared.Modules.ManagerBase)
AssetManager.__index = AssetManager
setmetatable(AssetManager, { __index = ManagerBase })

function AssetManager.new()
	local self = ManagerBase.new()
	AssetManager:Prepare()
	return setmetatable(self, AssetManager)
end

function AssetManager:Prepare() end

local PlayerManagerObject = AssetManager.new()
return PlayerManagerObject
