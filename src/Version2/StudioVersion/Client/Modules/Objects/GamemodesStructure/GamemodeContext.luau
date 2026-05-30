local GamemodeContext = {}

GamemodeContext.__index = GamemodeContext

function GamemodeContext.new(Context)
	local self = setmetatable({}, GamemodeContext)

	self.TeamContext = Context.TeamContext or {}
	self.RoundContext = Context.RoundContext or {}
	self.WeaponContext = Context.WeaponContext or {}
	self.PlayerContext = Context.PlayerContext or {}
    self.InputContext = Context.InputContext or {}
	self.CustomContext = {}

	return self
end

return GamemodeContext
