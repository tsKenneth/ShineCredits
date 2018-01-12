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
        error("ShineCredits SprayRedemptions:CheckConfig() - Error in config, " ..
            "Subsystem requires Credits model to be enabled.")
        CheckFlag = false
    end

    if self.SpraysMenu:GetIsEnabled() == false then
        error("ShineCredits SprayRedemptions:CheckConfig() - Error in config, " ..
            "Subsystem requires SpraysMenu model to be enabled.")
        CheckFlag = false
    end

    if self.Sprays:GetIsEnabled() == false then
        error("ShineCredits SprayRedemptions:CheckConfig() - Error in config, " ..
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
    local Settings = self.Settings
    -- Checks if player already owns the spray
    if self.Sprays:GetIfPlayerHasSpray( Player, NewSpray ) then
        return false
    end

    -- Subtract credits by the cost, return false if insufficient credits
    if self.Credits:SpendPlayerCredits(Player ,
        self.SpraysMenu:GetInfo(NewSpray).Cost) then

        for _,row in ipairs(Settings.SprayRows) do
            self.Sprays:AddSpray(Player, NewSpray, row)
        end
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
function SprayRedemptions:EquipSpray()
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
                    " succesfully redeemed!" ..
                    " (Will take effect after map changes)"
            else
                ReturnMessage = "You already own the spray "..
                    "or you have insufficient credits to redeem the spray ("
                    .. SprayNameArg ..")"
            end

        else
            ReturnMessage = "There are no sprays with name " .. SprayNameArg
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
        local LocalSpraysMenu = self.SpraysMenu:GetAllInfo()
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
                SprayNameArg .. " was not added;the spray might be reserved"
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
end

return SprayRedemptions
