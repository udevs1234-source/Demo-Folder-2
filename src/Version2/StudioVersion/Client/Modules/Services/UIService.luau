local Players = game:GetService("Players")

local UIService = {}
local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local VideModules = Registry.Client.Modules.Vide
local Vide = require(VideModules)
local UIComponents = require(Registry.Client.Modules.UIComponents)
local UIThemes = require(Registry.Client.Modules.UIThemes)
local CharmModules = Registry.Client.Modules.Charm

local atom = require(CharmModules.atom)
local subscribe = require(CharmModules.subscribe)

local function useCharm(charmAtom)
	local state = Vide.source(charmAtom())

	local unsubscribe = subscribe(charmAtom, function(newValue)
		state(newValue)
	end)

	Vide.cleanup(unsubscribe)
	return function()
		return state()
	end
end
local countAtom = atom(0)

function UIService.Init(context)
	task.spawn(function()
		for i = 0, 60 do
			task.wait(1)
			countAtom(i)
		end
	end)
	local GameUI = Vide.root(function()	
		local count = useCharm(countAtom)
		local App = UIComponents.App({count = count})
		local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
		local HUD = PlayerGui:WaitForChild("HUD")
		App.Parent = HUD
		print("Setupped UI")
	end)

end

return UIService