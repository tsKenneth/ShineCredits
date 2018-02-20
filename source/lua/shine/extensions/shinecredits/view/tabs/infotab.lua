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
Currentcredits = 0

function InfoTab.OnInit( Panel, Data )
    Label = SGUI:Create( "Label", Panel )
    Label:SetFont( Fonts.kAgencyFB_Small )
    Label:SetText( "Under Construction" )
    Label:SetPos( Vector( 16, 24, 0 ) )

    CreditBalanceLabel = SGUI:Create( "Label", Panel )
    CreditBalanceLabel:SetFont( Fonts.kAgencyFB_Small )
    CreditBalanceLabel:SetText( "Available Credits: " .. CurrentCredits)
    CreditBalanceLabel:SetPos( Vector( 350, 25, 0 ) )

    if Data and Data.ImportantInformation then
        return true
    end
end

function InfoTab.OnCleanup( Panel )
    Label = nil
    CreditBalanceLabel = nil
    return { ImportantInformation = true }
end

function InfoTab.Update ( Data, NewCurrentCredits )
    CurrentCredits = NewCurrentCredits
    return true
end

function InfoTab.CreditsMessageUpdate( NewCurrentCredits )
    CurrentCredits = NewCurrentCredits
    CreditBalanceLabel:SetText( "Available Credits: " .. NewCurrentCredits)
end

return InfoTab
