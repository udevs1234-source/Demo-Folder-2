local AutoFireSystem = {}
AutoFireSystem.__index = AutoFireSystem

-- Constructor

function AutoFireSystem.new(Config)
	return setmetatable({}, AutoFireSystem)
end

function AutoFireSystem:Update(Config)
	self.FireRate = Config.FireRate
	self.MagazineSize = Config.MagazineSize
	self.FireToken = 0
	self.Reloading = false
end
function AutoFireSystem:StartFiring(Weapon)
	if not Weapon:CanFire() then
		return
	end
	Weapon:SetState("Firing")
	local FireRate = self.FireRate
	local MagzineSize = self.MagzineSize
	local AmmoUsed = Weapon.AmmoUsed
	self.FireToken = self.FireToken + 1
	local MyFireToken = self.FireToken
	task.spawn(function()
		while Weapon:IsState("Firing") do
			if Weapon.AmmoUsed >= self.MagazineSize then
				Weapon:SetState("Reloading")
				Weapon.SignalHandler:Fire("OnReload", Weapon)
				break
			end
			Weapon.AmmoUsed = Weapon.AmmoUsed + 1
			Weapon.ShootingSystem:ExecuteShooting(Weapon)
			Weapon.SignalHandler:Fire("OnFired", Weapon)
			task.wait(1 / FireRate)
		end
		if MyFireToken == self.FireToken then
			Weapon:SetState("Idle")
		end
	end)
end

function AutoFireSystem:StopFiring(Weapon)
	Weapon:SetState("Idle")
end

return AutoFireSystem
