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

local Shine = Shine
local ShineCredits = {}
local Notifications = require("shine/extensions/shinecredits/utility/notifications")

-- Models
local Credits = require("shine/extensions/shinecredits/model/credits")
local Badges = require("shine/extensions/shinecredits/model/badges")
local Levels = require("shine/extensions/shinecredits/model/levels")

-- Controllers
local CreditsAwarding = require("shine/extensions/shinecredits/controller/creditsawarding")
local Levelling = require("shine/extensions/shinecredits/controller/levelling")


ShineCredits.Version = "2.0"
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
    BaseConfigs = {
        Badges = {
            FileName = "ShineCredits_PlayerBadges.json",
            MaxBadgeRows = 8
        },
        Credits = {
            FileName = "ShineCredits_PlayerCredits.json"
        },
        Levels = {
            FileName = "ShineCredits_PlayerLevels.json"
        }
    },
    CreditsAwarding = {
        Enabled = true,
        ConfigDebug = true,
        AwardedWhen = {
            Disconnected = true,
            MapChange = true,
            LeaveTeam = true,
            GameEnds = true
        },
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
            SetCredits = {Console  = "sh_setcredits", Chat = "setcredits"},
            ViewCredits = {Console  = "sh_viewcredits", Chat = "viewcredits"},
            AddCredits = {Console  = "sh_addcredits", Chat = "addcredit"}
        }
    },

    Levelling = {
        Enabled = true,
        ConfigDebug = true,
        AwardedWhen = {
            Disconnected = true,
            MapChange = true,
            LeaveTeam = true,
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
            SetXP = {Console  = "sh_setxp", Chat = "setxp"},
            ViewXP = {Console  = "sh_viewxp", Chat = "viewxp"},
            AddXP = {Console  = "sh_addxp", Chat = "addxp"}
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

    -- Initialise Models
    self:InitialiseModels()

    -- Initialise Controllers
    self:InitialiseControllers()

	return true
end

function ShineCredits:InitialiseModels()
    Badges:Initialise(self.Config.Storage,self.Config.BaseConfigs.Badges)
    Credits:Initialise(self.Config.Storage,self.Config.BaseConfigs.Credits)
    Levels:Initialise(self.Config.Storage,self.Config.BaseConfigs.Levels)
end

function ShineCredits:InitialiseControllers()
    Levelling:Initialise(self.Config.Levelling,
    Notifications ,Badges, Levels, self)

    CreditsAwarding:Initialise(self.Config.CreditsAwarding,
    Notifications ,Credits, self)
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
    CreditsAwarding:PostJoinTeam( Gamerules, Player, OldTeam, NewTeam, Force, ShineForce )
end

-- Called when game starts or stops
function ShineCredits:SetGameState( Gamerules, NewState, OldState )
    Levelling:SetGameState( Gamerules, NewState, OldState )
    CreditsAwarding:SetGameState( Gamerules, NewState, OldState )

end

-- Called when a player connects
function ShineCredits:ClientConnect( Client )
    self:InitPlayer(Client)
end

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Helper Functions
-- ----------------------------------------------------------------------------
-- ============================================================================
function ShineCredits:InitPlayer(Client)
    Badges:InitPlayer(Client:GetControllingPlayer())
    Credits:InitPlayer(Client:GetControllingPlayer())
    Levels:InitPlayer(Client:GetControllingPlayer())
end

Shine:RegisterExtension("shinecredits", ShineCredits)
