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
SkinsTab.CurrentCredits = 0

function SkinsTab.OnInit( Panel, Data )
    SkinsTab.Label = SGUI:Create( "Label", Panel )
    SkinsTab.Label:SetFont( Fonts.kAgencyFB_Small )
    SkinsTab.Label:SetText( "Player Skins Menu" )
    SkinsTab.Label:SetPos( Vector( 16, 24, 0 ) )

    SkinsTab.CreditBalanceLabel = SGUI:Create( "Label", Panel )
    SkinsTab.CreditBalanceLabel:SetFont( Fonts.kAgencyFB_Small )
    SkinsTab.CreditBalanceLabel:SetText( "Available Credits: " .. SkinsTab.CurrentCredits)
    SkinsTab.CreditBalanceLabel:SetPos( Vector( 350, 25, 0 ) )

    if Data and Data.ImportantInformation then
        return true
    end
end

function SkinsTab.OnCleanup( Panel )
    SkinsTab.Label = nil
    SkinsTab.CreditBalanceLabel = nil
    return { ImportantInformation = true }
end

function SkinsTab.Update ( Data, NewCurrentCredits )
    SkinsTab.CurrentCredits = NewCurrentCredits
    return true
end

return SkinsTab
