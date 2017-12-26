local Shine = Shine
local Plugin = {}
local Json = require("shine/extensions/json")

Plugin.Version = "1.0"
Plugin.PrintName = "Shine Credits"
Plugin.HasConfig = false
Plugin.CheckConfig = false
Plugin.CheckConfigTypes = false

Plugin.HasConfig = true
Plugin.ConfigName = "ShineCredits.json"

Plugin.DefaultConfig = {
    Commands = {
        SetCredits = {Console  = "sh_setcredits", Chat = "SetCredits"},
        ViewCredits = {Console  = "sh_viewcredits", Chat = "ViewCredits"},
        AddCredits = {Console  = "sh_addcredits", Chat = "addcredit"},
        SubCredits = {Console  = "sh_subcredits", Chat = "SubCredits"},
        AddItem = {Console  = "sh_additem", Chat = "additem"},
        RemoveItem = {Console  = "sh_removeitem", Chat = "removeitem"},
        ViewItemMenu = {Console  = "sh_creditmenu", Chat = "creditmenu"}
    },

    Settings = {
        UserRankingSettings = {
            Enabled = true,
            PowerFactor = 1,
            MaxRank = 55
        },
        UserCreditsSettings =  {
            FilePath = "config://shine/ShineCredits_UserCredits.json",
            CreditsPerMinute = 1,
            MinimumNumberOfPlayers = 0
        },
        UserRedemptionsSettings = {
            FilePath = "config://shine/ShineCredits_UserRedemptions.json",
        },
        CreditsMenuSettings = {
            FilePath = "config://shine/ShineCredits_CreditMenu.json",
            ItemsPerPage = 10
        }
    }
}

Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true

Plugin.UserTimeTracker = {}
Plugin.PlayerCredits = {}
Plugin.CreditsMenu = {}
Plugin.PlayerRedemptions = {}

-- ==============================================
-- ============== Init System ===================
-- ==============================================

function Plugin:Initialise()
    self:LoadConfig()
    self.PlayerCredits = self:LoadUserCredits()
    self.CreditsMenu = self:LoadCreditsMenu()
    self.PlayerRedemptions = self:LoadUserRedemptions()
    self:CreateCommands()
	return true
end

function Plugin:InitUser( Player )
    -- Initialise local copy of global files
    local PluginSettings = self.Config.Settings
    local PlayerCredits = self.PlayerCredits
    local SteamID = Player:GetSteamId()
    local SteamIDStr = tostring(SteamID)

    -- Initialise Player's user credits if it does not exist
    if PlayerCredits[SteamIDStr] == nil then
        PlayerCredits[SteamIDStr] = {Total = 0, Current = 0}
    end

    local Target = Player:GetClient()
    local Existing, _ = Shine:GetUserData( Target )

    -- Initialise Player's badges if it does not exist
    if not Existing then
        Shine:ReinstateUser(Target,SteamID)
        Shine:SaveUsers( true )
        Existing, _ = Shine:GetUserData( Target )
    end

    if not Existing["Badges"] then
        Existing["Badges"] = {}
        Existing["Badges"]["1"] = {}
        Existing["Badges"]["2"] = {}
        Shine:SaveUsers( true )
    end

    -- Initialise Player's rank if it does not exist
    if PluginSettings.UserRankingSettings.Enabled and PlayerCredits[SteamIDStr].Rank == nil then
        PlayerCredits[SteamIDStr].Rank = 1
        table.insert(Existing["Badges"]["1"], 1, "level1")
        Shine:SaveUsers( true )
    end
end

function Plugin:ClientConnect( Client )
    self:InitUser( Client:GetControllingPlayer() )
end


-- ==============================================
-- ============== FileIO System =================
-- ==============================================
-- Save to file
function Plugin:SaveTable( Table, FilePath )
     local file = io.open(FilePath, "w")

     if file then
        local contents = Json.encode( Table )
        file:write( contents )
        io.close( file )
        return true
    else
        return false
    end
end

-- Load from file
function Plugin:LoadTable( FilePath )
    local contents = ""
    local myTable = {}
    local file = io.open( FilePath, "r" )

    if file then
        -- If file exists
        contents = file:read( "*a" )
        myTable = Json.decode(contents);
        io.close( file )
        return myTable
    else
        -- If file does not exist
        self:SaveTable({}, FilePath )
        return {}
    end

    return false
