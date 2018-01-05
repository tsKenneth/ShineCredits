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
-- The controller handles all the Shine Hooks and passes data into the levels
-- model for processing
--
-- ============================================================================

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Initialisation
-- ----------------------------------------------------------------------------
-- ============================================================================

local Shine = Shine
local Levelling = {}

local Levels = require("shine/extensions/shinecredits/model/levels")

Levelling.Settings = {
    Enabled = true,
    ConfigDebug = true,
    FileName = "ShineCredits_PlayerLevels.json",
    AwardedWhen = {
        Disconnected = true,
        MapChange = true,
        LeaveTeam = true,
        GameEnds = true
    },
    Player = {
        Enabled = true,
        XPFormula = {
            MaximumAwardedPerRound = 500,
            Formula = {
                Credits = false,
                Time = {
                    XPPerMinute = 1
                },
                Score = {
                    XPPerScore = 0.1,
                    XPPerKill = 1,
                    XPPerAssist = 0.5
                },
                Multipliers = {
                    Victory = 1.2
                }
            }
        },
        NextLevelFormula = {
            MaximumLevel = 55,
            Formula = "x^1"
        },
        Badges = {
            Enabled = true,
            BadgesOrder = {
                LevelBadgeNamePrefix = "level",
                LevelBadgeNameSuffix = "",
                BadgeRow = 1,
            },
            CustomBadgesOrder = {}
        }
    },
    Commander = {
        Enabled = true,
        XPFormula = {
            MaximumAwardedPerRound = 5,
            Formula = {
                Credits = false,
                Time = {
                    XPPerMinute = 1
                },
                Multipliers = {
                    Victory = 1.2
                }
            }
        },
        NextLevelFormula = {
            MaximumLevel = 5,
            Formula = "x^1"
        },
        Badges = {
            Enabled = true,
            BadgesOrder = {
                LevelBadgeNamePrefix = "",
                LevelBadgeNameSuffix = "",
                BadgeRow = 2,
            },
            CustomBadgesOrder = {"bay_supporter","bay_silver",
                "bay_red","bay_platinum","bay_gold"}
        }
    },
    Permissions = {
        SuspendLevelingForGroups = {}
    },
    Notifications = {
        PlayerLevelChange = "Player level increased to level %s!" ..
            " (badge will be refreshed when map changes)",
        CommanderLevelChange = "Commander level increased to level %s!" ..
            " (badge will be refreshed when map changes)",
    }
}

-- ============================================================================
-- Levelling:Initialise
-- Initialise the Leveling plguin by Shine
-- ============================================================================

function Levelling:Initialise(StorageConfig, LevellingConfig,
    Notifications,
    Badges)
    -- Load Config File
    self.Settings = LevellingConfig
    self.Settings.FileName = StorageConfig.Files.Directory .. self.Settings.FileName
    self.Notifications = Notifications
    self.Badges = Badges

    -- Checks if Config debug mode is enabled. Returns false if failed checking
    -- Debug mode can be turned off to improve performance
    if self.Settings.Enabled then
        if self.Settings.ConfigDebug and not self:CheckConfig(self.Settings) then
            return false
        else
            Levels:Initialise(self.Settings)
            return true
        end
    end
    return false
end

-- ============================================================================
-- Levelling:CheckConfig
-- Checks the config for correctness
-- ============================================================================

