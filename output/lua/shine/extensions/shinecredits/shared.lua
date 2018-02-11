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
local Plugin = {}

-- ============================================================================
-- Network Messages and Datatable
-- ============================================================================

function Plugin:SetupDataTable()
    self:AddNetworkMessage( "PrintSpray", {
        originX = "float",
        originY = "float",
        originZ = "float",
        yaw = "float",
        roll = "float",
        pitch = "float",
        name = "string (60)",
        lifetime = "float"
    }, "Client" )

    -- Badges =================================================================
    self:AddNetworkMessage( "BadgeData", {
        Name = "string (25)",
        Description = "string (255)",
        Cost = "integer (0 to 99999)"
    }, "Client" )

    self:AddNetworkMessage( "BadgeRedeemResult", { Badge = "string (25)",
        Result = "boolean" }
        , "Client" )

    -- Sprays =================================================================
    self:AddNetworkMessage( "SprayData", {
        Name = "string (25)",
        Description = "string (255)",
        Cost = "integer (0 to 99999)"
    }, "Client" )

    self:AddNetworkMessage( "SprayRedeemResult", { Badge = "string (25)",
        Result = "boolean" }
        , "Client" )

    self:AddNetworkMessage( "SprayEquipResult", { Badge = "string (25)",
        Result = "boolean" }
        , "Client" )

    -- Skins ==================================================================
    -- Command Items ==========================================================
    -- Sprays =================================================================

    self:AddNetworkMessage( "OpenCreditsMenu", {}, "Client" )
end

Shine:RegisterExtension("shinecredits", Plugin)
