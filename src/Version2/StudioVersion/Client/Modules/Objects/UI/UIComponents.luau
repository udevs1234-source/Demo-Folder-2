local UIComponents = {}
local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local Vide = require(Registry.Client.Modules.Vide)

local create, source, derive, effect, root, untrack, show, indexes, cleanup, action =
	Vide.create,
	Vide.source,
	Vide.derive,
	Vide.effect,
	Vide.root,
	Vide.untrack,
	Vide.show,
	Vide.indexes,
	Vide.cleanup,
	Vide.action

function UIComponents.App(props)
	return create("TextLabel")({
		Text = props.count,
		Size = UDim2.fromScale(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
	})
end

return UIComponents
