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
EffectsTab.CurrentCredits = 0

function EffectsTab.OnInit( Panel, Data )
    EffectsTab.Label = SGUI:Create( "Label", Panel )
    EffectsTab.Label:SetFont( Fonts.kAgencyFB_Small )
    EffectsTab.Label:SetText( "Player Effect Menu" )
    EffectsTab.Label:SetPos( Vector( 16, 24, 0 ) )

    EffectsTab.CreditBalanceLabel = SGUI:Create( "Label", Panel )
    EffectsTab.CreditBalanceLabel:SetFont( Fonts.kAgencyFB_Small )
    EffectsTab.CreditBalanceLabel:SetText( "Available Credits: " .. EffectsTab.CurrentCredits)
    EffectsTab.CreditBalanceLabel:SetPos( Vector( 350, 25, 0 ) )

    if Data and Data.ImportantInformation then
        return true
    end
end

function EffectsTab.OnCleanup( Panel )
    EffectsTab.Label = nil
    EffectsTab.CreditBalanceLabel = nil
    return { ImportantInformation = true }
end

function EffectsTab.Update ( Data, NewCurrentCredits)
    EffectsTab.CurrentCredits = NewCurrentCredits
    return true
end

return EffectsTab
