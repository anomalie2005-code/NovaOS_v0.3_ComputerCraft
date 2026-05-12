local MonitorData = dofile("apps/monitor/MonitorData.lua")
local MonitorView = dofile("apps/monitor/MonitorView.lua")
local HelpDialog = dofile("lib/help_dialog.lua")

local MonitorApp = {}

function MonitorApp.new(ctx, args)
    local self = {}

    self.ctx = ctx
    self.args = args or {}

    self.dataProvider = MonitorData.new(ctx)
    self.view = MonitorView.new(ctx)

    self.help = HelpDialog.new(ctx, {
        title = "Monitor Help",
        rows = {
            { key = "Wheel", action = "Scroll monitor content" },
            { key = "Up / Down", action = "Scroll one row" },
            { key = "PageUp / PageDown", action = "Scroll faster" },
            { key = "Home / End", action = "Jump to start / end" },
            { key = "R", action = "Refresh system information" },
            { key = "Left click", action = "Refresh system information" },
            { key = "Right click", action = "Quit Monitor" },
            { key = "Q / Esc", action = "Quit Monitor" },
            { key = "H", action = "Show this help" }
        }
    })

    self.data = nil
    self.scroll = 1
    self.maxScroll = 1

    function self:refreshData()
        self.data = self.dataProvider:collect()

        if self.scroll > self.maxScroll then
            self.scroll = self.maxScroll
        end

        if self.scroll < 1 then
            self.scroll = 1
        end
    end

    function self:draw()
        if not self.data then
            self:refreshData()
        end

        local result = self.view:draw(self.data, {
            scroll = self.scroll
        })

        self.scroll = result.scroll or self.scroll
        self.maxScroll = result.maxScroll or self.maxScroll

        if self.scroll > self.maxScroll then
            self.scroll = self.maxScroll
        end

        if self.scroll < 1 then
            self.scroll = 1
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

    function self:handleKey(key)
        if key == keys.q or key == keys.backspace or key == keys.escape then
            return "exit"
        end

        if key == keys.h then
            self.help:run()
            return nil
        end

        if key == keys.r then
            self:refreshData()
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

        self:refreshData()

        return nil
    end

    function self:run()
        self:refreshData()

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

return MonitorApp