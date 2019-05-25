-- ============================================================================
--
-- Player and Commander Levelling System (Controller)
--      Throughout the game, players and accumulate Experience points (XP)
--      when they perform various actions as spcified in the formula config
--      These XP then contributes to the requirements of reaching the next
--      level. Each level has a set required amount of points as specified
--      by the formula in the config and also a corresponding badge to
--      represent the level attained.
--
-- Requires Levels.lua and Badges.lua to be enabled
--
-- ============================================================================

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Initialisation
-- ----------------------------------------------------------------------------
-- ============================================================================

local Shine = Shine
local Levelling = {}

Levelling.Settings = {}

-- ============================================================================
-- Levelling:Initialise
-- Initialise the Leveling plguin by Shine
-- ============================================================================

function Levelling:Initialise(LevellingConfig, Notifications, Badges,
    Levels, Plugin)
    -- Load Config File
    self.Settings = LevellingConfig
    -- Checks if Config debug mode is enabled. Returns false if failed checking
    -- Debug mode can be turned off to improve performance
    if self.Settings.Enabled then
        self.Notifications = Notifications
        self.Badges = Badges
        self.Levels = Levels

        if self.Settings.ConfigDebug and not self:CheckConfig(self.Settings) then
            self.Settings.Enabled = false
            return false
        else
            self:CreateLevellingCommands(Plugin)
            return true
        end
    else
        return false
    end
end

-- ============================================================================
-- Levelling:CheckConfig
-- Checks the config for correctness
-- ============================================================================

function Levelling:CheckConfig(LevellingConfig)
    local CheckFlag = true
    local count = 0

    -- Check Dependencies
    if self.Badges:GetIsEnabled() == false then
        Shine:Print("ShineCredits Levelling:CheckConfig() - Error in config, " ..
            "Subsystem requires Badges model to be enabled.")
        CheckFlag = false
    end

    if self.Levels:GetIsEnabled() == false then
        Shine:Print("ShineCredits Levelling:CheckConfig() - Error in config, " ..
            "Subsystem requires Levels model to be enabled.")
        CheckFlag = false
    end

    -- Checks if Player leveling configs are correct
    if LevellingConfig.Player.Enabled then
        if string.find(LevellingConfig.Player.NextLevelFormula.Formula, "x")
            == nil then
            Shine:Print("ShineCredits Levelling:CheckConfig() - Error in config, " ..
                "Player.NextLevelFormula.Formula must contain " ..
                "a letter x to signify level as a variable")
            CheckFlag = false

    -- Checks if Player badges configs are correct
        elseif LevellingConfig.Player.Badges.Enabled then
            count = 0
            for _ in pairs(LevellingConfig.Player.Badges.CustomBadgesOrder)
                do count = count + 1
            end

            if count ~= 0 and count < LevellingConfig.Player.NextLevelFormula.MaximumLevel then
                Shine:Print("ShineCredits Levelling:CheckConfig() - Error in config, " ..
                "Player.Badges.CustomBadgesOrder must have more " ..
                "elements (badges) than the number of self.Levels")
                CheckFlag = false
            elseif LevellingConfig.Player.Badges.BadgeRow < 1 then
                Shine:Print("ShineCredits Levelling:CheckConfig() - Error in config, " ..
                "Commander.Badges.BadgesOrder.LocalBadgeRow must be " ..
                "greater than 0")
                CheckFlag = false
            end
        end
    end

    -- Checks if Commander leveling configs are correct
    if LevellingConfig.Commander.Enabled then
        if string.find(LevellingConfig.Commander.NextLevelFormula.Formula, "x")
            == nil then
            Shine:Print("ShineCredits Levelling:CheckConfig() - Error in config, " ..
                "Commander.NextLevelFormula.Formula must contain " ..
                "a letter x to signify level as a variable")
            CheckFlag = false

    -- Checks if Commander badges configs are correct
        elseif LevellingConfig.Commander.Badges.Enabled then
            count = 0
            for _ in pairs(LevellingConfig.Commander.Badges.CustomBadgesOrder)
                do count = count + 1
            end

            if count ~= 0 and count < LevellingConfig.Commander.NextLevelFormula.MaximumLevel then
                Shine:Print("ShineCredits Levelling:CheckConfig() - Error in config, " ..
                "Commander.Badges.CustomBadgesOrder must have more " ..
                "elements (badges) than the number of self.Levels. ")
                CheckFlag = false
            elseif LevellingConfig.Commander.Badges.BadgeRow < 1 then
                Shine:Print("ShineCredits Levelling:CheckConfig() - Error in config, " ..
                "Commander.Badges.BadgesOrder.LocalBadgeRow must be " ..
                "greater than 0")
                CheckFlag = false
            end
        end
    end
    return CheckFlag
