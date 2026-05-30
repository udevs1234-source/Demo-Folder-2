local ServerWeapon = {}
local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local WeaponBaseModule = require(Registry.Shared.Modules.WeaponBase)
local Assets = Registry.Server.Assets
local WeaponConfigs = require(Registry.Shared.Modules.WeaponsConfig)
local DamageSystems = Registry.Shared.Modules.DamageSystems :: Folder

ServerWeapon.__index = function(Element, Key)
	local Value = rawget(ServerWeapon, Key)
	if Value ~= nil then
		return Value
	end
	local WeaponBase = rawget(Element, "WeaponBase")
	if WeaponBase then
		return WeaponBase[Key]
	end
	return nil
end

ServerWeapon.__newindex = function(Element, Key, Value)
	local WeaponBase = rawget(Element, "WeaponBase")
	if WeaponBase and WeaponBase[Key] ~= nil then
		WeaponBase[Key] = Value
	else
		rawset(Element, Key, Value)
	end
end
function ServerWeapon.new(Config)
	local self = setmetatable({}, ServerWeapon)
	self.WeaponBase = WeaponBaseModule.new(Config)
	local DamageType = Config.DamageSystem.type
	self.Model = Assets.Weapons.Guns:FindFirstChild(Config.Name):Clone()
	self.DamageSystem = require(DamageSystems[tostring(DamageType)]).new(Config.DamageSystem) -- new DamageSystem
	return self
end

function ServerWeapon:Update(player, WeaponData)
	local WeaponName = WeaponData.WeaponName
	local Config = WeaponConfigs[WeaponName]
	Config.RuntimeConfig = nil
	self.Config = Config
	self.WeaponBase:Update(WeaponData)
	self.DamageSystem:Update(Config.DamageSystem)
	self.Owner = player
end

function ServerWeapon:StartFiring(Weapon)
	self.FireSystem:StartFiring(Weapon)
end

function ServerWeapon:StopFiring(Weapon)
	self.FireSystem:StopFiring(Weapon)
end

function ServerWeapon:Reload(Weapon)
	self.SignalHandler:Fire("OnReload", Weapon) -- Only Firing signal here
end

return ServerWeapon
