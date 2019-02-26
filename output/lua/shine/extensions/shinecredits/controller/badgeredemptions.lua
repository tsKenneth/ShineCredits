-- ============================================================================
--
-- BadgeRedemptions (Controller)
--      Allows managing and redemption of badges
--
-- Dependencies: Requires badges.lua, BadgesMenu.lua
-- and credits.lua to be enabled
-- ============================================================================

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Initialisation
-- ----------------------------------------------------------------------------
-- ============================================================================

local BadgeRedemptions = { _version = "0.1.0" }

BadgeRedemptions.RedemptionsFile = {}

-- ============================================================================
-- BadgeRedemptions:Initialise
-- Initialise the Badges Redemption Menu
-- ============================================================================
function BadgeRedemptions:Initialise(BadgeRedemptionsConfig,
    Notifications, Badges, BadgesMenu, Credits, Plugin)
    -- Load Config File
    self.Settings = BadgeRedemptionsConfig

    -- Checks if Config debug mode is enabled. Returns false if failed checking
    -- Debug mode can be turned off to improve performance
    if self.Settings.Enabled then
        self.Notifications = Notifications
        self.Credits = Credits
        self.Badges = Badges
        self.BadgesMenu = BadgesMenu
        self.Plugin = Plugin

        if self.Settings.ConfigDebug and not self:CheckConfig(self.Settings) then
            self.Settings.Enabled = false
            return false
        else
            self:CreateMenuCommands(Plugin)
            return true
        end
    else
        return false
    end
end

-- ============================================================================
-- BadgeRedemptions:CheckConfig
-- Checks the config for correctness
-- ============================================================================

function BadgeRedemptions:CheckConfig(CreditsAwardingConfig)
    local CheckFlag = true

    --- Check Dependencies
    if self.Credits:GetIsEnabled() == false then
        Shine:Print("ShineCredits BadgeRedemptions:CheckConfig() - Error in config, " ..
            "Subsystem requires Credits model to be enabled.")
        CheckFlag = false
    end

    if self.Badges:GetIsEnabled() == false then
        Shine:Print("ShineCredits BadgeRedemptions:CheckConfig() - Error in config, " ..
            "Subsystem requires Badges model to be enabled.")
        CheckFlag = false
    end

    if self.BadgesMenu:GetIsEnabled() == false then
        Shine:Print("ShineCredits BadgeRedemptions:CheckConfig() - Error in config, " ..
            "Subsystem requires BadgesMenu model to be enabled.")
        CheckFlag = false
    end

    return CheckFlag
end

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Hooks
-- ----------------------------------------------------------------------------
-- ============================================================================

-- ============================================================================
-- SprayRedemptions:MapChange
-- Save player sprays and the spray menu on map change
-- ============================================================================
function BadgeRedemptions:MapChange()
    self.BadgesMenu:SaveBadgesMenu()
    self.Badges:SavePlayerBadges()
end

-- ============================================================================
-- Functions
-- ============================================================================
-- ============================================================================
-- BadgeRedemptions:AddBadge
-- Adds a new badge to the badges menu
-- ============================================================================

function BadgeRedemptions:AddBadge( BadgeNameArg, DescriptionArg, CostArg )
    if self:CheckIfBadgeIsReserved(BadgeNameArg) then
        return false
    else
        self.BadgesMenu:AddBadge(BadgeNameArg, DescriptionArg, CostArg)
        return true
    end
end

-- ============================================================================
-- BadgeRedemptions:RemoveBadge
-- Removes a badge from the badges menu
-- ============================================================================

function BadgeRedemptions:RemoveBadge( BadgeNameArg )
    return self.BadgesMenu:RemoveBadge(BadgeNameArg)
end

-- ============================================================================
-- BadgeRedemptions:CheckIfBadgeIsReserved
-- Checks if the badge is reserved
-- ============================================================================

function BadgeRedemptions:CheckIfBadgeIsReserved( BadgeName )
    local Settings = self.Settings

    if Settings.ReservedBadges then
        for _, badge in ipairs(Settings.ReservedBadges) do
            if badge == BadgeName then
                return true
            end
        end
    end
    return false
end

-- ============================================================================
-- BadgeRedemptions:RedeemBadge
-- Insert the redeemed badge into the player's userconfig
-- ============================================================================

function BadgeRedemptions:RedeemBadge( Player, NewBadge )
    local Settings = self.Settings
    -- Checks if player already owns the badge
    if self.Badges:GetIfPlayerHasBadge( Player, NewBadge ) then
        return false
    end

    -- Subtract credits by the cost, return false if insufficient credits
    if self.Credits:SpendPlayerCredits(Player ,
        self.BadgesMenu:GetInfo(NewBadge).Cost) then

        for _,row in ipairs(Settings.BadgeRows) do
            self.Badges:AddBadge(Player, NewBadge, row)
        end
        self.Credits:SaveCredits()
        self.Badges:SavePlayerBadges()
        return true
    else
        return false
    end
end

-- ============================================================================
-- Commands:
-- Navigate the Badges Menu System via the chat or console
-- ============================================================================