end

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Hooks
-- ----------------------------------------------------------------------------
-- ============================================================================

-- ============================================================================
-- Levelling:PostJoinTeam
-- Starts or stops XP accrueing upon joining or leaving a
-- playing team respectively
-- ============================================================================
function Levelling:PostJoinTeam( Gamerules, Player, OldTeam, NewTeam, Force,
    ShineForce )

    if self.Settings.Enabled == false then
        return false
    end

    -- Check if team changed to is 1:Marine Team, 2:Alien Team
    if Gamerules:GetGameStarted() and (NewTeam == 1 or NewTeam == 2) then
        self:StartXP(Player)
        return true
    else
        return false
    end

end

-- ============================================================================
-- Levelling:SetGameState
-- Starts or stops XP accrueing when game changes state
-- ============================================================================
function Levelling:SetGameState( Gamerules, NewState, OldState )
    if self.Settings.Enabled == false then
        return false
    end

    -- If new state is 5:"Game Started"
    if NewState == 5 then
        self:StartAllXP()
    elseif NewState >= 6 and NewState < 9 then
        self:StopAllXP(NewState)
    end
    return true
end

-- ============================================================================
-- Levelling:ClientConnect
-- Introduce player into the system
-- ============================================================================
function Levelling:ClientConnect( Client )
    if self.Settings.Enabled then
        self.Levels:InitPlayer( Client:GetControllingPlayer() )
        return true
    else
        return false
    end
end

-- ============================================================================
-- Levelling:MapChange
-- Stops XP when map is changing in the middle of the game
-- ============================================================================
function Levelling:MapChange()
    self.Levels:SaveLevels()
end

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Core Functions
-- ----------------------------------------------------------------------------
-- ============================================================================
-- ============================================================================
-- Levelling:StartXP
-- Starts accruing XP for the player
-- ============================================================================
function Levelling:StartXP( Player )
    return true
end

