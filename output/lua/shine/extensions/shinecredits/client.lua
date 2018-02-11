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

function Plugin:Initialise()
    CreditsMenu:Initialise( Client, Plugin )
	return true
end

-- ============================================================================
-- Handle Network Messages
-- ============================================================================

if Client then
    function Plugin:ReceiveOpenCreditsMenu( Data )
         CreditsMenu:ReceiveOpenCreditsMenu( Data )
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
        local origin = Vector(message.originX, message.originY, message.originZ)
        local coords = Angles(message.pitch, message.yaw, message.roll):GetCoords(origin)
        Client.CreateTimeLimitedDecal(
            string.format("ui/sprays/%s.material",message.name),
            coords, 1.5, message.lifetime)
    end
end
