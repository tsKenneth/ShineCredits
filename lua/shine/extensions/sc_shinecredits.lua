local Shine = Shine
local Plugin = {}
local Json = require("json")


Plugin.Version = "1.0"
Plugin.PrintName = "Shine Credits"
Plugin.HasConfig = false
Plugin.CheckConfig = false
Plugin.CheckConfigTypes = false

Plugin.HasConfig = true
Plugin.ConfigName = "ShineCredits.json"

Plugin.DefaultConfig = {
    Commands = {
        SetCredit = {Console  = "sh_setcredit",Chat = "setcredit"},
        AddCredit = {Console  = "sh_addcredit",Chat = "addcredit"},
        SubCredit = {Console  = "sh_subcredit",Chat = "subcredit"},
        AddItem = {Console  = "sh_additem",Chat = "additem"},
        RemoveItem = {Console  = "sh_removeitem",Chat = "removeitem"},
        ViewItemMenu = {Console  = "sh_creditmenu",Chat = "creditmenu"}
    },

    Settings = {
        Credits_Per_Minute = 1,
        Items_Per_Page = 10
    },

    UserCredits = {

    },

    CreditMenu = {

    }
}

Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true

Plugin.UserTimeTracker = {}
Plugin.UserCredits = {}
Plugin.CreditMenu = {}

function Plugin:Initialise()
    self:LoadConfig()
    self:CreateCommands()

	return true
end

-- ==============================================
-- ============== Credits System ================
-- ==============================================

-- ======= Functions to start and stop timing =======
-- Start credit for Player based on Steam ID

function Plugin:StartCredits(SteamID)
    Shine:Print("Credits Started")
    local StartTime = Shared.GetSystemTime()
    self.UserTimeTracker[SteamID] = StartTime
end

-- Stop credit for Player based on Steam ID

function Plugin:StopCredits(SteamID)
    if self.UserTimeTracker[SteamID] == 0 then
        return false
    end

    Shine:Print("Credits Stopped")

    local ConfigFile = self.Config
    local UserCredits = self.Config.UserCredits
    EndTime = Shared.GetSystemTime()

    CreditsAwarded = math.Round((EndTime - self.UserTimeTracker[SteamID])/60, 0 ) * ConfigFile.Settings.Credits_Per_Minute

    if UserCredits[SteamID] ~= nil then
        UserCredits[SteamID] = UserCredits[SteamID] + CreditsAwarded
    else
        UserCredits[SteamID] = CreditsAwarded
    end

    Shine:Print(CreditsAwarded .. " credits awarded")

    self.UserTimeTracker[SteamID] = 0
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
    if NewTeam == 0 or NewTeam == 3 then
        return self:StopCredits(SteamID)
    end

    if Gamerules:GetGameStarted() then
        self:StartCredits(SteamID)
    end
end

-- Called when game starts or stops
function Plugin:SetGameState( Gamerules, NewState, OldState )
    if NewState == 5 then
        self:StartCreditsAllInTeam()
    end

    if NewState >= 6 and NewState < 9 then
        self:StopCreditsAllInTeam()
        self:SaveConfig( true )
    end
end

-- ======= Hooks to stop credits =======
-- Called during map change to save the changes made to the users' credits
function Plugin:MapChange()
    self:StopCreditsAllInTeam()
    self:SaveConfig( true )
end

-- Called when server disconnects / Map Change to save the changes made to the users' credits
function Plugin:Cleanup()
    self:StopCreditsAllInTeam()
    self:SaveConfig( true )
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
end

