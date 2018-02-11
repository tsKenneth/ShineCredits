-- ============================================================================
--
-- Skins Tab (View)
--      Tab to preview and purchase skins
--
-- ============================================================================

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Initialisation
-- ----------------------------------------------------------------------------
-- ============================================================================
local SGUI = Shine.GUI

SkinsTab = {}

function SkinsTab.OnInit( Panel, Data )
    Label = SGUI:Create( "Label", Panel )
    Label:SetFont( Fonts.kAgencyFB_Small )
    Label:SetText( "TestLabel" )
    Label:SetPos( Vector( 16, 24, 0 ) )

    if Data and Data.ImportantInformation then
        return true
    end
end

function SkinsTab.OnCleanup( Panel )
    Label = nil
    return { ImportantInformation = true }
end

function SkinsTab.Update ( Data )
    return true
end

return SkinsTab