end

function Plugin:SaveUserCredits()
    return self:SaveTable(self.PlayerCredits,
    self.Config.Settings.UserCreditsSettings.FilePath)
end

function Plugin:LoadUserCredits()
    return self:LoadTable(self.Config.Settings.UserCreditsSettings.FilePath)
end

function Plugin:SaveCreditsMenu()
    return self:SaveTable(self.CreditsMenu,
    self.Config.Settings.CreditsMenuSettings.FilePath)
end

function Plugin:LoadCreditsMenu()
    return self:LoadTable(self.Config.Settings.CreditsMenuSettings.FilePath)
end

function Plugin:SaveUserRedemptions()
    return self:SaveTable(self.PlayerRedemptions,
    self.Config.Settings.UserRedemptionsSettings.FilePath)
end

function Plugin:LoadUserRedemptions()
    return self:LoadTable(self.Config.Settings.UserRedemptionsSettings.FilePath)
end

-- ==============================================
-- ======== Credits System (Time-Based) =========
-- ==============================================

-- ======= Functions to start and stop timing =======
-- Start credit for Player
function Plugin:StartCredits(Player)
    -- Initialise local copy of global files
    local UserTimeTracker = self.UserTimeTracker
    local StartTime = Shared.GetSystemTime()
    local SteamID = tostring(Player:GetSteamId())

    -- Store the time user started playing
    UserTimeTracker[SteamID] = StartTime
end

-- Stop credit for Player
function Plugin:StopCredits( Player , SaveChanges )
    -- Initialise local copy of global files
    local UserCreditsSettings = self.Config.Settings.UserCreditsSettings
    local PlayerCredits = self.PlayerCredits
    local UserTimeTracker = self.UserTimeTracker
    local TotalPlaying = #Shine.GetTeamClients(1) + #Shine.GetTeamClients(2)
    local SteamID = tostring(Player:GetSteamId())

    -- Check if Player Time == 0 (i.e. already been stopped)
    -- and that game has minimum number of players required for credits to be awarded
    if UserTimeTracker[SteamID] == 0 or TotalPlaying <= UserCreditsSettings.MinimumNumberOfPlayers then
        Shine:NotifyDualColour(Player,
        255,100,100,"[Shine Credits] ",
        255,255,255, "No credits awarded. (Not enough players)",nil)
        return false
    end

    -- Calculate the amount of credits to award based on the time elapsed
    -- and the amount to award per minute elapsed
    EndTime = Shared.GetSystemTime()
    CreditsAwarded = math.Round((EndTime - UserTimeTracker[SteamID])/60, 0 ) * UserCreditsSettings.CreditsPerMinute
    UserTimeTracker[SteamID] = 0

    -- Reward the points accordingly
    PlayerCredits[SteamID].Total = PlayerCredits[SteamID].Total + CreditsAwarded
    PlayerCredits[SteamID].Current = PlayerCredits[SteamID].Current + CreditsAwarded

    -- Save the changes
    if SaveChanges then
        self:SaveUserCredits()
    end

    Shine:NotifyDualColour(Player,
    255,100,100,"[Shine Credits] ",
    255,255,255, CreditsAwarded .. " credits awarded.",nil)

    self:UpdatePlayerRank( Player , SaveChanges)

end

-- Starts timing for all players in the playing teams
function Plugin:StartCreditsAllInTeam()
    local team1Players = GetGamerules():GetTeam1():GetPlayers()
    local team2Players = GetGamerules():GetTeam2():GetPlayers()

    -- For all players in Marines
    for _, team1Player in ipairs(team1Players) do
        self:StartCredits(team1Player)
    end

    -- For all players in Aliens
    for _, team2Player in ipairs(team2Players) do
        self:StartCredits(team2Player)
    end

end

-- Stops timing and award credits to all players in the playing teams
function Plugin:StopCreditsAllInTeam()
    local team1Players = GetGamerules():GetTeam1():GetPlayers()
    local team2Players = GetGamerules():GetTeam2():GetPlayers()

    for _, team1Player in ipairs(team1Players) do
        self:StopCredits(team1Player, false)
    end

    for _, team2Player in ipairs(team2Players) do
        self:StopCredits(team2Player, false)
    end

    self:SaveUserCredits()
end

