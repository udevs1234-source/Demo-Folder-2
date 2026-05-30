local Signal = {}

Signal.__index = Signal

function Signal.new(SignalName)
	local self = setmetatable({}, Signal)
	self.Name = SignalName
	self.CallbackFunctions = {}
	return self
end

function Signal:RegisterCallbackFunction(CallbackFunction)
	table.insert(self.CallbackFunctions, CallbackFunction)
end

function Signal:RegisterCallbackFunctions(CallbackFunctions)
	for _, CallbackFunction in ipairs(CallbackFunctions) do
		self:RegisterCallbackFunction(CallbackFunction)
	end
end

function Signal:Fire(...)
	-- Run Callback Functions on Fire
	for _, CallbackFunction in ipairs(self.CallbackFunctions) do
		CallbackFunction(...)
	end
end

function Signal:Connect(CallbackFunction)
	self:RegisterCallbackFunction(CallbackFunction)
end

function Signal:Disconnect()
	table.clear(self.CallbackFunctions)
	self.CallbackFunctions = nil
end

return Signal
