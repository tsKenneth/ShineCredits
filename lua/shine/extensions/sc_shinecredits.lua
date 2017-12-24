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
Plugin.UserCredits = {}
Plugin.CreditsMenu = {}
Plugin.UserRedemptions = {}

-- ==============================================
-- ============== Init System ===================
-- ==============================================

function Plugin:Initialise()
    self:LoadConfig()
    self.UserCredits = self:LoadUserCredits()
    self.CreditsMenu = self:LoadCreditsMenu()
    self.UserRedemptions = self:LoadUserRedemptions()
    self:CreateCommands()
	return true
end

function Plugin:InitUser( Player )
    local PluginSettings = self.Config.Settings
    local UserCredits = self.UserCredits
    local SteamID = Player:GetSteamId()
    local SteamIDStr = tostring(SteamID)


    if UserCredits[SteamIDStr] == nil then
        UserCredits[SteamIDStr] = {Total = 0, Current = 0}
    end

    local Target = Player:GetClient()
    local Existing, _ = Shine:GetUserData( Target )

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

    if PluginSettings.UserRankingSettings.Enabled and UserCredits[SteamIDStr].Rank == nil then
        UserCredits[SteamIDStr].Rank = 1
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

function Plugin:LoadTable( FilePath )
    local contents = ""
    local myTable = {}
    local file = io.open( FilePath, "r" )

    if file then
        contents = file:read( "*a" )
        myTable = Json.decode(contents);
        io.close( file )
        return myTable
    end

    self:SaveTable({}, FilePath )
    return {}
end

function Plugin:SaveUserCredits()
    return self:SaveTable(self.UserCredits,self.Config.Settings.UserCreditsSettings.FilePath)
end

function Plugin:LoadUserCredits()
    return self:LoadTable(self.Config.Settings.UserCreditsSettings.FilePath)
end

function Plugin:SaveCreditsMenu()
    return self:SaveTable(self.CreditsMenu,self.Config.Settings.CreditsMenuSettings.FilePath)
end

function Plugin:LoadCreditsMenu()
    return self:LoadTable(self.Config.Settings.CreditsMenuSettings.FilePath)
end

function Plugin:SaveUserRedemptions()
    return self:SaveTable(self.UserRedemptions,self.Config.Settings.UserRedemptionsSettings.FilePath)
end

function Plugin:LoadUserRedemptions()
    return self:LoadTable(self.Config.Settings.UserRedemptionsSettings.FilePath)
end




-- ==============================================
-- ======== Credits System (Time-Based) =========
-- ==============================================
-- ======= Functions to start and stop timing =======
-- Start credit for Player based on Steam ID

function Plugin:StartCredits(Player)
    local UserTimeTracker = self.UserTimeTracker
    local StartTime = Shared.GetSystemTime()
    local SteamID = tostring(Player:GetSteamId())
    UserTimeTracker[SteamID] = StartTime
end

-- Stop credit for Player based on Steam ID
function Plugin:StopCredits(Player)
    local UserCreditsSettings = self.Config.Settings.UserCreditsSettings
    local UserCredits = self.UserCredits
    local UserTimeTracker = self.UserTimeTracker
    local TotalPlaying = #Shine.GetTeamClients(1) + #Shine.GetTeamClients(2)
    local SteamID = tostring(Player:GetSteamId())

    if UserTimeTracker[SteamID] == 0 or TotalPlaying <= UserCreditsSettings.MinimumNumberOfPlayers then
        Shine:NotifyDualColour(Player,255,100,100,"[Shine Credits] ", 255,255,255, "No credits awarded. (Not enough players)",nil)
        return false
    end

    EndTime = Shared.GetSystemTime()
    CreditsAwarded = math.Round((EndTime - UserTimeTracker[SteamID])/60, 0 ) * UserCreditsSettings.CreditsPerMinute

    UserCredits[SteamID].Total = UserCredits[SteamID].Total + CreditsAwarded
    UserCredits[SteamID].Current = UserCredits[SteamID].Current + CreditsAwarded

    UserTimeTracker[SteamID] = 0

    Shine:NotifyDualColour(Player,255,100,100,"[Shine Credits] ", 255,255,255, CreditsAwarded .. " credits awarded.",nil)

    self:UpdatePlayerRank( Player )
end

