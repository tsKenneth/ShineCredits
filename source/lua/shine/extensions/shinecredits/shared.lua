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
local Plugin = {}

function Plugin:SetupDataTable()
    self:AddNetworkMessage( "CreateSpray", {
        originX = "float",
        originY = "float",
        originZ = "float",
        yaw = "float",
        roll = "float",
        pitch = "float",
        path = "string (60)"
    }, "Client" )
end


Shine:RegisterExtension("shinecredits", Plugin)
