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
SpraysTab.TabName = "Sprays"
SpraysTab.SpraysListData = {}
SpraysTab.PurchasedSprays = {}
SpraysTab.SpraysPreviewImages = {}
SpraysTab.RedeemCommand = "sc_redeemspray"
SpraysTab.EquipCommand = "sc_equipspray"
SpraysTab.EquippedSpray = ""
SpraysTab.CurrentCredits = 0

function SpraysTab.OnInit( Panel, Data )
    SpraysTab.PanelLabel = SGUI:Create( "Label", Panel )
    SpraysTab.PanelLabel:SetFont( Fonts.kAgencyFB_Small )
    SpraysTab.PanelLabel:SetText( "Sprays Menu" )
    SpraysTab.PanelLabel:SetAnchor( "TopLeft" )
    SpraysTab.PanelLabel:SetPos( Vector( 20, 25, 0 ) )

    SpraysTab.CreditBalanceLabel = SGUI:Create( "Label", Panel )
    SpraysTab.CreditBalanceLabel:SetFont( Fonts.kAgencyFB_Small )
    SpraysTab.CreditBalanceLabel:SetText( "Available Credits: "
        .. SpraysTab.CurrentCredits)
    SpraysTab.CreditBalanceLabel:SetAnchor( "TopRight" )
    SpraysTab.CreditBalanceLabel:SetPos( Vector( -200, 25, 0 ) )

    SpraysTab.RedemptionResultLabel = SGUI:Create( "Label", Panel )
    SpraysTab.RedemptionResultLabel:SetAnchor( "CentreMiddle" )
    SpraysTab.RedemptionResultLabel:SetFont( Fonts.kAgencyFB_Small )
    SpraysTab.RedemptionResultLabel:SetText( "" )
    SpraysTab.RedemptionResultLabel:SetPos( Vector( -25, 210, 0 ) )

    -- Shows a preview of the spray
    SpraysTab.PreviewImage = SGUI:Create( "Image", Panel )
    SpraysTab.PreviewImage:SetAnchor( "TopRight" )
    SpraysTab.PreviewImage:SetSize( Vector( 150, 150, 0 ) )
    SpraysTab.PreviewImage:SetPos( Vector( -200, 100, 0 ) )

    -- Populate the Sprays Menu
    SpraysTab.SpraysList = SGUI:Create( "List", Panel )
    SpraysTab.SpraysList:SetAnchor( "TopLeft" )
    SpraysTab.SpraysList:SetPos( Vector( 20, 100, 0 ) )
    SpraysTab.SpraysList:SetColumns( "Spray Name", "Cost" )
    SpraysTab.SpraysList:SetSpacing( 0.7, 0.3 )
    SpraysTab.SpraysList:SetSize( Vector( 400, 750, 0 ) )
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
    SpraysTab.EquipButton:SetAnchor( "BottomMiddle" )
    SpraysTab.EquipButton:SetSize( Vector( 150, 50, 0 ) )
    SpraysTab.EquipButton:SetPos( Vector( -175, -100, 0 ) )
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
    SpraysTab.RedemptionButton:SetAnchor( "BottomMiddle" )
    SpraysTab.RedemptionButton:SetSize( Vector( 150, 50, 0 ) )
    SpraysTab.RedemptionButton:SetPos( Vector( 25, -100, 0 ) )
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

-- Set all GUI objects to nil upon closing tab
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

function SpraysTab.UpdateRedeemCommand( Command )
    SpraysTab.RedeemCommand = Command
end

function SpraysTab.UpdateEquipCommand( Command )
    SpraysTab.EquipCommand = Command
end


return SpraysTab