function Levelling:CheckConfig(LevellingConfig)
    local CheckFlag = true

    -- Check if Levelling.Filename is a string and a json file
    if type(LevellingConfig.FileName) ~= "string" and
        string.sub(LevellingConfig.FileName,-4) ~= ".json" then
        error("ShineCredits Levelling:CheckConfig() - Error in config, " ..
            "FileName specified is not a string or is not a " ..
            "json file.")
        CheckFlag = false
    end

    -- Checks if Player leveling configs are correct
    if LevellingConfig.Player.Enabled then
        if string.find(LevellingConfig.Player.NextLevelFormula.Formula, "x")
            == nil then
            error("ShineCredits Levelling:CheckConfig() - Error in config, " ..
                "Player.NextLevelFormula.Formula must contain " ..
                "a letter x to signify level as a variable")
            CheckFlag = false
        end

    -- Checks if Player badges configs are correct
    elseif LevellingConfig.Player.Badges.Enabled then
        if #LevellingConfig.Player.Badges.CustomBadgesOrder <
        LevellingConfig.Player.NextLevelFormula.MaximumLevel then
            error("ShineCredits Levelling:CheckConfig() - Error in config, " ..
            "Player.Badges.CustomBadgesOrder must have more" ..
            "elements (badges) than the number of levels")
            CheckFlag = false
        elseif LevellingConfig.Player.Badges.BadgesOrder.BadgeRow
        < 1 then
            error("ShineCredits Levelling:CheckConfig() - Error in config, " ..
            "Commander.Badges.BadgesOrder.LocalBadgeRow must be " ..
            "greater than 0")
            CheckFlag = false
        end
    end

    -- Checks if Commander leveling configs are correct
    if LevellingConfig.Commander.Enabled then
        if string.find(LevellingConfig.Commander.NextLevelFormula.Formula, "x")
            == nil then
            error("ShineCredits Levelling:CheckConfig() - Error in config, " ..
                "Commander.NextLevelFormula.Formula must contain " ..
                "a letter x to signify level as a variable")
            CheckFlag = false
        end

    -- Checks if Commander badges configs are correct
    elseif LevellingConfig.Commander.Badges.Enabled then
        if #LevellingConfig.Commander.Badges.CustomBadgesOrder <
        LevellingConfig.Commander.NextLevelFormula.MaximumLevel then
            error("ShineCredits Levelling:CheckConfig() - Error in config, " ..
            "Commander.Badges.CustomBadgesOrder must have more" ..
            "elements (badges) than the number of levels")
            CheckFlag = false
        elseif LevellingConfig.Commander.Badges.BadgesOrder.BadgeRow
        < 1 then
            error("ShineCredits Levelling:CheckConfig() - Error in config, " ..
            "Commander.Badges.BadgesOrder.LocalBadgeRow must be " ..
            "greater than 0")
            CheckFlag = false
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
function Levelling:PostJoinTeam( Gamerules, Player, OldTeam, NewTeam, Force, ShineForce )
    local AwardSettings = self.Settings.AwardedWhen
    if Gamerules:GetGameStarted() then
        -- Check if team changed to is 0: Ready room , 3:Spectators
        if (NewTeam == 0 or NewTeam == 3) and AwardSettings.LeaveTeam then
            self:StopXP(Player)
        else
            self:StartXP(Player)
        end
        return true
    end
    return false
end

-- ============================================================================
-- Levelling:SetGameState
-- Starts or stops XP accrueing when game changes state
-- ============================================================================
function Levelling:SetGameState( Gamerules, NewState, OldState )
    -- If new state is 5:"Game Started"
    if NewState == 5 then
        self:StartXPAllInTeam()
    else
        self:StopXPAllInTeam(NewState)
    end
    return true
end

-- ============================================================================
-- Levelling:ClientConnect
-- Introduce player into the system
-- ============================================================================
function Levelling:ClientConnect( Client )
    if self.Settings.Enabled then
        Levels:InitPlayer( Client:GetControllingPlayer() )
        return true
    else
        return false
    end
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
function Levelling:StopXP( Player, Victory )
    local Settings = self.Settings
    local FormulaPlayer = Settings.Player.XPFormula
    local FormulaCommander = Settings.Commander.XPFormula

    local PlayerXPAwarded = 0
    local CommanderXPAwarded = 0

    -- Return false if player is not in a group allowed for leveling or
    --      in a group suspended from leveling
    if not self:GetAllowedForLeveling( Player ) then
        return false
    end


    -- Calculate Player XP
    PlayerXPAwarded =
    FormulaPlayer.Formula.Time.XPPerMinute * math.Round(Player:GetPlayTime()/60) +
    FormulaPlayer.Formula.Score.XPPerScore * math.Round(Player:GetScore()/60) +
    FormulaPlayer.Formula.Score.XPPerKill * math.Round(Player:GetKills()/60) +
    FormulaPlayer.Formula.Score.XPPerAssist * math.Round(Player:GetAssistKills()/60)

    -- Calculate Commander XP
    CommanderXPAwarded =
    FormulaCommander.Formula.Time.XPPerMinute * math.Round(Player:GetCommanderTime()/60)

    -- Apply Multipliers
    if Victory then
        PlayerXPAwarded = PlayerXPAwarded
            * FormulaPlayer.Formula.Multipliers.Victory
        CommanderXPAwarded = CommanderXPAwarded
            * FormulaCommander.Formula.Multipliers.Victory
    end

    -- Ensure that XP awarded does not go beyond maximum
    PlayerXPAwarded = Clamp(PlayerXPAwarded,0,
        FormulaPlayer.MaximumAwardedPerRound)
    CommanderXPAwarded = Clamp(CommanderXPAwarded,0,
        FormulaPlayer.MaximumAwardedPerRound)

    -- Add the XP awarded
    Shine:Print(PlayerXPAwarded)
    Levels:AddPlayerXP( Player, PlayerXPAwarded )
    Levels:AddCommanderXP( Player, CommanderXPAwarded)

    self:UpdateLevel( Player, Levels:GetPlayerXP( Player ), false)
    self:UpdateLevel( Player, Levels:GetCommanderXP( Player ), true)

    Levels:SaveLevels()

    return true

