local WeaponSystem = {}
local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)

local function GetCamera()
	return game.Workspace.CurrentCamera
end
WeaponSystem.__index = WeaponSystem

function WeaponSystem.ExecuteWeaponTask(Weapon, taskName)
	if WeaponSystem[taskName] then
		WeaponSystem[taskName](Weapon)
	end
end
local PreviousWeapon = nil
--------------------------
-- Functions which runs on response to Input
--------------------------

function WeaponSystem.Equip(Weapon)
	print("Equipping Weapon")
	local WeaponModel = Weapon.Model
	local RunService = game:GetService("RunService")
	local Camera = GetCamera()
	local CameraPart = WeaponModel.CameraPart
	WeaponModel.Parent = Camera
	RunService.RenderStepped:Connect(function()
		if not WeaponModel.Parent then
			return
		end
		CameraPart.CFrame = Camera:GetRenderCFrame()
	end)
	PreviousWeapon = Weapon
end

function WeaponSystem.Unequip(Weapon)
	-- Weapon:Unequip()
	local WeaponModel = Weapon.Model
	WeaponModel.Parent = nil
end

function WeaponSystem.Change(Weapon)
	WeaponSystem.Unequip(PreviousWeapon)
	WeaponSystem.Equip(Weapon)
end

function WeaponSystem.StartFiring(Weapon)
	Weapon:StartFiring(Weapon)
end

function WeaponSystem.StopFiring(Weapon)
	Weapon:StopFiring(Weapon)
end

function WeaponSystem.Reload(Weapon)
	Weapon:Reload(Weapon)
end

return WeaponSystem
