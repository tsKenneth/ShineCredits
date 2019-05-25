-- ============================================================================
--
-- Shine Credits System
--
-- Copyright (c) 2018 Kenneth
--
-- This NS2 Mod is free; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--
-- ============================================================================

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Initialisation
-- ----------------------------------------------------------------------------
-- ============================================================================

-- Utilities
local Notifications = require("shine/extensions/shinecredits/utility/notifications")

-- Models
local Credits = require("shine/extensions/shinecredits/model/credits")
local Levels = require("shine/extensions/shinecredits/model/levels")
local Badges = require("shine/extensions/shinecredits/model/badges")
local Sprays = require("shine/extensions/shinecredits/model/sprays")

-- Models - Menus
local BadgesMenu = require("shine/extensions/shinecredits/model/badgesmenu")
local SpraysMenu = require("shine/extensions/shinecredits/model/spraysmenu")

-- Controllers
local CreditsAwarding = require("shine/extensions/shinecredits/controller/creditsawarding")
local Levelling = require("shine/extensions/shinecredits/controller/levelling")
local CreditsMenu = require("shine/extensions/shinecredits/controller/creditsmenu")

-- Controllers - Redemptions
local BadgeRedemptions = require("shine/extensions/shinecredits/controller/badgeredemptions")
local SprayRedemptions = require("shine/extensions/shinecredits/controller/sprayredemptions")

Plugin.Version = "2.15"
Plugin.PrintName = "Shine Credits"

Plugin.HasConfig = true
Plugin.ConfigName = "ShineCredits.json"

