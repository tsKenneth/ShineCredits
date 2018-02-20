-- ============================================================================
--
-- SprayRedemptions (Controller)
--      Allows managing and redemption of sprays
--
-- Dependencies: Requires sprays.lua, SpraysMenu.lua
-- and credits.lua to be enabled
-- ============================================================================

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Initialisation
-- ----------------------------------------------------------------------------
-- ============================================================================

local SprayRedemptions = { _version = "0.1.0" }

SprayRedemptions.RedemptionsFile = {}
SprayRedemptions.SprayCooldown = {}


-- ============================================================================
-- SprayRedemptions:Initialise
-- Initialise the Sprays Redemption Menu
-- ============================================================================
function SprayRedemptions:Initialise(SprayRedemptionsConfig,
    Notifications, Sprays, SpraysMenu, Credits, Plugin)
    -- Load Config File
    self.Settings = SprayRedemptionsConfig

    -- Checks if Config debug mode is enabled. Returns false if failed checking
    -- Debug mode can be turned off to improve performance
    if self.Settings.Enabled then
        self.Notifications = Notifications
        self.Credits = Credits
        self.SpraysMenu = SpraysMenu
        self.Sprays = Sprays
        self.Plugin = Plugin

        if self.Settings.ConfigDebug and not self:CheckConfig(self.Settings) then
            self.Settings.Enabled = false
            return false
        else
            self:CreateMenuCommands(Plugin)
            return true
        end
    else
        return false
    end
end

-- ============================================================================
-- SprayRedemptions:CheckConfig
-- Checks the config for correctness
-- ============================================================================

function SprayRedemptions:CheckConfig(CreditsAwardingConfig)
    local CheckFlag = true

    --- Check Dependencies
    if self.Credits:GetIsEnabled() == false then
        Shine:Print("ShineCredits SprayRedemptions:CheckConfig() - Error in config, " ..
            "Subsystem requires Credits model to be enabled.")
        CheckFlag = false
    end

    if self.SpraysMenu:GetIsEnabled() == false then
        Shine:Print("ShineCredits SprayRedemptions:CheckConfig() - Error in config, " ..
            "Subsystem requires SpraysMenu model to be enabled.")
        CheckFlag = false
    end

    if self.Sprays:GetIsEnabled() == false then
        Shine:Print("ShineCredits SprayRedemptions:CheckConfig() - Error in config, " ..
            "Subsystem requires SpraysMenu model to be enabled.")
        CheckFlag = false
    end

    return CheckFlag
end

-- ============================================================================
-- Functions
-- ============================================================================
-- ============================================================================
-- SprayRedemptions:AddSpray
-- Adds a new spray to the sprays menu
-- ============================================================================

function SprayRedemptions:AddSpray( SprayNameArg, DescriptionArg, CostArg )
    self.SpraysMenu:AddSpray(SprayNameArg, DescriptionArg, CostArg)
    return true
end

-- ============================================================================
-- SprayRedemptions:RemoveSpray
-- Removes a spray from the sprays menu
-- ============================================================================

function SprayRedemptions:RemoveSpray( SprayNameArg )
    return self.SpraysMenu:RemoveSpray(SprayNameArg)
end

-- ============================================================================
-- SprayRedemptions:RedeemSpray
-- Insert the redeemed spray into the player's userconfig
-- ============================================================================

function SprayRedemptions:RedeemSpray( Player, NewSpray )
    -- Checks if player already owns the spray
    if self.Sprays:GetIfPlayerHasSpray( Player, NewSpray ) then
        return false
    end

    -- Subtract credits by the cost, return false if insufficient credits
    if self.Credits:SpendPlayerCredits(Player ,
        self.SpraysMenu:GetInfo(NewSpray).Cost) then

        self.Sprays:AddSpray(Player, NewSpray)

        self.Credits:SaveCredits()
        self.Sprays:SavePlayerSprays()

        return true
    else
        return false
    end
end

-- ============================================================================
-- SprayRedemptions:EquipSpray
-- Equip a redeemed spray
-- ============================================================================
function SprayRedemptions:EquipSpray(Player, NewSpray)
    self.Plugin:SendNetworkMessage( Player:GetClient(), "SprayEquipResult",{
        Spray = NewSpray, Result = true}, true)
    return self.Sprays:EquipSpray(Player, NewSpray)
end

