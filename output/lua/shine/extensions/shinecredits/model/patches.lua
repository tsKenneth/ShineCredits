-- ============================================================================
--
-- Badge (Model)
--      Shine Credits will manipulate patches for leveling and redemption
--      purposes. This model aims to manage inserting and removing patches.
--
-- ============================================================================

local Shine = Shine
local Patches = { _version = "0.1.0" }

local JsonLib = require("shine/extensions/shinecredits/utility/json")

Patches.PatchesFile = {}

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Initialisation
-- ----------------------------------------------------------------------------
-- ============================================================================

function Patches:Initialise(StorageConfig, ServerSettings)
    self.Settings = StorageConfig.Models.Patches
    self.ServerSettings = ServerSettings

    if self.Settings and self.Settings.Enabled then
        self.Settings.FilePath = StorageConfig.Files.Directory ..
            self.Settings.FileName

        self.PatchesFile = self:LoadPlayerBadges()

        return true
    else
        return false
    end
end

-- ============================================================================
-- Credits.InitialisePlayer
-- Initialise a player into the Patches system
-- ============================================================================
function Patches:InitPlayer( Player )
    -- Initialise local copy of global files
    local LocalBadgesFile = self.PatchesFile
    local Settings = self.Settings
    local ServerSettings = self.ServerSettings
    local SteamID = tostring(Player:GetSteamId())
    local SaveFlag = false
    local Result = false

    -- Get Player Config Data
    local Target = Player:GetClient()
    local Existing, _ = Shine:GetUserData( Target )

    if not Existing then
        Result = Shine:CreateUser( Target, ServerSettings.DefaultGroup)
        if Result then
            return true
        else
            Shine:Print("ShineCredits Patches:InitPlayer() - Error, " ..
                "failed to create a new user")
            return false
        end
    end

    -- Checks if the patches in userconfig are correct
    if not Existing["Patches"] then
        Existing["Patches"] = {}
        SaveFlag = true
    end

    for i = 1, Settings.MaxBadgeRows do
        if not Existing["Patches"][tostring(i)] then
            Existing["Patches"][tostring(i)] = {}
            SaveFlag = true
        end
    end

    -- Checks if player has patches mirrored the usercofig
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
-- Saves and loads Player Patches
-- ============================================================================

function Patches:LoadPlayerBadges()
    return JsonLib:LoadTable(self.Settings.FilePath)
end

function Patches:SavePlayerBadges()
    Shine:SaveUsers( true )
    return JsonLib:SaveTable(self.PatchesFile,self.Settings.FilePath)
end

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Accessors and Mutators
-- ----------------------------------------------------------------------------
-- ============================================================================
-- ============================================================================
-- Patches:GetIsEnabled
-- Returns if the model is enabled
-- ============================================================================
function Patches:GetIsEnabled()
    return self.Settings.Enabled
end

-- ============================================================================
-- Patches:GetBadgeFile
-- Returns the entire badge file
-- ============================================================================
function Patches:GetBadgeFile()
    return self.PatchesFile
end

-- ============================================================================
-- Patches:GetIfPlayerHasBadge
-- Returns if the player has the specified badge
-- ============================================================================
function Patches:GetIfPlayerHasBadge( Player, BadgeName )
    local LocalBadgesFile = self.PatchesFile
    local SteamID = tostring(Player:GetSteamId())

    if LocalBadgesFile then
        for k, row in pairs(LocalBadgesFile[SteamID]) do
            for i, badge in pairs(row) do
                if BadgeName == badge then
                    return true
                end
            end
            return false
        end
    end
end

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Helper Functions
-- ----------------------------------------------------------------------------
-- ============================================================================

-- ============================================================================
-- Patches:AddBadge
-- Adds a badge to the player
-- ============================================================================
function Patches:AddBadge( Player , NewBadge, BadgeRow )
    local Settings = self.Settings
    local LocalBadgesFile = self.PatchesFile

    local Target = Player:GetClient()
    local Existing, SteamID = Shine:GetUserData( Target )

    if not Existing then
        return false
    end

    SteamID = tostring(SteamID)

    if Existing["Patches"] then
        if BadgeRow and BadgeRow <= Settings.MaxBadgeRows then
            if Existing["Patches"][tostring(BadgeRow)] then
                table.insert(Existing["Patches"][tostring(BadgeRow)],NewBadge)
                table.insert(LocalBadgesFile[SteamID][tostring(BadgeRow)],
                    NewBadge)
                return true
            else
                Shine:Print("ShineCredits Patches:AddBadge() - Error, " ..
                    "attempting to insert a badge into a badgerow that " ..
                    "doesn't exist or beyond the max number of badgerows.")
                return false
            end
        else
            for k, row in pairs(Existing["Patches"]) do
                if tonumber(k) <= Settings.MaxBadgeRows then
                    table.insert(row,NewBadge)
                    table.insert(LocalBadgesFile[SteamID][tostring(k)],
                        NewBadge)
                    return true
                else
                    Shine:Print("ShineCredits Patches:AddBadge() - Error, " ..
                        "attempting to insert badge into a row beyond " ..
                        "the maximum number of badge rows.")
                    return false
                end
            end
        end
    else
        Shine:Print("ShineCredits Patches:AddBadge() - Error, " ..
            "patches field does not exist. Check config.")
        return false
    end
end

-- ============================================================================
-- Patches:RemoveBadge
-- Removes the specified badge from the player. only removes the first instance
-- ============================================================================
function Patches:RemoveBadge( Player , OldBadge, BadgeRow)
    local Settings = self.Settings
    local LocalBadgesFile = self.PatchesFile

    local Target = Player:GetClient()
    local Existing, SteamID = Shine:GetUserData( Target )

    if not Existing then
        return false
    end

    SteamID = tostring(SteamID)

    if Existing["Patches"] then
        if BadgeRow and BadgeRow <= Settings.MaxBadgeRows then
            local LocalBadgeRow = Existing["Patches"][tostring(BadgeRow)]
            for k, badge in pairs(LocalBadgeRow) do
                if OldBadge == badge then
                    table.remove(LocalBadgeRow, k)
                    table.remove(LocalBadgesFile[SteamID][tostring(BadgeRow)],k)
                    return true
                end
            end
            return false
        else
            for k, row in pairs(Existing["Patches"]) do
                for i, badge in pairs(row) do
                    if OldBadge == badge then
                        table.remove(row, i)
                        table.remove(LocalBadgesFile[SteamID][tostring(k)],i)
                        return true
                    end
                end
            end
            return true
        end
    else
        Shine:Print("ShineCredits Patches:RemoveBadge() - Error, " ..
            "patches field does not exist for player " .. SteamID ..
            ". Check config.")
        return false
    end

end

-- ============================================================================
-- Patches:SwitchBadge
-- Switches an old badge for a new badge
-- ============================================================================
function Patches:SwitchBadge( Player, OldBadge, NewBadge, BadgeRow )
    local SuccessFlagRemove = false
    local SuccessFlagAdd = false

    SuccessFlagRemove = self:RemoveBadge(Player, OldBadge, BadgeRow)
    SuccessFlagAdd = self:AddBadge(Player, NewBadge, BadgeRow)

    return SuccessFlagRemove and SuccessFlagAdd

end

return Patches
