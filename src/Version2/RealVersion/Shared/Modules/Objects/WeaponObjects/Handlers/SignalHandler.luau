local SignalHandler = {}

SignalHandler.__index = SignalHandler

function SignalHandler.new()
	local self = setmetatable({}, SignalHandler)
	self.Signals = {} -- Store all Signals
	return self
end

-- Register Signal
function SignalHandler:RegisterSignal(SignalName)
	if not self.Signals[SignalName] then
		self.Signals[SignalName] = {}
	end
end
-- Insert Callback Function to Signal
function SignalHandler:Connect(SignalName, CallbackFunction)
	self:RegisterSignal(SignalName)
	table.insert(self.Signals[SignalName], CallbackFunction)
end

-- Fire and Run Callback Functions
function SignalHandler:Fire(SignalName, ...)
	if not self.Signals[SignalName] then
		return
	end
	for _, CallbackFunction in pairs(self.Signals[SignalName]) do
		CallbackFunction(...)
	end
end

-- Destroys a signal
function SignalHandler:Destroy(SignalName)
	if self.Signals[SignalName] then
		self.Signals[SignalName] = nil
	end
end

-- Register Many Signals
function SignalHandler:RegisterSignals(SignalsName)
	for _, SignalName in pairs(SignalsName) do
		self:RegisterSignal(SignalName)
	end
end

return SignalHandler