-- ============================================================================
-- Levelling:StopXP
-- Stops accruing XP for the player, calculate and award XP
-- ============================================================================
function Levelling:StopXP( Player, GameState )
    local Settings = self.Settings
    local FormulaPlayer = Settings.Player.XPFormula
    local FormulaCommander = Settings.Commander.XPFormula

    local PlayerXPAwarded = 0
    local CommanderXPAwarded = 0

    -- Validation checks
    -- Return false if player is not in a group allowed for leveling or
    --      in a group suspended from leveling
    if not self:GetAllowedForLeveling( Player ) then
        return false
    end

    if Settings.Player.Enabled then
        -- Calculate Player XP
        local PlayerPlaytime = math.Round(Player:GetPlayTime()/60,0) or 0
        local PlayerScore = Player:GetScore() or 0
        local PlayerKills = Player:GetKills() or 0
        local PlayerAssist = Player:GetAssistKills() or 0

        PlayerXPAwarded =
        math.Round(FormulaPlayer.Formula.Time.XPPerMinute *
            PlayerPlaytime,0) +
        math.Round(FormulaPlayer.Formula.Score.XPPerScore * PlayerScore,0) +
        math.Round(FormulaPlayer.Formula.Score.XPPerKill * PlayerKills,0) +
        math.Round(FormulaPlayer.Formula.Score.XPPerAssist * PlayerAssist,0)

        if GameState == 6 and Player:GetTeamNumber() == 1 then
            PlayerXPAwarded = math.Round(PlayerXPAwarded
                * FormulaPlayer.Formula.Multipliers.Victory,0)
        elseif GameState == 7 and Player:GetTeamNumber() == 2 then
            PlayerXPAwarded = math.Round(PlayerXPAwarded
                * FormulaPlayer.Formula.Multipliers.Victory,0)
        end

        PlayerXPAwarded = Clamp(PlayerXPAwarded,0,
            FormulaPlayer.MaximumAwardedPerRound)

        self.Levels:AddPlayerXP( Player, PlayerXPAwarded )
        self:UpdateLevel( Player, self.Levels:GetPlayerXP( Player ), false)
    end

    if Settings.Commander.Enabled then
        -- Calculate Commander XP
        local CommanderPlaytime = math.Round(Player:GetCommanderTime()/60,0) or 0

        CommanderXPAwarded =
        math.Round(FormulaCommander.Formula.Time.XPPerMinute *
            CommanderPlaytime,0)

        if GameState == 6 and Player:GetTeamNumber() == 1 then
            CommanderXPAwarded = math.Round(CommanderXPAwarded
                * FormulaCommander.Formula.Multipliers.Victory,0)
        elseif GameState == 7 and Player:GetTeamNumber() == 2 then
            CommanderXPAwarded = math.Round(CommanderXPAwarded
                * FormulaCommander.Formula.Multipliers.Victory,0)
        end

        CommanderXPAwarded = Clamp(CommanderXPAwarded,0,
            FormulaPlayer.MaximumAwardedPerRound)
        self.Levels:AddCommanderXP( Player, CommanderXPAwarded)
        self:UpdateLevel( Player, self.Levels:GetCommanderXP( Player ), true)
    end
    return true

end

-- ============================================================================
-- Levelling:StartAllXP
-- Starts accruing XP for the player for all players in playing teams
-- ============================================================================
function Levelling:StartAllXP()
    local AllPlayers = Shine.GetAllPlayers()

    for _, player in ipairs(AllPlayers) do
        self:StartXP(player)
    end

    return true
end

-- ============================================================================
-- Levelling:StopAllXP
-- Stops accruing XP for the player for all players in playing teams
-- ============================================================================
function Levelling:StopAllXP(GameState)
    local AllPlayers = Shine.GetAllPlayers()

    if #AllPlayers < self.Settings.MinPlayers then
        return false
    end

    for _, player in ipairs(AllPlayers) do
        self:StopXP(player, GameState)
    end

    self.Levels:SaveLevels()

    return true
end

-- ============================================================================
-- Levelling:UpdatePlayerLevel
-- Updates the player's level
-- ============================================================================

