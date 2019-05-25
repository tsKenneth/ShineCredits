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

CommanderSkinsTab = {}
CommanderSkinsTab.CurrentCredits = 0

function CommanderSkinsTab.OnInit( Panel, Data )
    CommanderSkinsTab.Label = SGUI:Create( "Label", Panel )
    CommanderSkinsTab.Label:SetFont( Fonts.kAgencyFB_Small )
    CommanderSkinsTab.Label:SetText( "Commander Skins Menu" )
    CommanderSkinsTab.Label:SetPos( Vector( 16, 24, 0 ) )

    CommanderSkinsTab.CreditBalanceLabel = SGUI:Create( "Label", Panel )
    CommanderSkinsTab.CreditBalanceLabel:SetFont( Fonts.kAgencyFB_Small )
    CommanderSkinsTab.CreditBalanceLabel:SetText( "Available Credits: " .. CommanderSkinsTab.CurrentCredits)
    CommanderSkinsTab.CreditBalanceLabel:SetPos( Vector( 350, 25, 0 ) )

    if Data and Data.ImportantInformation then
        return true
    end
end

function CommanderSkinsTab.OnCleanup( Panel )
    CommanderSkinsTab.Label = nil
    CommanderSkinsTab.CreditBalanceLabel = nil
    return { ImportantInformation = true }
end

function CommanderSkinsTab.Update ( Data, NewCurrentCredits )
    CommanderSkinsTab.CurrentCredits = NewCurrentCredits
    return true
end

return CommanderSkinsTab
