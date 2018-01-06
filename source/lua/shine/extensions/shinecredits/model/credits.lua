-- ============================================================================
--
-- Credits (Model)
--      Credits are awarded for playing the game on the server. These credits
--      can then be used to redeem various comestic items, such as sprays and
--      skins.
--
-- This model obtains data from the creditsawarding.lua controller
-- and processes it
--
-- ============================================================================

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Initialisation
-- ----------------------------------------------------------------------------
-- ============================================================================

local Credits = { _version = "0.1.0" }
local Json = require("shine/extensions/shinecredits/utility/json")

Credits.Settings = {}
Credits.CreditsFile = {}

Credits.Enabled = false

-- ============================================================================
-- Credits.Initialise
-- Initialise the Credits subsystem
-- ============================================================================
function Credits:Initialise(StorageConfig, CreditsSettings)
    if CreditsSettings then
        self.Settings = CreditsSettings
        self.Settings.FileName = StorageConfig.Files.Directory ..
            self.Settings.FileName

        self.CreditsFile = self:LoadCredits()
        self.Enabled = true

        return true
    else
        error("[ShineCredits] Credits:Initialise() - An error has occurred during "
            .. "initialisation, credits will not be enabled")
        return false
    end
end

-- ============================================================================
-- Credits.InitialisePlayer
-- Initialise a player into the Credits system
-- ============================================================================
function Credits:InitPlayer( Player )
    -- Initialise local copy of global files
    local LocalCreditsFile = self.CreditsFile
    local SteamID = tostring(Player:GetSteamId())

    if LocalCreditsFile[SteamID] == nil then
        LocalCreditsFile[SteamID] = {
            Total = 0, Current = 0
            }
        self:SaveCredits()
        return true
    end
    return false

end

-- ============================================================================
-- FileIO Subsystem
-- Saves and loads player and commander Credits
-- ============================================================================
function Credits:LoadCredits()
    return Json:LoadTable(self.Settings.FileName)
end

function Credits:SaveCredits()
    return Json:SaveTable(self.CreditsFile,self.Settings.FileName)
end

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Accessors and Mutators
-- ----------------------------------------------------------------------------
-- ============================================================================

-- ============================================================================
-- Credits:AddPlayerCredits
-- Adds a specified amount of Credits to the player
-- Negative number for subtract
-- ============================================================================
function Credits:AddPlayerCredits( PlayerArg, Current, Total)
    local LocalCredits = self.CreditsFile
    local SteamID = tostring(PlayerArg:GetSteamId())
    local CurrentAdd = Current or 0
    local TotalAdd = Total or 0

    LocalCredits[SteamID].Current
        = LocalCredits[SteamID].Current + CurrentAdd

    LocalCredits[SteamID].Total
        = LocalCredits[SteamID].Total + TotalAdd

    return true
end


-- ============================================================================
-- Credits:GetPlayerCredits
-- Returns the credits of the player
-- ============================================================================
function Credits:GetPlayerCredits( PlayerArg )
    local SteamID = tostring(PlayerArg:GetSteamId())
    return {Total = self.CreditsFile[SteamID].Total,
        Current= self.CreditsFile[SteamID].Current}
end

-- ============================================================================
-- Credits:SetPlayerCredits
-- Set Player Credits
-- ============================================================================
function Credits:SetPlayerCredits( PlayerArg, Current, Total )
    local LocalCredits = self.CreditsFile
    local SteamID = tostring(PlayerArg:GetSteamId())
    local CurrentSet = Current or 0
    local TotalSet = Total or 0

    LocalCredits[SteamID].Current = CurrentSet
    LocalCredits[SteamID].Total = TotalSet

    return true
end

return Credits
