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
        SetCredits = {Console  = "sh_setcredits",Chat = "SetCredits"},
        ViewCredits = {Console  = "sh_viewcredits",Chat = "ViewCredits"},
        AddCredits = {Console  = "sh_addcredits",Chat = "addcredit"},
        SubCredits = {Console  = "sh_subcredits",Chat = "SubCredits"},
        AddItem = {Console  = "sh_additem",Chat = "additem"},
        RemoveItem = {Console  = "sh_removeitem",Chat = "removeitem"},
        ViewItemMenu = {Console  = "sh_creditmenu",Chat = "creditmenu"}
    },

    Settings = {
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

function Plugin:Initialise()
    self:LoadConfig()
    self.UserCredits = self:LoadUserCredits()
    self.CreditsMenu = self:LoadCreditsMenu()
    self.UserRedemptions = self:LoadUserRedemptions()
    self:CreateCommands()
	return true
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

function Plugin:StartCredits(SteamID)
    local UserTimeTracker = self.UserTimeTracker
    local StartTime = Shared.GetSystemTime()
    SteamID = tostring(SteamID)

    UserTimeTracker[SteamID] = StartTime

    Shine:Print("Credits Started")
end

-- Stop credit for Player based on Steam ID

function Plugin:StopCredits(SteamID)
    local UserCreditsSettings = self.Config.Settings.UserCreditsSettings
    local UserCredits = self.UserCredits
    local UserTimeTracker = self.UserTimeTracker
    local TotalPlaying = #Shine.GetTeamClients(1) + #Shine.GetTeamClients(2)
    SteamID = tostring(SteamID)

    if UserTimeTracker[SteamID] == 0 or TotalPlaying <= UserCreditsSettings.MinimumNumberOfPlayers then
        return false
    end

    EndTime = Shared.GetSystemTime()
    CreditsAwarded = math.Round((EndTime - UserTimeTracker[SteamID])/60, 0 ) * UserCreditsSettings.CreditsPerMinute

    if UserCredits[SteamID] ~= nil then
        UserCredits[SteamID].Total = UserCredits[SteamID].Total + CreditsAwarded
        UserCredits[SteamID].Current = UserCredits[SteamID].Current + CreditsAwarded
    else
        UserCredits[SteamID] = {}
        UserCredits[SteamID].Total = CreditsAwarded
        UserCredits[SteamID].Current = CreditsAwarded
    end

    UserTimeTracker[SteamID] = 0

    Shine:Print("Credits Stopped")
    Shine:Print(CreditsAwarded .. " credits awarded")
end

-- Starts timing for all players in the playing teams
function Plugin:StartCreditsAllInTeam()
    local team1Players = GetGamerules():GetTeam1():GetPlayers()
    local team2Players = GetGamerules():GetTeam2():GetPlayers()

    for _, teamPlayer in ipairs(team1Players) do
        self:StartCredits(teamPlayer:GetSteamId())
    end

    for _, teamPlayer in ipairs(team2Players) do
        self:StartCredits(teamPlayer:GetSteamId())
    end

end

-- Stops timing and award credits to all players in the playing teams
function Plugin:StopCreditsAllInTeam()
    local team1Players = GetGamerules():GetTeam1():GetPlayers()
    local team2Players = GetGamerules():GetTeam2():GetPlayers()

    for _, teamPlayer in ipairs(team1Players) do
        self:StopCredits(teamPlayer:GetSteamId())
    end

    for _, teamPlayer in ipairs(team2Players) do
        self:StopCredits(teamPlayer:GetSteamId())
    end
end

-- ======= Hooks to start credits =======
-- Called when a player joins a team in the midst of a game
function Plugin:PostJoinTeam( Gamerules, Player, OldTeam, NewTeam, Force, ShineForce )
    local SteamID = Player:GetSteamId()

    if Gamerules:GetGameStarted() then
        if (NewTeam == 0 or NewTeam == 3) then
            self:StopCredits(SteamID)
        else
            self:StartCredits(SteamID)
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
    self:StopCredits(Client.GetUserId())
end

-- ==============================================
-- ============== Commands ======================
-- ==============================================
-- Create the relevant commands for navigating the credit system
function Plugin:CreateCommands()
    self:CreateAdminCommands()
    self:CreatePlayerCommands()
end

-- ======= Player Commands =======

function Plugin:CreatePlayerCommands()
    local ConfigFile = self.Config
    local CommandsFile = ConfigFile.Commands

    -- ======= Credits System =======
    -- Create the player commands for the credits system
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
        .. " Current Credits: " .. Credits.Current

        Shine:AdminPrint( Client, ViewString )


    end
	local ViewCreditsCommand = self:BindCommand( CommandsFile.ViewCredits.Console,
        CommandsFile.ViewCredits.Chat, ViewCredits )
	ViewCreditsCommand:Help( "View Credits" )



    -- ======= Menu System ========
    -- Create the admin commands for the Menu system
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
end

-- ======= Admin Commands =======
function Plugin:CreateAdminCommands()
    local ConfigFile = self.Config
    local CommandsFile = ConfigFile.Commands

    -- ======= Credits System =======
    -- Create the admin commands for the credits system
    -- Set Credits
    local function SetCredits( Client, Targets, Amount )
        local UserCredits = self.UserCredits
        for i = 1, #Targets do
            SteamID = tostring(Targets[ i ]:GetUserId())
            UserCredits[SteamID] =  Amount
            self:SaveUserCredits()
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
        end
    end
	local SubCreditsCommand = self:BindCommand( CommandsFile.SubCredits.Console,
        CommandsFile.SubCredits.Chat, SubCredits )
    SubCreditsCommand:AddParam{ Type = "clients", Help = "Player(s)" }
    SubCreditsCommand:AddParam{ Type = "number", Help = "Integer" }
	SubCreditsCommand:Help( "Subtracts credits from the specified player(s)" )

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

Shine:RegisterExtension("sc_shinecredits", Plugin)
