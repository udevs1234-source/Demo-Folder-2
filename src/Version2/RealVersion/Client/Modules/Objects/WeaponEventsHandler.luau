local WeaponEventsHandler = {}
WeaponEventsHandler.__index = WeaponEventsHandler

function WeaponEventsHandler.new(Weapon)
	local self = setmetatable({}, WeaponEventsHandler)
	return self
end

function WeaponEventsHandler:Update(Weapon)
	self.Weapon = Weapon
	self.AnimationSystem = Weapon.AnimationHandler.AnimationSystem
	self.SignalHandler = Weapon.SignalHandler
end

function WeaponEventsHandler:ConnectEvents()
	local Weapon = self.Weapon
	local SignalHandler = self.SignalHandler
	local AnimationSystem = self.AnimationSystem
	local function HandleAnimationSystem(SignalName, ...)
		if AnimationSystem[SignalName] then
			AnimationSystem[SignalName](AnimationSystem, ...)
			Weapon.Config.FireSound:Play()
		end
	end

	local function ConnectAllSignals()
		for SignalName, _ in pairs(SignalHandler.Signals) do
			SignalHandler:Connect(SignalName, function(...)
				HandleAnimationSystem(SignalName, ...)
			end)
		end
	end
	ConnectAllSignals()
end
return WeaponEventsHandler
