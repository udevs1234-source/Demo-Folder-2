local Weaponmodule = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Registry = require(ReplicatedStorage.Shared.Modules.Registry)
local Assets = Registry.Shared.Assets
local Sounds = Assets.Sounds
local WeaponSounds = Sounds.WeaponsSound
local FireSounds = WeaponSounds.FireSounds
local ReloadSounds = WeaponSounds.ReloadSounds
local Effects = Assets.Effects
local Beams = Effects.Beams
Weaponmodule[1] = {
	Name = "Gun1",
	WeaponType = "Rifle",
	FireSystem = { type = "Auto", FireRate = 10, MagazineSize = 15 },
	ShootingSystem = { type = "Raycast", Range = 300 },
	DamageSystem = { type = "Standard", Damage = 25 },
	AnimationSystem = { type = "Rifle", Speed = 2 },
	Abilities = {
		{ type = "Laser", Beam = Beams.Beam1, Cooldown = 1 }, -- type of ability and its properties
	},
	Animations = { Fire = "rbxassetid://87048857641213", Reload = "rbxassetid://77166792488431" },
	FireSound = FireSounds.BasicRifleSound,
	ReloadSound = ReloadSounds.BasicRifleSound,
	Damage = 25,
	FireRate = 4,
	Speed = 100,
	Range = 300,
	ReloadTime = 2,
	MagazineSize = 15,
	Price = 100,
	RuntimeConfig = { AmmoUsed = 0 }, -- Used to set Runtime Properties
}

Weaponmodule[2] = {
	Name = "AK-47",
	WeaponType = "Rifle",
	FireSystem = { type = "Auto", FireRate = 10, MagazineSize = 15 },
	ShootingSystem = { type = "Raycast", Range = 300 },
	DamageSystem = { type = "Standard", Damage = 25 },
	AnimationSystem = { type = "Rifle", Speed = 2 },
	Abilities = {
		{ type = "Laser", Beam = Beams.Beam1, Cooldown = 1 }, -- type of ability and its properties
	},
	Animations = { Fire = "rbxassetid://87048857641213", Reload = "rbxassetid://77166792488431" },
	FireSound = FireSounds.BasicRifleSound,
	ReloadSound = ReloadSounds.BasicRifleSound,
	MinDamage = 10,
	MaxDamage = 30,
	Damage = 25,
	FireRate = 6,
	Speed = 100,
	Range = 300,
	ReloadTime = 2,
	MagazineSize = 15,
	Price = 100,
	RuntimeConfig = { AmmoUsed = 0 }, -- Used to set Runtime Properties
}

local WeaponsMap = {}
for id, config in pairs(Weaponmodule) do
	WeaponsMap[config.Name] = config
end

setmetatable(Weaponmodule, {
	__index = function(tbl, key)
		return WeaponsMap[key]
	end,
})
return Weaponmodule
