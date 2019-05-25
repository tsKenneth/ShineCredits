-- ============================================================================
-- ============= Notification System ==========================================
-- ============================================================================
-- Helper File to notify users of changes in the system

local Shine = Shine
local Notification = { _version = "0.1.0" }

-- ============================================================================
-- Default Config
-- ============================================================================

Notification.Settings =
{
    Enabled = true,
    Message = {
        Default = "",
        MessageRGB = {255,255,255}
    },
    Sender = {
        DefaultName = "[Shine Credits]",
        NameRGB = {255,20,30}
    }
}

function Notification:Initialise(NotificationSettings)
    if NotificationSettings and NotificationSettings.Enabled then
        self.Settings = NotificationSettings
        return true
    end
    return false
end

-- ============================================================================
-- Notification.Notify:
-- Sends a coloured server-initiated message to the player
-- ============================================================================
function Notification:Notify( Receiver, Message, Sender, MessageRGB,
    SenderRGB)

    -- Check if notification is enabled
    if not self.Settings.Enabled then
        return false
    end

    -- Initialise local variables with global values
    local Settings = self.Settings

    -- Check if optional parameters are filled
    local Msg = Message or Settings.Message.Default or ""
    local MsgRGB = MessageRGB or Settings.Sender.MessageRGB or {255,255,255}

    local Send = ""
    if Sender or Sender == nil then
        if type(Sender) == "string" then
            Send = Sender
        else
            Send = Settings.Sender.DefaultName or "[Shine Credits]"
        end
    else
        Send =  ""
    end


    local SendRGB = SenderRGB or Settings.Sender.NameRGB or {255,20,30}

    -- Check if Sender name is not String and Message is not String
    -- Throw error if either is true
    if type(Message) ~= "string" then
        error("ShineCredits sc_notification.lua: Message is not a string.")
        return false
    end

    -- Commit to the action: send message to the player with the specified
    -- settings

    Shine:NotifyDualColour(Receiver,
        SendRGB[1], SendRGB[2], SendRGB[3], Send,
        MsgRGB[1], MsgRGB[2], MsgRGB[3], Msg,
        nil)

    Shine:AdminPrint( Receiver:GetClient() , Msg )
    return true
end

-- ============================================================================
-- Notification.NotifyAll:
-- Sends a coloured server-initiated message to all players in the game
-- ============================================================================
function Notification:NotifyAll( Message, Sender, MessageRGB,SenderRGB )

    -- Check if notification is enabled
    if not self.Settings.Enabled then
        return false
    end

    -- Initialise local variables with global values
    local Settings = self.Settings

    -- Check if optional parameters are filled
    local Msg = Message or Settings.Message.Default or ""
    local MsgRGB = MessageRGB or Settings.Sender.MessageRGB or {255,255,255}

    local Send = ""
    if Sender or Sender == nil then
        if type(Sender) == "string" then
            Send = Sender
        else
            Send = Settings.Sender.DefaultName or "[Shine Credits]"
        end
    else
        Send =  ""
    end


    local SendRGB = SenderRGB or Settings.Sender.NameRGB or {255,20,30}

    -- Check if Sender name is not String and Message is not String
    -- Throw error if either is true
    if type(Message) ~= "string" then
        error("ShineCredits sc_notification.lua: Message is not a string.")
        return false
    end

    -- Commit to the action: send message to all players with the specified
    -- settings

    local AllPlayers = Shine.GetAllPlayers()

    for _, player in ipairs(AllPlayers) do
        Shine:NotifyDualColour(player,
            SendRGB[1], SendRGB[2], SendRGB[3], Send,
            MsgRGB[1], MsgRGB[2], MsgRGB[3], Msg,
            nil)

        Shine:AdminPrint( player:GetClient() , Msg )
    end


    return true
end

return Notification
