local WeaponSystem = {}
local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local Players = game:GetService("Players")
WeaponSystem.__index = WeaponSystem

function WeaponSystem.ExecuteWeaponTask(UserId, Weapon, taskName)
	if WeaponSystem[taskName] then
		WeaponSystem[taskName](Players:GetPlayerByUserId(UserId), Weapon)
	end
end
local PreviousWeapon = nil
--------------------------
-- Functions which runs on response to Input
--------------------------

function WeaponSystem.Equip(player, Weapon)
	-- Weapon:Equip()
	local WeaponTool = Weapon.Model
	WeaponTool.Parent = player.Character
	PreviousWeapon = Weapon
end

function WeaponSystem.Unequip(player, Weapon)
	-- Weapon:Unequip()
	local WeaponTool = Weapon.Model
	WeaponTool.Parent = player.Backpack
end

function WeaponSystem.Change(player, Weapon)
	WeaponSystem.Unequip(player, PreviousWeapon)
	WeaponSystem.Equip(player, Weapon)
end

function WeaponSystem.StartFiring(player, Weapon)
	Weapon:StartFiring(Weapon)
end

function WeaponSystem.StopFiring(player, Weapon)
	Weapon:StopFiring(Weapon)
end

function WeaponSystem.Reload(player, Weapon)
	Weapon:Reload(Weapon)
end

return WeaponSystem
