local TerminalInput = {}

function TerminalInput.new(options)
    options = options or {}

    local self = {}

    self.ctx = options.ctx
    self.buffer = options.buffer
    self.renderer = options.renderer

    function self:getHistory()
        if self.ctx and self.ctx.history and self.ctx.history.get then
            return self.ctx.history:get()
        end

        return {}
    end

    function self:complete(input, cursor)
        if not self.ctx or not self.ctx.autocomplete then
            return input, cursor
        end

        local beforeCursor = string.sub(input, 1, cursor - 1)
        local afterCursor = string.sub(input, cursor)

        local matches = self.ctx.autocomplete:complete(self.ctx, beforeCursor)

        if not matches or #matches == 0 then
            return input, cursor
        end

        if #matches == 1 then
            local suffix = matches[1]

            input = beforeCursor .. suffix .. afterCursor
            cursor = cursor + #suffix

            return input, cursor
        end

        local width = term.getSize()

        self.buffer:addLine(table.concat(matches, "  "), width)

        return input, cursor
    end

    function self:read(prompt)
        local input = ""
        local cursor = 1

        local history = self:getHistory()
        local historyIndex = #history + 1

        while true do
            local layout = self.renderer:draw(prompt, input, cursor)
            local event, a = os.pullEvent()

            if event == "char" then
                input = string.sub(input, 1, cursor - 1) .. tostring(a) .. string.sub(input, cursor)
                cursor = cursor + #tostring(a)
                self.buffer:scrollToBottom()

            elseif event == "paste" then
                input = string.sub(input, 1, cursor - 1) .. tostring(a) .. string.sub(input, cursor)
                cursor = cursor + #tostring(a)
                self.buffer:scrollToBottom()

            elseif event == "mouse_scroll" then
                if a > 0 then
                    self.buffer:scrollBy(3, layout.outputH)
                else
                    self.buffer:scrollBy(-3, layout.outputH)
                end

            elseif event == "key" then
                local key = a

                if key == keys.enter then
                    term.setCursorBlink(false)
                    self.buffer:scrollToBottom()
                    return input

                elseif key == keys.tab then
                    input, cursor = self:complete(input, cursor)

                elseif key == keys.backspace then
                    if cursor > 1 then
                        input = string.sub(input, 1, cursor - 2) .. string.sub(input, cursor)
                        cursor = cursor - 1
                    end

                elseif key == keys.delete then
                    if cursor <= #input then
                        input = string.sub(input, 1, cursor - 1) .. string.sub(input, cursor + 1)
                    end

                elseif key == keys.left then
                    cursor = math.max(1, cursor - 1)

                elseif key == keys.right then
                    cursor = math.min(#input + 1, cursor + 1)

                elseif key == keys.home then
                    cursor = 1

                elseif key == keys["end"] then
                    cursor = #input + 1

                elseif key == keys.pageUp then
                    self.buffer:scrollBy(10, layout.outputH)

                elseif key == keys.pageDown then
                    self.buffer:scrollBy(-10, layout.outputH)

                elseif key == keys.up then
                    if #history > 0 then
                        historyIndex = math.max(1, historyIndex - 1)
                        input = history[historyIndex] or ""
                        cursor = #input + 1
                        self.buffer:scrollToBottom()
                    end

                elseif key == keys.down then
                    if #history > 0 then
                        historyIndex = math.min(#history + 1, historyIndex + 1)

                        if historyIndex > #history then
                            input = ""
                        else
                            input = history[historyIndex] or ""
                        end

                        cursor = #input + 1
                        self.buffer:scrollToBottom()
                    end
                end
            end
        end
    end

    return self
end

return TerminalInput