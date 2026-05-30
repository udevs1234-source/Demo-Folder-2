local InputService = {}
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local SignalBus = require(Registry.Shared.Modules.SignalBus)

local DeviceType = (function()
	if UserInputService.GamepadEnabled then
		return "Console"
	elseif UserInputService.TouchEnabled then
		return "Mobile"
	else
		return "PC"
	end
end)()

local function _BindAction(actionName, handler, hasDefaultButton, inputs)
	ContextActionService:BindAction(actionName, handler, hasDefaultButton, unpack(inputs))
end

local function _FireInput(actionName, isActive)
	SignalBus.FireSignal("InputsSignal", { actionName = actionName, isActive = isActive })
end

local function _BeginEndHandler(actionName)
	return function(_, inputState, _)
		if inputState == Enum.UserInputState.Begin then
			_FireInput(actionName, true)
			print(inputState,actionName)
		elseif inputState == Enum.UserInputState.End then
			_FireInput(actionName, false)
		end
		print(inputState,actionName)
	end
end

local function _WheelHandler(actionName, inputName)
	return function(_, _, inputObject)
		local isForward = inputName == "WheelForward" and inputObject.Position.Z > 0
		local isBackward = inputName == "WheelBackward" and inputObject.Position.Z < 0
		if isForward or isBackward then
			_FireInput(actionName, true)
		end
	end
end

local function ConnectInputAction(actionName, inputName)
	if inputName == "WheelForward" or inputName == "WheelBackward" then
		_BindAction(actionName, _WheelHandler(actionName, inputName), false, { Enum.UserInputType.MouseWheel })
		return
	end

	if DeviceType == "PC" then
		local keyInput = Enum.KeyCode[inputName]
		local mouseInput = Enum.UserInputType[inputName]
		if keyInput then
			_BindAction(actionName, _BeginEndHandler(actionName), false, { keyInput })
		elseif mouseInput then
			_BindAction(actionName, _BeginEndHandler(actionName), false, { mouseInput })
		end
	elseif DeviceType == "Console" then
		local gamepadInput = Enum.KeyCode[inputName]
		if gamepadInput then
			_BindAction(actionName, _BeginEndHandler(actionName), false, { gamepadInput })
		end
	elseif DeviceType == "Mobile" then
		local touchInput = Enum.UserInputType[inputName]
		if touchInput then
			_BindAction(actionName, _BeginEndHandler(actionName), true, { touchInput })
		end
	end
end

function InputService.Init(context)
	for deviceType, deviceBindings in pairs(context) do
		if deviceType ~= DeviceType then
			continue
		end
		for actionName, inputName in pairs(deviceBindings) do
			ConnectInputAction(actionName, inputName)
		end
	end
end

return InputService
