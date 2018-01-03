-- ============================================================================
-- ============= Credit System ================================================
-- ============================================================================
-- Calculates and awards the player credits accordingly

local Shine = Shine
local PlayerCredits = { _version = "0.1.0" }
local sc_json = require("shine/extensions/shinecredits/sc_jsonfileio")
local sc_notification = require("shine/extensions/shinecredits/sc_notification")
local sc_playerleveling = require("shine/extensions/shinecredits/sc_playerleveling")

-- ============================================================================
-- Default Config
-- ============================================================================
PlayerCredits.Settings = {
    Enabled = true,
    FilePath = "config://shine/plugins/ShineCredits_UserCredits.json",

    AwardModes = {
        ModeSelected = "Time",
        Time = {
            CreditsPerMinute = 1
        },
        Score = {
            CreditsPerScoreEarned = 0.01
        },
        HybridScore = {
            CreditsPerMinute = 1,
            CreditsPerScoreEarned = 0.01
        },
        SiegeScore = {
            CreditsPerMinute = 0.1,
            PerTresSpent = 0.1,
            PerRawDamageInflictedToPlayers = 0.1,
            PerPercentageTotalHealthInflictedToPlayers = 0.1,
            SpecialPlayers = nil,
            MultiplierForSpecialPlayers = 1.5,
            PerRawDamageInflictedToStructures = 0.1,
            PerPercentageTotalHealthInflictedToStructures = 0.1,
            SpecialStructures = {"Tunnel","PhaseGate","Hive","CommandStation"},
            MultiplierForSpecialStructures = 1.5,
            AlienPerPercentageHealed = 0.5,
            MarinesPerPercentageHealed = 1,
            AlienPerPercentageBuilt = 1,
            MarinesPerPercentageBuilt = 0.5,
            TimeMultiplierFactor = 1.1,
            VictoryBase = 10,
            VictoryMultiplier = 1.2,
            CommanderBase = 10,
            CommanderMultiplier = 1.2
        }
    },
    MinimumNumberOfPlayers = 0,
    Commands = {
        SetCredits = {Console  = "sh_setcredits", Chat = "setcredits"},
        ViewCredits = {Console  = "sh_viewcredits", Chat = "viewcredits"},
        AddCredits = {Console  = "sh_addcredits", Chat = "addcredit"},
        SubCredits = {Console  = "sh_subcredits", Chat = "subcredits"},
    }
}

PlayerCredits.PlayerTimeTracker = {}
PlayerCredits.PlayerCredits = {}

-- ============================================================================
-- PlayerCredits.Initialise:
-- Initialise the Credit System
-- ============================================================================
function PlayerCredits:Initialise(PlayerCreditsSettings, Plugin)
    if PlayerCreditsSettings
        and PlayerCreditsSettings.Enabled then
        self.Settings = PlayerCreditsSettings
        self.PlayerCredits = self:LoadPlayerCredits()

        self:CreateCreditsCommands(Plugin)
        return true
    else
        error("ShineCredits sc_playercredits.lua: An error has occurred during "
            .. "initilisation, player credits will not be enabled")
        self.Settings.Enabled = false
        return false
    end
end

-- ============================================================================
-- FileIO Subsystem:
-- Saves and loads player credits
-- ============================================================================
function PlayerCredits:SavePlayerCredits()
    return sc_json.SaveTable(self.PlayerCredits,
    self.Settings.FilePath)
end

function PlayerCredits:LoadPlayerCredits()
    return sc_json.LoadTable(self.Settings.FilePath)
end

-- ============================================================================
-- Functions
-- ============================================================================
-- ============================================================================
-- PlayerCredits.InitPlayer:
-- Initialise player to be added into the credit System
-- ============================================================================
function PlayerCredits:InitPlayer( Player )
    -- Initialise local copy of global files
    local LocalPlayerCredits = self.PlayerCredits
    local SteamID = tostring(Player:GetSteamId())

    -- Initialise Player's user credits if it does not exist
    if LocalPlayerCredits[SteamID] == nil then
        LocalPlayerCredits[SteamID] = {Total = 0, Current = 0}
    end

    local Target = Player:GetClient()
    local Existing, _ = Shine:GetUserData( Target )

    -- Initialise Player's badges if it does not exist
    if not Existing then
        Shine:ReinstateUser(Target,SteamID)
        Shine:SaveUsers( true )
        Existing, _ = Shine:GetUserData( Target )
    end
end

