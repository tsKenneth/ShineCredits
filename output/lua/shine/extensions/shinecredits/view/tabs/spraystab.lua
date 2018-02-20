-- ============================================================================
--
-- Sprays Tab (View)
--      Tab to preview purchase and equip sprays
--
-- ============================================================================

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Initialisation
-- ----------------------------------------------------------------------------
-- ============================================================================
local SGUI = Shine.GUI

SpraysTab = {}
SpraysListData = {}
SpraysPreviewImages = {}
CurrentCredits = 0

function SpraysTab.OnInit( Panel, Data )
    PanelLabel = SGUI:Create( "Label", Panel )
    PanelLabel:SetFont( Fonts.kAgencyFB_Small )
    PanelLabel:SetText( "Sprays Menu" )
    PanelLabel:SetPos( Vector( 20, 25, 0 ) )

    CreditBalanceLabel = SGUI:Create( "Label", Panel )
    CreditBalanceLabel:SetFont( Fonts.kAgencyFB_Small )
    CreditBalanceLabel:SetText( "Available Credits: " .. CurrentCredits)
    CreditBalanceLabel:SetPos( Vector( 350, 25, 0 ) )

    RedemptionResultLabel = SGUI:Create( "Label", Panel )
    RedemptionResultLabel:SetAnchor( "CentreMiddle" )
    RedemptionResultLabel:SetFont( Fonts.kAgencyFB_Small )
    RedemptionResultLabel:SetText( "" )
    RedemptionResultLabel:SetPos( Vector( -25, 210, 0 ) )

    -- Shows a preview of the badge
    PreviewImage = SGUI:Create( "Image", Panel )
    PreviewImage:SetAnchor( "CentreMiddle" )
    PreviewImage:SetSize( Vector( 150, 150, 0 ) )
    PreviewImage:SetPos( Vector( 90, -250, 0 ) )

    -- Populate the Sprays Menu
    SpraysList = SGUI:Create( "List", Panel )
    SpraysList:SetAnchor( "CentreMiddle" )
    SpraysList:SetPos( Vector( -250, -250, 0 ) )
    SpraysList:SetColumns( "Spray Name", "Cost" )
    SpraysList:SetSpacing( 0.7, 0.3 )
    SpraysList:SetSize( Vector( 300, 450, 0 ) )
    SpraysList:SetNumericColumn( 2 )
    SpraysList:SetMultiSelect( false )
    SpraysList:SetSecondarySortColumn( 2, 1 )
    SpraysList.ScrollPos = Vector( 0, 30, 0 )
    SpraysList.OnRowSelected = function (Index, Row)
        local SpraySelected = SpraysList:GetSelectedRow()
        if SpraySelected then
            local Path = string.format( "ui/sprays/%s.dds",
                SpraySelected:GetColumnText( 1 ) )
            PreviewImage:SetTexture( Path )
        end
    end

    for ID, RowData in ipairs(SpraysListData) do
        SpraysList:AddRow(RowData.Name,RowData.Cost)
    end

    -- Button for equipping
    EquipButton = SGUI:Create( "Button", Panel )
    EquipButton:SetAnchor( "CentreMiddle" )
    EquipButton:SetSize( Vector( 150, 50, 0 ) )
    EquipButton:SetPos( Vector( -175, 250, 0 ) )
    EquipButton:SetText( "Equip" )
    EquipButton.DoClick = function( Button )
        local SpraySelected = SpraysList:GetSelectedRow()
        if SpraySelected then
            Shared.ConsoleCommand(string.format("sc_equipspray %s",
                SpraySelected:GetColumnText( 1 )))
        end
    end

    -- Button for redemption
    RedemptionButton = SGUI:Create( "Button", Panel )
    RedemptionButton:SetAnchor( "CentreMiddle" )
    RedemptionButton:SetSize( Vector( 150, 50, 0 ) )
    RedemptionButton:SetPos( Vector( 25, 250, 0 ) )
    RedemptionButton:SetText( "Redeem" )
    RedemptionButton.DoClick = function( Button )
        local SpraySelected = SpraysList:GetSelectedRow()
        if SpraySelected then
            Shared.ConsoleCommand(string.format("sc_redeemspray %s",
                SpraySelected:GetColumnText( 1 )))
        end
    end

    if Data and Data.ImportantInformation then
        return true
    end
end

function SpraysTab.OnCleanup( Panel )
    PanelLabel = nil
    RedemptionButton = nil
    PreviewImage = nil
    EquipButton = nil
    SpraysList = nil
    RedemptionResultLabel = nil
    CreditBalanceLabel = nil
    return { ImportantInformation = true }
end

function SpraysTab.Update( Data, NewCurrentCredits )
    local SpraysMenu = Data

    -- Add new sprays to the list
    for ID, RowData in ipairs(SpraysMenu) do
        SpraysListData[ID] = RowData
    end

    -- Remove any sprays from the list that was removed from the menu
    for ID, RowData in ipairs(SpraysListData) do
        if not SpraysMenu[ID] then
			SpraysListData[ID] = nil
		end
    end

    CurrentCredits = NewCurrentCredits
end

function SpraysTab.CreditsMessageUpdate( NewCurrentCredits )
    CurrentCredits = NewCurrentCredits
    CreditBalanceLabel:SetText( "Available Credits: " .. NewCurrentCredits)
end

function SpraysTab.RedeemMessageUpdate( Success )
    if Success then
        RedemptionResultLabel:SetText( "Success!" )
    else
        RedemptionResultLabel:SetText( "Failed!" )
    end
end

function SpraysTab.EquipMessageUpdate( Success )
    if Success then
        RedemptionResultLabel:SetText( "Equipped!" )
    else
        RedemptionResultLabel:SetText( "Failed!" )
    end
end

return SpraysTab
