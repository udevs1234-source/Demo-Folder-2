local SignalBus = {}
local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local Signal = require(Registry.Shared.Modules.Signal)
local SessionManager = require(Registry.GetServerOrClientInstance("Modules","SessionManager"))

SignalBus.__index = function(Element, Index)
	return SignalBus.GetSignal(Index)
end

function SignalBus.IsSignal(signalName)
	return SessionManager:GetMatchObject("Signals", signalName) ~= nil
end

function SignalBus.CreateSignal(signalName)
	if SignalBus.IsSignal(signalName) then
		return
	end
	SessionManager:StoreMatchObject("Signals", signalName, Signal.new(signalName))
end

function SignalBus.CreateSignals(SignalNames)
	for _, signalName in ipairs(SignalNames) do
		SignalBus.CreateSignal(signalName)
	end
end

function SignalBus.GetSignal(signalName)
	SignalBus.CreateSignal(signalName)
	return SessionManager:GetMatchObject("Signals", signalName)
end

function SignalBus.ConnectSignal(signalName, callback)
	SignalBus.GetSignal(signalName):Connect(callback)
end

function SignalBus.FireSignal(signalName, callback)
	SignalBus.GetSignal(signalName):Fire()
end

setmetatable({}, SignalBus)

return SignalBus
