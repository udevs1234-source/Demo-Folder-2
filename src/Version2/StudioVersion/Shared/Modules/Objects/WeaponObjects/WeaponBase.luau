local WeaponBase = {}
local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local Shared = Registry.Shared.Modules
local WeaponConfigs = require(Shared.WeaponsConfig)
local RunService = game:GetService("RunService")
local FireSystems = Shared.FireSystems :: Folder
local ShootingSystems = Shared.ShootingSystems :: Folder
local AbilitySystems = Shared.AbilitySystems
local SignalHandler = Shared.SignalHandler
WeaponBase.__index = WeaponBase

-- Constructor , Runs Single Time

function WeaponBase.new(Config)
	-- Common properties to server and client
	local self = setmetatable({}, WeaponBase)
	-- Only called to create a new weapon object
	self.Config = Config
	local FireType = Config.FireSystem.type
	local ShootingType = Config.ShootingSystem.type
	self.FireSystem = require(FireSystems[tostring(FireType)]).new(Config) --  new FireSystem
	self.ShootingSystem = require(ShootingSystems[tostring(ShootingType)]).new(Config) -- new ShootingSystem
	self.SignalHandler = require(SignalHandler).new() -- new SignalHandler
	self.AbilityHandler = require(Shared.AbilityHandler).new(self)
	self:RegisterSignals() -- Registers all Signals
	return self
end

function WeaponBase:Update(WeaponData)
	local Config = WeaponConfigs[WeaponData.WeaponName]
	self.Config = Config
	for PropertyName, PropertyValue in pairs(WeaponData) do
		self[PropertyName] = PropertyValue
	end
	self.State = "Idle"
	self.Charge = 0
	self.FireSystem:Update(Config.FireSystem)
	self.ShootingSystem:Update(Config.ShootingSystem)
	self.AbilityHandler:Update(self)

	self.AbilityHandler:ConnectAbilitySystem() -- Connect all signals
end

function WeaponBase:SetRuntimeProperties(RuntimeConfig)
	for propertyName, propertyValue in pairs(RuntimeConfig) do
		self[propertyName] = propertyValue
	end
end

function WeaponBase:StartFiring(Weapon)
	self.FireSystem:StartFiring(Weapon)
end

function WeaponBase:StopFiring(Weapon)
	self.FireSystem:StopFiring(Weapon)
end

function WeaponBase:Reload(Weapon)
	self.SignalHandler:Fire("OnReload", Weapon) -- Only Firing signal here
end
function WeaponBase:Equip(player)
	self.Owner = player
end

function WeaponBase:Unequip()
	self.Owner = nil
end

function WeaponBase:SetState(StateName)
	self.State = StateName
end
function WeaponBase:IsState(StateName)
	return self.State == StateName
end
function WeaponBase:CanFire()
	return self.State ~= "Firing" and self.AmmoUsed < self.Config.MagazineSize and self.State ~= "Reloading"
end

function WeaponBase:RegisterSignals()
	self.SignalHandler:RegisterSignals({
		"OnFired",
		"OnFireDenied",
		"OnFireStarted",
		"OnFireStopped",
		"OnShoot",
		"OnHit",
		"OnPlayerHit",
		"OnHitMissed",
		"OnAmmoEmpty",
		"OnAmmoChanged",
		"OnReload",
		"OnReloadStarted",
		"OnReloadFinished",
		"OnReloadCancelled",
		"OnAimStarted",
		"OnAimStopped",
		"OnEquipped",
		"OnUnequipped",
		"OnWeaponChanged",
	})
end

return WeaponBase
