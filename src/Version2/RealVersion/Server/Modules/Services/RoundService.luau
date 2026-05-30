local RoundService = {}

local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local SignalBus = require(Registry.Shared.Modules.SignalBus)
local SessionManager = require(Registry.Server.Modules.SessionManager)
-- Module state

local _matchTask = nil
local _roundTask = nil
local _roundSync = Instance.new("BindableEvent")

local DEFAULT_ROUND_STATE = { currentRound = 0, phase = "Waiting", timeRemaining = 0 }

function RoundService.SetRoundState(stateName, value)
	if stateName then
		SessionManager:StoreObject({ "Match", "Round", stateName }, value)
	else
		SessionManager:StoreObject({ "Match", "Round" }, value)
	end
end

function RoundService.GetRoundState(stateName)
	local State = nil
	if stateName then
		State = SessionManager:GetObject({ "Match", "Round", stateName })
	else
		State = SessionManager:GetObject({ "Match", "Round" })
	end
	return State
end

function RoundService.IncrementRoundState(stateName, incrementValue)
	RoundService.SetRoundState(stateName, RoundService.GetRoundState(stateName) + incrementValue)
end

function RoundService.InitializeRoundState()
	RoundService.SetRoundState(nil, DEFAULT_ROUND_STATE)
end

local function cleanupTasks()
	if _matchTask then
		task.cancel(_matchTask)
		_matchTask = nil
	end
	if _roundTask then
		task.cancel(_roundTask)
		_roundTask = nil
	end
end

function RoundService.StopMatch()
	cleanupTasks()
	RoundService.SetRoundState("currentRound", 0)
end

function RoundService.ForceEndRound()
	if not _roundTask then
		return
	end
	task.cancel(_roundTask)
	_roundTask = nil
	_roundSync:Fire()
end

--------------------------
-- Timeline
--------------------------

function RoundService.StartTimeline(context)
	cleanupTasks()
	local MatchStart = context.MatchStart
	local RoundWaiting = context.RoundWaiting
	local RoundDuration = context.RoundDuration
	local MatchEnd = context.MatchEnd
	local MaxRounds = context.MaxRounds
	_matchTask = task.spawn(function()
		SignalBus.FireSignal("OnMatchStarted")
		task.wait(MatchStart)
		for i = 1, MaxRounds do
			RoundService.IncrementRoundState("currentRound", 1)
			RoundService.SetRoundState("phase", "Waiting")
			SignalBus.FireSignal("OnRoundWaitingStarted")
			task.wait(RoundWaiting)
			RoundService.SetRoundState("phase", "Active")
			SignalBus.FireSignal("OnRoundStarted")
			_roundTask = task.delay(RoundDuration, function()
				_roundTask = nil
				_roundSync:Fire()
			end)
			task.spawn(function()
				local remaining = RoundDuration
				while remaining > 0 and RoundService.GetRoundState("phase") == "Active" do
					task.wait(1)
					remaining -= 1
					RoundService.SetRoundState("timeRemaining", remaining)
				end
			end)
			_roundSync.Event:Wait()
			RoundService.SetRoundState("phase", "Ended")
			SignalBus.FireSignal("OnRoundEnded")
		end
		SignalBus.FireSignal("OnMatchWaitingStarted")
		task.wait(MatchEnd)
		SignalBus.FireSignal("OnMatchEnded")
	end)
end

--------------------------
-- Initialisation
--------------------------

function RoundService.Init(context)
	RoundService.InitializeRoundState()
	RoundService.StartTimeline(context)
end

return RoundService