-- ======= Hooks to start credits =======
-- Called when a player joins a team in the midst of a game
function Plugin:PostJoinTeam( Gamerules, Player, OldTeam, NewTeam, Force, ShineForce )
    if Gamerules:GetGameStarted() then
        -- Check if team changed to is 0: Ready room , 3:Spectators
        if (NewTeam == 0 or NewTeam == 3) then
            self:StopCredits(Player, true)
        else
            self:StartCredits(Player)
        end
    end
end

-- Called when game starts or stops
function Plugin:SetGameState( Gamerules, NewState, OldState )
    -- If new state is 5:"Game Started"
    if NewState == 5 then
        self:StartCreditsAllInTeam()
    end

    -- If new state is 6:"Team 1 victory", 7:"Team 2 Victory" or 8:"Draw"
    if NewState >= 6 and NewState < 9 then
        self:StopCreditsAllInTeam()
    end
end

-- ======= Hooks to stop credits =======
-- Called during map change to save the changes made to the users' credits
function Plugin:MapChange()
    self:StopCreditsAllInTeam()
end

-- Called when server disconnects / Map Change to save the changes made to the users' credits
function Plugin:Cleanup()
    self:StopCreditsAllInTeam()
end

-- Called when the user disconnects mid-game
function Plugin:ClientDisconnect( Client )
    self:StopCredits(Client:GetControllingPlayer())
end

-- ==============================================
-- ============= Ranking System =================
-- ==============================================
-- Update players' rank based on their total credits
function Plugin:UpdatePlayerRank( Player , SaveChanges )
    -- Initialise local copy of global files
    local ConfigFile = self.Config
    local PlayerCredits = self.PlayerCredits
    local UserRankingSettings = ConfigFile.Settings.UserRankingSettings

    -- Checks if User Ranking System is Enabled
    if not UserRankingSettings.Enabled then
        return false
    end

    -- Obtain pre-requisite data on player
    local Target = Player:GetClient()
    local Existing, SteamID = Shine:GetUserData( Target )
    SteamID = tostring(SteamID)
    local CurrentRank = PlayerCredits[SteamID].Rank

    -- Checks which way to update the user's rank
    if PlayerCredits[SteamID].Total < PlayerCredits[SteamID].Rank^UserRankingSettings.PowerFactor then
        -- When player's total credits is less than Rank's required credits:
        -- Decrease player's rank by 1 until user's credits is equivalent to the required amount
        while (PlayerCredits[SteamID].Total < (PlayerCredits[SteamID].Rank^UserRankingSettings.PowerFactor))
        and PlayerCredits[SteamID].Rank ~= 1 do
            PlayerCredits[SteamID].Rank = PlayerCredits[SteamID].Rank - 1
        end
    else
        -- When player's total credits is more than Rank's required credits:
        --Increase player's rank by 1 until user's credits is equivalent to the required amount
        while (PlayerCredits[SteamID].Total > (PlayerCredits[SteamID].Rank^UserRankingSettings.PowerFactor))
        and PlayerCredits[SteamID].Rank ~= UserRankingSettings.MaxRank do
            PlayerCredits[SteamID].Rank = PlayerCredits[SteamID].Rank + 1
        end
    end

    -- If player's rank has changed, perform badge change
    if CurrentRank ~= PlayerCredits[SteamID].Rank then
        local NewBadgeName = "level" .. PlayerCredits[SteamID].Rank
        table.remove(Existing["Badges"]["1"], 1)
        table.insert(Existing["Badges"]["1"], 1, NewBadgeName)

        -- Notify user of the rank up
        Shine:NotifyDualColour(Player,255,100,100,"[Shine Credits] ", 255,150,150, "Ranked up to Rank "
        .. PlayerCredits[SteamID].Rank
        .. " (badge will be refreshed when map changes)"  , nil)

        -- Save changes
        if SaveChanges then
            Shine:SaveUsers( true )
        end

        return true
    end
    return false
end


-- ==============================================
-- ============ Redemption System ===============
-- ==============================================

-- ==============================================
-- ============== Commands ======================
-- ==============================================
-- Create the relevant commands for navigating the Shine Credit system
function Plugin:CreateCommands()
    self:CreateMenuCommands()
    self:CreateCreditsCommands()
end

