-- ============================================================================
--
-- Shine Credits System
--
-- Copyright (c) 2015 Kenneth
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

local Shine = Shine
local ShineCredits = {}
local Notifications = require("shine/extensions/shinecredits/utility/notifications")

-- Models
local Credits = require("shine/extensions/shinecredits/model/credits")
local Badges = require("shine/extensions/shinecredits/model/badges")
local Levels = require("shine/extensions/shinecredits/model/levels")
local BadgesMenu = require("shine/extensions/shinecredits/model/badgesmenu")

-- Controllers
local CreditsAwarding = require("shine/extensions/shinecredits/controller/creditsawarding")
local Levelling = require("shine/extensions/shinecredits/controller/levelling")
local BadgeRedemptions = require("shine/extensions/shinecredits/controller/badgeredemptions")

ShineCredits.Version = "2.4"
ShineCredits.PrintName = "Shine Credits"

ShineCredits.HasConfig = true
ShineCredits.ConfigName = "ShineCredits.json"

ShineCredits.DefaultConfig = {
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
            Badges = {
                Enabled = true,
                FileName = "ShineCredits_PlayerBadges.json",
                MaxBadgeRows = 8
            },
            Credits = {
                Enabled = true,
                FileName = "ShineCredits_PlayerCredits.json"
            },
            Levels = {
                Enabled = true,
                FileName = "ShineCredits_PlayerLevels.json"
            }
        },
        RedemptionMenus = {
            BadgesMenu = {
                Enabled = true,
                FileName = "ShineCredits_BadgesMenu.json"
            }
        },
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
            }
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
            ChatItemsPerPage = 10,
            Commands = {
                RedeemBadge = {Console = "sc_redeembadge", Chat="redeembadge"},
                ViewBadges = {Console = "sc_viewbadge", Chat="viewbadge"},
                AddBadge = {Console = "sc_addbadge", Chat="addbadge"},
                RemoveBadge = {Console = "sc_removebadge", Chat="removebadge"}
            }
        }
    },
    CreditsAwarding = {
        Enabled = true,
        ConfigDebug = true,
        Player = {
            Enabled = true,
            CreditsFormula = {
                MaximumAwardedPerRound = 500,
                Formula = {
                    Time = {
                        CreditsPerMinute = 1
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
            AddCredits = {Console  = "sc_addcredits", Chat = "addcredit"}
        }
    },

    Levelling = {
        Enabled = true,
        ConfigDebug = true,
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
                Formula = "x^1"
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
                MaximumAwardedPerRound = 5,
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
                Formula = "x^1"
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

ShineCredits.CheckConfig = true
ShineCredits.CheckConfigTypes = true

-- ============================================================================
-- Levelling:Initialise
-- Initialise the Shine Credits System
-- ============================================================================

function ShineCredits:Initialise()
    self:LoadConfig()

    self:TestCommands()

    -- Initialise Utilities
    self:InitialiseUtility()

    -- Initialise Models
    self:InitialiseModels()

    -- Initialise Controllers
    self:InitialiseControllers()

	return true
end

function ShineCredits:InitialiseUtility()
    Notifications:Initialise(self.Config.Utility.Notifications)
end

function ShineCredits:InitialiseModels()
    Badges:Initialise(self.Config.Storage)
    Credits:Initialise(self.Config.Storage)
    Levels:Initialise(self.Config.Storage)
    BadgesMenu:Initialise(self.Config.Storage)
end

function ShineCredits:InitialiseControllers()
    Levelling:Initialise(self.Config.Levelling,
    Notifications ,Badges, Levels, self)

    CreditsAwarding:Initialise(self.Config.CreditsAwarding,
    Notifications ,Credits, self)

    BadgeRedemptions:Initialise(self.Config.Redemptions.Badges,
    Notifications ,Badges, BadgesMenu, Credits, self)
end


-- ============================================================================
-- ----------------------------------------------------------------------------
-- Hooks
-- ----------------------------------------------------------------------------
-- ============================================================================

function ShineCredits:TestCommands()
    local function DrawDecal(client, material, scale, lifetime)
        local localPlayer = client:GetControllingPlayer()
        if localPlayer and material then
            -- trace to a surface and draw the decal
            local startPoint = localPlayer:GetEyePos()
            local endPoint = startPoint + localPlayer:GetViewCoords().zAxis * 100
            local trace = Shared.TraceRay(startPoint, endPoint,  CollisionRep.Default, PhysicsMask.Bullets, EntityFilterAll())

            if trace.fraction ~= 1 then

                local coords = Coords.GetTranslation(trace.endPoint)
                coords.yAxis = trace.normal
                coords.zAxis = coords.yAxis:GetPerpendicular()
                coords.xAxis = coords.yAxis:CrossProduct(coords.zAxis)

                scale = scale and tonumber(scale) or 1.5
                lifetime = lifetime and tonumber(lifetime) or 5

                client.CreateTimeLimitedDecal(material, coords, scale, lifetime)
                Shine:Print("created decal %s", ToString(material))
            else
                Shine:Print("usage: drawdecal <materialname> <scale>")
            end
        end
    end

    local TestSprayCommand = ShineCredits:BindCommand( "sc_testspray",
        "testspray", DrawDecal )
    TestSprayCommand:AddParam{ Type = "string", Help = "Material" }
    TestSprayCommand:AddParam{ Type = "number", Help = "Scale" }
    TestSprayCommand:AddParam{ Type = "number", Help = "Lifetime" }
	TestSprayCommand:Help( "Test Spray")
end

-- ============================================================================
-- ShineCredits:PostJoinTeam
-- Called when a player joins a team in the midst of a game
-- Used to provide controllers access to Shine Hooks
-- ============================================================================
-- Called when a player connects
function ShineCredits:ClientConnect( Client )
    local LocalPlayer = Client:GetControllingPlayer()

    Badges:InitPlayer(LocalPlayer)
    Credits:InitPlayer(LocalPlayer)
    Levels:InitPlayer(LocalPlayer)
end


--
function ShineCredits:PostJoinTeam( Gamerules, Player, OldTeam, NewTeam, Force,
     ShineForce )

    Levelling:PostJoinTeam( Gamerules, Player, OldTeam, NewTeam, Force,
     ShineForce )

    CreditsAwarding:PostJoinTeam( Gamerules, Player, OldTeam, NewTeam, Force,
     ShineForce )
end

-- Called when game starts or stops
function ShineCredits:SetGameState( Gamerules, NewState, OldState )
    Levelling:SetGameState( Gamerules, NewState, OldState )
    CreditsAwarding:SetGameState( Gamerules, NewState, OldState )

end

-- Called when the map changes
function ShineCredits:MapChange()
    Levelling:MapChange()
    CreditsAwarding:MapChange()
end

Shine:RegisterExtension("shinecredits", ShineCredits)
