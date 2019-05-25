-- ============================================================================
--
-- Settings Tab (View)
--      Tab to configure player settings
--
-- ============================================================================

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Initialisation
-- ----------------------------------------------------------------------------
-- ============================================================================
local SGUI = Shine.GUI

SettingsTab = {}
SettingsTab.TabName = "Settings"
SettingsTab.CurrentCredits = 0

function SettingsTab.OnInit( Panel, Data )
    SettingsTab.PanelLabel = SGUI:Create( "Label", Panel )
    SettingsTab.PanelLabel:SetFont( Fonts.kAgencyFB_Small )
    SettingsTab.PanelLabel:SetText( "Settings Menu" )
    SettingsTab.PanelLabel:SetAnchor( "TopLeft" )
    SettingsTab.PanelLabel:SetPos( Vector( 20, 25, 0 ) )

    SettingsTab.CreditBalanceLabel = SGUI:Create( "Label", Panel )
    SettingsTab.CreditBalanceLabel:SetFont( Fonts.kAgencyFB_Small )
    SettingsTab.CreditBalanceLabel:SetText( "Available Credits: "
        .. SettingsTab.CurrentCredits)
    SettingsTab.CreditBalanceLabel:SetAnchor( "TopRight" )
    SettingsTab.CreditBalanceLabel:SetPos( Vector( -200, 25, 0 ) )

    if Data and Data.ImportantInformation then
        return true
    end
end

-- Set all GUI objects to nil upon closing tab
function SettingsTab.OnCleanup( Panel )
    SettingsTab.PanelLabel = nil
    SettingsTab.CreditBalanceLabel = nil
    return { ImportantInformation = true }
end

function SettingsTab.Update ( Data, NewCurrentCredits )
    SettingsTab.CurrentCredits = NewCurrentCredits
end

function SettingsTab.CreditsMessageUpdate( NewCurrentCredits )
    SettingsTab.CurrentCredits = NewCurrentCredits
end

return SettingsTab
