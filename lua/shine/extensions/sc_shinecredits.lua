local Shine = Shine
local Plugin = {}
local sc_json = require("shine/extensions/shinecredits/sc_jsonfileio")
local sc_playerleveling = require("shine/extensions/shinecredits/sc_playerleveling")
local sc_notification = require("shine/extensions/shinecredits/sc_notification")
local sc_badges = require("shine/extensions/shinecredits/sc_badgesmenu")
--local sc_commanditems = require("shine/extensions/shinecredits/sc_commanditemsmenu")
--local sc_skins = require("shine/extensions/shinecredits/sc_skinsmenu")

Plugin.Version = "1.0"
Plugin.PrintName = "Shine Credits"

Plugin.HasConfig = true
Plugin.ConfigName = "ShineCredits.json"

Plugin.DefaultConfig = {
    Storage = {
        Mode = "Files",
        WebServer = {
            Host = nil,
            Method = nil,
            Password = nil
        }
    },
    Settings = {
        PlayerLeveling =
        {
            Enabled = true,
            FilePath = "config://shine/plugins/ShineCredits_UserLevels.json",
            Formula = {
                PowerFactor = 1,
                CustomFormula = nil
            },
            Levels = {
                Minimum = 1,
                Maximum = 55,
                LevelBadgeNamePrefix = "level",
                LevelBadgeNameSuffix = "",
                CustomLevelBadgesOrder = nil
            },
            Permissions = {
                SuspendLevelingForGroup = nil,
                AllowLevelingForGroup = nil
            },
            Notifications = {
                LevelChange = "Leveled to level %s!" ..
                    " (badge will be refreshed when map changes)"
            },
            Commands = {
                SuspendLevelForPlayer = {Console  = "sh_suspendlevel", Chat = "suspendlevel"}
            }
        },
        PlayerCredits =  {
            FilePath = "config://shine/plugins/ShineCredits_UserCredits.json",

            AwardModes = {
                ModeSelected = "Time",
                Time = {
                    CreditsPerMinute = 1
                },
                Score = {
                    CreditsPerScoreEarned = 0.01
                },
                HybridScore = {
                    CreditsPerMinute = 1,
                    CreditsPerScoreEarned = 0.01
                },
                SiegeScore = {
                    PerTresSpent = 0.1,
                    PerRawDamageInflictedToPlayers = 0.1,
                    PerPercentageTotalHealthInflictedToPlayers = 0.1,
                    SpecialPlayers = nil,
                    MultiplierForSpecialPlayers = 1.5,
                    PerRawDamageInflictedToStructures = 0.1,
                    PerPercentageTotalHealthInflictedToStructures = 0.1,
                    SpecialStructures = {"Tunnel","PhaseGate","Hive","CommandStation"},
                    MultiplierForSpecialStructures = 1.5,
                    AlienPerPercentageHealed = 0.5,
                    MarinesPerPercentageHealed = 1,
                    AlienPerPercentageBuilt = 1,
                    MarinesPerPercentageBuilt = 0.5,
                    TimeMultiplierFactor = 1.1,
                    VictoryBase = 10,
                    VictoryMultiplier = 1.2,
                    CommanderBase = 10,
                    CommanderMultiplier = 1.2

                }
            },
            MinimumNumberOfPlayers = 0,
            Commands = {
                SetCredits = {Console  = "sh_setcredits", Chat = "setcredits"},
                ViewCredits = {Console  = "sh_viewcredits", Chat = "viewcredits"},
                AddCredits = {Console  = "sh_addcredits", Chat = "addcredit"},
                SubCredits = {Console  = "sh_subcredits", Chat = "subcredits"},
            },
        },
        Notification =
        {
            Enabled = true,
            Message = {
                Default = "",
                MessageRGB = {255,255,255}
            },
            Sender = {
                DefaultName = "[Shine Credits]",
                NameRGB = {255,20,30}
            }

        },
        RedemptionMenus =
        {
            FilePath = "config://shine/plugins/ShineCredits_RedemptionMenus.json",
            UserRedemptions = {
                FilePath = "config://shine/plugins/ShineCredits_UserRedemptions.json"
            },
            BadgesMenu = {
                Enabled = true,
                ReservedBadges = nil,
                ItemsPerPage = 10,
                Commands = {
                    AddBadgeToMenu = {Console = "sh_addbadge", Chat = "addbadge"},
                    RemoveBadgeFromMenu = {Console = "sh_removebadge", Chat = "removebadge"},
                    ViewBadgesMenu = {Console = "sh_viewbadgse", Chat = "viewbadges"}
                }
            },
            CommandsMenu = {
                Enabled = false,
                RestrictedCommands = nil,
                ItemsPerPage = 10,
                CommandItems = {
                    AddCommandItemToMenu = {Console = "sh_addcommanditem", Chat = "addcommanditem"},
                    RemoveCommandItemFromMenu = {Console = "sh_removecommanditem", Chat = "removecommanditem"},
                    ViewCommandItemsMenu = {Console = "sh_viewcommanditems", Chat = "viewcommanditems"}
                }
            },
            SkinsMenu = {
                Enabled = false,
                ReservedSkins = nil,
                ItemsPerPage = 10,
                Commands = {
                    AddSkinToMenu = {Console = "sh_addskin", Chat = "addskin"},
                    RemoveSkinFromMenu = {Console = "sh_removeskin", Chat = "removeskin"},
                    ViewSkinsMenu = {Console = "sh_viewskins", Chat = "viewskins"}
                }
            }
        }
    }
}

Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true