-- Starts timing for all players in the playing teams
function Plugin:StartCreditsAllInTeam()
    local team1Players = GetGamerules():GetTeam1():GetPlayers()
    local team2Players = GetGamerules():GetTeam2():GetPlayers()

    for _, team1Player in ipairs(team1Players) do
        self:StartCredits(team1Player)
    end

    for _, team2Player in ipairs(team2Players) do
        self:StartCredits(team2Player)
    end

end

-- Stops timing and award credits to all players in the playing teams
function Plugin:StopCreditsAllInTeam()
    local team1Players = GetGamerules():GetTeam1():GetPlayers()
    local team2Players = GetGamerules():GetTeam2():GetPlayers()

    for _, team1Player in ipairs(team1Players) do
        self:StopCredits(team1Player)
    end

    for _, team2Player in ipairs(team2Players) do
        self:StopCredits(team2Player)
    end

    self:SaveUserCredits()
end

-- ======= Hooks to start credits =======
-- Called when a player joins a team in the midst of a game
function Plugin:PostJoinTeam( Gamerules, Player, OldTeam, NewTeam, Force, ShineForce )
    if Gamerules:GetGameStarted() then
        if (NewTeam == 0 or NewTeam == 3) then
            self:StopCredits(Player)
            self:SaveUserCredits()
        else
            self:StartCredits(Player)
        end
    end
end

-- Called when game starts or stops
function Plugin:SetGameState( Gamerules, NewState, OldState )
    if NewState == 5 then
        self:StartCreditsAllInTeam()
    end

    if NewState >= 6 and NewState < 9 then
        self:StopCreditsAllInTeam()
        self:SaveUserCredits()
    end
end

-- ======= Hooks to stop credits =======
-- Called during map change to save the changes made to the users' credits
function Plugin:MapChange()
    self:StopCreditsAllInTeam()
    self:SaveUserCredits()
end

-- Called when server disconnects / Map Change to save the changes made to the users' credits
function Plugin:Cleanup()
    self:StopCreditsAllInTeam()
    self:SaveUserCredits()
end

-- Called when the user disconnects mid-game
function Plugin:ClientDisconnect( Client )
    self:StopCredits(Client:GetControllingPlayer())
end

-- ==============================================
-- ============= Ranking System =================
-- ==============================================
-- Update players' rank based on their total credits
function Plugin:UpdatePlayerRank( Player )
    local ConfigFile = self.Config
    local UserCredits = self.UserCredits
    local UserRankingSettings = ConfigFile.Settings.UserRankingSettings

    if not UserRankingSettings.Enabled then
        return false
    end

    local Target = Player:GetClient()
    local Existing, SteamID = Shine:GetUserData( Target )
    SteamID = tostring(SteamID)
    local CurrentRank = UserCredits[SteamID].Rank

    while (UserCredits[SteamID].Total > (UserCredits[SteamID].Rank^UserRankingSettings.PowerFactor)) do
        UserCredits[SteamID].Rank = UserCredits[SteamID].Rank + 1
    end

    if CurrentRank ~= UserCredits[SteamID].Rank then
        local NewBadgeName = "level" .. UserCredits[SteamID].Rank
        table.remove(Existing["Badges"]["1"], 1)
        table.insert(Existing["Badges"]["1"], 1, NewBadgeName)

        Shine:SaveUsers( true )
        Shine:NotifyDualColour(Player,255,100,100,"[Shine Credits] ", 255,150,150, "Ranked up to Rank "
        .. UserCredits[SteamID].Rank
        .. " (badge will be refreshed when map changes)"  , nil)
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
        local UserCredits = self.UserCredits
        for i = 1, #Targets do
            SteamID = tostring(Targets[ i ]:GetUserId())
            UserCredits[SteamID] =  Amount
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
        local UserCredits = self.UserCredits
        for i = 1, #Targets do
            SteamID = tostring(Targets[ i ]:GetUserId())
            if UserCredits[SteamID] ~= nil then
                UserCredits[SteamID] = UserCredits[SteamID] + Amount
            else
                UserCredits[SteamID] = Amount
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
        local UserCredits = self.UserCredits
        for i = 1, #Targets do
            SteamID = tostring(Targets[ i ]:GetUserId())
            if UserCredits[SteamID] ~= nil then
                UserCredits[SteamID] = UserCredits[SteamID] - Amount
            else
                UserCredits[SteamID] = Amount
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
        local UserCredits = self.UserCredits
        local UserSteamID = tostring(Client:GetUserId())
        local Credits = UserCredits[UserSteamID]
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
