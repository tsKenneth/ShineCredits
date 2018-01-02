-- ============================================================================
-- ============= Leveling System ==============================================
-- ============================================================================
-- Update players' Level based on their total credits accumulated

local Shine = Shine
local PlayerLeveling = { _version = "0.1.0" }
local sc_json = require("shine/extensions/shinecredits/sc_jsonfileio")
local sc_notification = require("shine/extensions/shinecredits/sc_notification")

-- ============================================================================
-- Default Config
-- ============================================================================
PlayerLeveling.Settings =
{
    Enabled = true,
    FilePath = "config://shine/plugins/ShineCredits_UserLevels.json",
    Formula = {
        PowerFactor = 1,
        CustomFormula = nil
    },
    Levels = {
        Minimum = 1,
        Maximum = 55,
        LevelBadgeNamePrefix = "level",
        LevelBadgeNameSuffix = "",
        CustomLevelBadgesOrder = nil
    },
    Permissions = {
        SuspendLevelingForGroup = nil,
        AllowLevelingForGroup = nil
    },
    Notifications = {
        LevelChange = "Leveled to %s!" ..
            " (badge will be refreshed when map changes)"
    }
}

PlayerLeveling.PlayerLevelingFile = {}

-- ============================================================================
-- PlayerLeveling.Initialise:
-- Initialise the Player Leveling subsystem
-- ============================================================================
function PlayerLeveling:Initialise(PlayerLevelingSettings)
    if PlayerLevelingSettings
        and PlayerLevelingSettings.Enabled
        and self:ConfigSanityCheck() then
        self.Settings = PlayerLevelingSettings
        self.PlayerLevelingFile = self:LoadPlayerLevels()
        return true
    end
    error("ShineCredits sc_playerleveling.lua: An error has occurred during "
        .. "initilisation, player leveling will not be enabled")
    self.Settings.Enabled = false
    return false
end

-- ============================================================================
-- PlayerLeveling.ConfigSanityCheck:
-- Checks if default configs are valid before proceeding
-- ============================================================================
function PlayerLeveling:ConfigSanityCheck()
    local Settings = self.Settings
    if type(Settings.Formula.PowerFactor) ~= "number" then
        error("ShineCredits sc_playerleveling.lua: PowerFactor is not a number.")
        return false
    elseif Settings.Levels.Minimum ~= math.floor(Settings.Levels.Minimum) or Settings.Levels.Minimum < 0 then
        error("ShineCredits sc_playerleveling.lua: Minimum Level must be a positive integer.")
        return false
    elseif Settings.Levels.Maximum ~= math.floor(Settings.Levels.Maximum) or Settings.Levels.Maximum < 0 then
        error("ShineCredits sc_playerleveling.lua: Maximum Level must be a positive integer.")
        return false
    else
        return true
    end
end

-- ============================================================================
-- FileIO Subsystem:
-- Saves and loads player levels
-- ============================================================================

function PlayerLeveling:LoadPlayerLevels()
    return sc_json.LoadTable(self.Settings.FilePath)
end

function PlayerLeveling:SavePlayerLevels()
    return sc_json.SaveTable(self.PlayerLevelingFile,self.Settings.FilePath)
end

-- ============================================================================
-- Helper Functions
-- ============================================================================
-- ============================================================================
-- PlayerLeveling:GetPlayerLevel:
-- Returns the level of the player
-- ============================================================================
function PlayerLeveling:GetPlayerLevel( Player )
    return self.PlayerLevelingFile[tostring(Player:GetSteamId())].Level
end


-- ============================================================================
-- PlayerLeveling:GetAllowedForLeveling:
-- Checks if the player belongs to a user group that has leveling suspended or
-- enabled
-- ============================================================================
function PlayerLeveling:GetAllowedForLeveling( Player )
    -- Initialise local variables with global values
    local Settings = self.Settings

    -- Obtain required data on player to check player's group
    local Target = Player:GetClient()
    local Existing, _ = Shine:GetUserData( Target )

    -- Return false if player is not in a group allowed for leveling or
    --      in a group suspended from leveling
    if Settings.Permissions.SuspendLevelingForGroup then
        for _, group in ipairs(Settings.Permissions.SuspendLevelingForGroup) do
            if group == Existing.Group then
                return false
            end
        end
        return true
    elseif Settings.Permissions.AllowLevelingForGroup then
        for _, group in ipairs(Settings.AllowLevelingForGroup) do
            if group == Existing.Group then
                return true
            end
        end
        return false
    else
        return true
    end
end

-- ============================================================================
-- PlayerLeveling:SwitchBadge:
-- Remove player's old badge and insert player's new badge according to the new
-- level attained
-- ============================================================================

