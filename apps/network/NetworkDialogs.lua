local NetworkDialogs = {}

function NetworkDialogs.new(ctx)
    local self = {}

    self.ctx = ctx

    function self:message(title, message, color)
        local ctx = self.ctx
        local theme = ctx.theme
        local Box = ctx.ui.Box

        ctx.screen:clear(theme.background, theme.text)

        local width, height = term.getSize()
        local boxW = math.min(width - 4, 56)
        local boxH = 9
        local boxX = math.floor((width - boxW) / 2) + 1
        local boxY = math.floor((height - boxH) / 2) + 1

        Box.draw(ctx, boxX, boxY, boxW, boxH, title or "Network")
        Box.writeInside(ctx, boxX, boxY, boxW, 3, tostring(message or ""), color or theme.foreground)
        Box.footer(ctx, boxX, boxY, boxW, boxH, "Press any key or click to continue")

        local event = os.pullEvent()

        while event ~= "key" and event ~= "mouse_click" do
            event = os.pullEvent()
        end
    end

    function self:askText(title, label, placeholder, value)
        if self.ctx.ui and self.ctx.ui.Input then
            return self.ctx.ui.Input.prompt(self.ctx, {
                title = title or "Input",
                label = label or "Value:",
                placeholder = placeholder or "",
                value = value or "",
                allowEmpty = false
            })
        end

        write((label or "Value") .. " ")
        return read()
    end

    function self:askComputerId()
        local value = self:askText(
            "Send message",
            "Target computer ID:",
            "Example: 12",
            ""
        )

        if not value then
            return nil
        end

        local id = tonumber(value)

        if not id then
            self:message("Network", "Invalid computer ID.", self.ctx.theme.error)
            return nil
        end

        return id
    end

    function self:askMessage(title)
        return self:askText(
            title or "Message",
            "Message:",
            "Type rednet message text",
            ""
        )
    end

    function self:receiveMessage(timeout)
        local ctx = self.ctx
        local theme = ctx.theme
        local Box = ctx.ui.Box

        ctx.screen:clear(theme.background, theme.text)

        local width, height = term.getSize()
        local boxW = math.min(width - 4, 58)
        local boxH = 10
        local boxX = math.floor((width - boxW) / 2) + 1
        local boxY = math.floor((height - boxH) / 2) + 1

        Box.draw(ctx, boxX, boxY, boxW, boxH, "Receive")
        Box.writeInside(ctx, boxX, boxY, boxW, 2, "Waiting for rednet message...", theme.accent2)
        Box.writeInside(ctx, boxX, boxY, boxW, 4, "Timeout: " .. tostring(timeout or 5) .. " seconds", theme.muted)
        Box.footer(ctx, boxX, boxY, boxW, boxH, "Please wait")

        local senderId, message, protocol = rednet.receive(nil, timeout or 5)

        if not senderId then
            return false, "No message received."
        end

        return true, {
            senderId = senderId,
            message = message,
            protocol = protocol
        }
    end

    return self
end

return NetworkDialogs