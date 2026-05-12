local EditorDialogs = {}

local function cutText(text, maxLength)
    text = tostring(text or "")

    if maxLength <= 0 then
        return ""
    end

    if #text <= maxLength then
        return text
    end

    if maxLength <= 3 then
        return string.sub(text, 1, maxLength)
    end

    return string.sub(text, 1, maxLength - 3) .. "..."
end

local function padRight(text, width)
    text = tostring(text or "")

    if #text >= width then
        return string.sub(text, 1, width)
    end

    return text .. string.rep(" ", width - #text)
end

local function normalizeExtension(value)
    value = tostring(value or "")

    if value == "" then
        return ""
    end

    if string.sub(value, 1, 1) ~= "." then
        value = "." .. value
    end

    return value
end

function EditorDialogs.new(ctx)
    local self = {}

    self.ctx = ctx

    function self:message(title, message, color)
        local theme = self.ctx.theme
        local Box = self.ctx.ui.Box

        self.ctx.screen:clear(theme.background, theme.text)

        local width, height = term.getSize()
        local boxW = math.min(width - 4, 56)
        local boxH = 9
        local boxX = math.floor((width - boxW) / 2) + 1
        local boxY = math.floor((height - boxH) / 2) + 1

        Box.draw(self.ctx, boxX, boxY, boxW, boxH, title or "Message")
        Box.writeInside(self.ctx, boxX, boxY, boxW, 3, cutText(message or "", boxW - 4), color or theme.foreground)
        Box.footer(self.ctx, boxX, boxY, boxW, boxH, "Press any key or click to continue")

        while true do
            local event = os.pullEvent()

            if event == "key" or event == "mouse_click" then
                return true
            end
        end
    end

    function self:confirm(title, message)
        local theme = self.ctx.theme
        local Box = self.ctx.ui.Box

        self.ctx.screen:clear(theme.background, theme.text)

        local width, height = term.getSize()
        local boxW = math.min(width - 4, 58)
        local boxH = 10
        local boxX = math.floor((width - boxW) / 2) + 1
        local boxY = math.floor((height - boxH) / 2) + 1

        Box.draw(self.ctx, boxX, boxY, boxW, boxH, title or "Confirm")
        Box.writeInside(self.ctx, boxX, boxY, boxW, 2, cutText(message or "", boxW - 4), theme.warning)
        Box.writeInside(self.ctx, boxX, boxY, boxW, 4, "Y: yes   N/Esc/right click: no", theme.muted)
        Box.footer(self.ctx, boxX, boxY, boxW, boxH, "Y: confirm   anything else: cancel")

        local event, a = os.pullEvent()

        if event == "key" and a == keys.y then
            return true
        end

        return false
    end

    function self:input(title, label, placeholder, value)
        local theme = self.ctx.theme
        local Box = self.ctx.ui.Box

        local input = tostring(value or "")
        local cursor = #input + 1

        while true do
            self.ctx.screen:clear(theme.background, theme.text)

            local width, height = term.getSize()
            local boxW = math.min(width - 4, 58)
            local boxH = 12
            local boxX = math.floor((width - boxW) / 2) + 1
            local boxY = math.floor((height - boxH) / 2) + 1

            Box.draw(self.ctx, boxX, boxY, boxW, boxH, title or "Input")
            Box.writeInside(self.ctx, boxX, boxY, boxW, 2, label or "Value:", theme.foreground)

            if placeholder and placeholder ~= "" then
                Box.writeInside(self.ctx, boxX, boxY, boxW, 3, placeholder, theme.muted)
            end

            local fieldX = boxX + 2
            local fieldY = boxY + 6
            local fieldW = boxW - 4

            term.setCursorPos(fieldX, fieldY)
            term.setBackgroundColor(theme.background)
            term.setTextColor(theme.text)
            term.write("> " .. padRight(cutText(input, fieldW - 2), fieldW - 2))

            Box.footer(self.ctx, boxX, boxY, boxW, boxH, "Enter: confirm   Esc/F10/right click: cancel")

            local cursorX = fieldX + 1 + cursor

            if cursorX > fieldX + fieldW - 1 then
                cursorX = fieldX + fieldW - 1
            end

            term.setCursorPos(cursorX, fieldY)
            term.setCursorBlink(true)

            local event, a = os.pullEvent()

            if event == "char" then
                input = string.sub(input, 1, cursor - 1) .. tostring(a) .. string.sub(input, cursor)
                cursor = cursor + #tostring(a)

            elseif event == "paste" then
                input = string.sub(input, 1, cursor - 1) .. tostring(a) .. string.sub(input, cursor)
                cursor = cursor + #tostring(a)

            elseif event == "key" then
                if a == keys.enter then
                    term.setCursorBlink(false)

                    if input == "" then
                        return nil
                    end

                    return input

                elseif a == keys.backspace then
                    if cursor > 1 then
                        input = string.sub(input, 1, cursor - 2) .. string.sub(input, cursor)
                        cursor = cursor - 1
                    end

                elseif a == keys.delete then
                    if cursor <= #input then
                        input = string.sub(input, 1, cursor - 1) .. string.sub(input, cursor + 1)
                    end

                elseif a == keys.left then
                    cursor = math.max(1, cursor - 1)

                elseif a == keys.right then
                    cursor = math.min(#input + 1, cursor + 1)

                elseif a == keys.home then
                    cursor = 1

                elseif a == keys["end"] then
                    cursor = #input + 1

                elseif a == keys.escape or a == keys.f10 then
                    term.setCursorBlink(false)
                    return nil
                end

            elseif event == "mouse_click" then
                if a ~= 1 then
                    term.setCursorBlink(false)
                    return nil
                end
            end
        end
    end

    function self:chooseFormat(currentPath)
        local theme = self.ctx.theme
        local Box = self.ctx.ui.Box

        local currentName = fs.getName(currentPath or "untitled.txt")
        local currentExt = string.match(currentName, "%.[^%.]+$") or "(none)"

        local options = {
            { key = keys.one, char = "1", label = "Keep current", extension = nil },
            { key = keys.two, char = "2", label = "Plain text", extension = ".txt" },
            { key = keys.three, char = "3", label = "Lua script", extension = ".lua" },
            { key = keys.four, char = "4", label = "JSON", extension = ".json" },
            { key = keys.five, char = "5", label = "Markdown", extension = ".md" },
            { key = keys.six, char = "6", label = "Config", extension = ".cfg" },
            { key = keys.seven, char = "7", label = "Custom extension", extension = "custom" }
        }

        while true do
            self.ctx.screen:clear(theme.background, theme.text)

            local width, height = term.getSize()
            local boxW = math.min(width - 4, 58)
            local boxH = math.min(height - 4, 16)
            local boxX = math.floor((width - boxW) / 2) + 1
            local boxY = math.floor((height - boxH) / 2) + 1

            Box.draw(self.ctx, boxX, boxY, boxW, boxH, "Save format")
            Box.writeInside(self.ctx, boxX, boxY, boxW, 2, "Current: " .. cutText(currentName, boxW - 13), theme.accent2)
            Box.writeInside(self.ctx, boxX, boxY, boxW, 3, "Extension: " .. tostring(currentExt), theme.muted)

            local startY = 5

            for index, option in ipairs(options) do
                local extText = ""

                if option.extension == nil then
                    extText = ""
                elseif option.extension == "custom" then
                    extText = "..."
                else
                    extText = option.extension
                end

                Box.writeInside(
                    self.ctx,
                    boxX,
                    boxY,
                    boxW,
                    startY + index - 1,
                    option.char .. ". " .. option.label .. " " .. extText,
                    theme.foreground
                )
            end

            Box.footer(self.ctx, boxX, boxY, boxW, boxH, "1-7: select   Esc/right click: cancel")

            local event, a = os.pullEvent()

            if event == "key" then
                if a == keys.escape or a == keys.f10 then
                    return nil
                end

                for _, option in ipairs(options) do
                    if a == option.key then
                        if option.extension == "custom" then
                            local custom = self:input(
                                "Custom format",
                                "Extension:",
                                "Example: .html, .csv, .dat",
                                ".txt"
                            )

                            if not custom then
                                return nil
                            end

                            return normalizeExtension(custom)
                        end

                        return option.extension
                    end
                end

            elseif event == "char" then
                for _, option in ipairs(options) do
                    if a == option.char then
                        if option.extension == "custom" then
                            local custom = self:input(
                                "Custom format",
                                "Extension:",
                                "Example: .html, .csv, .dat",
                                ".txt"
                            )

                            if not custom then
                                return nil
                            end

                            return normalizeExtension(custom)
                        end

                        return option.extension
                    end
                end

            elseif event == "mouse_click" then
                if a ~= 1 then
                    return nil
                end
            end
        end
    end

    function self:help()
        local HelpDialog = dofile("lib/help_dialog.lua")

        local help = HelpDialog.new(self.ctx, {
            title = "Editor Help",
            rows = {
                { key = "F2", action = "Save current file" },
                { key = "F3", action = "Find text" },
                { key = "F4", action = "Go to line" },
                { key = "F5", action = "NovaPaste escaped text with \\n" },
                { key = "F6", action = "Import text from another file" },
                { key = "F7", action = "Save As with replace confirmation" },
                { key = "Ctrl+A", action = "Select all text" },
                { key = "Ctrl+C", action = "Copy selected text" },
                { key = "Ctrl+X", action = "Cut selected text" },
                { key = "Ctrl+V", action = "Paste internal editor clipboard" },
                { key = "Ctrl+S", action = "Save current file" },
                { key = "F10 / Esc", action = "Exit editor" },
                { key = "H", action = "Show this help" },
                { key = "Wheel", action = "Scroll document" },
                { key = "Left click text", action = "Move cursor" },
                { key = "Left click line number", action = "Select whole line" },
                { key = "Right click word", action = "Select word" },
                { key = "Left mouse drag", action = "Select text range" },
                { key = "Arrow keys", action = "Move cursor" },
                { key = "PageUp / PageDown", action = "Scroll faster" },
                { key = "Home / End", action = "Line start / line end" },
                { key = "Enter", action = "Insert new line" },
                { key = "Backspace", action = "Delete before cursor or selection" },
                { key = "Delete", action = "Delete after cursor or selection" },
                { key = "Tab", action = "Insert four spaces" }
            }
        })

        return help:run()
    end

    return self
end

return EditorDialogs