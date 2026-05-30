local AbilityHandler = {}
AbilityHandler.__index = AbilityHandler
local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local AbilitySystems = Registry.AbilitySystems

function AbilityHandler.new(Weapon)
	local self = setmetatable({}, AbilityHandler)
	return self
end

function AbilityHandler:Update(Weapon)
	self.AbilitySystems = {}
	self.Weapon = Weapon
end

-- Function to connect signals to ability systems , for both server and client
function AbilityHandler:ConnectAbilitySystem()
	if #self.AbilitySystems > 0 then -- Prevent re-Creation of Ability Systems
		table.clear(self.AbilitySystems)
	end

	local Weapon = self.Weapon
	local Configs = Weapon.Config.Abilities -- Whole Ability Table
	for _, AbilityConfig in pairs(Configs) do
		local AbilityName = AbilityConfig.type
		if not self.Weapon[AbilityName] then
			self.AbilitySystems[AbilityName] = require(AbilitySystems[tostring(AbilityName)]).new(AbilityConfig)
		else
			self.AbilitySystems:Update(AbilityConfig)
		end
	end

	local SignalHandler = Weapon.SignalHandler
	local function ConnectAbilitySystems(SignalName, ...)
		for _, AbilitySystem in pairs(self.AbilitySystems) do
			if AbilitySystem[SignalName] then -- Also use SignalName not AbilityName here
				AbilitySystem[SignalName](AbilitySystem, ...)
			end
		end
	end

	local function ConnectAllSignals()
		for SignalName, _ in pairs(SignalHandler.Signals) do
			SignalHandler:Connect(SignalName, function(...)
				ConnectAbilitySystems(SignalName, ...)
			end)
		end
	end
	ConnectAllSignals()
end

return AbilityHandler