Plugin.PlayerTimeTracker = {}
Plugin.PlayerCredits = {}

-- ==============================================
-- ============== Init System ===================
-- ==============================================

function Plugin:Initialise()
    self:LoadConfig()
    self.PlayerCredits = self:LoadUserCredits()
    sc_playerleveling:Initialise(self.Config.Settings.PlayerLeveling)
    sc_notification:Initialise(self.Config.Settings.Notification)
    sc_badges:Initialise(self.Config.Settings.RedemptionMenus, self)
    -- sc_commanditems:Initialise(self.Config.Settings.RedemptionMenus, self)
    -- sc_skins:Initialise(self.Config.Settings.RedemptionMenus, self)
    self:CreateCommands()
	return true
end

function Plugin:InitUser( Player )
    -- Initialise local copy of global files
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
end

function Plugin:ClientConnect( Client )
    self:InitUser( Client:GetControllingPlayer() )
end


-- ==============================================
-- ============== FileIO System =================
-- ==============================================

function Plugin:SaveUserCredits()
    return sc_json.SaveTable(self.PlayerCredits,
    self.Config.Settings.PlayerCredits.FilePath)
end

function Plugin:LoadUserCredits()
    return sc_json.LoadTable(self.Config.Settings.PlayerCredits.FilePath)
end

-- ==============================================
-- ======== Credits System (Time-Based) =========
-- ==============================================

-- ======= Functions to start and stop timing =======
-- Start credit for Player
function Plugin:StartCredits(Player)
    -- Initialise local copy of global files
    local PlayerTimeTracker = self.PlayerTimeTracker
    local StartTime = Shared.GetSystemTime()
    local SteamID = tostring(Player:GetSteamId())

    -- Store the time user started playing
    PlayerTimeTracker[SteamID] = StartTime
end

-- Stop credit for Player
function Plugin:StopCredits( Player )
    -- Initialise local copy of global files
    local PlayerCreditsSettings = self.Config.Settings.PlayerCredits
    local PlayerCredits = self.PlayerCredits
    local PlayerTimeTracker = self.PlayerTimeTracker
    local TotalPlaying = #Shine.GetTeamClients(1) + #Shine.GetTeamClients(2)
    local SteamID = tostring(Player:GetSteamId())

    -- Check if Player Time == 0 (i.e. already been stopped)
    -- and that game has minimum number of players required for credits to be awarded
    if PlayerTimeTracker[SteamID] == 0 or TotalPlaying <= PlayerCreditsSettings.MinimumNumberOfPlayers then
        sc_notification:Notify(Player,
            "No credits awarded. (Minimum players: " ..
            PlayerCreditsSettings.MinimumNumberOfPlayers ..
            " required)")
        return false
    end

    -- Calculate the amount of credits to award based on the time elapsed
    -- and the amount to award per minute elapsed
    EndTime = Shared.GetSystemTime()
    CreditsAwarded = math.Round((EndTime - PlayerTimeTracker[SteamID])/60, 0 ) * PlayerCreditsSettings.CreditsPerMinute
    PlayerTimeTracker[SteamID] = 0

    -- Reward the points accordingly
    PlayerCredits[SteamID].Total = PlayerCredits[SteamID].Total + CreditsAwarded
    PlayerCredits[SteamID].Current = PlayerCredits[SteamID].Current + CreditsAwarded

    self:SaveUserCredits()

    sc_notification:Notify(Player, CreditsAwarded .. " credits awarded.")

    sc_playerleveling:UpdatePlayerLevel( Player ,
        PlayerCredits[SteamID].Total)

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
        self:StopCredits(team1Player)
    end

    for _, team2Player in ipairs(team2Players) do
        self:StopCredits(team2Player)
    end