-- ============================================================================
-- PlayerCredits.AddCredits:
-- Adds credits to the player with the specified SteamID
-- ============================================================================
function PlayerCredits:AddCredits(SteamID, Current, Total)
    local LocalPlayerCredits = self.PlayerCredits
    local CurrentAdd = Current or 0
    local TotalAdd = Total or 0

    LocalPlayerCredits[SteamID].Current
        = LocalPlayerCredits[SteamID].Current + CurrentAdd

    LocalPlayerCredits[SteamID].Total
        = LocalPlayerCredits[SteamID].Total + TotalAdd

    return true
end

-- ============================================================================
-- PlayerCredits.SubtractCredits:
-- Subtracts credits from the player with the specified SteamID
-- ============================================================================
function PlayerCredits:SubtractCredits(SteamID, Current, Total, Overflow)
    local LocalPlayerCredits = self.PlayerCredits
    local CurrentSubtract = Current or 0
    local TotalSubtract = Total or 0
    local FlagCurrent = false
    local FlagTotal = false

    -- Check if current credits to be subtracted has overflow and if its allowed
    if LocalPlayerCredits[SteamID].Current - CurrentSubtract < 0 then
        if Overflow then
            FlagCurrent = true
        else
            FlagCurrent = false
        end
    else
        FlagCurrent = true
    end

    -- Check if total credits to be subtracted has overflow and if its allowed
    if LocalPlayerCredits[SteamID].Total - TotalSubtract < 0 then
        if Overflow then

            FlagTotal = true
        else
            FlagTotal = false
        end
    else
        FlagTotal = true
    end

    -- If both checks pass, commit to the calculations
    if FlagCurrent and FlagTotal then
        LocalPlayerCredits[SteamID].Current
            = LocalPlayerCredits[SteamID].Current - CurrentSubtract

        LocalPlayerCredits[SteamID].Total
            = LocalPlayerCredits[SteamID].Total - TotalSubtract

        self:SavePlayerCredits()
        return true
    else
        return false
    end
end

-- ============================================================================
-- PlayerCredits.StartCredits:
-- Starts accruing credits for the player
-- ============================================================================
function PlayerCredits:StartCredits(Player)
    -- Initialise local copy of global files
    local PlayerTimeTracker = self.PlayerTimeTracker
    local StartTime = Shared.GetSystemTime()
    local SteamID = tostring(Player:GetSteamId())

    -- Store the time user started playing
    PlayerTimeTracker[SteamID] = StartTime
end

-- ============================================================================
-- PlayerCredits.StopCredits:
-- Stops accruing credits for the player and rewards the credits accrued
-- ============================================================================
function PlayerCredits:StopCredits( Player )
    -- Initialise local copy of global files
    local PlayerCreditsSettings = self.Settings
    local LocalPlayerCredits = self.PlayerCredits
    local ModeCreditsSettings = PlayerCreditsSettings.AwardModes.Time
    local PlayerTimeTracker = self.PlayerTimeTracker
    local TotalPlaying = #Shine.GetTeamClients(1) + #Shine.GetTeamClients(2)
    local SteamID = ""

    -- Check if Player is Client or Player
    if type(Player) == "ClientConnectuserdata" then
        SteamID = tostring(Player:GetUserId())
        Shine:Print("Credits Stopped for Client")
    else
        SteamID = tostring(Player:GetSteamId())
    end

    -- Check if Player Time == 0 (i.e. already been stopped)
    -- and that game has minimum number of players required for credits to be awarded
    if PlayerTimeTracker[SteamID] == 0 or TotalPlaying <= PlayerCreditsSettings.MinimumNumberOfPlayers then
        sc_notification:Notify(Player,
            "No credits awarded. (Minimum players: " ..
            PlayerCreditsSettings.MinimumNumberOfPlayers ..
            " required)")
        return false
    end

    -- Calculate the amount of credits to award based on the time elapsed
    -- and the amount to award per minute elapsed
    EndTime = Shared.GetSystemTime()
    CreditsAwarded = math.Round((EndTime - PlayerTimeTracker[SteamID])/60, 0 ) * ModeCreditsSettings.CreditsPerMinute
    PlayerTimeTracker[SteamID] = 0

    -- Reward the points accordingly
    self:AddCredits(SteamID,CreditsAwarded,CreditsAwarded)

    sc_notification:Notify(Player, CreditsAwarded .. " credits awarded.")

    sc_playerleveling:UpdatePlayerLevel( Player ,
        LocalPlayerCredits[SteamID].Total)

end

-- ============================================================================
-- PlayerCredits.StartCreditsAllInTeam:
-- Starts accruing credits for the player for all players in playing teams
-- ============================================================================
function PlayerCredits:StartCreditsAllInTeam()
    local team1Players = GetGamerules():GetTeam1():GetPlayers()
    local team2Players = GetGamerules():GetTeam2():GetPlayers()

    -- For all players in Marines
    for _, team1Player in ipairs(team1Players) do
        self:StartCredits(team1Player)
    end

    -- For all players in Aliens
    for _, team2Player in ipairs(team2Players) do
        self:StartCredits(team2Player)
    end

