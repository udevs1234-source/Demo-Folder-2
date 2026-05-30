local GamemodeService = {}

local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local Gamemodes = Registry.Client.Modules.Gamemodes :: Folder
local Gamemode = nil
function GamemodeService.CreateGamemode(clientPackage)
	local GamemodeName = clientPackage.MatchContext.MatchInfo.Gamemode :: string
	Gamemode = require(Gamemodes[GamemodeName]).new(clientPackage)
	Gamemode:Init()
	return Gamemode
end

return GamemodeService
