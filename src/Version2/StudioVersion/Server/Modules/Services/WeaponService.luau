local WeaponService = {}
local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local SessionManager = require(Registry.Server.Modules.SessionManager)
local WeaponSystem = require(Registry.Server.Modules.WeaponSystem)
local WeaponsConfig = require(Registry.Shared.Modules.WeaponsConfig)
local WeaponObject = require(Registry.Server.Modules.ServerWeapon)
local ReplicationService = require(Registry.Shared.Modules.ReplicationService)
local Players = game:GetService("Players")
----------------------------
-- Initialisation
----------------------------
local Context = nil
function WeaponService.Init(context)
	-- Object Creation and Storage
	for UserId, Weapons in pairs(context) do
		for WeaponId, config in pairs(Weapons) do
			WeaponService.CreateAndStoreWeapon(UserId, WeaponId, config)
		end
	end
	Context = context
end

--------------------------------
-- Main Functions
--------------------------------

function WeaponService.StorePlayerWeapon(UserId, WeaponId, Weapon)
	SessionManager:StorePlayerObject(UserId, "Weapons", WeaponId, Weapon)
end

function WeaponService.GetPlayerWeapon(UserId, WeaponId)
	SessionManager:GetPlayerObject(UserId, WeaponId)
end

function WeaponService.CreateAndStoreWeapon(UserId, WeaponId, config)
	WeaponService.StorePlayerWeapon(UserId, WeaponId, WeaponService.CreateWeapon(WeaponId, config))
end

function WeaponService.ExecuteWeaponTask(UserId, WeaponId, taskName)
	WeaponSystem.ExecuteWeaponTask(UserId, SessionManager:GetPlayerObject(UserId, "Weapons", WeaponId), taskName)
end

function WeaponService.CreateWeaponConfig(WeaponId, config)
	local WEAPON_CONFIG = WeaponsConfig[tonumber(WeaponId)]
	local ModifiedConfig = {}
	for propertyName, propertyValue in pairs(WEAPON_CONFIG) do
		if config[propertyName] then
			ModifiedConfig[propertyName] = config[propertyName]
		else
			ModifiedConfig[propertyName] = WEAPON_CONFIG[propertyName]
		end
	end
	return ModifiedConfig
end

function WeaponService.CreateWeapon(WeaponId, config)
	return WeaponObject.new(WeaponService.CreateWeaponConfig(WeaponId, config))
end

return WeaponService