Plugin.DefaultConfig = {
    ServerSettings = {
        DefaultGroup = "DefaultGroup"
    },
    Storage = {
        Mode = "Files",
        Files = {
            Directory = "config://shine/shinecredits/"
        },
        WebServer = {
            Host = nil,
            Method = nil,
            Password = nil
        },
        Models = {
            Credits = {
                Enabled = true,
                StartingAmount = 50,
                FileName = "ShineCredits_PlayerCredits.json"
            },
            Levels = {
                Enabled = true,
                FileName = "ShineCredits_PlayerLevels.json"
            },
            Badges = {
                Enabled = true,
                FileName = "ShineCredits_PlayerBadges.json",
                MaxBadgeRows = 8
            },
            Sprays = {
                Enabled = true,
                MaxSprayDistance = 4,
                SprayCooldown = 10,
                SprayDuration = 10,
                FileName = "ShineCredits_PlayerSprays.json"
            },
            PlayerSkin = {
                Enabled = true,
                FileName = "ShineCredits_PlayerSkins.json"
            },
            CommanderSkins = {
                Enabled = true,
                FileName = "ShineCredits_CommanderSkins.json"
            },
            PlayerEffects = {
                Enabled = true,
                MaxNumberOfConcurrentEffects = 3,
                FileName = "ShineCredits_PlayerEffects.json"
            }
        },
        RedemptionMenus = {
            BadgesMenu = {
                Enabled = true,
                FileName = "ShineCredits_BadgesMenu.json"
            },
            SpraysMenu = {
                Enabled = true,
                FileName = "ShineCredits_SpraysMenu.json"
            },
            PlayerSkinsMenu = {
                Enabled = true,
                FileName = "ShineCredits_SkinsMenu.json"
            },
            CommanderSkinsMenu = {
                Enabled = true,
                FileName = "ShineCredits_CommanderSkinsMenu.json"
            },
            PlayerEffectsMenu = {
                Enabled = true,
                FileName = "ShineCredits_PlayerEffectsMenu.json"
            }
        }
    },
    Utility = {
        Notifications = {
            Enabled = true,
            Message = {
                Default = "",
                MessageRGB = {255,255,255}
            },
            Sender = {
                DefaultName = "[Shine Credits]",
                NameRGB = {255,20,30}
            },
        }
    },
    Redemptions = {
        Badges = {
            Enabled = true,
            ConfigDebug = true,
            BadgeRows = {3,4,5,6,7,8},
            ReservedBadges = {"level1","level2","level3","level4","level5",
                "level6","level7","level8","level9","level10","level11",
                "level12","level13","level14","level15","level16","level17",
                "level18","level19","level20","level21","level22","level23",
                "level24","level25","level26","level27","level28","level29",
                "level30","level31","level32","level33","level34","level35",
                "level36","level37","level38","level39","level40","level41",
                "level42","level43","level44","level45","level46","level47",
                "level48","level49","level50","level51","level52","level53",
                "level54","level55","bay_red","bay_silver","bay_supporter",
                "bay_gold","bay_platinum"
            },
            Commands = {
                RedeemBadge = {Console = "sc_redeembadge", Chat="redeembadge"},
                ViewBadges = {Console = "sc_viewbadges", Chat="viewbadges"},
                AddBadge = {Console = "sc_addbadge", Chat="addbadge"},
                RemoveBadge = {Console = "sc_removebadge", Chat="removebadge"}
            }
        },
        Sprays = {
            Enabled = true,
            ConfigDebug = true,
            Commands = {
                RedeemSpray = {Console = "sc_redeemspray", Chat="redeemspray"},
                ViewSprays = {Console = "sc_viewspray", Chat="viewspray"},
                AddSpray = {Console = "sc_addspray", Chat="addspray"},
                RemoveSpray = {Console = "sc_removespray", Chat="removespray"},
                EquipSpray = {Console = "sc_equipspray", Chat="equipspray"},
                PrintSpray = {Console = "sc_spray", Chat="spray"}
            }
        },
        PlayerSkins = {
            Enabled = true,
            ConfigDebug = true,
            Commands = {
                RedeemSkin = {Console = "sc_redeemskin", Chat="redeemskin"},
                ViewSkins = {Console = "sc_viewskins", Chat="viewskins"},
                AddSkin = {Console = "sc_addskin", Chat="addskin"},
                RemoveSkin = {Console = "sc_removeskin", Chat="removeskin"},
                EquipSkin = {Console = "sc_equipskin", Chat="equipskin"},
            }
        },
        CommanderSkins = {
            Enabled = true,
            ConfigDebug = true,
            Commands = {
                RedeemSkin = {Console = "sc_redeemcommskin", Chat="redeemcommskin"},
                ViewSkins = {Console = "sc_viewcommskins", Chat="viewcommskins"},
                AddSkin = {Console = "sc_addcommskin", Chat="addcommskin"},
                RemoveSkin = {Console = "sc_removecommskin", Chat="removecommskin"},
                EquipSkin = {Console = "sc_equipcommskin", Chat="equipcommskin"},
            }
        },
        PlayerEffects = {
            Enabled = true,
            ConfigDebug = true,
            Commands = {
                RedeemEffect = {Console = "sc_redeemeffect", Chat="redeemeffect"},
                ViewEffects = {Console = "sc_vieweffects", Chat="vieweffects"},
                AddEffect = {Console = "sc_addeffect", Chat="addeffect"},
                RemoveEffect = {Console = "sc_removeeffect", Chat="removeeffect"},
                EquipEffect = {Console = "sc_equipeffect", Chat="equipeffect"},
            }
        }
    },
    CreditsAwarding = {
        Enabled = true,
        ConfigDebug = true,
        MinPlayers = 6,
        Player = {
            Enabled = true,
            CreditsFormula = {
                MaximumAwardedPerRound = 300,
                Formula = {
                    Time = {
                        CreditsPerMinute = 1,
                        CommanderBonusCreditsPerMinute = 2
                    },
                    Score = {
                        CreditsPerScore = 0.1,
                        CreditsPerKill = 1,
                        CreditsPerAssist = 0.5
                    },
                    Multipliers = {
                        Victory = 1.2
                    }
                }
            },
            Notifications = {
                CreditsAwarded = "%s credits awarded!"
            }
        },
        Permissions = {
            SuspendCreditsForGroups = {}
        },
        Commands = {
            SetCredits = {Console  = "sc_setcredits", Chat = "setcredits"},
            ViewCredits = {Console  = "sc_viewcredits", Chat = "viewcredits"},
            AddCredits = {Console  = "sc_addcredits", Chat = "addcredit"},
            CreditsMultiplier = {Console  = "sc_multiplycredits", Chat = "multiplycredits"},
            TwoXCreditsMultiplier = {Console  = "sc_2xcredits", Chat = "2xcredits"},
            CheckCreditsMultiplier = {Console  = "sc_checkmultiplier", Chat = "checkmultiplier"}
        }
    },

    Levelling = {
        Enabled = true,
        ConfigDebug = true,
        MinPlayers = 6,
        Player = {
            Enabled = true,
            XPFormula = {
                MaximumAwardedPerRound = 500,
                Formula = {
                    Credits = false,
                    Time = {
                        XPPerMinute = 1
                    },
                    Score = {
                        XPPerScore = 0.1,
                        XPPerKill = 1,
                        XPPerAssist = 0.5
                    },
                    Multipliers = {
                        Victory = 1.2
                    }
                }
            },
            NextLevelFormula = {
                MaximumLevel = 55,
                Formula = "(30 * (x^2) - (30 * x))+300"
            },
            Badges = {
                Enabled = true,
                BadgeRow = 1,
                BadgesOrder = {
                    LevelBadgeNamePrefix = "level",
                    LevelBadgeNameSuffix = "",
                },
                CustomBadgesOrder = {}
            },
            Notifications = {
                LevelChange = "Player level increased to level %s!" ..
                    " (badge will be refreshed when map changes)"
            }
        },
        Commander = {
            Enabled = true,
            XPFormula = {
                MaximumAwardedPerRound = 500,
                Formula = {
                    Credits = false,
                    Time = {
                        XPPerMinute = 1
                    },
                    Multipliers = {
                        Victory = 1.2
                    }
                }
            },
            NextLevelFormula = {
                MaximumLevel = 5,
                Formula = "(1500 * (x^2) - (1500 * x))+300"
            },
            Badges = {
                Enabled = true,
                BadgeRow = 2,
                BadgesOrder = {
                    LevelBadgeNamePrefix = "",
                    LevelBadgeNameSuffix = "",
                },
                CustomBadgesOrder = {"bay_supporter","bay_silver",
                    "bay_red","bay_platinum","bay_gold"}
            },
            Notifications = {
                LevelChange = "Commander level increased to level %s!" ..
                    " (badge will be refreshed when map changes)"
            }
        },
        Permissions = {
            SuspendLevelingForGroups = {}
        },
        Commands = {
            SetXP = {Console  = "sc_setxp", Chat = "setxp"},
            ViewXP = {Console  = "sc_viewxp", Chat = "viewxp"},
            AddXP = {Console  = "sc_addxp", Chat = "addxp"}
        }
    }
}

Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true
Plugin.CheckConfigRecursively = true

