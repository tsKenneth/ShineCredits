-- ============================================================================
--
-- Badges Tab (View)
--      Tab to preview and purchase badges using credits
--
-- ============================================================================

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Initialisation
-- ----------------------------------------------------------------------------
-- ============================================================================
local SGUI = Shine.GUI

BadgesTab = {}
BadgesTab.BadgesListData = {}
BadgesTab.BadgesPreviewImages = {}
BadgesTab.RedeemCommand = "sc_redeembadge"
BadgesTab.CurrentCredits = 0

function BadgesTab.OnInit( Panel, Data )
    BadgesTab.PanelLabel = SGUI:Create( "Label", Panel )
    BadgesTab.PanelLabel:SetFont( Fonts.kAgencyFB_Small )
    BadgesTab.PanelLabel:SetText( "Badges Menu" )
    BadgesTab.PanelLabel:SetPos( Vector( 20, 25, 0 ) )

    BadgesTab.CreditBalanceLabel = SGUI:Create( "Label", Panel )
    BadgesTab.CreditBalanceLabel:SetFont( Fonts.kAgencyFB_Small )
    BadgesTab.CreditBalanceLabel:SetText( "Available Credits: " .. BadgesTab.CurrentCredits)
    BadgesTab.CreditBalanceLabel:SetPos( Vector( 350, 25, 0 ) )

    BadgesTab.RedemptionResultLabel = SGUI:Create( "Label", Panel )
    BadgesTab.RedemptionResultLabel:SetAnchor( "CentreMiddle" )
    BadgesTab.RedemptionResultLabel:SetFont( Fonts.kAgencyFB_Small )
    BadgesTab.RedemptionResultLabel:SetText( "" )
    BadgesTab.RedemptionResultLabel:SetPos( Vector( -25, 210, 0 ) )

    -- Shows a preview of the badge
    BadgesTab.PreviewImage = SGUI:Create( "Image", Panel )
    BadgesTab.PreviewImage:SetAnchor( "CentreMiddle" )
    BadgesTab.PreviewImage:SetSize( Vector( 150, 150, 0 ) )
    BadgesTab.PreviewImage:SetPos( Vector( 90, -250, 0  ) )

    -- Populate the Badges Menu
    BadgesTab.BadgesList = SGUI:Create( "List", Panel )
    BadgesTab.BadgesList:SetAnchor( "CentreMiddle" )
    BadgesTab.BadgesList:SetPos( Vector( -250, -250, 0 ) )
    BadgesTab.BadgesList:SetColumns( "Badge Name", "Cost" )
    BadgesTab.BadgesList:SetSpacing( 0.7, 0.3 )
    BadgesTab.BadgesList:SetSize( Vector( 300, 450, 0 ) )
    BadgesTab.BadgesList:SetNumericColumn( 2 )
    BadgesTab.BadgesList:SetMultiSelect( false )
    BadgesTab.BadgesList:SetSecondarySortColumn( 2, 1 )
    BadgesTab.BadgesList:SortRows( 2 )
    BadgesTab.BadgesList.ScrollPos = Vector( 0, 30, 0 )
    BadgesTab.BadgesList.OnRowSelected = function (Index, Row)
        local BadgeSelected = BadgesTab.BadgesList:GetSelectedRow()
        if BadgeSelected then
            local Path = string.format( "ui/badges/%s.dds",
                BadgeSelected:GetColumnText( 1 ) )
            BadgesTab.PreviewImage:SetTexture( Path )
        end
    end

    for ID, RowData in ipairs(BadgesTab.BadgesListData) do
        BadgesTab.BadgesList:AddRow(RowData.Name,RowData.Cost)
    end

    -- Button for redemption
    BadgesTab.RedemptionButton = SGUI:Create( "Button", Panel )
    BadgesTab.RedemptionButton:SetAnchor( "CentreMiddle" )
    BadgesTab.RedemptionButton:SetSize( Vector( 150, 50, 0 ) )
    BadgesTab.RedemptionButton:SetPos( Vector( -75, 250, 0 ) )
    BadgesTab.RedemptionButton:SetText( "Redeem" )
    BadgesTab.RedemptionButton.DoClick = function( Button )
        local BadgeSelected = BadgesTab.BadgesList:GetSelectedRow()
        if BadgeSelected then
            Shared.ConsoleCommand(string.format(BadgesTab.RedeemCommand .. " \"%s\"",
                BadgeSelected:GetColumnText( 1 )))
        end
    end

    if Data and Data.ImportantInformation then
        return true
    end
end

function BadgesTab.OnCleanup( Panel )
    BadgesTab.PanelLabel = nil
    BadgesTab.RedemptionButton = nil
    BadgesTab.BadgesList = nil
    BadgesTab.PreviewImage = nil
    BadgesTab.RedemptionResultLabel = nil
    BadgesTab.CreditBalanceLabel = nil
    return { ImportantInformation = true }
end

function BadgesTab.Update( Data, NewCurrentCredits)
    local BadgesMenu = Data

    -- Add new badges to the list
    for ID, RowData in ipairs(BadgesMenu) do
        BadgesTab.BadgesListData[ID] = RowData
    end

    -- Remove any badges from the list that was removed from the menu
    for ID, RowData in ipairs(BadgesTab.BadgesListData) do
        if not BadgesMenu[ID] then
			BadgesTab.BadgesListData[ID] = nil
		end
    end

    BadgesTab.CurrentCredits = NewCurrentCredits
end

function BadgesTab.CreditsMessageUpdate( NewCurrentCredits )
    BadgesTab.CurrentCredits = NewCurrentCredits
    BadgesTab.CreditBalanceLabel:SetText( "Available Credits: " .. CurrentCredits)
end

function BadgesTab.RedeemMessageUpdate( Success )
    if Success then
        BadgesTab.RedemptionResultLabel:SetText( "Success!" )
    else
        BadgesTab.RedemptionResultLabel:SetText( "Failed!" )
    end
end

function BadgesTab.UpdateRedeemCommand( Command )
    BadgesTab.RedeemCommand = Command
end

return BadgesTab
