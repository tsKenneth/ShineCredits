-- ============================================================================
--
-- Level (Model)
--      Throughout the game, players and accumulate Experience points (XP)
--      when they perform various actions as spcified in the formula config
--      These XP then contributes to the requirements of reaching the next
--      level. Each level has a set required amount of points as specified
--      by the formula in the config and also a corresponding badge to
--      represent the level attained.
--
-- ============================================================================

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Initialisation
-- ----------------------------------------------------------------------------
-- ============================================================================

local Levels = { _version = "0.1.0" }
local Json = require("shine/extensions/shinecredits/utility/json")

Levels.Settings = {}
Levels.LevelsFile = {}

-- ============================================================================
-- Level.Initialise:
-- Initialise the Leveling subsystem
-- ============================================================================
function Levels:Initialise(StorageConfig, LevelingSettings)
    self.Settings = StorageConfig.Models.Levels

    if self.Settings and self.Settings.Enabled then
        self.Settings.FilePath = StorageConfig.Files.Directory ..
            self.Settings.FileName

        self.LevelsFile = self:LoadLevels()

        return true
    else
        return false
    end
end

-- ============================================================================
-- Level.InitialisePlayer:
-- Initialise a player into the levels system
-- ============================================================================
function Levels:InitPlayer( Player )
    -- Initialise local copy of global files
    local LocalLevelsFile = self.LevelsFile
    local SteamID = tostring(Player:GetSteamId())

    if LocalLevelsFile[SteamID] == nil then
        LocalLevelsFile[SteamID] = {
            Player = {XP = 0, Level = 0},
            Commander = {XP = 0, Level = 0}
            }
        self:SaveLevels()
    end
end

-- ============================================================================
-- FileIO Subsystem:
-- Saves and loads player and commander levels
-- ============================================================================
function Levels:LoadLevels()
    return Json:LoadTable(self.Settings.FilePath)
end

function Levels:SaveLevels()
    return Json:SaveTable(self.LevelsFile,self.Settings.FilePath)
end

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Accessors and Mutators
-- ----------------------------------------------------------------------------
-- ============================================================================
-- ============================================================================
-- Levels:GetIsEnabled
-- Returns if the model is enabled
-- ============================================================================
function Levels:GetIsEnabled()
    return self.Settings.Enabled
end

-- ============================================================================
-- Levels:GetSummary
-- Returns the XP of the player
-- ============================================================================
function Levels:GetSummary( PlayerArg )
    local SteamID = tostring(PlayerArg:GetSteamId())
    local Results = {
        PlayerXP = self.LevelsFile[SteamID].Player.XP,
        CommanderXP = self.LevelsFile[SteamID].Commander.XP,
        PlayerLevel = self.LevelsFile[SteamID].Player.Level,
        CommanderLevel = self.LevelsFile[SteamID].Commander.Level
    }

    return Results
end


-- ============================================================================
-- Levels:GetPlayerXP
-- Returns the XP of the player
-- ============================================================================
function Levels:GetPlayerXP( PlayerArg )
    local SteamID = tostring(PlayerArg:GetSteamId())
    return self.LevelsFile[SteamID].Player.XP
end

-- ============================================================================
-- Levels:GetCommanderXP
-- Returns the XP of the commander
-- ============================================================================
function Levels:GetCommanderXP( CommanderArg )
    local SteamID = tostring(CommanderArg:GetSteamId())
    return self.LevelsFile[SteamID].Commander.XP
end

-- ============================================================================
-- Levels:GetPlayerLevel
-- Returns the level of the player
-- ============================================================================
function Levels:GetPlayerLevel( PlayerArg )
    local SteamID = tostring(PlayerArg:GetSteamId())
    return self.LevelsFile[SteamID].Player.Level
end

-- ============================================================================
-- Levels:GetCommanderLevel
-- Returns the level of the commander
-- ============================================================================
function Levels:GetCommanderLevel( CommanderArg )
    local SteamID = tostring(CommanderArg:GetSteamId())
    return self.LevelsFile[SteamID].Commander.Level
end

-- ============================================================================
-- Levels:AddPlayerXP
-- Adds a specified amount of XP to the player
-- Negative number for subtract
-- ============================================================================
function Levels:AddPlayerXP( Player, AmountArg )
    local LocalLevelsFiles = self.LevelsFile
    local SteamID = tostring(Player:GetSteamId())
    local Amount = AmountArg or 0

    LocalLevelsFiles[SteamID].Player.XP
        = LocalLevelsFiles[SteamID].Player.XP + Amount
    return true
end

-- ============================================================================
-- Levels:AddCommanderXP
-- Adds a specified amount of XP to the Commander
-- Negative number for subtract
-- ============================================================================
function Levels:AddCommanderXP( Player, AmountArg )
    local LocalLevelsFiles = self.LevelsFile
    local SteamID = tostring(Player:GetSteamId())
    local Amount = AmountArg or 0

    LocalLevelsFiles[SteamID].Commander.XP
        = LocalLevelsFiles[SteamID].Commander.XP + Amount
    return true
end

-- ============================================================================
-- Levels:SetPlayerXP
-- Set the player's XP to the specified amount
-- ============================================================================
function Levels:SetPlayerXP( Player, AmountArg )
    local LocalLevelsFiles = self.LevelsFile
    local SteamID = tostring(Player:GetSteamId())
    local Amount = AmountArg or 0

    LocalLevelsFiles[SteamID].Player.XP = Amount
    return true
end

-- ============================================================================
-- Levels:SetCommanderXP
-- Set the commander's XP to the specified amount
-- ============================================================================
function Levels:SetCommanderXP( Player, AmountArg )
    local LocalLevelsFiles = self.LevelsFile
    local SteamID = tostring(Player:GetSteamId())
    local Amount = AmountArg or 0

    LocalLevelsFiles[SteamID].Commander.XP = Amount
    return true
end

-- ============================================================================
-- Levels:SetPlayerLevel
-- Set Player Level
-- ============================================================================
function Levels:SetPlayerLevel( PlayerArg, NewLevel )
    local SteamID = tostring(PlayerArg:GetSteamId())
    self.LevelsFile[SteamID].Player.Level = NewLevel
    return true
end

-- ============================================================================
-- Levels:SetCommanderLevel
-- Set Commander Level
-- ============================================================================
function Levels:SetCommanderLevel( CommanderArg, NewLevel )
    local SteamID = tostring(CommanderArg:GetSteamId())
    self.LevelsFile[SteamID].Commander.Level = NewLevel
    return true
end

return Levels
