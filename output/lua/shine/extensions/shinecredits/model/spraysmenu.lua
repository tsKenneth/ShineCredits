-- ============================================================================
--
-- SpraysMenu (Model)
--      The sprays menu maintains and lists all the available sprays that
--      players can redeem
--
-- ============================================================================

local SpraysMenu = { _version = "0.1.0" }

local JsonLib = require("shine/extensions/shinecredits/utility/json")

SpraysMenu.SpraysMenu = {}

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Initialisation
-- ----------------------------------------------------------------------------
-- ============================================================================

function SpraysMenu:Initialise(StorageConfig)
    self.Settings = StorageConfig.RedemptionMenus.SpraysMenu

    if self.Settings and self.Settings.Enabled then
        self.Settings.FilePath = StorageConfig.Files.Directory ..
            self.Settings.FileName

        self.SpraysMenu = self:LoadSpraysMenu()

        return true
    else
        return false
    end
end

-- ============================================================================
-- FileIO Subsystem:
-- Saves and loads Player Sprays
-- ============================================================================

function SpraysMenu:LoadSpraysMenu()
    return JsonLib:LoadTable(self.Settings.FilePath)
end

function SpraysMenu:SaveSpraysMenu()
    return JsonLib:SaveTable(self.SpraysMenu,self.Settings.FilePath)
end

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Accessors and Mutators
-- ----------------------------------------------------------------------------
-- ============================================================================
-- ============================================================================
-- SpraysMenu:GetMenu
-- Returns the information on all sprays in the sprays menu
-- ============================================================================
function SpraysMenu:GetMenu()
    return self.SpraysMenu
end

-- ============================================================================
-- SpraysMenu:GetInfo
-- Returns the information on the specified spray
-- ============================================================================
function SpraysMenu:GetInfo( Spray )
    return self.SpraysMenu[Spray]
end

-- ============================================================================
-- SpraysMenu:GetIsEnabled
-- Returns if the model is enabled
-- ============================================================================
function SpraysMenu:GetIsEnabled()
    return self.Settings.Enabled
end

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Helper Functions
-- ----------------------------------------------------------------------------
-- ============================================================================

-- ============================================================================
-- SpraysMenu:AddSpray
-- Adds a spray to the menu
-- ============================================================================
function SpraysMenu:AddSpray( NewSpray, DescriptionArg, CostArg )
    local LocalSpraysMenu = self.SpraysMenu
    LocalSpraysMenu[NewSpray] = {Description = DescriptionArg, Cost = CostArg}
    self:SaveSpraysMenu()
    return true
end
-- ============================================================================
-- SpraysMenu:RemoveSpray
-- Removes the specified spray from the menu
-- ============================================================================
function SpraysMenu:RemoveSpray( OldSpray )
    local LocalSpraysMenu = self.SpraysMenu
    LocalSpraysMenu[OldSpray] = nil
    self:SaveSpraysMenu()
    return true
end

return SpraysMenu