end

-- ======= Hooks to start credits =======
-- Called when a player joins a team in the midst of a game
function Plugin:PostJoinTeam( Gamerules, Player, OldTeam, NewTeam, Force, ShineForce )
    if Gamerules:GetGameStarted() then
        -- Check if team changed to is 0: Ready room , 3:Spectators
        if (NewTeam == 0 or NewTeam == 3) then
            self:StopCredits(Player)
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
-- ============== Commands ======================
-- ==============================================
-- Create the relevant commands for navigating the Shine Credit system
function Plugin:CreateCommands()
    self:CreateCreditsCommands()
end

-- ======= Credits System =======
function Plugin:CreateCreditsCommands()
    local ConfigFile = self.Config
    local CommandsFile = ConfigFile.Settings.PlayerCredits.Commands
    local PlayerCredits = self.PlayerCredits

    -- Set Credits
    local function SetCredits( Client, Targets, Amount )
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
        for i = 1, #Targets do
            SteamID = tostring(Targets[ i ]:GetUserId())
            PlayerCredits[SteamID].Total = PlayerCredits[SteamID].Total + Amount
            PlayerCredits[SteamID].Current = PlayerCredits[SteamID].Current + Amount
            self:SaveUserCredits()
            sc_playerleveling:UpdatePlayerLevel( Targets[i]:GetControllingPlayer(), PlayerCredits[SteamID].Total )
        end
    end
	local AddCreditsCommand = self:BindCommand( CommandsFile.AddCredits.Console,
        CommandsFile.AddCredits.Chat, AddCredits )
    AddCreditsCommand:AddParam{ Type = "clients", Help = "Player(s)" }
    AddCreditsCommand:AddParam{ Type = "number", Help = "Integer" }
	AddCreditsCommand:Help( "Adds credits to the specified player(s)" )

    -- Subtract Credits
    local function SubCredits( Client, Targets, Amount )
        for i = 1, #Targets do
            SteamID = tostring(Targets[ i ]:GetUserId())
            PlayerCredits[SteamID].Total = PlayerCredits[SteamID].Total - Amount
            PlayerCredits[SteamID].Current = PlayerCredits[SteamID].Current - Amount
            self:SaveUserCredits()
            sc_playerleveling:UpdatePlayerLevel( Targets[i]:GetControllingPlayer(), PlayerCredits[SteamID].Total )
        end
    end
	local SubCreditsCommand = self:BindCommand( CommandsFile.SubCredits.Console,
        CommandsFile.SubCredits.Chat, SubCredits )
    SubCreditsCommand:AddParam{ Type = "clients", Help = "Player(s)" }
    SubCreditsCommand:AddParam{ Type = "number", Help = "Credits:Integer" }
	SubCreditsCommand:Help( "Subtracts credits from the specified player(s)" )

    -- View Credits
    local function ViewCredits( Client )
        local LocalPlayer = Client:GetControllingPlayer()
        local LocalSteamID = tostring(LocalPlayer:GetSteamId())

        local ViewString = "Info for " .. Shine.GetClientInfo( Client ) .. "\n"
        .. "Total Credits: " .. PlayerCredits[LocalSteamID].Total
        .. " | Current Credits: " .. PlayerCredits[LocalSteamID].Current
        .. " | Level: " .. sc_playerleveling:GetPlayerLevel(LocalPlayer)

        sc_notification:Notify(LocalPlayer, ViewString)
        sc_notification:ConsoleMessage( LocalPlayer, ViewString )
    end

    local ViewCreditsCommand = self:BindCommand( CommandsFile.ViewCredits.Console,
        CommandsFile.ViewCredits.Chat, ViewCredits )
    ViewCreditsCommand:Help( "View Credits" )

end

Shine:RegisterExtension("sc_shinecredits", Plugin)
