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
local CreditsMenu = require("shine/extensions/shinecredits/view/creditsmenu")
local SprayClient = require("shine/extensions/shinecredits/client/sprayclient")
local TrailClient = require("shine/extensions/shinecredits/client/trailclient")

function Plugin:Initialise()
    CreditsMenu:Initialise( Client, Plugin )

    -- Add Credits Menu to Vote Menu ==========================================
    Shine.VoteMenu:EditPage( "Main", function(self)
        self:AddSideButton( "Shine Credits", function()
            Shared.ConsoleCommand("sc_creditsmenu")
        Shine.VoteMenu:SetIsVisible(false,false)
        end )
    end)

	return true
end

-- ============================================================================
-- Handle Network Messages
-- ============================================================================

if Client then
    -- Credits Menu ===========================================================
    function Plugin:ReceiveMenuCommand( Data )
        CreditsMenu:ReceiveMenuCommand( Data )
    end

    function Plugin:ReceiveOpenCreditsMenu( Data )
         CreditsMenu:ReceiveOpenCreditsMenu( Data )
    end
    function Plugin:ReceiveUpdateCredits( Data )
         CreditsMenu:ReceiveUpdateCredits( Data )
    end

    -- Badges =================================================================
    function Plugin:ReceiveBadgeData( Data )
        CreditsMenu:ReceiveBadgeData( Data )
    end

    function Plugin:ReceiveBadgeRedeemResult( Data )
        CreditsMenu:ReceiveBadgeRedeemResult( Data )
    end

    -- Skins ==================================================================
    -- Command Items ==========================================================
    -- Sprays =================================================================

    function Plugin:ReceiveSprayData( Data )
        CreditsMenu:ReceiveSprayData( Data )
    end

    function Plugin:ReceiveSprayRedeemResult( Data )
        CreditsMenu:ReceiveSprayRedeemResult( Data )
    end

    function Plugin:ReceiveSprayEquipResult( Data )
        CreditsMenu:ReceiveSprayEquipResult( Data )
    end

    function Plugin:ReceivePrintSpray(message)
        SprayClient:PrintSpray(message)
    end

    -- Player Effects =========================================================
    function Plugin:ReceiveCreateTrail(message)
        TrailClient:CreateTrail(Client,message)
    end

end