-- ============================================================================
-- SprayRedemptions:PrintSpray
-- Print the equipped spray onto the surface that player is facing
-- ============================================================================
function SprayRedemptions:PrintSpray(player)
    local origin = player:GetOrigin()
    local maxSprayDistance = self.Settings.MaxSprayDistance or 4

    -- Spam protection
    local SteamID = tostring(player:GetSteamId())
    if (self.SprayCooldown[SteamID] and Shared.GetTime() -
        self.SprayCooldown[SteamID] < self.Settings.SprayCooldown) then
        return false
    end

    -- Get player's equipped spray
    local EquippedSpray = self.Sprays:GetEquippedSpray(player)

    local startPoint = player:GetEyePos()
    local endPoint = startPoint + player:GetViewCoords().zAxis * 100
    local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Default,
        PhysicsMask.Bullets, EntityFilterAll())

    if trace.fraction ~= 1 then
        local direction = startPoint - trace.endPoint
        local distance = direction:GetLength()
        direction:Normalize()
        if distance > maxSprayDistance then return end

        local coords = Coords.GetIdentity()
        if trace.normal:CrossProduct(Vector(0,1,0)):GetLength() < 0.35 then
            -- We are looking at the floor, a slope or the ceiling, so rotate decal to face us
            local isFacingUp = trace.normal:DotProduct(Vector(0,1,0)) < 0
            coords.origin = trace.endPoint - 0.5 * trace.normal
            coords.yAxis = trace.normal

            if isFacingUp then
                coords.xAxis = direction
            else
                coords.xAxis = -direction
            end
            coords.zAxis = coords.xAxis:CrossProduct(coords.yAxis)
            coords.xAxis = coords.yAxis:CrossProduct(coords.zAxis)
        else
            -- We are looking at a wall, decal is always upright
            coords.origin = trace.endPoint - 0.5 * direction
            coords.yAxis = trace.normal
            coords.zAxis = coords.yAxis:GetPerpendicular()
            coords.xAxis = coords.yAxis:CrossProduct(coords.zAxis)

        end

        local angles = Angles()
        angles:BuildFromCoords(coords)

        local nearbyPlayers = GetEntitiesWithinRange("Player", origin, 20)
        for p = 1, #nearbyPlayers do
            self.Plugin:SendNetworkMessage( nearbyPlayers[p], "PrintSpray", {
                originX = coords.origin.x, originY = coords.origin.y,
                originZ = coords.origin.z,
                yaw = angles.yaw, pitch = angles.pitch, roll = angles.roll,
                name = EquippedSpray,
                lifetime = self.Settings.SprayDuration}, true )
        end

        self.SprayCooldown[SteamID] = Shared.GetTime()
    end
end


-- ============================================================================
-- Commands:
-- Navigate the Sprays Menu System
-- ============================================================================