function BadgeRedemptions:CreateMenuCommands(LocalPlugin)
    local Settings = self.Settings
    local Commands = Settings.Commands

    -- ====== Redeem Badges ======
    local function RedeemBadge( Client , BadgeNameArg)
        local LocalPlayer = Client:GetControllingPlayer()
        local LocalPlayerCredits = 0
        local ReturnMessage = ""

        if self.BadgesMenu:GetInfo( BadgeNameArg ) then
            if self:RedeemBadge(LocalPlayer,BadgeNameArg) then
                ReturnMessage = "Badge " .. BadgeNameArg ..
                    " succesfully redeemed!" ..
                    " (Will take effect after map changes)"

                LocalPlayerCredits = self.Credits:GetPlayerCredits(
                    LocalPlayer )

                self.Plugin:SendNetworkMessage( Client,
                    "UpdateCredits",{
                CurrentCredits = LocalPlayerCredits.Current,
                TotalCredits = LocalPlayerCredits.Total}, true)

                self.Plugin:SendNetworkMessage( Client,
                    "BadgeRedeemResult",{
                Badge = NewBadge, Result = true}, true)
            else
                ReturnMessage = "You already own the badge "..
                    "or you have insufficient credits to redeem the badge ("
                    .. BadgeNameArg ..")"

                self.Plugin:SendNetworkMessage( Client,
                "BadgeRedeemResult",{
                Badge = NewBadge, Result = false}, false)
            end

        else
            ReturnMessage = "There are no badges with name " .. BadgeNameArg
            self.Plugin:SendNetworkMessage( Client,
            "BadgeRedeemResult",{
            Badge = NewBadge, Result = false}, false)
        end

        self.Notifications:Notify(LocalPlayer, ReturnMessage)
    end

    local RedeemBadgeCommand = LocalPlugin:BindCommand( Commands.RedeemBadge.Console,
        Commands.RedeemBadge.Chat, RedeemBadge,true, true )
    RedeemBadgeCommand:AddParam{ Type = "string", Help = "Badge Name: String" }
    RedeemBadgeCommand:Help( "Redeems the badge with the name specified" )


    -- ====== View Badges ======
    local function ViewBadges( Client )
        local LocalPlayer = Client:GetControllingPlayer()
        local LocalBadgesMenu = self.BadgesMenu:GetMenu()
        self.Notifications:Notify(LocalPlayer,string.format("%s %s %s",
            "[Name]", "Description -", "Cost"))

        for Name, Badge in pairs( LocalBadgesMenu ) do
            self.Notifications:Notify(LocalPlayer,
                string.format("[%s] %s - %s",
                Name, Badge.Description, Badge.Cost),false)
        end
        self.Notifications:Notify(LocalPlayer,
            "Type !redeembadge <badgename> to redeem.",false)

    end

    local ViewItemMenuCommand = LocalPlugin:BindCommand( Commands.ViewBadges.Console,
        Commands.ViewBadges.Chat, ViewBadges ,true, true )
    ViewItemMenuCommand:Help( "View badges redeemable with credits." )

    -- ====== Add Badges ======
    local function AddBadge(Client, BadgeNameArg, DescriptionArg, CostArg)
        local LocalPlayer = Client:GetControllingPlayer()
        local ReturnMessage = ""

        if CostArg == nil or CostArg < 0 then
            ReturnMessage = "Cost cannot be negative."
            self.Notifications:Notify(LocalPlayer, ReturnMessage)
            return false
        end

        if self:AddBadge(BadgeNameArg, DescriptionArg, CostArg) then
            ReturnMessage = "Badge "
                .. BadgeNameArg .. " had been added to menu."
        else
            ReturnMessage = "Badge " ..
                BadgeNameArg .. " was not added;the badge might be reserved"
        end

        self.Notifications:Notify(LocalPlayer, ReturnMessage)
    end

	local AddBadgeCommand = LocalPlugin:BindCommand( Commands.AddBadge.Console,
        Commands.AddBadge.Chat, AddBadge )
    AddBadgeCommand:AddParam{ Type = "string", Help = "Badge Name:String" }
    AddBadgeCommand:AddParam{ Type = "string", Help = "Description:String" }
    AddBadgeCommand:AddParam{ Type = "number", Help = "Cost:Integer" }
	AddBadgeCommand:Help( "Adds a new badge to the menu with the badge name," ..
        "description and cost provided." )

    -- ====== Remove Badges ======
    local function RemoveBadge(Client, BadgeNameArg)
        local LocalPlayer = Client:GetControllingPlayer()
        local ReturnMessage = ""

        if self:RemoveBadge(BadgeNameArg) then
            ReturnMessage = "Badge "
                .. BadgeNameArg .. " removed."
        else
            ReturnMessage = "Invalid badge "
                .. BadgeNameArg .. " not found."
        end

        self.Notifications:Notify(LocalPlayer,ReturnMessage)
    end

    local RemoveBadgeCommand = LocalPlugin:BindCommand( Commands.RemoveBadge.Console,
        Commands.RemoveBadge.Chat, RemoveBadge )
    RemoveBadgeCommand:AddParam{ Type = "string", Help = "Badge Name:String" }
	RemoveBadgeCommand:Help( "Removes an Badge from the menu with the badge name specified." )

end

return BadgeRedemptions
