-- ============================================================================
--
-- Credits (Model)
--      Credits are awarded for playing the game on the server. These credits
--      can then be used to redeem various comestic items, such as sprays and
--      skins.
--
-- ============================================================================

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Initialisation
-- ----------------------------------------------------------------------------
-- ============================================================================

local Credits = { _version = "0.1.0" }
local JsonLib = require("shine/extensions/shinecredits/utility/json")

Credits.Settings = {}
Credits.CreditsFile = {}

-- ============================================================================
-- Credits.Initialise
-- Initialise the Credits subsystem
-- ============================================================================
function Credits:Initialise(StorageConfig)
    self.Settings = StorageConfig.Models.Credits

    if self.Settings and self.Settings.Enabled then
        self.Settings.FilePath = StorageConfig.Files.Directory ..
            self.Settings.FileName

        self.CreditsFile = self:LoadCredits()

        return true
    else
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
            Total = self.Settings.StartingAmount,
                Current = self.Settings.StartingAmount
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
    return JsonLib:LoadTable(self.Settings.FilePath)
end

function Credits:SaveCredits()
    return JsonLib:SaveTable(self.CreditsFile,self.Settings.FilePath)
end

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Accessors and Mutators
-- ----------------------------------------------------------------------------
-- ============================================================================
-- ============================================================================
-- Credits:GetIsEnabled
-- Returns if the model is enabled
-- ============================================================================
function Credits:GetIsEnabled()
    return self.Settings.Enabled
end


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
-- Credits:SpendPlayerCredits
-- Spends a specified amount of credits of the player. Returns false if
-- player has insufficient credits
-- ============================================================================
function Credits:SpendPlayerCredits( PlayerArg, CostArg)
    local LocalCredits = self.CreditsFile
    local SteamID = tostring(PlayerArg:GetSteamId())
    local Cost = CostArg or 0

    if LocalCredits[SteamID].Current > Cost then
        LocalCredits[SteamID].Current =
            LocalCredits[SteamID].Current - Cost
        return true
    else
        return false
    end
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
