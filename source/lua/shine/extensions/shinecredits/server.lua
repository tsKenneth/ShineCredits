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
local Levelling = require("shine/extensions/shinecredits/controller/levelling")


ShineCredits.Version = "1.0"
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
        }
    },
    Levelling = {
        Enabled = true,
        ConfigDebug = true,
        FileName = "ShineCredits_PlayerLevels.json",
        AwardedWhen = {
            Disconnected = true,
            MapChange = true,
            GameEnds = true
        },
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
                BadgesOrder = {
                    LevelBadgeNamePrefix = "level",
                    LevelBadgeNameSuffix = "",
                    BadgeRow = 1,
                },
                CustomBadgesOrder = {}
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
                BadgesOrder = {
                    LevelBadgeNamePrefix = "",
                    LevelBadgeNameSuffix = "",
                    BadgeRow = 2,
                },
                CustomBadgesOrder = {"bay_supporter","bay_silver",
                    "bay_red","bay_platinum","bay_gold"}
            }
        },
        Permissions = {
            SuspendLevelingForGroups = {}
        },
        Notifications = {
            LevelChange = "Leveled to level %s!" ..
                " (badge will be refreshed when map changes)"
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

    Levelling:Initialise(self.Config.Storage,
    self.Config.Levelling,
    Notifications,Badges)
	return true
end

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Hooks
-- ----------------------------------------------------------------------------
-- ============================================================================
-- ======= Hooks to start credits =======
-- Called when a player joins a team in the midst of a game
function ShineCredits:PostJoinTeam( Gamerules, Player, OldTeam, NewTeam, Force, ShineForce )
    Levelling:PostJoinTeam( Gamerules, Player, OldTeam, NewTeam, Force, ShineForce )
end

-- Called when game starts or stops
function ShineCredits:SetGameState( Gamerules, NewState, OldState )
    Levelling:SetGameState( Gamerules, NewState, OldState )

end

-- Called when a player connects
function ShineCredits:ClientConnect( Client )
    Levelling:ClientConnect( Client )
end

Shine:RegisterExtension("shinecredits", ShineCredits)