end

-- ============================================================================
-- PlayerCredits.StopCreditsAllInTeam:
-- Stops accruing credits for the player for all players in playing teams
-- ============================================================================
function PlayerCredits:StopCreditsAllInTeam()
    local team1Players = GetGamerules():GetTeam1():GetPlayers()
    local team2Players = GetGamerules():GetTeam2():GetPlayers()

    for _, team1Player in ipairs(team1Players) do
        self:StopCredits(team1Player)
    end

    for _, team2Player in ipairs(team2Players) do
        self:StopCredits(team2Player)
    end
end


-- ============================================================================
-- Commands:
-- Manipulate players' credits
-- ============================================================================
function PlayerCredits:CreateCreditsCommands(Plugin)
    local CommandsFile = self.Settings.Commands
    local LocalPlayerCredits = self.PlayerCredits

    -- ====== Set Credits ======
    local function SetCredits( Client, Targets, Amount )
        for i = 1, #Targets do
            SteamID = tostring(Targets[ i ]:GetUserId())
            LocalPlayerCredits[SteamID] =  Amount
            self:SavePlayerCredits()
            self:UpdatePlayerRank( Targets[i]:GetControllingPlayer() )
        end
    end
	local SetCreditsCommand = Plugin:BindCommand( CommandsFile.SetCredits.Console,
        CommandsFile.SetCredits.Chat, SetCredits )
    SetCreditsCommand:AddParam{ Type = "clients", Help = "Player(s)" }
    SetCreditsCommand:AddParam{ Type = "number", Help = "Credits:Integer" }
	SetCreditsCommand:Help( "Set credits of the specified player(s)" )

    -- ====== Add Credits ======
    local function AddCredits( Client, Targets, Amount )
        for i = 1, #Targets do
            SteamID = tostring(Targets[ i ]:GetUserId())
            self:AddCredits(SteamID,Amount,Amount)
            self:SavePlayerCredits()
            sc_playerleveling:UpdatePlayerLevel( Targets[i]:GetControllingPlayer(),
                LocalPlayerCredits[SteamID].Total )
        end
    end
	local AddCreditsCommand = Plugin:BindCommand( CommandsFile.AddCredits.Console,
        CommandsFile.AddCredits.Chat, AddCredits )
    AddCreditsCommand:AddParam{ Type = "clients", Help = "Player(s)" }
    AddCreditsCommand:AddParam{ Type = "number", Help = "Credits:Integer" }
	AddCreditsCommand:Help( "Adds credits to the specified player(s)" )

    -- ====== Subtract Credits ======
    local function SubCredits( Client, Targets, Amount )
        for i = 1, #Targets do
            SteamID = tostring(Targets[ i ]:GetUserId())
            self:SubtractCredits(SteamID,Amount,Amount,"Yes")
            self:SavePlayerCredits()
            sc_playerleveling:UpdatePlayerLevel( Targets[i]:GetControllingPlayer(),
                LocalPlayerCredits[SteamID].Total )
        end
    end
	local SubCreditsCommand = Plugin:BindCommand( CommandsFile.SubCredits.Console,
        CommandsFile.SubCredits.Chat, SubCredits )
    SubCreditsCommand:AddParam{ Type = "clients", Help = "Player(s)" }
    SubCreditsCommand:AddParam{ Type = "number", Help = "Credits:Integer" }
	SubCreditsCommand:Help( "Subtracts credits from the specified player(s)" )

    -- ====== View Credits ======
    local function ViewCredits( Client )
        local LocalPlayer = Client:GetControllingPlayer()
        local LocalSteamID = tostring(LocalPlayer:GetSteamId())

        local ViewString = "Info for " .. Shine.GetClientInfo( Client ) .. "\n"
        .. "Total Credits: " .. LocalPlayerCredits[LocalSteamID].Total
        .. " | Current Credits: " .. LocalPlayerCredits[LocalSteamID].Current
        .. " | Level: " .. sc_playerleveling:GetPlayerLevel(LocalPlayer)

        sc_notification:Notify(LocalPlayer, ViewString)
        sc_notification:ConsoleMessage( LocalPlayer, ViewString )
    end

    local ViewCreditsCommand = Plugin:BindCommand( CommandsFile.ViewCredits.Console,
        CommandsFile.ViewCredits.Chat, ViewCredits )
    ViewCreditsCommand:Help( "View Credits" )
end

return PlayerCredits
