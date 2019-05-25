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
local BadgesTab = require("shine/extensions/shinecredits/view/tabs/badgestab")
local CommandItemsTab = require("shine/extensions/shinecredits/view/tabs/commanditemstab")
local PlayerSkinsTab = require("shine/extensions/shinecredits/view/tabs/playerskinstab")
local CommanderSkinsTab = require("shine/extensions/shinecredits/view/tabs/commanderskinstab")
local SpraysTab = require("shine/extensions/shinecredits/view/tabs/spraystab")
local SettingsTab = require("shine/extensions/shinecredits/view/tabs/settingstab")
local EffectsTab = require("shine/extensions/shinecredits/view/tabs/effectstab")

local Shine = Shine
local SGUI = Shine.GUI

local CreditsMenu = {}
local CreditsMenuData = {}
SGUI:AddMixin( CreditsMenu, "Visibility" )

CreditsMenu.Commands = {}
CreditsMenu.Tabs = {}
CreditsMenu.Data = {}

CreditsMenu.EasingTime = 0.25

function CreditsMenu:Initialise( Client, Plugin )
    self.Client = Client
    self.Plugin = Plugin

    -- Use custom skin for CreditsMenu
    Shine.GUI.SkinManager:SetSkin("creditsmenu")

    -- Prevent cursor bug when commander log in and log out
    Shine.Hook.Add( "OnCommanderLogout", "CreditsMenuLogout", function()
    	CreditsMenu:Close()
    end )
    Shine.Hook.Add( "OnCommanderLogin", "CreditsMenuLogin", function()
    	CreditsMenu:Close()
    end )

    self:InitialiseTabs()
end

function CreditsMenu:InitialiseTabs()
    -- Don't mind the prefix, it is used to sort the items
    self.Tabs.A_Badges = BadgesTab
    self.Tabs.B_Patches = PatchesTab
    self.Tabs.C_PlayerSkins = PlayerSkinsTab
    self.Tabs.D_CommanderSkins = CommanderSkinsTab
    self.Tabs.E_Sprays = SpraysTab
    self.Tabs.F_Effects = EffectsTab
    self.Tabs.G_CommandItems = CommandItemsTab
    self.Tabs.H_Settings = SettingsTab

    CreditsMenuData.Badges = {}
    CreditsMenuData.Patches = {}
    CreditsMenuData.Sprays = {}
    CreditsMenuData.PlayerSkins = {}
    CreditsMenuData.CommanderSkins = {}
    CreditsMenuData.Effects = {}
    CreditsMenuData.CommandItems = {}
    CreditsMenuData.Settings = {}

end

-- ============================================================================
-- Network Messages and Data Table
-- ============================================================================

function CreditsMenu:ReceiveMenuCommand( Data )
    BadgesTab.UpdateRedeemCommand( Data.RedeemBadge )
    SpraysTab.UpdateRedeemCommand( Data.RedeemSpray )
    SpraysTab.UpdateEquipCommand( Data.EquipSpray )
end

function CreditsMenu:ReceiveOpenCreditsMenu( Data )
    self.Data.CurrentCredits = Data.CurrentCredits
    self.Data.TotalCredits = Data.TotalCredits
    self:SetIsVisible( true, false )
end

function CreditsMenu:ReceiveUpdateCredits( Data )
    BadgesTab.CreditsMessageUpdate(Data.CurrentCredits)
    PlayerSkinsTab.CreditsMessageUpdate(Data.CurrentCredits)
    CommanderSkinsTab.CreditsMessageUpdate(Data.CurrentCredits)
    SpraysTab.CreditsMessageUpdate(Data.CurrentCredits)
    CommandItemsTab.CreditsMessageUpdate(Data.CurrentCredits)
    EffectsTab.CreditsMessageUpdate(Data.CurrentCredits)
    SettingsTab.CreditsMessageUpdate(Data.CurrentCredits)
    PatchesTab.CreditsMessageUpdate(Data.CurrentCredits)
end

function CreditsMenu:ReceiveGUINotify( Data )
    SGUI.NotificationManager.AddNotification(
        Shine.NotificationType.INFO, Data.Message, Data.Duration )
end

function CreditsMenu:ReceiveBadgeData( Data )
    table.insert(CreditsMenuData.Badges, Data)
end

function CreditsMenu:ReceiveSprayData( Data )
    table.insert(CreditsMenuData.Sprays, Data)
end

-- ============================================================================
-- Window Opening
-- ============================================================================
function CreditsMenu:Create()
	self.Created = true

    -- Obtain the user's screen size to scale the Window
    screenWidth = self.Client.GetScreenWidth()
    screenHeight = self.Client.GetScreenHeight()
    windowSize = Vector( 900, screenHeight, 0 )
    windowPos = Vector( 0, 0, 0 )

    -- Create the main tab panel
	local Window = SGUI:Create( "TabPanel" )
	Window:SetAnchor( "TopLeft" )
	Window:SetPos( windowPos )
	Window:SetSize( windowSize )

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
        windowPos, IgnoreAnim )
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
                -self.Client.GetScreenWidth() + TargetPos.x, TargetPos.y ), 0,
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
        Data.Update(CreditsMenuData[Name], self.Data.CurrentCredits)
		local Tab = Window:AddTab( Data.TabName, Data.OnInit )
		Data.TabObj = Tab
	end
end

return CreditsMenu
