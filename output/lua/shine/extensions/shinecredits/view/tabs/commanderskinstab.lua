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
CommanderSkinsTab.TabName = "Commander Skins"
CommanderSkinsTab.CurrentCredits = 0

function CommanderSkinsTab.OnInit( Panel, Data )
    CommanderSkinsTab.PanelLabel = SGUI:Create( "Label", Panel )
    CommanderSkinsTab.PanelLabel:SetFont( Fonts.kAgencyFB_Small )
    CommanderSkinsTab.PanelLabel:SetText( "Commander Skins Menu" )
    CommanderSkinsTab.PanelLabel:SetAnchor( "TopLeft" )
    CommanderSkinsTab.PanelLabel:SetPos( Vector( 20, 25, 0 ) )

    CommanderSkinsTab.CreditBalanceLabel = SGUI:Create( "Label", Panel )
    CommanderSkinsTab.CreditBalanceLabel:SetFont( Fonts.kAgencyFB_Small )
    CommanderSkinsTab.CreditBalanceLabel:SetText( "Available Credits: " ..
        CommanderSkinsTab.CurrentCredits)
    CommanderSkinsTab.CreditBalanceLabel:SetAnchor( "TopRight" )
    CommanderSkinsTab.CreditBalanceLabel:SetPos( Vector( -200, 25, 0 ) )

    if Data and Data.ImportantInformation then
        return true
    end
end

-- Set all GUI objects to nil upon closing tab
function CommanderSkinsTab.OnCleanup( Panel )
    CommanderSkinsTab.PanelLabel = nil
    CommanderSkinsTab.CreditBalanceLabel = nil
    return { ImportantInformation = true }
end

function CommanderSkinsTab.Update ( Data, NewCurrentCredits )
    CommanderSkinsTab.CurrentCredits = NewCurrentCredits
end

return CommanderSkinsTab
