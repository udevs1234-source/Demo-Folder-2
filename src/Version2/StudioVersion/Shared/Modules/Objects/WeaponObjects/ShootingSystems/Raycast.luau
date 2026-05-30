local RaycastShootingSystem = {}
local RunService = game:GetService("RunService") -- Way to determine Server or client
RaycastShootingSystem.__index = RaycastShootingSystem
local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local ShootingService = require(Registry.Shared.Modules.ShootingService)
-- Constructor
function RaycastShootingSystem.new(Config)
	local self = setmetatable({}, RaycastShootingSystem)
	return self
end

function RaycastShootingSystem:Update(Config)
	self.Range = Config.Range
end

function RaycastShootingSystem:ExecuteShooting(Weapon)
	local WeaponModel = Weapon.Model
	local FireInfo = ShootingService:GetFireInfo(Weapon)
	local Origin = FireInfo[1]
	local Direction = FireInfo[2] * self.Range
	local SignalHandler = Weapon.SignalHandler
	local RaycastParameters = RaycastParams.new()
	RaycastParameters.FilterDescendantsInstances = { self:ExcludeFromRaycast(Weapon) }
	RaycastParameters.FilterType = Enum.RaycastFilterType.Exclude
	local RaycastResult = workspace:Raycast(Origin, Direction, RaycastParameters)
	SignalHandler:Fire("OnShoot", { Origin = Origin, Direction = Direction })
	if RaycastResult then
		local HitPoint = RaycastResult.Position or Origin + Direction
		if RunService:IsServer() then
			Weapon.DamageSystem:ExecuteDamage({ Instance = RaycastResult.Instance, HitPoint = HitPoint })
		end
		if RunService:IsClient() then
			SignalHandler:Fire("OnHit", { HitPosition = HitPoint, Origin = Origin })
		end
	end
end

function RaycastShootingSystem:ExcludeFromRaycast(Weapon)
	local Player = Weapon.Owner
	if not Player then
		return
	end
	local Character = Player.Character
	local ExcludeParts = {}
	for _, Part in pairs(Character:GetDescendants()) do
		if Part:IsA("BasePart") then
			table.insert(ExcludeParts, Part)
		end
	end
	table.insert(ExcludeParts, Weapon.Model)
	return ExcludeParts
end

return RaycastShootingSystem
