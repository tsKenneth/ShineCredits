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
CommandsTab.TabName = "Commands"
CommandsTab.CurrentCredits = 0

function CommandsTab.OnInit( Panel, Data )
    CommandsTab.PanelLabel = SGUI:Create( "Label", Panel )
    CommandsTab.PanelLabel:SetFont( Fonts.kAgencyFB_Small )
    CommandsTab.PanelLabel:SetText( "Command Items Menu" )
    CommandsTab.PanelLabel:SetAnchor( "TopLeft" )
    CommandsTab.PanelLabel:SetPos( Vector( 20, 25, 0 ) )

    CommandsTab.CreditBalanceLabel = SGUI:Create( "Label", Panel )
    CommandsTab.CreditBalanceLabel:SetFont( Fonts.kAgencyFB_Small )
    CommandsTab.CreditBalanceLabel:SetText( "Available Credits: " ..
        CommandsTab.CurrentCredits)
    CommandsTab.CreditBalanceLabel:SetAnchor( "TopRight" )
    CommandsTab.CreditBalanceLabel:SetPos( Vector( -200, 25, 0 ) )

    if Data and Data.ImportantInformation then
        return true
    end
end

-- Set all GUI objects to nil upon closing tab
function CommandsTab.OnCleanup( Panel )
    CommandsTab.PanelLabel = nil
    CommandsTab.CreditBalanceLabel = nil
    return { ImportantInformation = true }
end

function CommandsTab.Update ( Data, NewCurrentCredits)
    CommandsTab.CurrentCredits = NewCurrentCredits
end

return CommandsTab