-- ======= Menu System ========
function Plugin:CreateMenuCommands()
    local ConfigFile = self.Config
    local CommandsFile = ConfigFile.Commands

    -- View Menu
    local function ViewItemMenu( Client , Page)
        local ItemIndex = 1
        local PageString = string.format("\n| %5s | %52s | %80s | %10s |\n","Index","Name", "Description", "Cost")
        local CreditsMenu = self.CreditsMenu

        if (Page-1)*10 > table.Count( CreditsMenu ) then
            Shine:AdminPrint( Client, "No items on this page!" )
        end

        for Name, Item in pairs(CreditsMenu) do
            PageString = PageString .. string.format("| %7s | %50s | %75s | %10s |\n",ItemIndex, Item.Name, Item.Description, Item.Cost)
            ItemIndex = ItemIndex + 1
        end
        Shine:AdminPrint( Client, PageString )
    end

    local ViewItemMenuCommand = self:BindCommand( CommandsFile.ViewItemMenu.Console,
        CommandsFile.ViewItemMenu.Chat, ViewItemMenu )
    ViewItemMenuCommand:AddParam{ Type = "number", Optional = true, Default = 1, Help = "Page Number" }
    ViewItemMenuCommand:Help( "View items redeemable with credits" )

    -- ====== Badges Submenu ======
    local function AddBadge(Client, BadgeNameArg, DescriptionArg, CostArg)
        local CreditsMenu = self.CreditsMenu
        if CostArg == nil or CostArg < 0 then
            return false
        end

        if CreditsMenu.Badges == nil then
            CreditsMenu.Badges = {}
        end

        table.insert(CreditsMenu.Badges,{Name = BadgeNameArg, Description = DescriptionArg, Cost = CostArg})
        self:SaveCreditsMenu()
    end

	local AddBadgeCommand = self:BindCommand( CommandsFile.AddItem.Console,
        CommandsFile.AddItem.Chat, AddBadge )
    AddBadgeCommand:AddParam{ Type = "string", Help = "Badge Name (As per in Badges Mod)" }
    AddBadgeCommand:AddParam{ Type = "string", Help = "Description" }
    AddBadgeCommand:AddParam{ Type = "number", Help = "Integer" }
	AddBadgeCommand:Help( "Adds a new badge to the menu with the badge name, description and cost provided" )

    -- ====== Command Submenu =====
    local function AddCommandItem(Client, NameArg, CommandArg, DescriptionArg, CostArg)
        local CreditsMenu = self.CreditsMenu
        if CostArg == nil or CostArg < 0 then
            return false
        end

        if CreditsMenu.Commands == nil then
            CreditsMenu.Commands = {}
        end

        table.insert(CreditsMenu.Commands,{Name = NameArg, Command = CommandArg, Description = DescriptionArg, Cost = CostArg})
        self:SaveCreditsMenu()
    end

	local AddCommandItemCommand = self:BindCommand( CommandsFile.AddItem.Console,
        CommandsFile.AddItem.Chat, AddCommandItem )
    AddCommandItemCommand:AddParam{ Type = "string", Help = "Name" }
    AddCommandItemCommand:AddParam{ Type = "string", Help = "Shine Command" }
    AddCommandItemCommand:AddParam{ Type = "string", Help = "Description" }
    AddCommandItemCommand:AddParam{ Type = "number", Help = "Integer" }
	AddCommandItemCommand:Help( "Adds a new command to the menu with the name, shine command, description and cost provided" )

    -- ====== Skin Submenu ========

    -- WIP

    -- Add Item
    local function AddItem(Client, NameArg, CommandArg, DescriptionArg, CostArg)
        local CreditsMenu = self.CreditsMenu
        if CostArg == nil or CostArg < 0 then
            return false
        end

        table.insert(CreditsMenu,{Name = NameArg, Command = CommandArg, Description = DescriptionArg, Cost = CostArg})
        self:SaveCreditsMenu()
    end

	local AddItemCommand = self:BindCommand( CommandsFile.AddItem.Console,
        CommandsFile.AddItem.Chat, AddItem )
    AddItemCommand:AddParam{ Type = "string", Help = "Name" }
    AddItemCommand:AddParam{ Type = "string", Help = "Shine Command" }
    AddItemCommand:AddParam{ Type = "string", Help = "Description" }
    AddItemCommand:AddParam{ Type = "number", Help = "Integer" }
	AddItemCommand:Help( "Adds a new item to the menu with the name, command, description and cost provided" )

    -- Remove Item
    local function RemoveItem(Client, ItemName)
        self:SaveCreditsMenu()
    end

    local RemoveItemCommand = self:BindCommand( CommandsFile.RemoveItem.Console,
        CommandsFile.RemoveItem.Chat, RemoveItem )
    RemoveItemCommand:AddParam{ Type = "string", Help = "Name" }
	RemoveItemCommand:Help( "Removes an item from the menu with the name specified" )
