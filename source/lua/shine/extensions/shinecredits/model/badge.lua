-- ============================================================================
--
-- Badge (Model)
--      Shine Credits will manipulate badges for leveling and redemption
--      purposes. This model aims to manage inserting and removing badges.
--
-- This model obtains data from the levelling.lua and redemptions.lua
-- controllers and processes it
--
-- ============================================================================

local Shine = Shine
local Badges = { _version = "0.1.0" }

Badges.Settings = {
    MaxBadgeRows = 6
}

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Initialisation
-- ----------------------------------------------------------------------------
-- ============================================================================

function Badges:Initialise()
    return true
end

-- ============================================================================
-- ----------------------------------------------------------------------------
-- Helper Functions
-- ----------------------------------------------------------------------------
-- ============================================================================
-- ============================================================================
-- Badges:AddBadge
-- Adds a badge to the player
-- ============================================================================
function Badges:AddBadge( Player , NewBadge, BadgeRow )
    local Target = Player:GetClient()
    local Existing, _ = Shine:GetUserData( Target )

    if Existing["Badges"] then
        if BadgeRow then
            if Existing["Badges"][tostring(BadgeRow)] then
                table.insert(Existing["Badges"][tostring(BadgeRow)],NewBadge)
                return false
            else
                return false
            end
        else
            for k, row in pairs(Existing["Badges"]) do
                if type(row) == "table" then
                    table.insert(row,NewBadge)
                else
                    table.insert(Existing["Badges"],NewBadge)
                    return true
                end
            end
        end
    else
        Existing["Badge"] = NewBadge
        return true
    end
    return false

end

-- ============================================================================
-- Badges:RemoveBadge
-- Removes the specified badge from the player. only removes the first instance
-- ============================================================================
function Badges:RemoveBadge( Player , OldBadge, BadgeRow)
    local Target = Player:GetClient()
    local Existing, _ = Shine:GetUserData( Target )

    if Existing["Badges"] then
        if BadgeRow then
            local LocalBadgeRow = Existing["Badges"][tostring(BadgeRow)]
            for k, badge in pairs(LocalBadgeRow) do
                if OldBadgeName == badge then
                    table.remove(LocalBadgeRow, k)
                    return true
                end
            end
            return false
        else
            for k, row in pairs(Existing["Badges"]) do
                if type(row) == "table" then
                    for i, badge in pairs(row) do
                        if OldBadge == badge then
                            table.remove(row, i)
                            return true
                        end
                    end
                else
                    if row == badge then
                        table.remove(Existing["Badges"], k)
                        return true
                    end
                end
            end
        end
    else
        Existing["Badge"] = nil
        return true
    end
    return false
end

-- ============================================================================
-- Badges:SwitchBadge
-- Switches an old badge for a new badge
-- ============================================================================
function Badges:SwitchBadge( Player, OldBadge, NewBadge )
    local SuccessFlagRemove = false
    local SuccessFlagAdd = false

    SuccessFlagRemove = self:RemoveBadge(Player, OldBadge)
    SuccessFlagAdd = self:AddBadge(Player, NewBadge)

    Shine:SaveUsers( true )
    return SuccessFlagRemove and SuccessFlagAdd

end
