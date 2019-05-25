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

EffectsTab = {}
EffectsTab.TabName = "Effects"
EffectsTab.CurrentCredits = 0

function EffectsTab.OnInit( Panel, Data )
    EffectsTab.PanelLabel = SGUI:Create( "Label", Panel )
    EffectsTab.PanelLabel:SetFont( Fonts.kAgencyFB_Small )
    EffectsTab.PanelLabel:SetText( "Player Effects Menu" )
    EffectsTab.PanelLabel:SetAnchor( "TopLeft" )
    EffectsTab.PanelLabel:SetPos( Vector( 20, 25, 0 ) )

    EffectsTab.CreditBalanceLabel = SGUI:Create( "Label", Panel )
    EffectsTab.CreditBalanceLabel:SetFont( Fonts.kAgencyFB_Small )
    EffectsTab.CreditBalanceLabel:SetText( "Available Credits: "
        .. EffectsTab.CurrentCredits)
    EffectsTab.CreditBalanceLabel:SetAnchor( "TopRight" )
    EffectsTab.CreditBalanceLabel:SetPos( Vector( -200, 25, 0 ) )

    if Data and Data.ImportantInformation then
        return true
    end
end

-- Set all GUI objects to nil upon closing tab
function EffectsTab.OnCleanup( Panel )
    EffectsTab.PanelLabel = nil
    EffectsTab.CreditBalanceLabel = nil
    return { ImportantInformation = true }
end

function EffectsTab.Update ( Data, NewCurrentCredits)
    EffectsTab.CurrentCredits = NewCurrentCredits
end

return EffectsTab
