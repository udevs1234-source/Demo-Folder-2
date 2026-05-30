local GameBehaviours = {}

local Player_Service_String = "PlayerService"
local Team_Service_String = "TeamService"
local Weapon_Service_String = "WeaponService"
local Round_Service_String = "RoundService"

------------------
-- Player Death Behaviours
------------------

function GameBehaviours:SetRespawnTimer(userId)
	task.delay(self.RespawnTime, function()
		self:HandlePlayerSpawn(userId, nil)
	end)
end

function GameBehaviours:WinMatchWhenAllKilledInTeam(Info)
    local attackerUserId, victimUserId = Info.attacker, Info.victim
    local PlayerService, TeamService = self:GetService(Player_Service_String), self:GetService(Team_Service_String)
	local currentAlivePlayers = TeamService.GetTeamState(PlayerService.GetPlayerState(victimUserId, "teamId"), "aliveCount")
	if currentAlivePlayers == 0 then
		self:HandleRoundWin(PlayerService.GetPlayerState(attackerUserId, "teamId"))
		self:HandleRoundEnd()
		self:HandleMatchEnd()
	end
end


return GameBehaviours
