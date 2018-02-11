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
function CreditsMenu:Initialise(Notifications,Menus, Plugin)
    self.Menus = Menus
    self:CreateMenuCommands(Plugin)
end

function CreditsMenu:CreateMenuCommands(Plugin)
    -- ====== Show GUI ======
    local function SendNetworkMessage( Client )
        local BadgesMenu = self.Menus.Badges:GetMenu()
        for Badge, Data in pairs(BadgesMenu) do
            Plugin:SendNetworkMessage( Client, "BadgeData",{
                Name = Badge,
                Description = Data.Description,
                Cost = Data.Cost}, true )

        end

        local SpraysMenu = self.Menus.Sprays:GetMenu()
        for Spray, Data in pairs(SpraysMenu) do
            Plugin:SendNetworkMessage( Client, "SprayData",{
                Name = Spray,
                Description = Data.Description,
                Cost = Data.Cost}, true )

        end

        Plugin:SendNetworkMessage( Client, "OpenCreditsMenu", {}, true )
    end
    local CreditsMenuCommand = Plugin:BindCommand( "sc_creditsmenu",
        "creditsmenu", SendNetworkMessage )
	CreditsMenuCommand:Help( "Opens the shine credits menu." )
end

return CreditsMenu
