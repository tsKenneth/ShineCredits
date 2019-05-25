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
    -- ========================================================================
    -- = General =
    -- ========================================================================
    -- Sprays =================================================================
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

    -- ========================================================================
    -- = Menu =
    -- ========================================================================
    -- General ================================================================
    self:AddNetworkMessage( "MenuCommand", {
        RedeemBadge = "string (255)",
        RedeemSpray = "string (255)",
        EquipSpray = "string (255)"
    }, "Client" )

    self:AddNetworkMessage( "OpenCreditsMenu", {
        CurrentCredits = "integer (0 to 99999)",
        TotalCredits = "integer (0 to 99999)"
    }, "Client" )

    self:AddNetworkMessage( "UpdateCredits", {
        CurrentCredits = "integer (0 to 99999)",
        TotalCredits = "integer (0 to 99999)"
    }, "Client" )

    self:AddNetworkMessage( "GUINotify", {
        Message = "string (255)",
        Duration = "integer (0 to 99999)"
    }, "Client" )


    -- Badges =================================================================
    self:AddNetworkMessage( "BadgeData", {
        Name = "string (255)",
        Description = "string (255)",
        Cost = "integer (0 to 99999)"
    }, "Client" )

    -- Sprays =================================================================
    self:AddNetworkMessage( "SprayData", {
        Name = "string (255)",
        Description = "string (255)",
        Cost = "integer (0 to 99999)"
    }, "Client" )

    -- Skins ==================================================================
    -- Command Items ==========================================================
    -- Effects ================================================================
    self:AddNetworkMessage( "CreateTrail", {
        TrailLink = "string (255)"}
        , "Client" )

end

Shine:RegisterExtension("shinecredits", Plugin)
