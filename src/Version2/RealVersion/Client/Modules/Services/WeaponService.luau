local WeaponService = {}
local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)

local WeaponSystem = require(Registry.Client.Modules.WeaponSystem)
local WeaponsConfig = require(Registry.Shared.Modules.WeaponsConfig)
local ClientWeapon = require(Registry.Client.Modules.ClientWeapon)

-- Storage
local SessionManager = require(Registry.Client.Modules.SessionManager)

function WeaponService.Init(Context)
	WeaponService.PrepareStorage(Context)
end

function WeaponService.PrepareStorage(Weapons_Config)
	for WeaponId, config in pairs(Weapons_Config) do
		WeaponService.CreateAndStoreWeapon(WeaponId, config)
	end
end

function WeaponService.CreateWeapon(WeaponId, config)
	local modifiedconfig = {}
	for property, value in pairs(WeaponsConfig[WeaponId]) do
		if not config[property] then
			modifiedconfig[property] = value
		else
			modifiedconfig[property] = config[property]
		end
	end
	return ClientWeapon.new(modifiedconfig)
end

function WeaponService.GetWeapon(WeaponId)
	return SessionManager:GetPlayerObject("Weapons", WeaponId)
end

function WeaponService.StoreWeapon(WeaponId, Weapon)
	SessionManager:StorePlayerObject("Weapons", WeaponId, Weapon)
end

function WeaponService.CreateAndStoreWeapon(WeaponId, config)
	WeaponService.StoreWeapon(WeaponId, WeaponService.CreateWeapon(WeaponId, config))
end

function WeaponService.ExecuteWeaponTask(WeaponId, taskName)
	WeaponSystem.ExecuteWeaponTask(WeaponService.GetWeapon(WeaponId), taskName)
end

return WeaponService
