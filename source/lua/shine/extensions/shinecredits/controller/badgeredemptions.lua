-- ============================================================================
--
-- BadgeRedemptions (Controller)
--      Allows managing and redemption of badges
--
-- ============================================================================

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Initialisation
-- ----------------------------------------------------------------------------
-- ============================================================================

local Shine = Shine
local BadgeRedemptions = { _version = "0.1.0" }

BadgeRedemptions.Settings =
{
    Badges = {
        Enabled = true,
        MenuFileName = "ShineCredits_BadgesMenu.json",
        BadgeRows = {3,4,5,6,7,8},
        ReservedBadges = {"level1","level2","level3","level4","level5","level6",
            "level7","level8","level9","level10","level11","level12","level13","level14",
            "level15","level16","level17","level18","level19","level20","level21","level22",
            "level23","level24","level25","level26","level27","level28","level29","level30",
            "level31","level32","level33","level34","level35","level36","level37","level38",
            "level39","level40","level41","level42","level43","level44","level45","level46",
            "level47","level48","level49","level50","level51","level52","level53","level54",
            "level55","bay_red","bay_silver","bay_supporter","bay_gold","bay_platinum"
        },
        ChatItemsPerPage = 10,
        Commands = {
            AddBadgeToMenu = {Console = "sh_addbadge", Chat = "addbadge"},
            RemoveBadgeFromMenu = {Console = "sh_removebadge", Chat = "removebadge"},
            RedeemBadge = {Console = "sh_redeembadge", Chat = "redeembadge"}
        }
    }

}

BadgeRedemptions.MenuFile = {}
BadgeRedemptions.RedemptionsFile = {}

-- ============================================================================
-- BadgeRedemptions:Initialise
-- Initialise the Badges Redemption Menu
-- ============================================================================
function BadgeRedemptions:Initialise(StorageConfig, BadgeRedemptionsConfigs,
    Notifications, Plugin)
    if BadgeRedemptionsConfigs
        and BadgeRedemptionsConfigs.Enabled then
        self.Settings = BadgeRedemptionsConfigs

        self.MenuFilePath = StorageConfig.Files.Directory ..
        BadgeRedemptionsConfigs.MenuFileName
        self.RedemptionsFilePath = StorageConfig.Files.Directory ..
        BadgeRedemptionsConfigs.RedemptionsFileName

        self.MenuFile = self:LoadBadgesMenu()
        self.RedemptionsFile = self:LoadBadgesRedemptions()

        self:CreateBadgeMenuCommands(Plugin)
        return true
    else
        error("ShineCredits BadgeRedemptions:Initialise() - An error " ..
            "has occurred during initialisation, badges menu and redemption " ..
            "will not be enabled")
        self.Settings.Enabled = false
        return false
    end
end
-- ============================================================================
-- FileIO Subsystem:
-- Saves and loads badges menu
-- ============================================================================
function BadgeRedemptions:LoadBadgesMenu()
    return Json.LoadTable(self.MenuFile)
end

function BadgeRedemptions:SaveBadgesMenu()
    return Json.SaveTable(self.RedemptionsFile,self.MenuFile)
end

-- ============================================================================
-- Functions
-- ============================================================================
-- ============================================================================
-- BadgeRedemptions:InitPlayer
-- Initialise player to be added into the leveling System
-- ============================================================================
function BadgeRedemptions:InitPlayer( Player )
    -- Initialise local copy of global files
    local Settings = self.Settings

    Shine:SaveUsers( true )

end
-- ============================================================================
-- BadgeRedemptions:RedeemBadge
-- Insert the redeemed badge into the player's userconfig
-- ============================================================================

function BadgeRedemptions:RedeemBadge( Player, NewBadgeName )
    local LocalBadgeRedemptions = self.BadgeRedemptionsFile
    local Settings = self.Settings
    local SteamID = tostring(Player:GetSteamId())

    -- Subtract credits by the cost, return false if insufficient credits
    if not sc_playercredits:SubtractCredits(SteamID ,
        LocalBadgeRedemptions[NewBadgeName].Cost) then
            return false
    end

    local Target = Player:GetClient()
    local Existing, _ = Shine:GetUserData( Target )

    if Existing["Badges"] then
        -- If field has rows like in Badges+
        for i, item in pairs(Existing["Badges"]) do
            if type(item) == "table" then
                for _,k in pairs(Settings.ReservedBadgeRows) do
                    if i ~= k then
                        table.insert(item, NewBadgeName)
                    end
                end
            -- If field doesnt have rows
            else
                table.insert(Existing["Badges"], NewBadgeName)
            end
        end
        return true
    else
        -- If there is only 1 badge
        Existing["Badge"] = NewBadgeName
        return true
    end
end