-- ======= Admin Commands =======
-- ======= Credits System =======
-- Create the admin commands for the credits system
function Plugin:CreateAdminCommands()
    local ConfigFile = self.Config
    local CommandsFile = ConfigFile.Commands
    local UserCreditsFile = ConfigFile.UserCredits
    local CreditMenuFile = ConfigFile.CreditMenu

    -- Set Credits
    local function SetCredits( Client, Targets, Amount )
        for i = 1, #Targets do
            SteamID = Targets[ i ]:GetUserId()
            UserCreditsFile[SteamID] =  Amount
            self:SaveConfig( true )
        end
    end
	local SetCreditsCommand = self:BindCommand( CommandsFile.SetCredit.Console,
        CommandsFile.SetCredit.Chat, SetCredits )
    SetCreditsCommand:AddParam{ Type = "clients", Help = "Player(s)" }
    SetCreditsCommand:AddParam{ Type = "number", Help = "Integer" }
	SetCreditsCommand:Help( "Set credits of the specified player(s)" )

    -- Add Credits
    local function AddCredits( Client, Targets, Amount )
        for i = 1, #Targets do
            SteamID = Targets[ i ]:GetUserId()
            if UserCreditsFile[SteamID] ~= nil then
                UserCreditsFile[SteamID] = UserCreditsFile[SteamID] + Amount
            else
                UserCreditsFile[SteamID] = Amount
            end
            self:SaveConfig( true )
        end
    end
	local AddCreditsCommand = self:BindCommand( CommandsFile.AddCredit.Console,
        CommandsFile.AddCredit.Chat, AddCredits )
    AddCreditsCommand:AddParam{ Type = "clients", Help = "Player(s)" }
    AddCreditsCommand:AddParam{ Type = "number", Help = "Integer" }
	AddCreditsCommand:Help( "Adds credits to the specified player(s)" )

    -- Subtract Credits
    local function SubCredits( Client, Targets, Amount )
        for i = 1, #Targets do
            SteamID = Targets[ i ]:GetUserId()
            if UserCreditsFile[SteamID] ~= nil then
                UserCreditsFile[SteamID] = UserCreditsFile[SteamID] - Amount
            else
                UserCreditsFile[SteamID] = Amount
            end
            self:SaveConfig( true )
        end
    end
	local SubCreditsCommand = self:BindCommand( CommandsFile.SubCredit.Console,
        CommandsFile.SubCredit.Chat, SubCredits )
    SubCreditsCommand:AddParam{ Type = "clients", Help = "Player(s)" }
    SubCreditsCommand:AddParam{ Type = "number", Help = "Integer" }
	SubCreditsCommand:Help( "Subtracts credits from the specified player(s)" )

-- ======= Menu System ========
    -- View Menu
    local function ViewItemMenu( Client , Page)
        local ItemTracker = 0
        local PageString = ""

        if Page*10 > table.Count( CreditMenuFile ) then
            Shine:AdminPrint( Client, "No items on this page!" )
        end

        for Name, Item in pairs(CreditMenuFile) do
            PageString = PageString .. Name .. " " .. Item.Description .. " " .. Item.Cost .. "\n"
            ItemTracker = ItemTracker + 1
        end
        Shine:AdminPrint( Client, PageString )
    end

	local ViewItemMenuCommand = self:BindCommand( CommandsFile.ViewItemMenu.Console,
        CommandsFile.ViewItemMenu.Chat, ViewItemMenu )
    ViewItemMenuCommand:AddParam{ Type = "number", Optional = true, Default = 1, Help = "Page Number" }
	ViewItemMenuCommand:Help( "View items redeemable with credits" )


    -- Add Item
    local function AddItem(Client, ItemNameArg, CommandArg, DescriptionArg, CostArg)
        if CostArg == nil or CostArg < 0 then
            return false
        end

        CreditMenuFile.insert ({ItemName = ItemNameArg, Command = CommandArg, Description = DescriptionArg, Cost = CostArg})
        self:SaveConfig( true )
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
        self:SaveConfig( true )
    end

    local RemoveItemCommand = self:BindCommand( CommandsFile.RemoveItem.Console,
        CommandsFile.RemoveItem.Chat, RemoveItem )
    RemoveItemCommand:AddParam{ Type = "string", Help = "Name" }
	RemoveItemCommand:Help( "Removes an item from the menu with the name specified" )
end

Shine:RegisterExtension("sc_shinecredits", Plugin)
