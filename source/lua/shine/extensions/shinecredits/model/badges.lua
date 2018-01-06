-- ============================================================================
--
-- Badge (Model)
--      Shine Credits will manipulate badges for leveling and redemption
--      purposes. This model aims to manage inserting and removing badges.
--
-- This model obtains data from the levelling.lua and redemptions.lua
-- controllers and processes it
--
-- ============================================================================

local Shine = Shine
local Badges = { _version = "0.1.0" }

local Json = require("shine/extensions/shinecredits/utility/json")

Badges.Enabled = false
Badges.BadgesFile = {}

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Initialisation
-- ----------------------------------------------------------------------------
-- ============================================================================

function Badges:Initialise(StorageConfig, BadgesSettings)
    if BadgesSettings then
        self.Settings = BadgesSettings
        self.Settings.FileName = StorageConfig.Files.Directory ..
            self.Settings.FileName

        self.BadgesFile = self:LoadPlayerBadges()
        self.Enabled = true

        return true
    else
        error("[ShineCredits] Badges:Initialise() - An error has occurred during "
            .. "initialisation, badges will not be enabled")
        return false
    end
end

-- ============================================================================
-- Credits.InitialisePlayer
-- Initialise a player into the Badges system
-- ============================================================================
function Badges:InitPlayer( Player )
    -- Initialise local copy of global files
    local LocalBadgesFile = self.BadgesFile
    local Settings = self.Settings
    local SteamID = tostring(Player:GetSteamId())
    local SaveFlag = false

    -- Get Player Config Data
    local Target = Player:GetClient()
    local Existing, _ = Shine:GetUserData( Target )

    -- Checks if the badges in userconfig are correct
    if not Existing["Badges"] then
        Existing["Badges"] = {}
        SaveFlag = true
    end

    for i = 1, Settings.MaxBadgeRows do
        if not Existing["Badges"][tostring(i)] then
            Existing["Badges"][tostring(i)] = {}
            SaveFlag = true
        end
    end

    -- Checks if player has badges mirrored the usercofig
    if LocalBadgesFile[SteamID] == nil then
        LocalBadgesFile[SteamID] = {}
        SaveFlag = true
    end

    for i = 1, Settings.MaxBadgeRows do
        if not LocalBadgesFile[SteamID][tostring(i)] then
            LocalBadgesFile[SteamID][tostring(i)] = {}
            SaveFlag = true
        end
    end

    -- If changes are made, write changes to files
    if SaveFlag then
        Shine:SaveUsers( true )
        self:SavePlayerBadges()
    end

    return true
end

-- ============================================================================
-- FileIO Subsystem:
-- Saves and loads Player Badges
-- ============================================================================

function Badges:LoadPlayerBadges()
    return Json:LoadTable(self.Settings.FileName)
end

function Badges:SavePlayerBadges()
    return Json:SaveTable(self.BadgesFile,self.Settings.FileName)
end

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Helper Functions
-- ----------------------------------------------------------------------------
-- ============================================================================

-- ============================================================================
-- Badges:AddBadge
-- Adds a badge to the player
-- ============================================================================
function Badges:AddBadge( Player , NewBadge, BadgeRow )
    local Settings = self.Settings
    local Target = Player:GetClient()
    local Existing, _ = Shine:GetUserData( Target )

    if Existing["Badges"] then
        if BadgeRow then
            if Existing["Badges"][tostring(BadgeRow)] then
                table.insert(Existing["Badges"][tostring(BadgeRow)],NewBadge)
                return true
            else
                error("ShineCredits Badges:AddBadge() - Error, " ..
                    "attempting to insert a badge into a badgerow that " ..
                    "doesn't exist.")
                return false
            end
        else
            for k, row in pairs(Existing["Badges"]) do
                if tonumber(k) <= Settings.MaxBadgeRows then
                    table.insert(row,NewBadge)
                    return true
                else
                    error("ShineCredits Badges:AddBadge() - Error, " ..
                        "attempting to insert badge into a row beyond " ..
                        "the maximum number of badge rows.")
                    return false
                end
            end
        end
    else
        error("ShineCredits Badges:AddBadge() - Error, " ..
            "badges field does not exist. Check config.")
        return false
    end
end

-- ============================================================================
-- Badges:RemoveBadge
-- Removes the specified badge from the player. only removes the first instance
-- ============================================================================
function Badges:RemoveBadge( Player , OldBadge, BadgeRow)
    local Target = Player:GetClient()
    local Existing, _ = Shine:GetUserData( Target )

    if Existing["Badges"] then
        if BadgeRow then
            local LocalBadgeRow = Existing["Badges"][tostring(BadgeRow)]
            for k, badge in pairs(LocalBadgeRow) do
                if OldBadgeName == badge then
                    table.remove(LocalBadgeRow, k)
                    return true
                end
            end
            return false
        else
            for k, row in pairs(Existing["Badges"]) do
                for i, badge in pairs(row) do
                    if OldBadge == badge then
                        table.remove(row, i)
                        return true
                    end
                end
            end
        end
    else
        error("ShineCredits Badges:RemoveBadge() - Error, " ..
            "badges field does not exist. Check config.")
        return false
    end

end

-- ============================================================================
-- Badges:SwitchBadge
-- Switches an old badge for a new badge
-- ============================================================================
function Badges:SwitchBadge( Player, OldBadge, NewBadge, BadgeRow )
    local SuccessFlagRemove = false
    local SuccessFlagAdd = false

    SuccessFlagRemove = self:RemoveBadge(Player, OldBadge, BadgeRow)
    SuccessFlagAdd = self:AddBadge(Player, NewBadge, BadgeRow)

    Shine:SaveUsers( true )
    return SuccessFlagRemove and SuccessFlagAdd

end

return Badges