function PlayerLeveling:SwitchBadge( Existing, OldBadgeName, NewBadgeName )
    if Existing["Badges"] then
        for i, item in pairs(Existing["Badges"]) do
            if type(item) == "table" then
                for k, badge in ipairs(item) do
                    if OldBadgeName == badge then
                        table.remove(item, k)
                        table.insert(item, 1, NewBadgeName)
                        return true
                    end
                end
            elseif OldBadgeName == i then
                table.remove(Existing["Badges"], k)
                table.insert(Existing["Badges"], 1, NewBadgeName)
                return true
            end
        end
    else
        Existing["Badge"] = NewBadgeName
        return true
    end
end

-- ============================================================================
-- PlayerLeveling:GetCorrectLevel:
-- Calculate the player's actual level, based on the formula specified
-- ============================================================================
function PlayerLeveling:GetCorrectLevel( CustomFormula, PlayerTotalCredits
    , PlayerCurrentLevel )
    local CurrentLevel = PlayerCurrentLevel
    local Settings = self.Settings

    -- Determine whether to use Custom Formula or the default exponential
    --      formula
    local FormulaFunction = nil
    if CustomFormula and type(CustomFormula) == "string" then
        CustomFormula = "return " .. CustomForumla
        FormulaFunction = loadstring(CustomFormula)
    else
        CustomFormula = "return x^" .. Settings.Formula.PowerFactor
        FormulaFunction = loadstring(CustomFormula)
    end

    local LoopFormula = CustomFormula:gsub("x", CurrentLevel)
    FormulaFunction = loadstring(LoopFormula)

    -- Checks which way to update the player's level
    if PlayerTotalCredits < FormulaFunction() then
        -- When player's total credits is less than Level's required credits:
        --      Decrease player's Level by 1 until player's credits is
        --      equivalent to the required amount
        while (PlayerTotalCredits < FormulaFunction())
        and CurrentLevel ~= Settings.Levels.Minimum do
            CurrentLevel = CurrentLevel - 1
            LoopFormula = CustomFormula:gsub("x", CurrentLevel)
            FormulaFunction = loadstring(LoopFormula)
        end
    else
        -- When player's total credits is more than Level's required credits:
        --      Increase player's Level by 1 until player's credits is
        --      equivalent to the required amount
        while (PlayerTotalCredits > FormulaFunction() )
        and CurrentLevel ~= Settings.Levels.Maximum do
            CurrentLevel = CurrentLevel + 1
            LoopFormula = CustomFormula:gsub("x", CurrentLevel)
            FormulaFunction = loadstring(LoopFormula)
        end
    end
    return CurrentLevel
end

-- ============================================================================
-- PlayerLeveling:UpdatePlayerLevel:
-- Updates the player's level
-- ============================================================================

function PlayerLeveling:UpdatePlayerLevel( Player ,
    PlayerTotalCredits)

    -- Initialise local variables with global values
    local PlayerLevelingFile = self.PlayerLevelingFile
    local Settings = self.Settings

    -- Checks if Player Leveling System is Enabled
    if not Settings.Enabled then
        return false
    end

    -- Return false if player is not in a group allowed for leveling or
    --      in a group suspended from leveling
    if not self:GetAllowedForLeveling( Player ) then
        return false
    end

    -- Obtain required data on player for updating level
    local Target = Player:GetClient()
    local Existing, SteamID = Shine:GetUserData( Target )
    SteamID = tostring(SteamID)

    local PreviousLevel = PlayerLevelingFile[SteamID].Level or 0

    -- Determine the player's correct level
    local CustomFormula = Settings.Formula.CustomFormula
    local NewLevel = self:GetCorrectLevel(
        CustomFormula, PlayerTotalCredits, PreviousLevel)

    -- If player's Level has changed, perform badge change
    if PreviousLevel ~= NewLevel then
        if Settings.Levels.CustomLevelBadgesOrder then
            if Settings.Levels.CustomLevelBadgesOrder[NewLevel] then
                self:SwitchBadge(Existing,
                Settings.Levels.CustomLevelBadgesOrder[PreviousLevel],
                Settings.Levels.CustomLevelBadgesOrder[NewLevel])
            else
                error("ShineCredits sc_playerleveling.lua: Custom Level " ..
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

            self:SwitchBadge(Existing,OldBadge,NewBadge)
        end

        PlayerLevelingFile[SteamID].Level = NewLevel

        -- Notify player of changes
        sc_notification:Notify(Player,string.format(
            Settings.Notifications.LevelChange,NewLevel))
    end

    PlayerLeveling:SavePlayerLevels()
    Shine:SaveUsers( true )
    return true
end

return PlayerLeveling
