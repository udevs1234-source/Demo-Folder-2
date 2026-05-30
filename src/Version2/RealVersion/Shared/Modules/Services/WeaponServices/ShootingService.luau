local ShootingService = {}
local RunService = game:GetService("RunService")
local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local FireEvent = Registry.Shared.Events.UnreliableRemoteEvent

local CurrentFireInfo = {}

local function GetCamera()
	return game.Workspace.CurrentCamera
end

-- Listen for fire events

if RunService:IsServer() then
	FireEvent.OnServerEvent:Connect(function(player, FireInfo)
		CurrentFireInfo[player.UserId] = FireInfo
	end)
end

function ShootingService:GetFireInfo(Weapon)
	local Config = Weapon.Config
	local WeaponName = Config.Name
	if RunService:IsServer() then
		local FireInfo = nil
		local Owner = Weapon.Owner
		local Elapsed = 0
		if not CurrentFireInfo[Owner.UserId] and Elapsed < 0.1 then
			task.wait(0.001)
			Elapsed = Elapsed + 0.001
			print("Waiting For Fire Info in Server")
		end
		FireInfo = CurrentFireInfo[Owner.UserId]
		return FireInfo
	end

	if RunService:IsClient() then
		local Camera = GetCamera()
		local WeaponModel = Camera:WaitForChild(WeaponName)
		if WeaponName then
			local FirePosition = WeaponModel:WaitForChild("Handle"):WaitForChild("FirePoint").WorldPosition
			local FireDirection = Camera.CFrame.LookVector.Unit
			local FireInfo = { FirePosition, FireDirection }
			FireEvent:FireServer(FireInfo)
			return FireInfo
		end
	end
end

return ShootingService
