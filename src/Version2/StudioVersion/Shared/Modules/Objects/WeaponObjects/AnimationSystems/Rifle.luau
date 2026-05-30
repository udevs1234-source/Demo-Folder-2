local RifleAnimationSystem = {}
RifleAnimationSystem.__index = RifleAnimationSystem
local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local AnimationService = require(Registry.Shared.Modules.AnimationService)
local AnimationHandlerModule = require(Registry.Shared.Modules.AnimationHandler)
function RifleAnimationSystem.new()
	local self = setmetatable({}, RifleAnimationSystem)
	return self
end

function RifleAnimationSystem:Update(Config, AnimationTracks)
	self.AnimationTracks = AnimationTracks
	self.Speed = 2
end

function RifleAnimationSystem:OnFired(...)
	local AnimationTracks = self.AnimationTracks
	AnimationService:Play(AnimationTracks["Fire"], { Speed = self.Speed })
end

function RifleAnimationSystem:OnReload()
	local AnimationTracks = self.AnimationTracks
	AnimationService:Play(AnimationTracks["Reload"], { Speed = self.Speed })
end

return RifleAnimationSystem
