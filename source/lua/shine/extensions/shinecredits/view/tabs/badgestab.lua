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
BadgesListData = {}
BadgesPreviewImages = {}

function BadgesTab.OnInit( Panel, Data )
    PanelLabel = SGUI:Create( "Label", Panel )
    PanelLabel:SetFont( Fonts.kAgencyFB_Small )
    PanelLabel:SetText( "Badges Menu" )
    PanelLabel:SetPos( Vector( 20, 25, 0 ) )

    RedemptionResultLabel = SGUI:Create( "Label", Panel )
    RedemptionResultLabel:SetAnchor( "CentreMiddle" )
    RedemptionResultLabel:SetFont( Fonts.kAgencyFB_Small )
    RedemptionResultLabel:SetText( "" )
    RedemptionResultLabel:SetPos( Vector( -25, 210, 0 ) )

    -- Shows a preview of the badge
    PreviewImage = SGUI:Create( "Image", Panel )
    PreviewImage:SetAnchor( "CentreMiddle" )
    PreviewImage:SetSize( Vector( 150, 150, 0 ) )
    PreviewImage:SetPos( Vector( 90, -250, 0  ) )

    -- Populate the Badges Menu
    BadgesList = SGUI:Create( "List", Panel )
    BadgesList:SetAnchor( "CentreMiddle" )
    BadgesList:SetPos( Vector( -250, -250, 0 ) )
    BadgesList:SetColumns( "Badge Name", "Cost" )
    BadgesList:SetSpacing( 0.7, 0.3 )
    BadgesList:SetSize( Vector( 300, 450, 0 ) )
    BadgesList:SetNumericColumn( 2 )
    BadgesList:SetMultiSelect( false )
    BadgesList:SetSecondarySortColumn( 2, 1 )
    BadgesList.ScrollPos = Vector( 0, 30, 0 )
    BadgesList.OnRowSelected = function (Index, Row)
        local BadgeSelected = BadgesList:GetSelectedRow()
        if BadgeSelected then
            local Path = string.format( "ui/badges/%s.dds",
                BadgeSelected:GetColumnText( 1 ) )
            PreviewImage:SetTexture( Path )
        end
    end

    for ID, RowData in ipairs(BadgesListData) do
        BadgesList:AddRow(RowData.Name,RowData.Cost)
    end

    -- Button for redemption
    RedemptionButton = SGUI:Create( "Button", Panel )
    RedemptionButton:SetAnchor( "CentreMiddle" )
    RedemptionButton:SetSize( Vector( 150, 50, 0 ) )
    RedemptionButton:SetPos( Vector( -75, 250, 0 ) )
    RedemptionButton:SetText( "Redeem" )
    RedemptionButton.DoClick = function( Button )
        local BadgeSelected = BadgesList:GetSelectedRow()
        if BadgeSelected then
            Shared.ConsoleCommand(string.format("sc_redeembadge %s",
                BadgeSelected:GetColumnText( 1 )))
        end
    end

    if Data and Data.ImportantInformation then
        return true
    end
end

function BadgesTab.OnCleanup( Panel )
    PanelLabel = nil
    RedemptionButton = nil
    BadgesList = nil
    PreviewImage = nil
    RedemptionResultLabel = nil
    return { ImportantInformation = true }
end

function BadgesTab.Update( Data )
    local BadgesMenu = Data

    -- Add new badges to the list
    for ID, RowData in ipairs(BadgesMenu) do
        BadgesListData[ID] = RowData
    end

    -- Remove any badges from the list that was removed from the menu
    for ID, RowData in ipairs(BadgesListData) do
        if not BadgesMenu[ID] then
			BadgesListData[ID] = nil
		end
    end
end

function BadgesTab.RedeemMessageUpdate( Success )
    if Success then
        RedemptionResultLabel:SetText( "Success!" )
    else
        RedemptionResultLabel:SetText( "Failed!" )
    end
end

return BadgesTab
