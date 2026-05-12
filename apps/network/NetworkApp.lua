local NetworkData = dofile("apps/network/NetworkData.lua")
local NetworkView = dofile("apps/network/NetworkView.lua")
local NetworkDialogs = dofile("apps/network/NetworkDialogs.lua")
local HelpDialog = dofile("lib/help_dialog.lua")

local NetworkApp = {}

function NetworkApp.new(ctx, args)
    local self = {}

    self.ctx = ctx
    self.args = args or {}

    self.dataProvider = NetworkData.new(ctx)
    self.view = NetworkView.new(ctx)
    self.dialogs = NetworkDialogs.new(ctx)

    self.help = HelpDialog.new(ctx, {
        title = "Network Help",
        rows = {
            { key = "O", action = "Open first available modem for rednet" },
            { key = "C", action = "Close all open rednet modems" },
            { key = "S", action = "Send message to computer ID" },
            { key = "B", action = "Broadcast message to all computers" },
            { key = "L", action = "Listen for one rednet message" },
            { key = "R", action = "Refresh network status" },
            { key = "Left click", action = "Refresh network status" },
            { key = "Right click", action = "Quit Network" },
            { key = "Q / Esc", action = "Quit Network" },
            { key = "H", action = "Show this help" }
        }
    })

    self.data = nil
    self.message = ""

    function self:refresh()
        self.data = self.dataProvider:collect()
    end

    function self:draw()
        if not self.data then
            self:refresh()
        end

        self.view:draw(self.data, self.message)
        self.message = ""
    end

    function self:ensureOpen()
        if self.dataProvider:hasOpenModem() then
            return true
        end

        local ok, result = self.dataProvider:openFirst()

        if not ok then
            self.message = result or "Failed to open modem."
            self:refresh()
            return false
        end

        self.message = "Opened modem: " .. tostring(result)
        self:refresh()

        return true
    end

    function self:openFirst()
        local ok, result = self.dataProvider:openFirst()

        if ok then
            self.message = "Opened modem: " .. tostring(result)
        else
            self.message = result or "Failed to open modem."
        end

        self:refresh()
    end

    function self:closeAll()
        local ok, result = self.dataProvider:closeAll()

        if ok then
            self.message = "Closed all rednet modems."
        else
            self.message = result or "Failed to close modems."
        end

        self:refresh()
    end

    function self:sendMessage()
        if not self:ensureOpen() then
            return
        end

        local targetId = self.dialogs:askComputerId()

        if not targetId then
            return
        end

        local message = self.dialogs:askMessage("Send message")

        if not message then
            return
        end

        local ok, err = pcall(function()
            rednet.send(targetId, message)
        end)

        if ok then
            self.message = "Sent to #" .. tostring(targetId)
        else
            self.message = "Send failed: " .. tostring(err)
        end

        self:refresh()
    end

    function self:broadcastMessage()
        if not self:ensureOpen() then
            return
        end

        local message = self.dialogs:askMessage("Broadcast message")

        if not message then
            return
        end

        local ok, err = pcall(function()
            rednet.broadcast(message)
        end)

        if ok then
            self.message = "Broadcast sent."
        else
            self.message = "Broadcast failed: " .. tostring(err)
        end

        self:refresh()
    end

    function self:listenOnce()
        if not self:ensureOpen() then
            return
        end

        local ok, result = self.dialogs:receiveMessage(5)

        if not ok then
            self.message = result or "No message received."
            self:refresh()
            return
        end

        local text =
            "From #" ..
            tostring(result.senderId) ..
            ": " ..
            tostring(result.message)

        self.dialogs:message("Received", text, self.ctx.theme.success)

        self.message = "Received message from #" .. tostring(result.senderId)
        self:refresh()
    end

    function self:handleKey(key)
        if key == keys.q or key == keys.backspace or key == keys.escape then
            return "exit"
        end

        if key == keys.h then
            self.help:run()
            return nil
        end

        if key == keys.r then
            self:refresh()
            self.message = "Network status refreshed."
            return nil
        end

        if key == keys.o then
            self:openFirst()
            return nil
        end

        if key == keys.c then
            self:closeAll()
            return nil
        end

        if key == keys.s then
            self:sendMessage()
            return nil
        end

        if key == keys.b then
            self:broadcastMessage()
            return nil
        end

        if key == keys.l then
            self:listenOnce()
            return nil
        end

        return nil
    end

    function self:handleMouseClick(button)
        if button ~= 1 then
            return "exit"
        end

        self:refresh()
        self.message = "Network status refreshed."

        return nil
    end

    function self:run()
        self:refresh()

        while true do
            self:draw()

            local event, a = os.pullEvent()

            if event == "key" then
                local result = self:handleKey(a)

                if result == "exit" then
                    return true
                end
            elseif event == "mouse_click" then
                local result = self:handleMouseClick(a)

                if result == "exit" then
                    return true
                end
            end
        end
    end

    return self
end

return NetworkApp