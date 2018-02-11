-- ============================================================================
--
-- Credits Menu
--      A user-friendly GUI for players to easily preview and redeem items
--      Serves as the main hub for all the submenus
--      All views are client sided.
--
-- ============================================================================

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Initialisation
-- ----------------------------------------------------------------------------
-- ============================================================================
local InfoTab = require("shine/extensions/shinecredits/view/tabs/infotab")
local BadgesTab = require("shine/extensions/shinecredits/view/tabs/badgestab")
local CommandItemsTab = require("shine/extensions/shinecredits/view/tabs/commanditemstab")
local SkinsTab = require("shine/extensions/shinecredits/view/tabs/skinstab")
local SpraysTab = require("shine/extensions/shinecredits/view/tabs/spraystab")

local Shine = Shine
local SGUI = Shine.GUI

local CreditsMenu = {}
local CreditsMenuData = {}
SGUI:AddMixin( CreditsMenu, "Visibility" )

CreditsMenu.Commands = {}
CreditsMenu.Tabs = {}

CreditsMenu.Pos = Vector( -325, -325, 0 )
CreditsMenu.Size = Vector( 700, 700, 0 )

CreditsMenu.EasingTime = 0.25

function CreditsMenu:Initialise( Client, Plugin )
    self.Client = Client
    self.Plugin = Plugin
    self:InitialiseTabs()
end

function CreditsMenu:InitialiseTabs()
    self.Tabs.Info = InfoTab
    self.Tabs.Badges = BadgesTab
    self.Tabs.Sprays = SpraysTab
    self.Tabs.CommandItems = CommandItemsTab
    self.Tabs.Skins = SkinsTab

    CreditsMenuData.Badges = {}
    CreditsMenuData.Skins = {}
    CreditsMenuData.CommandItems = {}
    CreditsMenuData.Sprays = {}
    CreditsMenuData.Info = {}
end

-- ============================================================================
-- Network Messages and Data Table
-- ============================================================================

function CreditsMenu:ReceiveOpenCreditsMenu( Data )
    self:SetIsVisible( true, false )
end

function CreditsMenu:ReceiveBadgeData( Data )
    table.insert(CreditsMenuData.Badges, Data)
end

function CreditsMenu:ReceiveBadgeRedeemResult( Data )
    BadgesTab.RedeemMessageUpdate( Data.Result )
end

function CreditsMenu:ReceiveSprayData( Data )
    table.insert(CreditsMenuData.Sprays, Data)
end

function CreditsMenu:ReceiveSprayRedeemResult( Data )
    SpraysTab.RedeemMessageUpdate( Data.Result )
end

function CreditsMenu:ReceiveSprayEquipResult( Data )
    SpraysTab.EquipMessageUpdate( Data.Result )
end

-- ============================================================================
-- Window Opening
-- ============================================================================
function CreditsMenu:Create()
	self.Created = true

	local Window = SGUI:Create( "TabPanel" )
	Window:SetAnchor( "CentreMiddle" )
	Window:SetPos( self.Pos )
	Window:SetSize( self.Size )

	self.Window = Window

    Window.OnPreTabChange = function( LocalWindow )
		if not LocalWindow.ActiveTab then return end

		local Tab = LocalWindow.Tabs[ Window.ActiveTab ]

		if not Tab then return end

		self:OnTabCleanup( Window, Tab.Name )
	end

	self:PopulateTabs( Window )

	Window:AddCloseButton()
	Window.OnClose = function()
		self:Close()
		return true
	end
end

function CreditsMenu:SetIsVisible( Bool, IgnoreAnim )
	if not self.Created then
		self:Create()
	end

	self:AnimateVisibility( self.Window, Bool, self.Visible, self.EasingTime,
        self.Pos, IgnoreAnim )
	self.Visible = Bool
end

function CreditsMenu:GetIsVisible()
	return self.Visible or false
end

-- ============================================================================
-- Window Closing and Destroying
-- ============================================================================

function CreditsMenu:PlayerKeyPress( Key, Down )
	if not self.Visible then return end

	if Key == InputKey.Escape and Down then
		self:Close()

		return true
	end
end

function CreditsMenu:Close()
	self:ForceHide()

	if self.ToDestroyOnClose then
		for Panel in pairs( self.ToDestroyOnClose ) do
			if Panel:IsValid() then
				Panel:Destroy()
			end

			self.ToDestroyOnClose[ Panel ] = nil
		end
	end
end

function CreditsMenu:DestroyOnClose( Object )
	self.ToDestroyOnClose = self.ToDestroyOnClose or {}
	self.ToDestroyOnClose[ Object ] = true
end

function CreditsMenu:DontDestroyOnClose( Object )
	if not self.ToDestroyOnClose then return end
	self.ToDestroyOnClose[ Object ] = nil
end

-- ============================================================================
-- Window Animations
-- ============================================================================

function CreditsMenu:AnimateVisibility( Window, Show, Visible,
    EasingTime, TargetPos, IgnoreAnim )
	local IsAnimated = Shine.Config.AnimateUI and not IgnoreAnim

	if not Show and IsAnimated then
		Shine.Timer.Simple( EasingTime, function()
			if not SGUI.IsValid( Window ) then return end
			Window:SetIsVisible( false )
		end )
	else
		Window:SetIsVisible( Show )
	end

	if Show and not Visible then
		if IsAnimated then
			Window:SetPos( Vector2(
                -self.Client.GetScreenWidth() + TargetPos.x, TargetPos.y ) )
			Window:MoveTo( nil, nil, TargetPos, 0, EasingTime )
		else
			Window:SetPos( TargetPos )
		end

		SGUI:EnableMouse( true )
	elseif not Show and Visible then
		SGUI:EnableMouse( false )

		if IsAnimated then
			Window:MoveTo( nil, nil, Vector2(
                self.Client.GetScreenWidth() - TargetPos.x, TargetPos.y ), 0,
				EasingTime, nil, math.EaseIn )
		end
	end
end


-- ============================================================================
-- Tabs
-- ============================================================================

function CreditsMenu:AddTab( Name, Data )
	self.Tabs[ Name ] = Data

	if self.Created then
		local ActiveTab = self.Window:GetActiveTab()

		--A bit brute force, but its the easiest way to preserve tab order.
		for i = 1, self.Window.NumTabs do
			self.Window:RemoveTab( 1 )
		end

		self:PopulateTabs( self.Window )

		local WindowTabs = self.Window.Tabs
		for i = 1, #WindowTabs do
			local Tab = WindowTabs[ i ]
			if Tab.Name == ActiveTab.Name then
				Tab.TabButton:DoClick()
				break
			end
		end
	end
end

function CreditsMenu:RemoveTab( Name )
	local Data = self.Tabs[ Name ]

	if not Data then return end

	--Remove the actual menu tab.
	if Data.TabObj and SGUI.IsValid( Data.TabObj.TabButton ) then
		self.Window:RemoveTab( Data.TabObj.TabButton.Index )
	end

	self.Tabs[ Name ] = nil
end


function CreditsMenu:OnTabCleanup( Window, Name )
	local Tab = self.Tabs[ Name ]
	if not Tab then return end

	local OnCleanup = Tab.OnCleanup
	if not OnCleanup then return end

	local Ret = OnCleanup( Window.ContentPanel )
	if Ret then
		Tab.Data = Ret
	end
end

function CreditsMenu:PopulateTabs( Window )
	for Name, Data in SortedPairs( self.Tabs ) do
        Data.Update(CreditsMenuData[Name])
		local Tab = Window:AddTab( Name, Data.OnInit )
		Data.TabObj = Tab
	end
end

return CreditsMenu
