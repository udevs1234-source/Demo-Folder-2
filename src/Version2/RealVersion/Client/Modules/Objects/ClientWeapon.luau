local ClientWeapon = {}
local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local WeaponEventsHandler = Registry.Client.Modules.WeaponEventsHandler
local AnimationHandler = Registry.Shared.Modules.AnimationHandler
local Assets = Registry.Shared.Assets
local WeaponBaseModule = Registry.Shared.Modules.WeaponBase

ClientWeapon.__index = function(Element, Key)
	local Value = rawget(ClientWeapon, Key)
	if Value ~= nil then
		return Value
	end
	local WeaponBase = rawget(Element, "WeaponBase")
	if WeaponBase then
		return WeaponBase[Key]
	end
	return nil
end

ClientWeapon.__newindex = function(Element, Key, Value)
	local WeaponBase = rawget(Element, "WeaponBase")
	if WeaponBase and WeaponBase[Key] ~= nil then
		WeaponBase[Key] = Value
	else
		rawset(Element, Key, Value)
	end
end

function ClientWeapon.new(WeaponData)
	local self = setmetatable({}, ClientWeapon)
	self.WeaponBase = require(WeaponBaseModule).new(WeaponData) -- Has Common Properties
	-- Extra Client Properties
	self.Model = Assets.ViewModels.Guns:FindFirstChild(WeaponData.Name):Clone()
	self.AnimationHandler = require(AnimationHandler).new(self)
	self.WeaponEventsHandler = require(WeaponEventsHandler).new(self)

	return self
end

function ClientWeapon:Update(WeaponData)
	self.WeaponBase:Update(WeaponData)
	self.AnimationHandler:Update(self)
	self.WeaponEventsHandler:Update(self)
	self.WeaponEventsHandler:ConnectEvents()
end

function ClientWeapon:Equip(player) end

function ClientWeapon:Unequip() end
function ClientWeapon:StartFiring(Weapon)
	self.FireSystem:StartFiring(Weapon)
end
function ClientWeapon:StopFiring(Weapon)
	self.FireSystem:StopFiring(Weapon)
end

function ClientWeapon:Reload(Weapon)
	self.SignalHandler:Fire("OnReload", Weapon) -- Only Firing signal here
end

return ClientWeapon
