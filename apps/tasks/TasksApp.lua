local TasksData = dofile("apps/tasks/TasksData.lua")
local TasksView = dofile("apps/tasks/TasksView.lua")
local HelpDialog = dofile("lib/help_dialog.lua")

local TasksApp = {}

function TasksApp.new(ctx, args)
    local self = {}

    self.ctx = ctx
    self.args = args or {}

    self.dataProvider = TasksData.new(ctx)
    self.view = TasksView.new(ctx)

    self.help = HelpDialog.new(ctx, {
        title = "Tasks Help",
        rows = {
            { key = "Wheel", action = "Move task selection" },
            { key = "Up / Down", action = "Move task selection by one row" },
            { key = "PageUp / PageDown", action = "Move faster" },
            { key = "Home / End", action = "Jump to first / last task" },
            { key = "Left click row", action = "Select task row" },
            { key = "Left click outside", action = "Refresh task list" },
            { key = "R", action = "Refresh task list" },
            { key = "Right click", action = "Quit Tasks" },
            { key = "Q / Esc", action = "Quit Tasks" },
            { key = "H", action = "Show this help" }
        }
    })

    self.tasks = {}
    self.info = {}
    self.selected = 1
    self.scroll = 1
    self.lastLayout = nil

    function self:refresh()
        self.tasks = self.dataProvider:getTasks()
        self.info = self.dataProvider:getInfo()

        if self.selected > #self.tasks then
            self.selected = #self.tasks
        end

        if self.selected < 1 then
            self.selected = 1
        end
    end

    function self:draw()
        self.lastLayout = self.view:draw(self.tasks, {
            selected = self.selected,
            scroll = self.scroll
        }, self.info)

        self.selected = self.lastLayout.selected or self.selected
        self.scroll = self.lastLayout.scroll or self.scroll
    end

    function self:moveSelection(delta)
        if #self.tasks <= 0 then
            self.selected = 1
            self.scroll = 1
            return
        end

        self.selected = self.selected + delta

        if self.selected < 1 then
            self.selected = 1
        end

        if self.selected > #self.tasks then
            self.selected = #self.tasks
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

        if key == keys.up then
            self:moveSelection(-1)
            return nil
        end

        if key == keys.down then
            self:moveSelection(1)
            return nil
        end

        if key == keys.pageUp then
            self:moveSelection(-8)
            return nil
        end

        if key == keys.pageDown then
            self:moveSelection(8)
            return nil
        end

        if key == keys.home then
            self.selected = 1
            return nil
        end

        if key == keys["end"] then
            self.selected = #self.tasks
            return nil
        end

        if key == keys.r then
            self:refresh()
            return nil
        end

        return nil
    end

    function self:handleMouseScroll(direction)
        if direction > 0 then
            self:moveSelection(3)
        else
            self:moveSelection(-3)
        end
    end

    function self:handleMouseClick(button, mouseX, mouseY)
        if button ~= 1 then
            return "exit"
        end

        if self.lastLayout then
            local index = self.view:hitTestList(self.lastLayout, mouseX, mouseY, #self.tasks)

            if index then
                self.selected = index
                return nil
            end
        end

        self:refresh()

        return nil
    end

    function self:run()
        self:refresh()

        while true do
            self:draw()

            local event, a, b, c = os.pullEvent()

            if event == "key" then
                local result = self:handleKey(a)

                if result == "exit" then
                    return true
                end
            elseif event == "mouse_scroll" then
                self:handleMouseScroll(a)
            elseif event == "mouse_click" then
                local result = self:handleMouseClick(a, b, c)

                if result == "exit" then
                    return true
                end
            end
        end
    end

    return self
end

return TasksApp