end

-- ======= Credits System =======
function Plugin:CreateCreditsCommands()
    local ConfigFile = self.Config
    local CommandsFile = ConfigFile.Commands

    -- Set Credits
    local function SetCredits( Client, Targets, Amount )
        local PlayerCredits = self.PlayerCredits
        for i = 1, #Targets do
            SteamID = tostring(Targets[ i ]:GetUserId())
            PlayerCredits[SteamID] =  Amount
            self:SaveUserCredits()
            self:UpdatePlayerRank( Targets[i]:GetControllingPlayer() )
        end
    end
	local SetCreditsCommand = self:BindCommand( CommandsFile.SetCredits.Console,
        CommandsFile.SetCredits.Chat, SetCredits )
    SetCreditsCommand:AddParam{ Type = "clients", Help = "Player(s)" }
    SetCreditsCommand:AddParam{ Type = "number", Help = "Integer" }
	SetCreditsCommand:Help( "Set credits of the specified player(s)" )

    -- Add Credits
    local function AddCredits( Client, Targets, Amount )
        local PlayerCredits = self.PlayerCredits
        for i = 1, #Targets do
            SteamID = tostring(Targets[ i ]:GetUserId())
            if PlayerCredits[SteamID] ~= nil then
                PlayerCredits[SteamID] = PlayerCredits[SteamID] + Amount
            else
                PlayerCredits[SteamID] = Amount
            end
            self:SaveUserCredits()
            self:UpdatePlayerRank( Targets[i]:GetControllingPlayer() )
        end
    end
	local AddCreditsCommand = self:BindCommand( CommandsFile.AddCredits.Console,
        CommandsFile.AddCredits.Chat, AddCredits )
    AddCreditsCommand:AddParam{ Type = "clients", Help = "Player(s)" }
    AddCreditsCommand:AddParam{ Type = "number", Help = "Integer" }
	AddCreditsCommand:Help( "Adds credits to the specified player(s)" )

    -- Subtract Credits
    local function SubCredits( Client, Targets, Amount )
        local PlayerCredits = self.PlayerCredits
        for i = 1, #Targets do
            SteamID = tostring(Targets[ i ]:GetUserId())
            if PlayerCredits[SteamID] ~= nil then
                PlayerCredits[SteamID] = PlayerCredits[SteamID] - Amount
            else
                PlayerCredits[SteamID] = Amount
            end
            self:SaveUserCredits()
            self:UpdatePlayerRank( Targets[i]:GetControllingPlayer() )
        end
    end
	local SubCreditsCommand = self:BindCommand( CommandsFile.SubCredits.Console,
        CommandsFile.SubCredits.Chat, SubCredits )
    SubCreditsCommand:AddParam{ Type = "clients", Help = "Player(s)" }
    SubCreditsCommand:AddParam{ Type = "number", Help = "Integer" }
	SubCreditsCommand:Help( "Subtracts credits from the specified player(s)" )

    -- View Credits
    local function ViewCredits( Client )
        local PlayerCredits = self.PlayerCredits
        local UserSteamID = tostring(Client:GetUserId())
        local Credits = PlayerCredits[UserSteamID]
        if Credits == nil then
            Credits = {Total = 0, Current = 0}
        end
        local ViewString = "Info for " .. Shine.GetClientInfo( Client ) .. "\n"
        .. "Total Credits: " .. Credits.Total
        .. " | Current Credits: " .. Credits.Current .. " | Rank: " .. Credits.Rank

        Shine:NotifyDualColour(Client:GetControllingPlayer(),255,100,100,"[Shine Credits] ", 255,255,255, ViewString ,nil)
        Shine:AdminPrint( Client, ViewString )
    end

    local ViewCreditsCommand = self:BindCommand( CommandsFile.ViewCredits.Console,
        CommandsFile.ViewCredits.Chat, ViewCredits )
    ViewCreditsCommand:Help( "View Credits" )





end

Shine:RegisterExtension("sc_shinecredits", Plugin)
