-- ============================================================================
-- ============= GUI GUINotification System ======================================
-- ============================================================================
-- Helper File to notify users of changes in the system through the GUI

local Shine = Shine
local GUINotification = { _version = "0.1.0" }

-- ============================================================================
-- Default Config
-- ============================================================================

GUINotification.Settings =
{
    Enabled = true,
    PopupDuration = 10
}

function GUINotification:Initialise(GUINotificationSettings, Plugin)
    if GUINotificationSettings and GUINotificationSettings.Enabled then
        self.Settings = GUINotificationSettings
        self.Plugin = Plugin
        return true
    end
    return false
end

-- ============================================================================
-- GUINotification.Notify:
-- Sends a popup GUI notification to the user
-- ============================================================================
function GUINotification:Notify( Receiver, Message )

    -- Check if GUINotification is enabled
    if not self.Settings.Enabled then
        return false
    end

    self.Plugin:SendNetworkMessage( Receiver:GetClient(),
        "GUINotify",{
    Message = Message, Duration = self.Settings.PopupDuration}, true)

    return true
end

return GUINotification