-- ============================================================================
-- Levelling:Initialise
-- Initialise the Shine Credits System
-- ============================================================================

function Plugin:Initialise()
    self:LoadConfig()
    self:SaveConfig()

    -- Initialise Utilities
    self:InitialiseUtility()

    -- Initialise Models
    self:InitialiseModels()

    -- Initialise Controllers
    self:InitialiseControllers()

    -- Initialise Playground
    --self:Playground()

	return true
end

function Plugin:InitialiseUtility()
    Notifications:Initialise(self.Config.Utility.Notifications)
end

function Plugin:InitialiseModels()
    Credits:Initialise(self.Config.Storage)
    Levels:Initialise(self.Config.Storage)
    Badges:Initialise(self.Config.Storage, self.Config.ServerSettings)
    Sprays:Initialise(self.Config.Storage)

    BadgesMenu:Initialise(self.Config.Storage)
    SpraysMenu:Initialise(self.Config.Storage)
end

function Plugin:InitialiseControllers()
    Levelling:Initialise(self.Config.Levelling,
    Notifications ,Badges, Levels, self)

    CreditsAwarding:Initialise(self.Config.CreditsAwarding,
    Notifications, Credits, self)

    BadgeRedemptions:Initialise(self.Config.Redemptions.Badges,
    Notifications, Badges, BadgesMenu, Credits, self)

    SprayRedemptions:Initialise(self.Config.Redemptions.Sprays,
    Notifications, Sprays, SpraysMenu, Credits, self)

    CreditsMenu:Initialise(Notifications, {
        Badges=BadgesMenu,
        Sprays=SpraysMenu,
    }, self.Config,
    Credits, self)
end

function Plugin:Playground()
    local function EquipTrail(Client)
        local LocalPlayer = Client:GetControllingPlayer()

        self:SendNetworkMessage( Client, "CreateTrail", {
            TrailLink = "Sex",
            }, true )

        Notifications:Notify(LocalPlayer,"Trail Equipped")
    end

    local EquipTrailCommand = self:BindCommand("sc_equiptrail",
        "equiptrail", EquipTrail, true, true)
	EquipTrailCommand:Help( "Equip the specified trail." )
end

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Hooks
-- ----------------------------------------------------------------------------
-- ============================================================================

-- ============================================================================
-- Plugin:PostJoinTeam
-- Called when a player joins a team in the midst of a game
-- Used to provide controllers access to Shine Hooks
-- ============================================================================
-- Called when a player connects
function Plugin:ClientConnect( client )
    local LocalPlayer = client:GetControllingPlayer()

    Credits:InitPlayer(LocalPlayer)
    Levels:InitPlayer(LocalPlayer)
    Badges:InitPlayer(LocalPlayer)
    Sprays:InitPlayer(LocalPlayer)
end


-- Called when a player joins a team
function Plugin:PostJoinTeam( Gamerules, Player, OldTeam, NewTeam, Force,
     ShineForce )

    Levelling:PostJoinTeam( Gamerules, Player, OldTeam, NewTeam, Force,
     ShineForce )

    CreditsAwarding:PostJoinTeam( Gamerules, Player, OldTeam, NewTeam, Force,
     ShineForce )
end

-- Called when game starts or stops
function Plugin:SetGameState( Gamerules, NewState, OldState )
    Levelling:SetGameState( Gamerules, NewState, OldState )
    CreditsAwarding:SetGameState( Gamerules, NewState, OldState )
end

-- Called when the map changes
function Plugin:MapChange()
    Levelling:MapChange()
    CreditsAwarding:MapChange()
    SprayRedemptions:MapChange()
    BadgeRedemptions:MapChange()
end
