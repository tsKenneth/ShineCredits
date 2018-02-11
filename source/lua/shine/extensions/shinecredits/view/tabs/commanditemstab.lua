-- ============================================================================
--
-- CommandItems Tab (View)
--      Tab to preview and purchase rights to commands
--
-- ============================================================================

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Initialisation
-- ----------------------------------------------------------------------------
-- ============================================================================
local SGUI = Shine.GUI

CommandsTab = {}

function CommandsTab.OnInit( Panel, Data )
    Label = SGUI:Create( "Label", Panel )
    Label:SetFont( Fonts.kAgencyFB_Small )
    Label:SetText( "TestLabel" )
    Label:SetPos( Vector( 16, 24, 0 ) )

    if Data and Data.ImportantInformation then
        return true
    end
end

function CommandsTab.OnCleanup( Panel )
    Label = nil
    return { ImportantInformation = true }
end

function CommandsTab.Update ( Data )
    return true
end

return CommandsTab
