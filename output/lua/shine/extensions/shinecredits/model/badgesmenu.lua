-- ============================================================================
--
-- BadgesMenu (Model)
--      The badges menu maintains and lists all the available badges that
--      players can redeem
--
-- ============================================================================

local BadgesMenu = { _version = "0.1.0" }

local JsonLib = require("shine/extensions/shinecredits/utility/json")

BadgesMenu.BadgesMenu = {}

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Initialisation
-- ----------------------------------------------------------------------------
-- ============================================================================

function BadgesMenu:Initialise(StorageConfig)
    self.Settings = StorageConfig.RedemptionMenus.BadgesMenu

    if self.Settings and self.Settings.Enabled then
        self.Settings.FilePath = StorageConfig.Files.Directory ..
            self.Settings.FileName

        self.BadgesMenu = self:LoadBadgesMenu()

        return true
    else
        return false
    end
end

-- ============================================================================
-- FileIO Subsystem:
-- Saves and loads Player Badges
-- ============================================================================

function BadgesMenu:LoadBadgesMenu()
    return JsonLib:LoadTable(self.Settings.FilePath)
end

function BadgesMenu:SaveBadgesMenu()
    return JsonLib:SaveTable(self.BadgesMenu,self.Settings.FilePath)
end

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Accessors and Mutators
-- ----------------------------------------------------------------------------
-- ============================================================================
-- ============================================================================
-- BadgesMenu:GetAllInfo
-- Returns the information on all badges in the badges menu
-- ============================================================================
function BadgesMenu:GetAllInfo()
    return self.BadgesMenu
end

-- ============================================================================
-- BadgesMenu:GetInfo
-- Returns the information on the specified badge
-- ============================================================================
function BadgesMenu:GetInfo( Badge )
    return self.BadgesMenu[Badge]
end

-- ============================================================================
-- BadgesMenu:GetIsEnabled
-- Returns if the model is enabled
-- ============================================================================
function BadgesMenu:GetIsEnabled()
    return self.Settings.Enabled
end

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Helper Functions
-- ----------------------------------------------------------------------------
-- ============================================================================

-- ============================================================================
-- BadgesMenu:AddBadge
-- Adds a badge to the menu
-- ============================================================================
function BadgesMenu:AddBadge( NewBadge, DescriptionArg, CostArg )
    local LocalBadgesMenu = self.BadgesMenu
    LocalBadgesMenu[NewBadge] = {Description = DescriptionArg, Cost = CostArg}
    self:SaveBadgesMenu()
    return true

end
-- ============================================================================
-- BadgesMenu:RemoveBadge
-- Removes the specified badge from the menu
-- ============================================================================
function BadgesMenu:RemoveBadge( OldBadge )
    local LocalBadgesMenu = self.BadgesMenu
    LocalBadgesMenu[OldBadge] = nil
    self:SaveBadgesMenu()
    return true
end

return BadgesMenu
