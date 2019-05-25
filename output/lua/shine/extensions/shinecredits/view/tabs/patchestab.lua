-- ============================================================================
--
-- Patches Tab (View)
--      Tab to configure shoulder patches
--
-- ============================================================================

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Initialisation
-- ----------------------------------------------------------------------------
-- ============================================================================
local SGUI = Shine.GUI

PatchesTab = {}
PatchesTab.TabName = "Settings"
PatchesTab.CurrentCredits = 0

function PatchesTab.OnInit( Panel, Data )
    PatchesTab.PanelLabel = SGUI:Create( "Label", Panel )
    PatchesTab.PanelLabel:SetFont( Fonts.kAgencyFB_Small )
    PatchesTab.PanelLabel:SetText( "Settings Menu" )
    PatchesTab.PanelLabel:SetAnchor( "TopLeft" )
    PatchesTab.PanelLabel:SetPos( Vector( 20, 25, 0 ) )

    PatchesTab.CreditBalanceLabel = SGUI:Create( "Label", Panel )
    PatchesTab.CreditBalanceLabel:SetFont( Fonts.kAgencyFB_Small )
    PatchesTab.CreditBalanceLabel:SetText( "Available Credits: "
        .. PatchesTab.CurrentCredits)
    PatchesTab.CreditBalanceLabel:SetAnchor( "TopRight" )
    PatchesTab.CreditBalanceLabel:SetPos( Vector( -200, 25, 0 ) )

    if Data and Data.ImportantInformation then
        return true
    end
end

-- Set all GUI objects to nil upon closing tab
function PatchesTab.OnCleanup( Panel )
    PatchesTab.PanelLabel = nil
    PatchesTab.CreditBalanceLabel = nil
    return { ImportantInformation = true }
end

function PatchesTab.Update ( Data, NewCurrentCredits )
    PatchesTab.CurrentCredits = NewCurrentCredits
end

function PatchesTab.CreditsMessageUpdate( NewCurrentCredits )
    PatchesTab.CurrentCredits = NewCurrentCredits
end

return PatchesTab
