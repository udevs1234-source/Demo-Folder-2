local AnimationHandler = {}
local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local AnimationSystems = Registry.Shared.Modules.AnimationSystems :: Folder
AnimationHandler.__index = AnimationHandler

function AnimationHandler.new(Weapon)
	local self = setmetatable({}, AnimationHandler)
	self.AnimationSystem = require(AnimationSystems[tostring(Weapon.Config.AnimationSystem.type)]).new()

	return self
end

function AnimationHandler:Update(Weapon)
	self.Weapon = Weapon
	self.Animator = Weapon.Model.AnimationController.Animator
	self.AnimationTracks = {}
	self:LoadAnimations(Weapon.Config.Animations) -- Update Animation Tracks otr Animation Handler
	self.AnimationSystem:Update(Weapon.Config.AnimationSystem, self.AnimationTracks) -- Update Animation System
end

local function MakeTrack(Animator, AnimationId, AnimationName)
	local Animation = Instance.new("Animation")
	Animation.AnimationId = AnimationId
	Animation.Name = AnimationName
	return Animator:LoadAnimation(Animation)
end
function AnimationHandler:LoadAnimation(AnimationName, AnimationId)
	if not self.AnimationTracks[AnimationName] then
		self.AnimationTracks[AnimationName] = MakeTrack(self.Animator, AnimationId, AnimationName)
	end
end

function AnimationHandler:LoadAnimations(AnimationsTable)
	if #self.AnimationTracks > 0 then -- Prevents re-loading animations
		table.clear(self.AnimationTracks)
	end
	for AnimationName, AnimationId in pairs(AnimationsTable) do
		self:LoadAnimation(AnimationName, AnimationId)
	end
end

return AnimationHandler
