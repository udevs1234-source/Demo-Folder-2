local DeathMatch = {}
local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local GameRules = require(Registry.Client.Modules.GameRules)
local WeaponService = require(Registry.Client.Modules.WeaponService)

DeathMatch.__index = DeathMatch
setmetatable(DeathMatch, { __index = GameRules })
function DeathMatch.new(Context)
	local self = GameRules.new(Context)

	return setmetatable(self, DeathMatch)
end

--------------------
-- Initialising Gamemode
--------------------

function DeathMatch:InitializeContext()
	local ModifiedContext = {}
	local Context = self.Context
	---- Modyfying it
end

function DeathMatch:InitializeConnections()

end

------------------
-- Gamemode Related Features
------------------

return DeathMatch
