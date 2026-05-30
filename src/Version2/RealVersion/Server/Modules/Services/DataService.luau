local DataService = {}

local Registry = require(game.ReplicatedStorage.Shared.Modules.Registry)
local SessionManager = require(Registry.Server.Modules.SessionManager)
local PlayerDataManager = require(Registry.Server.Modules.PlayerDataManager)
local Promise = require(Registry.Shared.Modules.Promise)
local DataStoreService = game:GetService("DataStoreService")
local TableUtils = require(Registry.Shared.Modules.TableUtils)
local ProfileStore = require(Registry.Shared.Modules.ProfileStore)
local Players = game:GetService("Players")

--[[
------- ["Data Service"] -

 Functions-
    -- Functions["Match Data Handling"] : - 
       -- (1) StartMatchSession (2) EndMatchSession
    -- Functions["Player Data Handling"] : -
       -- (1) StartPlayerSession (2) EndPlayerSession 
    Note - These Fuctions include both ProfileStore And Managers interaction
    Dependencies - ProfileStore,TableUtils And Managers
]]

--------------------- Private  -----------------------

-----------------------------------------
-------- Player Data Handling ----------
-----------------------------------------

------ Variables ------

local profiles = {}
local ExpandedPlayerData = {}
local Player_store_name = "PlayerProfileStore"
local PlayerProfileStore = nil

local PlayerDataTemplate = {
	Version = 1,
	I = { W = { [1] = { Lv = 12, Att = 4 } }, S = {}, E = {} },
	St = { C = 0, G = 0, K = 49 },
	Se = { A = true, B = 30 },
	Q = { C = { "Hunter", "Killer" } },
	C = { PC = {F = "M1", S = "M2", R = "R", WF = "WF", WB = "WB" } }
}

------- Data Expansion And Modification -------

----- Data Expansion

local function MapNamingOfTwoTables(Table, MapTable, expansionFunction)
	--- Ex of MapTable : {"W" = "Weapons","S" = "Skins"}
	local modifiedTable = {}
	for defaultName, modifiedName in pairs(MapTable) do
		if Table[defaultName] then
			if expansionFunction then
				modifiedTable[modifiedName] = expansionFunction(defaultName)
			else
				modifiedTable[modifiedName] = Table[defaultName]
			end
		end
	end
	return modifiedTable
end

local function ExpandInventory(InventoryData)
	local modifiedData = {}
	local MapTable1, MapTable2 = { W = "Weapons", S = "Skins" }, { Lv = "Level", Att = "Attachment" }
	modifiedData = MapNamingOfTwoTables(InventoryData, MapTable1, function(defaultName)
		if defaultName == "W" then
			local modifiedWeaponsTable = {}
			for weaponId, weaponData in ipairs(InventoryData.W) do
				modifiedWeaponsTable[weaponId] = MapNamingOfTwoTables(weaponData, MapTable2, nil)
			end
			return modifiedWeaponsTable
		else
			return {}
		end
	end)
	return modifiedData
end

local function ExpandStats(StatsData)
	local modifiedData = {}
	local MapTable = { C = "Coins", G = "Gems", K = "Kills" }
	modifiedData = MapNamingOfTwoTables(StatsData, MapTable, nil)
	return modifiedData
end

local function ExpandControls(KeyBindingsData)
	local modifiedPlayerData = {}
	for deviceName, deviceBindings in pairs(KeyBindingsData) do
		modifiedPlayerData[deviceName] = {}
		if deviceName == "PC" then
			local MapTable1, MapTable2 =
				{ F = "Fire", R = "Reload", S = "Scope", WF = "WeaponForward", WB = "WeaponBackward" },
				{ M1 = "MouseButton1", M2 = "MouseButton1", WF = "WheelForward", WB = "WheelBackward" }
			MapNamingOfTwoTables(modifiedPlayerData.PC, MapTable1, function(defaultValue)
				return MapTable2[MapTable1[defaultValue]] or defaultValue
			end)
		end
		
	end
	return modifiedPlayerData
end

local function ExpandPlayerData(PlayerData)
	local modifiedPlayerData = {}
	modifiedPlayerData.Inventory = ExpandInventory(PlayerData.I)
	modifiedPlayerData.Stats = ExpandStats(PlayerData.St)
	modifiedPlayerData.Controls = ExpandControls(PlayerData.C)
	return modifiedPlayerData
end

local function RegisterExpandedPlayerData(UserId, PlayerData)
	ExpandedPlayerData[UserId] = ExpandPlayerData(PlayerData)
end

local function GetExpandedPlayerData(UserId)
	return ExpandedPlayerData[UserId]
end

