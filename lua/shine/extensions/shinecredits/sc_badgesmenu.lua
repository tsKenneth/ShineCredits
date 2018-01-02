-- ============================================================================
-- ============= Badges Redemption System =====================================
-- ============================================================================
-- Allows managing and redemption of badges

local Shine = Shine
local BadgesMenu = { _version = "0.1.0" }
local sc_json = require("shine/extensions/shinecredits/sc_jsonfileio")
local sc_notification = require("shine/extensions/shinecredits/sc_notification")

-- ============================================================================
-- Default Config
-- ============================================================================
BadgesMenu.Settings =
{
    Enabled = true,
    ReservedBadges = nil,
    ItemsPerPage = 10,
    Commands = {
        AddBadgeToMenu = {Console = "sh_addbadge", Chat = "addbadge"},
        RemoveBadgeFromMenu = {Console = "sh_removebadge", Chat = "removebadge"},
        ViewBadgesMenu = {Console = "sh_viewbadge", Chat = "viewbadge"}
    }
}

BadgesMenu.MenuFile = {}
BadgesMenu.BadgesMenuFile = {}

-- ============================================================================
-- BadgesMenu.Initialise:
-- Initialise the Badges Redemption Menu
-- ============================================================================
function BadgesMenu:Initialise(RedemptionsMenuSettings, Plugin)
    if RedemptionsMenuSettings
        and RedemptionsMenuSettings.BadgesMenu.Enabled then
        self.FilePath = RedemptionsMenuSettings.FilePath
        self.Settings = RedemptionsMenuSettings.BadgesMenu
        self.MenuFile = self:LoadBadgesMenu()

        if self.MenuFile.Badges then
            self.BadgesMenuFile = self.MenuFile.Badges
        end

        self:CreateBadgeMenuCommands(Plugin)
        return true
    else
        error("ShineCredits sc_badgesmenu.lua: An error has occurred during "
            .. "initilisation, badges menu and redemption will not be enabled")
        self.Settings.Enabled = false
        return false
    end
end
-- ============================================================================
-- FileIO Subsystem:
-- Saves and loads badges menu
-- ============================================================================

function BadgesMenu:LoadBadgesMenu()
    return sc_json.LoadTable(self.FilePath)
end

function BadgesMenu:SaveBadgesMenu()
    self.MenuFile.Badges = self.BadgesMenuFile
    return sc_json.SaveTable(self.MenuFile,self.FilePath)
end

-- ============================================================================
-- Badges Menu system:
-- Shows a list of redeemable badges, and handle badges redemption
-- ============================================================================

-- ============================================================================
-- Commands:
-- Navigate the Badges Menu System
-- ============================================================================

function BadgesMenu:CreateBadgeMenuCommands(Plugin)
    local Settings = self.Settings
    local Commands = Settings.Commands
    local LocalBadgesMenu = self.BadgesMenuFile

    -- ====== View Badges ======
    local function ViewItemMenu( Client , Page)
        local LocalPlayer = Client:GetControllingPlayer()
        local ItemIndex = 1
        local PageString = string.format("\n| %5s | %50s | %80s | %10s |\n",
            "Index","Name", "Description", "Cost")

        if (Page-1)*10 > table.Count( LocalBadgesMenu ) then
            sc_notification:ConsoleMessage(Client, "No items on this page!")
        end

        for Name, Badge in pairs( LocalBadgesMenu ) do
            PageString = PageString .. string.format("| %7s | %50s | %80s | %10s |\n",
                ItemIndex, Name, Badge.Description, Badge.Cost)
            ItemIndex = ItemIndex + 1
        end
        sc_notification:ConsoleMessage(LocalPlayer, PageString)
    end

    local ViewItemMenuCommand = Plugin:BindCommand( Commands.ViewBadgesMenu.Console,
        Commands.ViewBadgesMenu.Chat, ViewItemMenu )
    ViewItemMenuCommand:AddParam{ Type = "number", Optional = true, Default = 1, Help = "Page Number" }
    ViewItemMenuCommand:Help( "View badges redeemable with credits." )

    -- ====== Add Badges ======
    local function AddBadge(Client, BadgeNameArg, DescriptionArg, CostArg)
        local LocalPlayer = Client:GetControllingPlayer()
        local ReturnMessage = ""

        if CostArg == nil or CostArg < 0 then
            return false
        end

        if Settings.ReservedBadges then
            for _, badge in ipairs(Settings.ReservedBadges) do
                if badge == BadgeNameArg then
                    ReturnMessage = "Badge "
                        .. BadgeNameArg .. " is a reserved badge;" ..
                        "Badge will not be added"
                    sc_notification:Notify(LocalPlayer, ReturnMessage)
                    sc_notification:ConsoleMessage(LocalPlayer, ReturnMessage)
                    return false
                end
            end
        end

        LocalBadgesMenu[BadgeNameArg] = {
            Description = DescriptionArg,
            Cost = CostArg}

        ReturnMessage = "Badge "
            .. BadgeNameArg .. " had been added to menu."

        sc_notification:Notify(LocalPlayer, ReturnMessage)
        sc_notification:ConsoleMessage(LocalPlayer, ReturnMessage)
        self:SaveBadgesMenu()
    end

	local AddBadgeCommand = Plugin:BindCommand( Commands.AddBadgeToMenu.Console,
        Commands.AddBadgeToMenu.Chat, AddBadge )
    AddBadgeCommand:AddParam{ Type = "string", Help = "Badge Name:String" }
    AddBadgeCommand:AddParam{ Type = "string", Help = "Description:String" }
    AddBadgeCommand:AddParam{ Type = "number", Help = "Cost:Integer" }
	AddBadgeCommand:Help( "Adds a new badge to the menu with the badge name, description and cost provided." )

    -- ====== Remove Badges ======
    local function RemoveBadge(Client, BadgeNameArg)
        local LocalPlayer = Client:GetControllingPlayer()
        local ReturnMessage = ""

        if LocalBadgesMenu.BadgeNameArg then
            LocalBadgesMenu.BadgeNameArg = nil
            ReturnMessage = "Badge "
                .. BadgeNameArg .. " removed."
        else
            ReturnMessage = "Invalid badge "
                .. BadgeNameArg .. " not found."
        end

        sc_notification:Notify(Client:GetControllingPlayer(),ReturnMessage)
        sc_notification:ConsoleMessage(LocalPlayer, ReturnMessage)
        self:SaveBadgesMenu()
    end

    local RemoveBadgeCommand = Plugin:BindCommand( Commands.RemoveBadgeFromMenu.Console,
        Commands.RemoveBadgeFromMenu.Chat, RemoveBadge )
    RemoveBadgeCommand:AddParam{ Type = "string", Help = "Badge Name:String" }
	RemoveBadgeCommand:Help( "Removes an Badge from the menu with the badge name specified." )
end

return BadgesMenu
