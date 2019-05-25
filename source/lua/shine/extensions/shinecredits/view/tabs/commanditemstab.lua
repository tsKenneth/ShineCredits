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
CommandsTab.CurrentCredits = 0

function CommandsTab.OnInit( Panel, Data )
    CommandsTab.Label = SGUI:Create( "Label", Panel )
    CommandsTab.Label:SetFont( Fonts.kAgencyFB_Small )
    CommandsTab.Label:SetText( "Command Items Menu" )
    CommandsTab.Label:SetPos( Vector( 16, 24, 0 ) )

    CommandsTab.CreditBalanceLabel = SGUI:Create( "Label", Panel )
    CommandsTab.CreditBalanceLabel:SetFont( Fonts.kAgencyFB_Small )
    CommandsTab.CreditBalanceLabel:SetText( "Available Credits: " .. CommandsTab.CurrentCredits)
    CommandsTab.CreditBalanceLabel:SetPos( Vector( 350, 25, 0 ) )

    if Data and Data.ImportantInformation then
        return true
    end
end

function CommandsTab.OnCleanup( Panel )
    CommandsTab.Label = nil
    CommandsTab.CreditBalanceLabel = nil
    return { ImportantInformation = true }
end

function CommandsTab.Update ( Data, NewCurrentCredits)
    CommandsTab.CurrentCredits = NewCurrentCredits
    return true
end

return CommandsTab