function Levelling:UpdateLevel( Player, CurrentXP, Commander)
    -- Initialise local variables with global values
    local Settings = self.Settings

    -- Get the current level of the Player
    local PreviousLevel = 0
    local NotificationText = ""

    if Commander then
        Settings = Settings.Commander
        PreviousLevel = self.Levels:GetCommanderLevel( Player )
    else
        Settings = Settings.Player
        PreviousLevel = self.Levels:GetPlayerLevel( Player )
    end

    -- Determine the player's new level
    local NewLevel = self:GetCorrectLevel(
        Settings.NextLevelFormula.Formula,
        CurrentXP,
        PreviousLevel,
        Settings.NextLevelFormula.MaximumLevel)

    -- If player's Level has changed, perform badge change
    if PreviousLevel ~= NewLevel and
        ((Commander and self.Settings.Commander.Badges.Enabled) or
        self.Settings.Player.Badges.Enabled)  then

        local CustomOrder = Settings.Badges.CustomBadgesOrder
        if CustomOrder and #CustomOrder > 0 then
            if CustomOrder[NewLevel] then
                self.Badges:SwitchBadge(Player ,
                CustomOrder[PreviousLevel],
                CustomOrder[NewLevel], Settings.Badges.BadgeRow)
                self.Badges:SavePlayerBadges()
            else
                Shine:Print("ShineXP sc_playerleveling.lua: Custom Level " ..
                    "Badges has no badges specified for level " .. NewLevel ..
                    ", check your config file!")
                return false
            end
        else
            local NewBadge = Settings.Badges.BadgesOrder.LevelBadgeNamePrefix ..
                NewLevel ..
                Settings.Badges.BadgesOrder.LevelBadgeNameSuffix

            local OldBadge = Settings.Badges.BadgesOrder.LevelBadgeNamePrefix ..
                PreviousLevel ..
                Settings.Badges.BadgesOrder.LevelBadgeNameSuffix

            self.Badges:SwitchBadge(Player,OldBadge,
                NewBadge,Settings.Badges.BadgeRow)
            self.Badges:SavePlayerBadges()
        end

        -- Commit changes to files
        if Commander then
            self.Levels:SetCommanderLevel( Player, NewLevel)
            NotificationText = Settings.Notifications.LevelChange
        else
            self.Levels:SetPlayerLevel( Player, NewLevel)
            NotificationText = Settings.Notifications.LevelChange
        end

        self.Notifications:Notify(Player,
            string.format(NotificationText,NewLevel))

        return NewLevel
    else
        return nil
    end
end


-- ============================================================================
-- ----------------------------------------------------------------------------
-- Helper Functions
-- ----------------------------------------------------------------------------
-- ============================================================================

-- ============================================================================
-- Levelling:GetAllowedForLeveling
-- Checks if the player belongs to a user group that has leveling suspended
-- ============================================================================
function Levelling:GetAllowedForLeveling( Player )
    -- Initialise local variables with global values
    local Settings = self.Settings

    -- Obtain required data on player to check player's group
    local Target = Player:GetClient()
    local Existing, _ = Shine:GetUserData( Target )

    -- Return false if player is in a group suspended from leveling
    if Settings.Permissions.SuspendLevelingForGroup then
        for _, group in ipairs(Settings.Permissions.SuspendLevelingForGroup) do
            if group == Existing.Group then
                return false
            end
        end
    end

    return true
end

-- ============================================================================
-- Levelling:GetCorrectLevel:
-- Calculate the player's actual level, based on the formula specified
-- ============================================================================
function Levelling:GetCorrectLevel( CustomFormula, CurrentXP
    , CurrentLevel, MaxLevel )
    local FormulaFunction = nil

    CustomFormula = "return " .. CustomFormula
    FormulaFunction = loadstring(CustomFormula)

    -- Substitute x for the current level of the player/commander
    local LoopFormula = CustomFormula:gsub("x", CurrentLevel)
    FormulaFunction = loadstring(LoopFormula)

    -- Check if the formula is a valid mathematical construct
    if not FormulaFunction() then
        Shine:Print("ShineCredits self.Levels:GetCorrectLevel - Formula provided is " ..
        "not valid.")
    end

    -- Checks which way to update the player's level
    if CurrentXP < FormulaFunction() then
        -- When player's total XP is less than Level's required XP:
        --      Decrease player's Level by 1 until player's XP is
        --      equivalent to the required amount
        while (CurrentXP < FormulaFunction())
        and CurrentLevel ~= 0 do
            CurrentLevel = CurrentLevel - 1
            LoopFormula = CustomFormula:gsub("x", CurrentLevel)
            FormulaFunction = loadstring(LoopFormula)
        end
    else
        -- When player's total XP is more than Level's required XP:
        --      Increase player's Level by 1 until player's XP is
        --      equivalent to the required amount

        while (CurrentXP >= FormulaFunction() )
        and CurrentLevel ~= MaxLevel do
            CurrentLevel = CurrentLevel + 1
            LoopFormula = CustomFormula:gsub("x", CurrentLevel )
            FormulaFunction = loadstring(LoopFormula)
        end

        CurrentLevel = CurrentLevel - 1
    end
    return CurrentLevel
