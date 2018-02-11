-- ============================================================================
--
-- Info Tab (View)
--      Tab to view player information
--
-- ============================================================================

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Initialisation
-- ----------------------------------------------------------------------------
-- ============================================================================
local SGUI = Shine.GUI

InfoTab = {}

function InfoTab.OnInit( Panel, Data )
    Label = SGUI:Create( "Label", Panel )
    Label:SetFont( Fonts.kAgencyFB_Small )
    Label:SetText( "TestLabel" )
    Label:SetPos( Vector( 16, 24, 0 ) )

    if Data and Data.ImportantInformation then
        return true
    end
end

function InfoTab.OnCleanup( Panel )
    Label = nil
    return { ImportantInformation = true }
end

function InfoTab.Update ( Data )
    return true
end

return InfoTab
