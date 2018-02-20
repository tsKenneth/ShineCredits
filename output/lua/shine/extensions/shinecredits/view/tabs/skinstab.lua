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

SkinsTab = {}
CurrentCredits = 0

function SkinsTab.OnInit( Panel, Data )
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

function SkinsTab.OnCleanup( Panel )
    Label = nil
    CreditBalanceLabel = nil
    return { ImportantInformation = true }
end

function SkinsTab.Update ( Data, NewCurrentCredits )
    CurrentCredits = NewCurrentCredits
    return true
end

function SkinsTab.CreditsMessageUpdate( NewCurrentCredits )
    CurrentCredits = NewCurrentCredits
    CreditBalanceLabel:SetText( "Available Credits: " .. NewCurrentCredits)
end

return SkinsTab