-- ============================================================================
-- Commands:
-- Navigate the Badges Menu System
-- ============================================================================

function BadgeRedemptions:CreateBadgeMenuCommands(Plugin)
    local Settings = self.Settings
    local Commands = Settings.Commands
    local LocalBadgeRedemptions = self.BadgeRedemptionsFile

    -- ====== Redeem Badges ======
    local function RedeemBadge( Client , BadgeNameArg)
        local LocalPlayer = Client:GetControllingPlayer()
        local Flag = true
        local ReturnMessage = ""

        if LocalBadgeRedemptions[BadgeNameArg] then
            if self:RedeemBadge(LocalPlayer,BadgeNameArg) then
                ReturnMessage = "Badge " .. BadgeNameArg .. " succesfully redeemed!"
                .. "(Will take effect after map changes)"
                Shine:SaveUsers( true )
            else
                ReturnMessage = "Insufficient credits to redeem badge "
                    .. BadgeNameArg
                Flag = false
            end

        else
            ReturnMessage = "There are no badges with name " .. BadgeNameArg
            Flag = false
        end

        sc_notification:Notify(LocalPlayer, ReturnMessage)
        sc_notification:ConsoleMessage(LocalPlayer, ReturnMessage)
        return Flag
    end

    local RedeemBadgeCommand = Plugin:BindCommand( Commands.RedeemBadge.Console,
        Commands.RedeemBadge.Chat, RedeemBadge )
    RedeemBadgeCommand:AddParam{ Type = "string", Help = "Badge Name: String" }
    RedeemBadgeCommand:Help( "Redeems the badge with the name specified" )


    -- ====== View Badges ======
    local function ViewItemMenu( Client , Page)
        local LocalPlayer = Client:GetControllingPlayer()
        local ItemIndex = 1
        local PageString = string.format("\n| %5s | %50s | %80s | %10s |\n",
            "Index","Name", "Description", "Cost")

        if (Page-1)*10 > table.Count( LocalBadgeRedemptions ) then
            sc_notification:ConsoleMessage(Client, "No items on this page!")
        end

        for Name, Badge in pairs( LocalBadgeRedemptions ) do
            PageString = PageString .. string.format("| %7s | %50s | %80s | %10s |\n",
                ItemIndex, Name, Badge.Description, Badge.Cost)
            ItemIndex = ItemIndex + 1
        end
        sc_notification:ConsoleMessage(LocalPlayer, PageString)
    end

    local ViewItemMenuCommand = Plugin:BindCommand( Commands.ViewBadgeRedemptions.Console,
        Commands.ViewBadgeRedemptions.Chat, ViewItemMenu )
    ViewItemMenuCommand:AddParam{ Type = "number", Optional = true, Default = 1, Help = "Page Number:Integer" }
    ViewItemMenuCommand:Help( "View badges redeemable with credits." )

    -- ====== Add Badges ======
    local function AddBadge(Client, BadgeNameArg, DescriptionArg, CostArg)
        local LocalPlayer = Client:GetControllingPlayer()
        local ReturnMessage = ""

        if CostArg == nil or CostArg < 0 then
            ReturnMessage = "Cost cannot be negative."
            sc_notification:Notify(LocalPlayer, ReturnMessage)
            sc_notification:ConsoleMessage(LocalPlayer, ReturnMessage)
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

        LocalBadgeRedemptions[BadgeNameArg] = {
            Description = DescriptionArg,
            Cost = CostArg}

        ReturnMessage = "Badge "
            .. BadgeNameArg .. " had been added to menu."

        sc_notification:Notify(LocalPlayer, ReturnMessage)
        sc_notification:ConsoleMessage(LocalPlayer, ReturnMessage)
        self:SaveBadgeRedemptions()
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
        local Flag = false

        if LocalBadgeRedemptions.BadgeNameArg then
            LocalBadgeRedemptions.BadgeNameArg = nil
            ReturnMessage = "Badge "
                .. BadgeNameArg .. " removed."
            self:SaveBadgeRedemptions()
            Flag = true
        else
            ReturnMessage = "Invalid badge "
                .. BadgeNameArg .. " not found."
            Flag = false
        end

        sc_notification:Notify(Client:GetControllingPlayer(),ReturnMessage)
        sc_notification:ConsoleMessage(LocalPlayer, ReturnMessage)
        return Flag
    end

    local RemoveBadgeCommand = Plugin:BindCommand( Commands.RemoveBadgeFromMenu.Console,
        Commands.RemoveBadgeFromMenu.Chat, RemoveBadge )
    RemoveBadgeCommand:AddParam{ Type = "string", Help = "Badge Name:String" }
	RemoveBadgeCommand:Help( "Removes an Badge from the menu with the badge name specified." )
end

return BadgeRedemptions
