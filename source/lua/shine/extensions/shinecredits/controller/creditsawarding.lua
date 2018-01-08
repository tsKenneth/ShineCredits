-- ============================================================================
--
-- self.Credits Awarding System (Controller)
--      self.Credits are awarded for playing the game on the server. These self.Credits
--      can then be used to redeem various comestic items, such as sprays and
--      skins.
--
-- Dependencies: Requires credits.lua to be enabled
--
-- ============================================================================

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Initialisation
-- ----------------------------------------------------------------------------
-- ============================================================================

local Shine = Shine
local CreditsAwarding = {}

CreditsAwarding.Settings = {}

-- ============================================================================
-- CreditsAwarding:Initialise
-- Initialise the Awarding plguin by Shine
-- ============================================================================

function CreditsAwarding:Initialise(CreditsAwardingConfig,
    Notifications, Credits, Plugin)
    -- Load Config File
    self.Settings = CreditsAwardingConfig

    -- Checks if Config debug mode is enabled. Returns false if failed checking
    -- Debug mode can be turned off to improve performance
    if self.Settings.Enabled then
        self.Notifications = Notifications
        self.Credits = Credits
        if self.Settings.ConfigDebug and not self:CheckConfig(self.Settings) then
            self.Settings.Enabled = false
            return false
        else
            self:CreateCreditsCommands(Plugin)
            return true
        end
    else
        return false
    end
end

-- ============================================================================
-- CreditsAwarding:CheckConfig
-- Checks the config for correctness
-- ============================================================================

function CreditsAwarding:CheckConfig(CreditsAwardingConfig)
    local CheckFlag = true

    --- Check Dependencies
    if self.Credits:GetIsEnabled() == false then
        error("ShineCredits CreditsAwarding:CheckConfig() - Error in config, " ..
            "Subsystem requires Credits model to be enabled.")
        CheckFlag = false
    end

    return CheckFlag
end

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Hooks
-- ----------------------------------------------------------------------------
-- ============================================================================

-- ============================================================================
-- CreditsAwarding:PostJoinTeam
-- Starts or stops self.Credits accrueing upon joining or leaving a
-- playing team respectively
-- ============================================================================
function CreditsAwarding:PostJoinTeam( Gamerules, Player, OldTeam, NewTeam, Force, ShineForce )
    -- Check if controller is enabled
    if self.Settings.Enabled == false then
        return false
    end


    if Gamerules:GetGameStarted() and (NewTeam == 1 or NewTeam == 2) then
        -- Check if team changed to is 1:Marine Team, 2:Alien Team
        self:StartCredits(Player)
        return true
    else
        return false
    end

end

-- ============================================================================
-- CreditsAwarding:SetGameState
-- Starts or stops self.Credits accrueing when game changes state
-- ============================================================================
function CreditsAwarding:SetGameState( Gamerules, NewState, OldState )
    -- Check if controller is enabled
    if self.Settings.Enabled == false then
        return false
    end

    -- If new state is 5:"Game Started"
    if NewState == 5 then
        self:StartCreditsAllInTeam()
    elseif NewState >= 6 and NewState < 9 then
        self:StopCreditsAllInTeam(NewState)
    end
    return true
end

-- ============================================================================
-- CreditsAwarding:ClientConnect
-- Introduce player into the system
-- ============================================================================
function CreditsAwarding:ClientConnect( Client )
    -- Check if controller is enabled
    if self.Settings.Enabled == false then
        return false
    end

    self.Credits:InitPlayer( Client:GetControllingPlayer() )
end

-- ============================================================================
-- CreditsAwarding:MapChange
-- Stops credits when map is changing in the middle of the game
-- ============================================================================
function CreditsAwarding:MapChange()
    if self.Settings.Enabled == false then
        return false
    end

    if Gamerules:GetGameStarted() then
        -- Induce a draw scenario
        self:StopCreditsAllInTeam(8)
    end
end

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Core Functions
-- ----------------------------------------------------------------------------
-- ============================================================================
-- ============================================================================
-- CreditsAwarding:StartCredits
-- Starts accruing self.Credits for the player
-- ============================================================================
function CreditsAwarding:StartCredits( Player )
    return true
end

-- ============================================================================
-- CreditsAwarding:StopCredits
-- Stops accruing self.Credits for the player, calculate and award self.Credits
-- ============================================================================
function CreditsAwarding:StopCredits( Player, Victory )
    local Settings = self.Settings
    local FormulaPlayer = Settings.Player.CreditsFormula

    local PlayerCreditsAwarded = 0

    -- Return false if player is not in a group allowed for Awarding or
    --      in a group suspended from Awarding
    if not self:GetAllowedForAwarding( Player ) then
        return false
    end

    -- Calculate Player self.Credits
    PlayerCreditsAwarded =
    math.Round(FormulaPlayer.Formula.Time.CreditsPerMinute *
        math.Round(Player:GetPlayTime()/60,0),0) +
    math.Round(FormulaPlayer.Formula.Score.CreditsPerScore * Player:GetScore(),0) +
    math.Round(FormulaPlayer.Formula.Score.CreditsPerKill * Player:GetKills(),0) +
    math.Round(FormulaPlayer.Formula.Score.CreditsPerAssist * Player:GetAssistKills(),0)

    -- Apply Multipliers
    if Victory then
        PlayerCreditsAwarded = math.Round(PlayerCreditsAwarded
            * FormulaPlayer.Formula.Multipliers.Victory,0)
    end

    -- Ensure that self.Credits awarded does not go beyond maximum
    PlayerCreditsAwarded = Clamp(PlayerCreditsAwarded,0,
        FormulaPlayer.MaximumAwardedPerRound)

    -- Add the self.Credits awarded
    self.Credits:AddPlayerCredits( Player, PlayerCreditsAwarded, PlayerCreditsAwarded )

    -- Commit changes to files
    NotificationText = Settings.Player.Notifications.CreditsAwarded

    self.Notifications:Notify(Player,
        string.format(NotificationText,PlayerCreditsAwarded))

    self.Credits:SaveCredits()
    return true