function SprayRedemptions:CreateMenuCommands(Plugin)
    local Settings = self.Settings
    local Commands = Settings.Commands

    -- ====== Redeem Sprays ======
    local function RedeemSpray( Client , SprayNameArg)
        local LocalPlayer = Client:GetControllingPlayer()
        local ReturnMessage = ""

        if self.SpraysMenu:GetInfo( SprayNameArg ) then
            if self:RedeemSpray(LocalPlayer,SprayNameArg) then
                ReturnMessage = "Spray " .. SprayNameArg ..
                    " succesfully redeemed!"

                local LocalPlayerCredits = self.Credits:GetPlayerCredits(
                    LocalPlayer )

                self.Plugin:SendNetworkMessage( Client,
                    "UpdateCredits",{
                Current = LocalPlayerCredits.Current,
                Total = LocalPlayerCredits.Total}, true)

                self.Plugin:SendNetworkMessage( Client,
                    "SprayRedeemResult",{
                Spray = NewSpray, Result = true}, true)
            else
                ReturnMessage = "You already own the spray "..
                    "or you have insufficient credits to redeem the spray ("
                    .. SprayNameArg ..")"
                self.Plugin:SendNetworkMessage( Client,
                    "SprayRedeemResult",{
                Spray = NewSpray, Result = false}, true)
            end

        else
            ReturnMessage = "There are no sprays with name " .. SprayNameArg
            self.Plugin:SendNetworkMessage( Client,
                "SprayRedeemResult",{
            Spray = NewSpray, Result = false}, true)
        end

        self.Notifications:Notify(LocalPlayer, ReturnMessage)
    end

    local RedeemSprayCommand = Plugin:BindCommand( Commands.RedeemSpray.Console,
        Commands.RedeemSpray.Chat, RedeemSpray )
    RedeemSprayCommand:AddParam{ Type = "string", Help = "Spray Name: String" }
    RedeemSprayCommand:Help( "Redeems the spray with the name specified" )


    -- ====== View Sprays ======
    local function ViewSprays( Client )
        local LocalPlayer = Client:GetControllingPlayer()
        local LocalSpraysMenu = self.SpraysMenu:GetMenu()
        self.Notifications:Notify(LocalPlayer,string.format("%s %s %s",
            "[Name]", "Description -", "Cost"))

        for Name, Spray in pairs( LocalSpraysMenu ) do
            self.Notifications:Notify(LocalPlayer,
                string.format("[%s] %s - %s",
                Name, Spray.Description, Spray.Cost),false)
        end
        self.Notifications:Notify(LocalPlayer,
            "Type !redeemspray <sprayname> to redeem.",false)

    end

    local ViewItemMenuCommand = Plugin:BindCommand( Commands.ViewSprays.Console,
        Commands.ViewSprays.Chat, ViewSprays )
    ViewItemMenuCommand:Help( "View sprays redeemable with credits." )

    -- ====== Add Sprays ======
    local function AddSpray(Client, SprayNameArg, DescriptionArg, CostArg)
        local LocalPlayer = Client:GetControllingPlayer()
        local ReturnMessage = ""

        if CostArg == nil or CostArg < 0 then
            ReturnMessage = "Cost cannot be negative."
            self.Notifications:Notify(LocalPlayer, ReturnMessage)
            return false
        end

        if self:AddSpray(SprayNameArg, DescriptionArg, CostArg) then
            ReturnMessage = "Spray "
                .. SprayNameArg .. " had been added to menu."
        else
            ReturnMessage = "Spray " ..
                SprayNameArg .. " was not added."
        end

        self.Notifications:Notify(LocalPlayer, ReturnMessage)
    end

	local AddSprayCommand = Plugin:BindCommand( Commands.AddSpray.Console,
        Commands.AddSpray.Chat, AddSpray )
    AddSprayCommand:AddParam{ Type = "string", Help = "Spray Name:String" }
    AddSprayCommand:AddParam{ Type = "string", Help = "Description:String" }
    AddSprayCommand:AddParam{ Type = "number", Help = "Cost:Integer" }
	AddSprayCommand:Help( "Adds a new spray to the menu with the spray name," ..
        "description and cost provided." )

    -- ====== Remove Sprays ======
    local function RemoveSpray(Client, SprayNameArg)
        local LocalPlayer = Client:GetControllingPlayer()
        local ReturnMessage = ""

        if self:RemoveSpray(SprayNameArg) then
            ReturnMessage = "Spray "
                .. SprayNameArg .. " removed."
        else
            ReturnMessage = "Invalid spray "
                .. SprayNameArg .. " not found."
        end

        self.Notifications:Notify(LocalPlayer,ReturnMessage)
    end

    local RemoveSprayCommand = Plugin:BindCommand( Commands.RemoveSpray.Console,
        Commands.RemoveSpray.Chat, RemoveSpray )
    RemoveSprayCommand:AddParam{ Type = "string", Help = "Spray Name:String" }
	RemoveSprayCommand:Help( "Removes an Spray from the menu with the spray name specified." )

    -- ====== Equip Sprays ======
    local function EquipSpray(Client, SprayNameArg)
        local LocalPlayer = Client:GetControllingPlayer()
        local ReturnMessage = ""

        if self.Sprays:EquipSpray(LocalPlayer, SprayNameArg) then
            ReturnMessage = "Spray "
                .. SprayNameArg .. " equipped."
        else
            ReturnMessage = "Spray "
                .. SprayNameArg .. " has not been redeemed!"
        end

        self.Notifications:Notify(LocalPlayer,ReturnMessage)
    end

    local EquipSprayCommand = Plugin:BindCommand( Commands.EquipSpray.Console,
        Commands.EquipSpray.Chat, EquipSpray )
    EquipSprayCommand:AddParam{ Type = "string", Help = "Spray Name:String" }
	EquipSprayCommand:Help( "Equip the specified spray." )

    -- ====== Print Spray ======
    local function PrintSpray(Client)
        local LocalPlayer = Client:GetControllingPlayer()
        self:PrintSpray(LocalPlayer)
    end

    local PrintSprayCommand = Plugin:BindCommand( Commands.PrintSpray.Console,
        Commands.PrintSpray.Chat, PrintSpray )
	PrintSprayCommand:Help( "Use your equipped spray" )
end

return SprayRedemptions
