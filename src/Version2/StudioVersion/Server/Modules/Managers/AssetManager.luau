local AssetManager = {}
local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local ManagerBase = require(Registry.Shared.Modules.ManagerBase)
ManagerBase.__index = ManagerBase
setmetatable(AssetManager, { __index = ManagerBase })

function AssetManager.new()
	local self = ManagerBase.new()
	self:StoreObject("Pool", {})
	self:StoreObject("Configs", {})
	self:StoreObject("Templates", {})
	AssetManager:Prepare()
	return setmetatable(self, AssetManager)
end

function AssetManager:Prepare() end

local AssetManagerObject = AssetManager.new()
return AssetManagerObject