end

-- ============================================================================
-- CreditsAwarding:StartCreditsAllInTeam
-- Starts accruing self.Credits for the player for all players in playing teams
-- ============================================================================
function CreditsAwarding:StartCreditsAllInTeam()
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
-- CreditsAwarding:StopCreditsAllInTeam
-- Stops accruing self.Credits for the player for all players in playing teams
-- ============================================================================
function CreditsAwarding:StopCreditsAllInTeam(GameState)
    local team1Players = GetGamerules():GetTeam1():GetPlayers()
    local team2Players = GetGamerules():GetTeam2():GetPlayers()
    local MarineVictoryFlag = false
    local AlienVictoryFlag = false

    if GameState == 6 then
        MarineVictoryFlag = true
    elseif GameState == 7 then
        AlienVictoryFlag = true
    end

    for _, team1Player in ipairs(team1Players) do
        self:StopCredits(team1Player, MarineVictoryFlag)
    end

    for _, team2Player in ipairs(team2Players) do
        self:StopCredits(team2Player, AlienVictoryFlag)
    end
end

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Helper Functions
-- ----------------------------------------------------------------------------
-- ============================================================================

-- ============================================================================
-- CreditsAwarding:GetAllowedForAwarding
-- Checks if the player belongs to a user group that has Awarding suspended
-- ============================================================================
function CreditsAwarding:GetAllowedForAwarding( Player )
    -- Initialise local variables with global values
    local Settings = self.Settings

    -- Obtain required data on player to check player's group
    local Target = Player:GetClient()
    local Existing, _ = Shine:GetUserData( Target )

    -- Return false if player is in a group suspended from Awarding
    if Settings.Permissions.SuspendAwardingForGroup then
        for _, group in ipairs(Settings.Permissions.SuspendAwardingForGroup) do
            if group == Existing.Group then
                return false
            end
        end
        return true
    else
        return true
    end
end

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Commands
-- ----------------------------------------------------------------------------
-- ============================================================================
function CreditsAwarding:CreateCreditsCommands(Plugin)
    local CommandsFile = self.Settings.Commands
    local Credits = self.Credits

    -- ====== Set Credits ======
    local function SetCredits( Client, Targets, Amount )
        local LocalPlayer = Client:GetControllingPlayer()
        for i = 1, #Targets do
            SteamID = tostring(Targets[ i ]:GetUserId())
            Credits:SetPlayerCredits( Client:GetControllingPlayer(),
                Amount, Amount )
        end
        Credits:SaveCredits()
        self.Notifications:Notify(LocalPlayer, "Credits Set")
        self.Notifications:ConsoleMessage( LocalPlayer, "Credits Set" )
    end
	local SetCreditsCommand = Plugin:BindCommand( CommandsFile.SetCredits.Console,
        CommandsFile.SetCredits.Chat, SetCredits )
    SetCreditsCommand:AddParam{ Type = "clients", Help = "Player(s)" }
    SetCreditsCommand:AddParam{ Type = "number", Help = "Credits:Integer" }
	SetCreditsCommand:Help( "Set credits of the specified player(s)" )

    -- ====== Add Credits ======
    local function AddCredits( Client, Targets, Amount )
        local LocalPlayer = Client:GetControllingPlayer()
        for i = 1, #Targets do
            SteamID = tostring(Targets[ i ]:GetUserId())
            Credits:AddPlayerCredits( Client:GetControllingPlayer(),
                Amount, Amount )
        end
        Credits:SaveCredits()
        self.Notifications:Notify(LocalPlayer, "Credits Added")
        self.Notifications:ConsoleMessage( LocalPlayer, "Added" )
    end
	local AddCreditsCommand = Plugin:BindCommand( CommandsFile.AddCredits.Console,
        CommandsFile.AddCredits.Chat, AddCredits )
    AddCreditsCommand:AddParam{ Type = "clients", Help = "Player(s)" }
    AddCreditsCommand:AddParam{ Type = "number", Help = "Credits:Integer" }
	AddCreditsCommand:Help( "Adds credits to the specified player(s), " ..
        "input a negative integer to subtract")

    -- ====== View Credits ======
    local function ViewCredits( Client )
        local LocalPlayer = Client:GetControllingPlayer()
        local LocalCredits = Credits:GetPlayerCredits( LocalPlayer )

        local ViewString = "Credits Info for " ..
        Shine.GetClientInfo( Client ) .. "\n"
        .. "Total Credits: " .. LocalCredits.Total
        .. " | Current Credits: " .. LocalCredits.Current

        self.Notifications:Notify(LocalPlayer, ViewString)
        self.Notifications:ConsoleMessage( LocalPlayer, ViewString )
    end

    local ViewCreditsCommand = Plugin:BindCommand( CommandsFile.ViewCredits.Console,
        CommandsFile.ViewCredits.Chat, ViewCredits )
    ViewCreditsCommand:Help( "Show your credits information" )
end

return CreditsAwarding
