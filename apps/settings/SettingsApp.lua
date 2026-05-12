local SettingsStore = dofile("apps/settings/SettingsStore.lua")
local SettingsView = dofile("apps/settings/SettingsView.lua")

local SettingsApp = {}

function SettingsApp.new(ctx, args)
    local self = {}

    self.ctx = ctx
    self.args = args or {}
    self.store = SettingsStore.new(ctx)
    self.view = SettingsView.new(ctx)

    self.selected = 1
    self.message = ""

    function self:applyItem(item)
        if not item then
            return nil
        end

        if item.key == "username" then
            local value = self.view:promptText("Change username", self.ctx.config.username)
            local ok, message = self.store:setUsername(value)
            self.message = message or ""

            if not ok then
                self.message = message or "Failed to save username."
            end
        elseif item.key == "hostname" then
            local value = self.view:promptText("Change hostname", self.ctx.config.hostname)
            local ok, message = self.store:setHostname(value)
            self.message = message or ""

            if not ok then
                self.message = message or "Failed to save hostname."
            end
        elseif item.key == "theme" then
            local ok, message = self.store:nextTheme()

            if ok then
                self.message = "Theme changed to: " .. tostring(self.ctx.config.theme)
            else
                self.message = message or "Failed to change theme."
            end
        elseif item.key == "fetch" then
            local ok, message = self.store:toggleFetchOnBoot()

            if ok then
                self.message = "Fetch on boot: " .. tostring(self.ctx.config.showFetchOnBoot)
            else
                self.message = message or "Failed to update setting."
            end
        elseif item.key == "box" then
            local ok, message = self.store:toggleBoxStyle()

            if ok then
                self.message = "Box style: " .. tostring(self.ctx.config.boxStyle)
            else
                self.message = message or "Failed to update box style."
            end
        elseif item.key == "save" then
            local ok, message = self.store:save()

            if ok then
                self.message = "Settings saved to: data/settings.lua"
            else
                self.message = message or "Failed to save settings."
            end
        elseif item.key == "exit" then
            self.store:save()
            return "exit"
        end

        return nil
    end

    function self:handleKey(key, items)
        if key == keys.q or key == keys.backspace or key == keys.escape then
            self.store:save()
            return "exit"
        end

        if key == keys.up then
            self.selected = self.ctx.ui.List.move(self.selected, -1, #items)
            return nil
        end

        if key == keys.down then
            self.selected = self.ctx.ui.List.move(self.selected, 1, #items)
            return nil
        end

        if key == keys.enter then
            return self:applyItem(items[self.selected])
        end

        return nil
    end

    function self:handleMouseScroll(direction, items)
        if direction > 0 then
            self.selected = self.ctx.ui.List.move(self.selected, 1, #items)
        else
            self.selected = self.ctx.ui.List.move(self.selected, -1, #items)
        end
    end

    function self:handleMouseClick(button, mouseX, mouseY, items, layout)
        if button ~= 1 then
            self.store:save()
            return "exit"
        end

        local index = self.ctx.ui.List.hitTest({
            x = layout.listX,
            y = layout.listY,
            width = layout.listW,
            height = layout.listH,
            scroll = layout.scroll,
            count = #items
        }, mouseX, mouseY)

        if index then
            self.selected = index
            return self:applyItem(items[self.selected])
        end

        return nil
    end

    function self:run()
        while true do
            local items = self.store:getItems()

            if self.selected > #items then
                self.selected = #items
            end

            if self.selected < 1 then
                self.selected = 1
            end

            local layout = self.view:draw(items, self.selected, self.message)
            self.message = ""

            local event, a, b, c = os.pullEvent()

            if event == "key" then
                local result = self:handleKey(a, items)

                if result == "exit" then
                    return true
                end
            elseif event == "mouse_scroll" then
                self:handleMouseScroll(a, items)
            elseif event == "mouse_click" then
                local result = self:handleMouseClick(a, b, c, items, layout)

                if result == "exit" then
                    return true
                end
            end
        end
    end

    return self
end

return SettingsApp