end

-- ============================================================================
-- Levelling:StartXPAllInTeam
-- Starts accruing XP for the player for all players in playing teams
-- ============================================================================
function Levelling:StartXPAllInTeam()
    local team1Players = GetGamerules():GetTeam1():GetPlayers()
    local team2Players = GetGamerules():GetTeam2():GetPlayers()

    -- For all players in Marines
    for _, team1Player in ipairs(team1Players) do
        self:StartXP(team1Player)
    end

    -- For all players in Aliens
    for _, team2Player in ipairs(team2Players) do
        self:StartXP(team2Player)
    end

end

-- ============================================================================
-- Levelling:StopXPAllInTeam
-- Stops accruing XP for the player for all players in playing teams
-- ============================================================================
function Levelling:StopXPAllInTeam(GameState)
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
        self:StopXP(team1Player, MarineVictoryFlag)
    end

    for _, team2Player in ipairs(team2Players) do
        self:StopXP(team2Player, AlienVictoryFlag)
    end
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
    local CustomFormula = ""
    local NotificationText = ""
    local MaxLevel = 0
    if Commander then
        PreviousLevel = Levels:GetPlayerLevel( Player )
        CustomFormula = Settings.Commander.NextLevelFormula.Formula
        MaxLevel = Settings.Commander.NextLevelFormula.MaximumLevel
    else
        PreviousLevel = Levels:GetPlayerLevel( Player )
        CustomFormula = Settings.Player.NextLevelFormula.Formula
        MaxLevel = Settings.Player.NextLevelFormula.MaximumLevel
    end

    -- If player is already at max level
    if PreviousLevel == Settings.Player.NextLevelFormula.MaximumLevel then
        return nil
    end

    -- Determine the player's new level
    local NewLevel = self:GetCorrectLevel(
        CustomFormula, CurrentXP, PreviousLevel, MaxLevel)

    -- If player's Level has changed, perform badge change
    if PreviousLevel ~= NewLevel then
        local CustomOrder = Settings.Levels.CustomLevelBadgesOrder
        if CustomOrder and #CustomOrder > 0 then
            if CustomOrder[NewLevel] then
                self.Badges:SwitchBadge(Player ,
                CustomOrder[PreviousLevel],
                CustomOrder[NewLevel])
            else
                error("ShineXP sc_playerleveling.lua: Custom Level " ..
                    "Badges has no badges specified for level " .. NewLevel ..
                    ", check your config file!")
                return false
            end
        else
            local NewBadge = Settings.Levels.LevelBadgeNamePrefix ..
                NewLevel ..
                Settings.Levels.LevelBadgeNameSuffix

            local OldBadge = Settings.Levels.LevelBadgeNamePrefix ..
                PreviousLevel ..
                Settings.Levels.LevelBadgeNameSuffix

            self.Badges:SwitchBadge(Player,OldBadge,NewBadge)
        end

        -- Commit changes to files
        if Commander then
            Levels:SetCommanderLevel( Player, NewLevel)
            NotificationText = Settings.Notifications.CommanderLevelChange
        else
            Levels:SetPlayerLevel( Player, NewLevel)
            NotificationText = Settings.Notifications.PlayerLevelChange
        end

        self.Notifications:Notify(Player,
            string.format(NotificationText,NewLevel))

        Shine:SaveUsers( true )

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
        return true
    else
        return true
    end
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
        error("ShineCredits Levels:GetCorrectLevel - Formula provided is " ..
        "not valid.")
    end

    -- Checks which way to update the player's level
    if CurrentXP < FormulaFunction() then
        -- When player's total XP is less than Level's required XP:
        --      Decrease player's Level by 1 until player's XP is
        --      equivalent to the required amount
        while (CurrentXP < FormulaFunction())
        and CurrentLevel ~= MaxLevel do
            CurrentLevel = CurrentLevel - 1
            LoopFormula = CustomFormula:gsub("x", CurrentLevel)
            FormulaFunction = loadstring(LoopFormula)
        end
    else
        -- When player's total XP is more than Level's required XP:
        --      Increase player's Level by 1 until player's XP is
        --      equivalent to the required amount
        while (CurrentXP > FormulaFunction() )
        and CurrentLevel ~= MaxLevel do
            CurrentLevel = CurrentLevel + 1
            LoopFormula = CustomFormula:gsub("x", CurrentLevel)
            FormulaFunction = loadstring(LoopFormula)
        end
    end
    return CurrentLevel
end

return Levelling
