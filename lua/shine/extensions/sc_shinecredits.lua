local Shine = Shine
local Plugin = {}
local sc_playerleveling = require("shine/extensions/shinecredits/sc_playerleveling")
local sc_notification = require("shine/extensions/shinecredits/sc_notification")
local sc_badgesmenu = require("shine/extensions/shinecredits/sc_badgesmenu")
local sc_playercredits = require("shine/extensions/shinecredits/sc_playercredits")
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
                BadgeRow = "1",
                CustomLevelBadgesOrder = {}
            },
            Permissions = {
                SuspendLevelingForGroups = {},
                AllowLevelingForGroups = {}
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
            Enabled = true,
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
                    CreditsPerMinute = 0.1,
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
            }
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
                ReservedBadges = {"level1","level2","level3","level4","level5","level6",
                    "level7","level8","level9","level10","level11","level12","level13","level14",
                    "level15","level16","level17","level18","level19","level20","level21","level22",
                    "level23","level24","level25","level26","level27","level28","level29","level30",
                    "level31","level32","level33","level34","level35","level36","level37","level38",
                    "level39","level40","level41","level42","level43","level44","level45","level46",
                    "level47","level48","level49","level50","level51","level52","level53","level54",
                    "level55"
                },
                ReservedBadgeRows = {"1"},
                MaximumAllowedBadges = 5,
                ItemsPerPage = 10,
                Commands = {
                    AddBadgeToMenu = {Console = "sh_addbadge", Chat = "addbadge"},
                    RemoveBadgeFromMenu = {Console = "sh_removebadge", Chat = "removebadge"},
                    ViewBadgesMenu = {Console = "sh_viewbadgse", Chat = "viewbadges"},
                    RedeemBadge = {Console = "sh_redeembadge", Chat = "redeembadge"}
                }
            },
            CommandsMenu = {
                Enabled = false,
                RestrictedCommands = nil,
                ItemsPerPage = 10,
                CommandItems = {
                    AddCommandItemToMenu = {Console = "sh_addcommanditem", Chat = "addcommanditem"},
                    RemoveCommandItemFromMenu = {Console = "sh_removecommanditem", Chat = "removecommanditem"},
                    ViewCommandItemsMenu = {Console = "sh_viewcommanditems", Chat = "viewcommanditems"},
                    RedeemCommand = {Console = "sh_redeemcommanditem", Chat = "redeemcommanditem"}
                }
            },
            SkinsMenu = {
                Enabled = false,
                ReservedSkins = nil,
                ItemsPerPage = 10,
                Commands = {
                    AddSkinToMenu = {Console = "sh_addskin", Chat = "addskin"},
                    RemoveSkinFromMenu = {Console = "sh_removeskin", Chat = "removeskin"},
                    ViewSkinsMenu = {Console = "sh_viewskins", Chat = "viewskins"},
                    RedeemSkin = {Console = "sh_redeemskin", Chat = "redeemskin"}
                }
            }
        }
    }
}

Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true

-- ==============================================
-- ============== Init System ===================
-- ==============================================

function Plugin:Initialise()
    self:LoadConfig()

    sc_playerleveling:Initialise(self.Config.Settings.PlayerLeveling)
    sc_notification:Initialise(self.Config.Settings.Notification)
    sc_badgesmenu:Initialise(self.Config.Settings.RedemptionMenus, self)
    sc_playercredits:Initialise(self.Config.Settings.PlayerCredits, self)
    -- sc_commanditems:Initialise(self.Config.Settings.RedemptionMenus, self)
    -- sc_skins:Initialise(self.Config.Settings.RedemptionMenus, self)

	return true
end

function Plugin:ClientConnect( Client )
    sc_playercredits:InitPlayer( Client:GetControllingPlayer() )
    sc_playerleveling:InitPlayer( Client:GetControllingPlayer() )
    sc_badgesmenu:InitPlayer( Client:GetControllingPlayer() )
end

-- ============================================================================
-- Hooks
-- ============================================================================
-- ======= Hooks to start credits =======
-- Called when a player joins a team in the midst of a game
function Plugin:PostJoinTeam( Gamerules, Player, OldTeam, NewTeam, Force, ShineForce )
    if Gamerules:GetGameStarted() then
        -- Check if team changed to is 0: Ready room , 3:Spectators
        if (NewTeam == 0 or NewTeam == 3) then
            sc_playercredits:StopCredits(Player)
        else
            sc_playercredits:StartCredits(Player)
        end
    end
end

-- Called when game starts or stops
function Plugin:SetGameState( Gamerules, NewState, OldState )
    -- If new state is 5:"Game Started"
    if NewState == 5 then
        sc_playercredits:StartCreditsAllInTeam()
    end

    -- If new state is 6:"Team 1 victory", 7:"Team 2 Victory" or 8:"Draw"
    if NewState >= 6 and NewState < 9 then
        sc_playercredits:StopCreditsAllInTeam()
    end
end

-- ======= Hooks to stop credits =======
-- Called during map change to save the changes made to the users' credits
function Plugin:MapChange()
    sc_playercredits:StopCreditsAllInTeam()
end

-- Called when server disconnects / Map Change to save the changes made to the users' credits
function Plugin:Cleanup()
    sc_playercredits:StopCreditsAllInTeam()
end

-- Called when the user disconnects mid-game
function Plugin:ClientDisconnect( Client )
    sc_playercredits:StopCredits(Client:GetControllingPlayer())
end

Shine:RegisterExtension("sc_shinecredits", Plugin)
