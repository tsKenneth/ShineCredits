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

PlayerSkinsTab = {}
PlayerSkinsTab.TabName = "Player Skin"
PlayerSkinsTab.CurrentCredits = 0

function PlayerSkinsTab.OnInit( Panel, Data )
    PlayerSkinsTab.PanelLabel = SGUI:Create( "Label", Panel )
    PlayerSkinsTab.PanelLabel:SetFont( Fonts.kAgencyFB_Small )
    PlayerSkinsTab.PanelLabel:SetText( "Player Skins Menu" )
    PlayerSkinsTab.PanelLabel:SetAnchor( "TopLeft" )
    PlayerSkinsTab.PanelLabel:SetPos( Vector( 20, 25, 0 ) )

    PlayerSkinsTab.CreditBalanceLabel = SGUI:Create( "Label", Panel )
    PlayerSkinsTab.CreditBalanceLabel:SetFont( Fonts.kAgencyFB_Small )
    PlayerSkinsTab.CreditBalanceLabel:SetText( "Available Credits: "
        .. PlayerSkinsTab.CurrentCredits)
    PlayerSkinsTab.CreditBalanceLabel:SetAnchor( "TopRight" )
    PlayerSkinsTab.CreditBalanceLabel:SetPos( Vector( -200, 25, 0 ) )

    if Data and Data.ImportantInformation then
        return true
    end
end

-- Set all GUI objects to nil upon closing tab
function PlayerSkinsTab.OnCleanup( Panel )
    PlayerSkinsTab.PanelLabel = nil
    PlayerSkinsTab.CreditBalanceLabel = nil
    return { ImportantInformation = true }
end

function PlayerSkinsTab.Update ( Data, NewCurrentCredits )
    PlayerSkinsTab.CurrentCredits = NewCurrentCredits
end

return PlayerSkinsTab
