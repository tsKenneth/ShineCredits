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
SpraysTab.SpraysListData = {}
SpraysTab.SpraysPreviewImages = {}
SpraysTab.RedeemCommand = "sc_redeemspray"
SpraysTab.EquipCommand = "sc_equipspray"
SpraysTab.CurrentCredits = 0

function SpraysTab.OnInit( Panel, Data )
    SpraysTab.PanelLabel = SGUI:Create( "Label", Panel )
    SpraysTab.PanelLabel:SetFont( Fonts.kAgencyFB_Small )
    SpraysTab.PanelLabel:SetText( "Sprays Menu" )
    SpraysTab.PanelLabel:SetPos( Vector( 20, 25, 0 ) )

    SpraysTab.CreditBalanceLabel = SGUI:Create( "Label", Panel )
    SpraysTab.CreditBalanceLabel:SetFont( Fonts.kAgencyFB_Small )
    SpraysTab.CreditBalanceLabel:SetText( "Available Credits: " .. SpraysTab.CurrentCredits)
    SpraysTab.CreditBalanceLabel:SetPos( Vector( 350, 25, 0 ) )

    SpraysTab.RedemptionResultLabel = SGUI:Create( "Label", Panel )
    SpraysTab.RedemptionResultLabel:SetAnchor( "CentreMiddle" )
    SpraysTab.RedemptionResultLabel:SetFont( Fonts.kAgencyFB_Small )
    SpraysTab.RedemptionResultLabel:SetText( "" )
    SpraysTab.RedemptionResultLabel:SetPos( Vector( -25, 210, 0 ) )

    -- Shows a preview of the badge
    SpraysTab.PreviewImage = SGUI:Create( "Image", Panel )
    SpraysTab.PreviewImage:SetAnchor( "CentreMiddle" )
    SpraysTab.PreviewImage:SetSize( Vector( 150, 150, 0 ) )
    SpraysTab.PreviewImage:SetPos( Vector( 90, -250, 0 ) )

    -- Populate the Sprays Menu
    SpraysTab.SpraysList = SGUI:Create( "List", Panel )
    SpraysTab.SpraysList:SetAnchor( "CentreMiddle" )
    SpraysTab.SpraysList:SetPos( Vector( -250, -250, 0 ) )
    SpraysTab.SpraysList:SetColumns( "Spray Name", "Cost" )
    SpraysTab.SpraysList:SetSpacing( 0.7, 0.3 )
    SpraysTab.SpraysList:SetSize( Vector( 300, 450, 0 ) )
    SpraysTab.SpraysList:SetNumericColumn( 2 )
    SpraysTab.SpraysList:SetMultiSelect( false )
    SpraysTab.SpraysList:SetSecondarySortColumn( 2, 1 )
    SpraysTab.SpraysList:SortRows( 2 )
    SpraysTab.SpraysList.ScrollPos = Vector( 0, 30, 0 )
    SpraysTab.SpraysList.OnRowSelected = function (Index, Row)
        local SpraySelected = SpraysTab.SpraysList:GetSelectedRow()
        if SpraySelected then
            local Path = string.format( "ui/sprays/%s.dds",
                SpraySelected:GetColumnText( 1 ) )
            SpraysTab.PreviewImage:SetTexture( Path )
        end
    end

    for ID, RowData in ipairs(SpraysTab.SpraysListData) do
        SpraysTab.SpraysList:AddRow(RowData.Name,RowData.Cost)
    end

    -- Button for equipping
    SpraysTab.EquipButton = SGUI:Create( "Button", Panel )
    SpraysTab.EquipButton:SetAnchor( "CentreMiddle" )
    SpraysTab.EquipButton:SetSize( Vector( 150, 50, 0 ) )
    SpraysTab.EquipButton:SetPos( Vector( -175, 250, 0 ) )
    SpraysTab.EquipButton:SetText( "Equip" )
    SpraysTab.EquipButton.DoClick = function( Button )
        local SpraySelected = SpraysTab.SpraysList:GetSelectedRow()
        if SpraySelected then
            Shared.ConsoleCommand(string.format(SpraysTab.EquipCommand .. " \"%s\"",
                SpraySelected:GetColumnText( 1 )))
        end
    end

    -- Button for redemption
    SpraysTab.RedemptionButton = SGUI:Create( "Button", Panel )
    SpraysTab.RedemptionButton:SetAnchor( "CentreMiddle" )
    SpraysTab.RedemptionButton:SetSize( Vector( 150, 50, 0 ) )
    SpraysTab.RedemptionButton:SetPos( Vector( 25, 250, 0 ) )
    SpraysTab.RedemptionButton:SetText( "Redeem" )
    SpraysTab.RedemptionButton.DoClick = function( Button )
        local SpraySelected = SpraysTab.SpraysList:GetSelectedRow()
        if SpraySelected then
            Shared.ConsoleCommand(string.format(SpraysTab.RedeemCommand .. " \"%s\"",
                SpraySelected:GetColumnText( 1 )))
        end
    end

    if Data and Data.ImportantInformation then
        return true
    end
end

function SpraysTab.OnCleanup( Panel )
    SpraysTab.PanelLabel = nil
    SpraysTab.RedemptionButton = nil
    SpraysTab.PreviewImage = nil
    SpraysTab.EquipButton = nil
    SpraysTab.SpraysList = nil
    SpraysTab.RedemptionResultLabel = nil
    SpraysTab.CreditBalanceLabel = nil
    return { ImportantInformation = true }
end

function SpraysTab.Update( Data, NewCurrentCredits )
    local SpraysMenu = Data

    -- Add new sprays to the list
    for ID, RowData in ipairs(SpraysMenu) do
        SpraysTab.SpraysListData[ID] = RowData
    end

    -- Remove any sprays from the list that was removed from the menu
    for ID, RowData in ipairs(SpraysTab.SpraysListData) do
        if not SpraysMenu[ID] then
			SpraysListData[ID] = nil
		end
    end

    SpraysTab.CurrentCredits = NewCurrentCredits
end

function SpraysTab.CreditsMessageUpdate( NewCurrentCredits )
    SpraysTab.CurrentCredits = NewCurrentCredits
end

function SpraysTab.RedeemMessageUpdate( Success, NewCurrentCredits )
    if Success then
        SpraysTab.RedemptionResultLabel:SetText( "Success!" )
    else
        SpraysTab.RedemptionResultLabel:SetText( "Failed!" )
    end
end

function SpraysTab.EquipMessageUpdate( Success )
    if Success then
        SpraysTab.RedemptionResultLabel:SetText( "Equipped!" )
    else
        SpraysTab.RedemptionResultLabel:SetText( "Failed!" )
    end
end

function SpraysTab.UpdateRedeemCommand( Command )
    SpraysTab.RedeemCommand = Command
end

function SpraysTab.UpdateEquipCommand( Command )
    SpraysTab.EquipCommand = Command
end


return SpraysTab