end

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Commands
-- ----------------------------------------------------------------------------
-- ============================================================================
function Levelling:CreateLevellingCommands(Plugin)
    local Settings = self.Settings
    local CommandsFile = self.Settings.Commands
    local Levels = self.Levels

    -- ====== Set XP ======
    local function SetXP( Client, Targets, AmountPlayer, AmountCommander)
        local LocalPlayer = Client:GetControllingPlayer()
        for i = 1, #Targets do
            SteamID = tostring(Targets[ i ]:GetUserId())
            Levels:SetPlayerXP( Client:GetControllingPlayer(),
                AmountPlayer )
            Levels:SetCommanderXP( Client:GetControllingPlayer(),
                AmountCommander )
        end
        Levels:SaveLevels()

        self.Notifications:Notify(LocalPlayer, "XP Set","[Shine Credits]")
    end
	local SetXPCommand = Plugin:BindCommand( CommandsFile.SetXP.Console,
        CommandsFile.SetXP.Chat, SetXP )
    SetXPCommand:AddParam{ Type = "clients", Help = "Player(s)" }
    SetXPCommand:AddParam{ Type = "number", Help = "PlayerXP:Integer" }
    SetXPCommand:AddParam{ Type = "number", Help = "CommanderXP:Integer" }
	SetXPCommand:Help( "Set Levels of the specified player(s)" )

    -- ====== Add XP ======
    local function AddXP( Client, Target, AmountPlayer, AmountCommander )
        local LocalPlayer = Client:GetControllingPlayer()
        Levels:AddPlayerXP( Target:GetControllingPlayer(),
            AmountPlayer )
        Levels:AddCommanderXP( Target:GetControllingPlayer(),
            AmountCommander )
        Levels:SaveLevels()

        self.Notifications:Notify(LocalPlayer, "XP Added","[Shine Credits]")
    end
	local AddXPCommand = Plugin:BindCommand( CommandsFile.AddXP.Console,
        CommandsFile.AddXP.Chat, AddXP )
    AddXPCommand:AddParam{ Type = "client", Help = "Player" }
    AddXPCommand:AddParam{ Type = "number", Help = "PlayerXP:Integer" }
    AddXPCommand:AddParam{ Type = "number", Help = "CommanderXP:Integer" }
	AddXPCommand:Help( "Adds Levels to the specified player(s), " ..
        "input a negative integer to subtract")

    -- ====== View Levels ======
    local function ViewXP( Client )
        local LocalPlayer = Client:GetControllingPlayer()
        local Summary = Levels:GetSummary( LocalPlayer )
        local PlayerNextLevelFormula =
            "return " .. Settings.Player.NextLevelFormula.Formula:gsub(
            "x", Summary.PlayerLevel + 1)
        local CommanderNextLevelFormula =
            "return " .. Settings.Commander.NextLevelFormula.Formula:gsub(
            "x", Summary.CommanderLevel + 1)

        local PlayerNextLevelFunction =
            loadstring(PlayerNextLevelFormula )
        local CommanderNextLevelFunction =
            loadstring(CommanderNextLevelFormula)

        self.Notifications:Notify(LocalPlayer, "Levels Info for " ..
            Shine.GetClientInfo( Client ), "[Shine Credits]")

        self.Notifications:Notify(LocalPlayer,"Level: " ..
        "Player > " ..
        Summary.PlayerLevel ..
        " (" .. Summary.PlayerXP .. ")" ..
        ", Commander > " ..
        Summary.CommanderLevel ..
        " (" .. Summary.CommanderXP .. ")",
        false)

        self.Notifications:Notify(LocalPlayer,"XP to next level: " ..
        "Player > " .. PlayerNextLevelFunction() - Summary.PlayerXP ..
        ", Commander > " .. CommanderNextLevelFunction() - Summary.CommanderXP,
        false)
    end

    local ViewXPCommand = Plugin:BindCommand( CommandsFile.ViewXP.Console,
        CommandsFile.ViewXP.Chat, ViewXP,true, true )
    ViewXPCommand:Help( "Show your Levels information" )
end
return Levelling
