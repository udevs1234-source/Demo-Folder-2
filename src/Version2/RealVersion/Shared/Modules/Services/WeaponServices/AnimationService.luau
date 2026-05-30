local AnimationService = {}

function AnimationService:Play(AnimationTrack, Options)
	AnimationTrack:Play()
end

function AnimationService:Stop(AnimationTrack, Options)
	AnimationTrack:Stop()
end

return AnimationService