local function CombineCachedAndUpdatedRoundsPlayerStats(userId, DefaultStats, AllRoundsUpdatedStats)
	local PlayerFinalStats = DefaultStats
	for _, roundStats in pairs(AllRoundsUpdatedStats) do
		local playerRoundStats = roundStats.Players[userId]
		for key, incrementValue in pairs(playerRoundStats) do
			if DefaultStats[key] == true then
				PlayerFinalStats[key] += incrementValue
			end
		end
	end
	return PlayerFinalStats
end

----- Player Data Security And Validation

local function GetPlayerProfileData(PlayerProfile)
	return PlayerProfile.Data
end

local function ProcessPurchaseRecieptOfPlayerProfile(PlayerProfile, Reciept) end

local function SetPlayerProfileData(PlayerProfile, Setter) end

local function UpdatePlayerProfileData(PlayerProfile, Updation) end

----- Migration

local function MigratePlayerData(PlayerProfile)
	local CurrentVersion = GetPlayerProfileData(PlayerProfile).Version
	if CurrentVersion == 1 then
		--modifiedPlayerData
		CurrentVersion += 1
	end
	if CurrentVersion == 2 then
		--modifiedPlayerData
		CurrentVersion += 1
	end
	if CurrentVersion == 3 then
		--modifiedPlayerData
		---- Last Version , No Addition in CurrentVersion
	end
end

--------- Profile Strore and Player Profile Handling  ---------

------ Profile Store

local function AddPlayerProfileStore()
	PlayerProfileStore = ProfileStore.New(Player_store_name, PlayerDataTemplate).Mock
end

local function ConnectProfileStoreSignals()

	--PlayerProfileStore.OnError:Connect(function(message, store_name, profile_key)

	--end)

	--PlayerProfileStore.OnOverwrite:Connect(function(store_name, profile_key)

	--end)

	--PlayerProfileStore.OnCriticalToggle:Connect(function(isCritical)

	--end)
end

------ Player Profile
local function GetPlayerProfile(UserId: string)
	return profiles[UserId]
end

local function RegisterPlayerProfile(UserId, PlayerProfile)
	profiles[UserId] = PlayerProfile
end

local function ConnectPlayerProfileSignals(PlayerProfile)

	--PlayerProfile.OnLastSave:Connect(function(reason)

	--end)
	--PlayerProfile.OnAfterSave:Connect(function(savedData)

	--end)
	--PlayerProfile.OnSessionEnd:Connect(function()
	--	profiles[PlayerProfile.key] = nil
	--end)
end

---------- Storage And Data Management  -----------

local function StorePlayerData(UserId, PlayerData)
	PlayerDataManager:StorePlayerData(UserId, PlayerData)
end

---------- Player Session Handling ----------
local function StartPlayerSession(UserId: string)
	local Player = Players:GetPlayerByUserId(UserId)
	local Profile = PlayerProfileStore:StartSessionAsync(UserId, {
		Cancel = function(is_active)
			return Player:IsDescendantOf(Players)
		end,
	})
	if not Profile then
		Player:Kick("Data Failed to load ,Please rejoin")
	end

	Profile:AddUserId(tonumber(UserId))
	Profile:Reconcile()
	MigratePlayerData(Profile)
	RegisterPlayerProfile(UserId, Profile)
	ConnectPlayerProfileSignals(Profile)
	RegisterExpandedPlayerData(UserId, GetPlayerProfileData(Profile))
	StorePlayerData(tonumber(UserId), GetExpandedPlayerData(UserId))
end

local function EndPlayerSession(UserId: string)
	local PlayerProfile = GetPlayerProfile(UserId)
	local UpdatedPlayerStats = CombineCachedAndUpdatedRoundsPlayerStats(
		UserId,
		PlayerDataManager:GetObject({ UserId, "Cache", "Stats" }),
		SessionManager:GetObject({ "Match", "RoundsHistory" })
	)
	PlayerDataManager:CleanupPlayer(UserId)
	SessionManager:CleanupPlayer(UserId)
	PlayerProfile:EndSession()
end

--------------------------------
-- Match Data Handling
--------------------------------

------ Storage -------

local function StoreMatchData(MatchData)
	SessionManager:StoreMatchData(MatchData)
end

------ Match Session Handling -----

local function StartMatchSession(MatchData)
	StoreMatchData(MatchData)
end

--------------------- Public -----------------------

------------------------------------
------ Player Data Handling ------
------------------------------------

------- Profile Srore and Player Profile Handling -------
function DataService.InitProfileStore()
	AddPlayerProfileStore()
	ConnectProfileStoreSignals()
end

function DataService.StartPlayerSession(UserId: number)
	StartPlayerSession(tostring(UserId))
end

function DataService.EndPlayerSession(UserId: number)
	EndPlayerSession(tostring(UserId))
end

--------------------------------
-- Match Data Handling
--------------------------------

function DataService.StartMatchSession(MatchData)
	StartMatchSession(MatchData)
end

function DataService.EndMatchSession(args) end

return DataService
