-- ============================================================================
--
-- Sprays (Model)
--      Shine Credits will manipulate sprays for redemption
--      purposes. This model aims to manage inserting and removing sprays.
--
--
-- ============================================================================

local Sprays = { _version = "0.1.0" }

local JsonLib = require("shine/extensions/shinecredits/utility/json")

Sprays.SpraysFile = {}

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Initialisation
-- ----------------------------------------------------------------------------
-- ============================================================================

function Sprays:Initialise(StorageConfig)
    self.Settings = StorageConfig.Models.Sprays

    if self.Settings and self.Settings.Enabled then
        self.Settings.FilePath = StorageConfig.Files.Directory ..
            self.Settings.FileName

        self.SpraysFile = self:LoadPlayerSprays()

        return true
    else
        return false
    end
end

-- ============================================================================
-- Credits.InitialisePlayer
-- Initialise a player into the Sprays system
-- ============================================================================
function Sprays:InitPlayer( Player )
    -- Initialise local copy of global files
    local LocalSpraysFile = self.SpraysFile
    local SteamID = tostring(Player:GetSteamId())

    -- Create and maintain data on players' sprays
    if LocalSpraysFile[SteamID] == nil then
        LocalSpraysFile[SteamID] = {}
        self:SavePlayerSprays()
    end

    return true
end

-- ============================================================================
-- FileIO Subsystem:
-- Saves and loads Player Sprays
-- ============================================================================

function Sprays:LoadPlayerSprays()
    return JsonLib:LoadTable(self.Settings.FilePath)
end

function Sprays:SavePlayerSprays()
    return JsonLib:SaveTable(self.SpraysFile,self.Settings.FilePath)
end

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Accessors and Mutators
-- ----------------------------------------------------------------------------
-- ============================================================================
-- ============================================================================
-- Sprays:GetIsEnabled
-- Returns if the model is enabled
-- ============================================================================
function Sprays:GetIsEnabled()
    return self.Settings.Enabled
end

-- ============================================================================
-- Sprays:GetIfPlayerHasSpray
-- Returns if the player has the specified spray
-- ============================================================================
function Sprays:GetIfPlayerHasSpray( Player, SprayName )
    local LocalSpraysFile = self.SpraysFile
    local SteamID = tostring(Player:GetSteamId())

    if LocalSpraysFile then
        for k, spray in pairs(LocalSpraysFile[SteamID]) do
            if SprayName == spray then
                return true
            end
        end
    end
    return false
end

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Helper Functions
-- ----------------------------------------------------------------------------
-- ============================================================================

-- ============================================================================
-- Sprays:AddSpray
-- Adds a spray to the player
-- ============================================================================
function Sprays:AddSpray( Player , NewSpray)
    local LocalSpraysFile = self.SpraysFile
    local SteamID = tostring(Player:GetSteamId())

    table.insert(LocalSpraysFile[SteamID],NewSpray)

end

-- ============================================================================
-- Sprays:RemoveSpray
-- Removes the specified spray from the player. only removes the first instance
-- ============================================================================
function Sprays:RemoveSpray( Player , OldSpray)
    local LocalSpraysFile = self.SpraysFile
    local SteamID = tostring(Player:GetSteamId())

    for i,spray in ipairs(LocalSpraysFile[SteamID]) do
        if spray == OldSpray then
            table.remove(LocalSpraysFile[SteamID],i)
            return true
        end
    end
    return false

end

return Sprays
