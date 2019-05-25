-- ============================================================================
--
-- Credits Menu (Controller)
--      A user-friendly GUI for players to easily preview and redeem items
--      Serves as the main hub for all the submenus
--
--      The contoller initiates all the functions that handles the hook
--      calls from the client
--
-- ============================================================================

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Initialisation
-- ----------------------------------------------------------------------------
-- ============================================================================
local CreditsMenu = { _version = "0.1.0" }

-- ============================================================================
-- CreditsMenu:Initialise
-- Initialise the Credits Menu GUI Controller
-- ============================================================================
function CreditsMenu:Initialise(Notifications, Menus, Models, ConfigFile, Credits, Plugin)
    self.Menus = Menus
    self.Models = Models
    self.Credits = Credits
    self.ConfigFile = ConfigFile
    self.Plugin = Plugin
    self:CreateMenuCommands(Plugin)
end

function CreditsMenu:CreateMenuCommands(Plugin)
    -- ====== Show GUI ======
    local function SendGUIMessage( Client )
        -- Init all the menus
        local BadgesMenu = self.Menus.BadgesMenu:GetMenu()
        for Badge, Data in pairs(BadgesMenu) do
            Plugin:SendNetworkMessage( Client, "BadgeData",{
                Name = Badge,
                Description = Data.Description,
                Cost = Data.Cost}, true )
        end

        local SpraysMenu = self.Menus.SpraysMenu:GetMenu()
        for Spray, Data in pairs(SpraysMenu) do
            Plugin:SendNetworkMessage( Client, "SprayData",{
                Name = Spray,
                Description = Data.Description,
                Cost = Data.Cost}, true )
        end

        -- Change the commands if necessary
        self.Plugin:SendNetworkMessage(Client, "MenuCommand", {
            RedeemBadge = self.ConfigFile.Redemptions.Badges.Commands.RedeemBadge.Console,
            RedeemSpray = self.ConfigFile.Redemptions.Sprays.Commands.RedeemSpray.Console,
            EquipSpray = self.ConfigFile.Redemptions.Sprays.Commands.EquipSpray.Console
            }, true )

        -- Open the credits menu
        local LocalPlayerCredits = self.Credits:GetPlayerCredits(
            Client:GetControllingPlayer() )

        Plugin:SendNetworkMessage( Client, "OpenCreditsMenu", {
            CurrentCredits = LocalPlayerCredits.Current,
            TotalCredits = LocalPlayerCredits.Total
        }, true )


    end
    local CreditsMenuCommand = Plugin:BindCommand( "sc_creditsmenu",
        "creditsmenu", SendGUIMessage,true, true  )
	CreditsMenuCommand:Help( "Opens the shine credits menu." )
end

return CreditsMenu
