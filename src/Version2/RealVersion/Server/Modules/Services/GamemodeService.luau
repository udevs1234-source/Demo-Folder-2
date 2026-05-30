local GamemodeService = {}
local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry).Server.Modules
local Gamemodes = Registry.Gamemodes :: Folder
local Gamemode = nil
local MatchData = nil
function GamemodeService.CreateGamemode(Match_Data)
	local GamemodeName = Match_Data.MatchInfo.Gamemode :: string
	Gamemode = require(Gamemodes[GamemodeName]).new(Match_Data)
	Gamemode:Init()
	MatchData = Match_Data
	return Gamemode
end

function GamemodeService.GetMatchData()
	return MatchData
end

function GamemodeService.GetMatchDataOfIndex(Index)
	return MatchData[Index]
end

return GamemodeService
