local LauncherData = dofile("apps/launcher/LauncherData.lua")
local LauncherView = dofile("apps/launcher/LauncherView.lua")
local HelpDialog = dofile("lib/help_dialog.lua")

local LauncherApp = {}

function LauncherApp.new(ctx, args)
    local self = {}

    self.ctx = ctx
    self.args = args or {}

    self.dataProvider = LauncherData.new(ctx)
    self.view = LauncherView.new(ctx)

    self.help = HelpDialog.new(ctx, {
        title = "Launcher Help",
        rows = {
            { key = "Enter", action = "Launch selected application" },
            { key = "Left click selected", action = "Launch selected application" },
            { key = "Wheel over list", action = "Move application selection" },
            { key = "Wheel over details", action = "Scroll application details" },
            { key = "Up / Down", action = "Move application selection" },
            { key = "PageUp / PageDown", action = "Move faster" },
            { key = "Home / End", action = "Jump to first / last application" },
            { key = "R", action = "Refresh application list" },
            { key = "Q / Esc", action = "Quit Launcher" },
            { key = "Right click", action = "Quit Launcher" },
            { key = "H", action = "Show this help" }
        }
    })

    self.selected = 1
    self.listScroll = 1
    self.detailsScroll = 1
    self.message = ""
    self.lastLayout = nil

    function self:resetDetailsScroll()
        self.detailsScroll = 1
    end

    function self:launchSelected(apps)
        local app = apps[self.selected]

        if not app then
            self.message = "No app selected."
            return
        end

        if app.id == "launcher" then
            self.message = "Launcher is already open."
            return
        end

        local ok, result = self.ctx.appManager:launch(app.id, {
            "open",
            app.id
        })

        if not ok then
            self.message = result or "Failed to launch app."
            return
        end

        self.message = "Returned from: " .. tostring(app.name)
    end

    function self:moveSelection(delta, apps)
        local oldSelected = self.selected

        self.selected = self.ctx.ui.List.move(self.selected, delta, #apps)

        if self.selected ~= oldSelected then
            self:resetDetailsScroll()
        end
    end

    function self:scrollDetails(delta)
        self.detailsScroll = self.detailsScroll + delta

        if self.detailsScroll < 1 then
            self.detailsScroll = 1
        end

        if self.lastLayout and self.lastLayout.maxDetailsScroll then
            if self.detailsScroll > self.lastLayout.maxDetailsScroll then
                self.detailsScroll = self.lastLayout.maxDetailsScroll
            end
        end
    end

    function self:handleKey(key, apps)
        if key == keys.q or key == keys.backspace or key == keys.escape then
            return "exit"
        end

        if key == keys.h then
            self.help:run()
            self.message = ""
            return nil
        end

        if key == keys.up then
            self:moveSelection(-1, apps)
            return nil
        end

        if key == keys.down then
            self:moveSelection(1, apps)
            return nil
        end

        if key == keys.pageUp then
            self:moveSelection(-5, apps)
            return nil
        end

        if key == keys.pageDown then
            self:moveSelection(5, apps)
            return nil
        end

        if key == keys.home then
            self.selected = 1
            self:resetDetailsScroll()
            return nil
        end

        if key == keys["end"] then
            self.selected = #apps
            self:resetDetailsScroll()
            return nil
        end

        if key == keys.enter then
            self:launchSelected(apps)
            return nil
        end

        if key == keys.r then
            self.message = "App list refreshed."
            return nil
        end

        return nil
    end

    function self:handleMouseScroll(direction, mouseX, mouseY, apps, layout)
        if not layout then
            return
        end

        local delta

        if direction > 0 then
            delta = 1
        else
            delta = -1
        end

        if self.view:isInsideDetails(layout, mouseX, mouseY) then
            self:scrollDetails(delta * 3)
            return
        end

        if self.view:isInsideList(layout, mouseX, mouseY) then
            self:moveSelection(delta, apps)
            return
        end

        self:moveSelection(delta, apps)
    end

    function self:handleMouseClick(button, mouseX, mouseY, apps, layout)
        if button ~= 1 then
            return "exit"
        end

        local index = self.view:hitTestList(layout, mouseX, mouseY, #apps)

        if index then
            local wasSelected = index == self.selected

            self.selected = index

            if not wasSelected then
                self:resetDetailsScroll()
            end

            if wasSelected then
                self:launchSelected(apps)
            end
        end

        return nil
    end

    function self:run()
        while true do
            local apps = self.dataProvider:listApps()

            if self.selected > #apps then
                self.selected = #apps
            end

            if self.selected < 1 then
                self.selected = 1
            end

            self.lastLayout = self.view:draw(apps, self.selected, {
                message = self.message,
                listScroll = self.listScroll,
                detailsScroll = self.detailsScroll
            })

            self.listScroll = self.lastLayout.listScroll or self.listScroll
            self.detailsScroll = self.lastLayout.detailsScroll or self.detailsScroll
            self.message = ""

            local event, a, b, c = os.pullEvent()

            if event == "key" then
                local result = self:handleKey(a, apps)

                if result == "exit" then
                    return true
                end
            elseif event == "mouse_scroll" then
                self:handleMouseScroll(a, b, c, apps, self.lastLayout)
            elseif event == "mouse_click" then
                local result = self:handleMouseClick(a, b, c, apps, self.lastLayout)

                if result == "exit" then
                    return true
                end
            end
        end
    end

    return self
end

return LauncherApp