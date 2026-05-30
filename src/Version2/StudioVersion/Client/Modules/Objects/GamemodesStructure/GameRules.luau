local GameRules = {}
local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local GamemodeBase = require(Registry.Client.Modules.GamemodeBase)
local GameBehaviours = require(Registry.Client.Modules.GameBehaviours)
GameRules.__index = GameRules
setmetatable(GameRules, { __index = GamemodeBase })
function GameRules.new(context)
	local self = GamemodeBase.new(context)

	return setmetatable(self, GameRules)
end

function GameRules._RegisterGameBehaviours()
	for behaviourName, gameBehaviour in pairs(GameBehaviours) do
		GameRules[behaviourName] = gameBehaviour
	end
end
GameRules._RegisterGameBehaviours()
--------------------------
-- Initialisation
--------------------------

local UI_Service_String = "UIService"
local Player_Service_String = "PlayerService"
local Input_Service_String = "InputService"

function GameRules:_RegisterAllSignalsAndHooks()
	local SignalInfo = {
		{ signalName = "InputsSignal", handler = "HandlePlayerInput" },
	}
	local EventInfo = {
		{ eventName = "StateSync", handler = "HandleStateSync", hookName = "StateRecieved" },
	}
	for _, Info in pairs({ SignalInfo, EventInfo }) do
		for _, hookInfo in pairs(Info) do
			local signalName, eventName, handler, hookName =
				hookInfo.signalName, hookInfo.eventName, hookInfo.handler, hookInfo.hookName
			local handlerFunction = handler
			if type(handler) == "string" and self[handler] then
				handlerFunction = self[handler]
			end
			if signalName or eventName then
				local executionPipeline = nil
				if hookName then
					for _, hookType in pairs({ "After", "Before" }) do
						if not self[hookType .. hookName] then
							self[hookType .. hookName] = function() end
						end
					end
					executionPipeline = function(...)
						self["Before" .. hookName](...)
						handlerFunction(self,...)
						self["After" .. hookName](...)
					end
				else
					executionPipeline = function(...)
						handlerFunction(self,...)
					end
				end
				if signalName then
					self:ConnectSignal(signalName, function(...)
						executionPipeline(...)
					end)
				end
				if eventName then
					self:ConnectEvent(eventName, function(...)
						executionPipeline(...)
					end)
				end
			end
		end
	end
end

function GameRules:InitializeRuleConnections()
	self:_RegisterAllSignalsAndHooks()
end

function GameRules:HandlePlayerInput(inputInfo)
	local PlayerService = self:GetService(Player_Service_String)
	local WeaponFireActions = { Fire = true }
	local WeaponActionActions = {
		Reload = true,
		WeaponForward = true,
		WeaponBackward = true,
		Scope = true,
	}
	local actionName = inputInfo.actionName
	local requiredEvent = nil
	if WeaponFireActions[actionName] then
		requiredEvent = "WeaponFireEvent"
		self:HandleWeaponTask(PlayerService.GetPlayerState("weaponEquipped"), "Fire")
	elseif WeaponActionActions[actionName] then
		requiredEvent = "WeaponActionEvent"
	else
		requiredEvent = "PlayerActionEvent"
	end

	self:FireEvent(requiredEvent, inputInfo)
end
function GameRules:HandleStateSync(state)
	
	
 end

return GameRules
