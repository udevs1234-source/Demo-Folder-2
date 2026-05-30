local StandardDamageSystem = {}

StandardDamageSystem.__index = StandardDamageSystem
local Registry = require(game:GetService("ReplicatedStorage").Shared.Modules.Registry)
local SignalBus = require(Registry.Shared.Modules.SignalBus)
-- Constructor
function StandardDamageSystem.new(Config)
	local self = setmetatable({}, StandardDamageSystem)
	return self
end

function StandardDamageSystem:Update(Config)
	self.Damage = Config.Damage
end

function StandardDamageSystem:ExecuteDamage(DamageInfo)
	local instance = DamageInfo.Instance
	local HitPoint = DamageInfo.HitPoint
	local Damage = self.Damage
	local Humanoid = instance.Parent:FindFirstChild("Humanoid")
	if Humanoid then
		Humanoid:TakeDamage(Damage)
		print("Damage is given to player")
	end
	if instance.Name == "Rig" then
		instance.Humanoid.Health = instance.Humanoid.Health - Damage
	end
end

return StandardDamageSystem
