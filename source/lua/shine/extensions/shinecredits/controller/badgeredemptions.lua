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
        error("ShineCredits CreditsAwarding:CheckConfig() - Error in config, " ..
            "Subsystem requires Credits model to be enabled.")
        CheckFlag = false
    end

    if self.Badges:GetIsEnabled() == false then
        error("ShineCredits CreditsAwarding:CheckConfig() - Error in config, " ..
            "Subsystem requires Badges model to be enabled.")
        CheckFlag = false
    end

    if self.BadgesMenu:GetIsEnabled() == false then
        error("ShineCredits CreditsAwarding:CheckConfig() - Error in config, " ..
            "Subsystem requires BadgesMenu model to be enabled.")
        CheckFlag = false
    end

    return CheckFlag
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
    if Credits:SpendCredits(Player ,
        self.BadgesMenu:GetInfo(NewBadge).Cost) then

        for _,row in ipairs(Settings.BadgeRows) do
            self.Badges:AddBadge(Player, NewBadgeName, row)
        end
        self.Badges:SavePlayerBadges()
        return true
    else
        return false
    end
end


-- ============================================================================
-- Commands:
-- Navigate the Badges Menu System
-- ============================================================================

function BadgeRedemptions:CreateMenuCommands(Plugin)
    local Settings = self.Settings
    local Commands = Settings.Commands

    -- ====== Redeem Badges ======
    local function RedeemBadge( Client , BadgeNameArg)
        local LocalPlayer = Client:GetControllingPlayer()
        local ReturnMessage = ""

        if self.BadgesMenu:GetInfo( BadgeNameArg ) then
            if self:RedeemBadge(LocalPlayer,BadgeNameArg) then
                ReturnMessage = "Badge " .. BadgeNameArg ..
                    " succesfully redeemed!" ..
                    " (Will take effect after map changes)"
            else
                ReturnMessage = "You already own the badge "..
                    "or you have insufficient credits to redeem the badge ("
                    .. BadgeNameArg ..")"
            end

        else
            ReturnMessage = "There are no badges with name " .. BadgeNameArg
        end

        self.Notifications:Notify(LocalPlayer, ReturnMessage)
        self.Notifications:ConsoleMessage(LocalPlayer, ReturnMessage)
    end

    local RedeemBadgeCommand = Plugin:BindCommand( Commands.RedeemBadge.Console,
        Commands.RedeemBadge.Chat, RedeemBadge )
    RedeemBadgeCommand:AddParam{ Type = "string", Help = "Badge Name: String" }
    RedeemBadgeCommand:Help( "Redeems the badge with the name specified" )


    -- ====== View Badges ======
    local function ViewItemMenu( Client , Page)
        local LocalPlayer = Client:GetControllingPlayer()
        local ItemIndex = 1
        local LocalBadgesMenu = self.BadgesMenu:GetAllInfo()
        local PageString = string.format("\n| %5s | %50s | %80s | %10s |\n",
            "Index","Name", "Description", "Cost")

        for Name, Badge in pairs( LocalBadgesMenu ) do
            PageString = PageString .. string.format("| %7s | %50s | %80s | %10s |\n",
                ItemIndex, Name, Badge.Description, Badge.Cost)
            ItemIndex = ItemIndex + 1
        end

        PageString = PageString .. "\n type !redeembadge <badgename> to redeem"

        self.Notifications:ConsoleMessage(LocalPlayer, PageString)
    end

    local ViewItemMenuCommand = Plugin:BindCommand( Commands.ViewBadges.Console,
        Commands.ViewBadges.Chat, ViewItemMenu )
    ViewItemMenuCommand:AddParam{ Type = "number", Optional = true, Default = 1, Help = "Page Number:Integer" }
    ViewItemMenuCommand:Help( "View badges redeemable with credits." )

    -- ====== Add Badges ======
    local function AddBadge(Client, BadgeNameArg, DescriptionArg, CostArg)
        local LocalPlayer = Client:GetControllingPlayer()
        local ReturnMessage = ""

        if CostArg == nil or CostArg < 0 then
            ReturnMessage = "Cost cannot be negative."
            self.Notifications:Notify(LocalPlayer, ReturnMessage)
            self.Notifications:ConsoleMessage(LocalPlayer, ReturnMessage)
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
        self.Notifications:ConsoleMessage(LocalPlayer, ReturnMessage)
    end

	local AddBadgeCommand = Plugin:BindCommand( Commands.AddBadge.Console,
        Commands.AddBadge.Chat, AddBadge )
    AddBadgeCommand:AddParam{ Type = "string", Help = "Badge Name:String" }
    AddBadgeCommand:AddParam{ Type = "string", Help = "Description:String" }
    AddBadgeCommand:AddParam{ Type = "number", Help = "Cost:Integer" }
	AddBadgeCommand:Help( "Adds a new badge to the menu with the badge name, description and cost provided." )

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
        self.Notifications:ConsoleMessage(LocalPlayer, ReturnMessage)
    end

    local RemoveBadgeCommand = Plugin:BindCommand( Commands.RemoveBadge.Console,
        Commands.RemoveBadge.Chat, RemoveBadge )
    RemoveBadgeCommand:AddParam{ Type = "string", Help = "Badge Name:String" }
	RemoveBadgeCommand:Help( "Removes an Badge from the menu with the badge name specified." )
end

return BadgeRedemptions
