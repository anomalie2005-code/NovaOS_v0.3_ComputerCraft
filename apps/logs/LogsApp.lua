local LogsData = dofile("apps/logs/LogsData.lua")
local LogsView = dofile("apps/logs/LogsView.lua")
local HelpDialog = dofile("lib/help_dialog.lua")

local LogsApp = {}

function LogsApp.new(ctx, args)
    local self = {}

    self.ctx = ctx
    self.args = args or {}

    self.dataProvider = LogsData.new(ctx)
    self.view = LogsView.new(ctx)

    self.help = HelpDialog.new(ctx, {
        title = "Logs Help",
        rows = {
            { key = "Wheel", action = "Scroll log lines" },
            { key = "Up / Down", action = "Scroll one line" },
            { key = "PageUp / PageDown", action = "Scroll faster" },
            { key = "Home / End", action = "Jump to start / end" },
            { key = "R", action = "Refresh log file" },
            { key = "C", action = "Clear system.log after confirmation" },
            { key = "Left click", action = "Refresh log file" },
            { key = "Right click", action = "Quit Logs" },
            { key = "Q / Esc", action = "Quit Logs" },
            { key = "H", action = "Show this help" }
        }
    })

    self.lines = {}
    self.info = {}
    self.scroll = 1
    self.maxScroll = 1

    function self:refresh()
        self.lines = self.dataProvider:readLines()
        self.info = self.dataProvider:getInfo()

        if self.scroll > self.maxScroll then
            self.scroll = self.maxScroll
        end

        if self.scroll < 1 then
            self.scroll = 1
        end
    end

    function self:draw()
        local result = self.view:draw(self.lines, {
            scroll = self.scroll
        }, self.info)

        self.scroll = result.scroll or self.scroll
        self.maxScroll = result.maxScroll or self.maxScroll

        if self.scroll < 1 then
            self.scroll = 1
        end

        if self.scroll > self.maxScroll then
            self.scroll = self.maxScroll
        end
    end

    function self:scrollBy(delta)
        self.scroll = self.scroll + delta

        if self.scroll < 1 then
            self.scroll = 1
        end

        if self.scroll > self.maxScroll then
            self.scroll = self.maxScroll
        end
    end

    function self:clearLog()
        local confirmed = self.view:confirmClear()

        if not confirmed then
            return
        end

        local ok, message = self.dataProvider:clear()

        if ok then
            self.scroll = 1
            self:refresh()
        else
            self.ctx.ui.Box.message(self.ctx, "Logs", message or "Failed to clear log.", self.ctx.theme.error)
            self:refresh()
        end
    end

    function self:handleKey(key)
        if key == keys.q or key == keys.escape or key == keys.backspace then
            return "exit"
        end

        if key == keys.h then
            self.help:run()
            return nil
        end

        if key == keys.up then
            self:scrollBy(-1)
            return nil
        end

        if key == keys.down then
            self:scrollBy(1)
            return nil
        end

        if key == keys.pageUp then
            self:scrollBy(-8)
            return nil
        end

        if key == keys.pageDown then
            self:scrollBy(8)
            return nil
        end

        if key == keys.home then
            self.scroll = 1
            return nil
        end

        if key == keys["end"] then
            self.scroll = self.maxScroll
            return nil
        end

        if key == keys.r then
            self:refresh()
            return nil
        end

        if key == keys.c then
            self:clearLog()
            return nil
        end

        return nil
    end

    function self:handleMouseScroll(direction)
        if direction > 0 then
            self:scrollBy(3)
        else
            self:scrollBy(-3)
        end
    end

    function self:handleMouseClick(button)
        if button ~= 1 then
            return "exit"
        end

        self:refresh()

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
            elseif event == "mouse_scroll" then
                self:handleMouseScroll(a)
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

return LogsApp