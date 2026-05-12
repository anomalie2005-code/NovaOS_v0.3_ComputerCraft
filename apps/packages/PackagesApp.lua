local PackagesData = dofile("apps/packages/PackagesData.lua")
local PackagesView = dofile("apps/packages/PackagesView.lua")
local PackageTemplate = dofile("apps/packages/PackageTemplate.lua")
local PackageOperations = dofile("apps/packages/PackageOperations.lua")
local HelpDialog = dofile("lib/help_dialog.lua")

local PackagesApp = {}

function PackagesApp.new(ctx, args)
    local self = {}

    self.ctx = ctx
    self.args = args or {}

    self.dataProvider = PackagesData.new(ctx)
    self.view = PackagesView.new(ctx)
    self.template = PackageTemplate.new(ctx)

    self.operations = PackageOperations.new(ctx, {
        confirm = function(_, title, message)
            local theme = ctx.theme
            local Box = ctx.ui.Box

            ctx.screen:clear(theme.background, theme.text)

            local width, height = term.getSize()
            local boxW = math.min(width - 4, 58)
            local boxH = 10
            local boxX = math.floor((width - boxW) / 2) + 1
            local boxY = math.floor((height - boxH) / 2) + 1

            Box.draw(ctx, boxX, boxY, boxW, boxH, title or "Confirm")
            Box.writeInside(ctx, boxX, boxY, boxW, 2, message or "Are you sure?", theme.warning)
            Box.writeInside(ctx, boxX, boxY, boxW, 4, "A backup will be created before deletion.", theme.muted)
            Box.footer(ctx, boxX, boxY, boxW, boxH, "Y: confirm   any other key/right click: cancel")

            local event, a = os.pullEvent()

            if event == "key" and a == keys.y then
                return true
            end

            return false
        end
    })

    self.help = HelpDialog.new(ctx, {
        title = "Package Manager Help",
        rows = {
            { key = "Enter", action = "Launch selected package" },
            { key = "Left click selected", action = "Launch selected package" },
            { key = "Wheel over list", action = "Move package selection" },
            { key = "Wheel over details", action = "Scroll package details" },
            { key = "Up / Down", action = "Move package selection" },
            { key = "PageUp / PageDown", action = "Move faster" },
            { key = "Home / End", action = "Jump to first / last package" },
            { key = "V", action = "Validate selected package" },
            { key = "B", action = "Backup selected package" },
            { key = "D", action = "Delete selected user package with backup" },
            { key = "R", action = "Repair selected package if possible" },
            { key = "F", action = "Open selected package folder in Files" },
            { key = "N", action = "Create new app package from template" },
            { key = "Q / Esc", action = "Quit Package Manager" },
            { key = "Right click", action = "Quit Package Manager" },
            { key = "H", action = "Show this help" }
        }
    })

    self.packages = {}
    self.summary = {}
    self.selected = 1
    self.listScroll = 1
    self.detailsScroll = 1
    self.message = ""
    self.lastLayout = nil

    function self:refresh()
        self.packages = self.dataProvider:listPackages()
        self.summary = self.dataProvider:getSummary(self.packages)

        if self.selected > #self.packages then
            self.selected = #self.packages
        end

        if self.selected < 1 then
            self.selected = 1
        end
    end

    function self:resetDetails()
        self.detailsScroll = 1
    end

    function self:moveSelection(delta)
        if #self.packages <= 0 then
            self.selected = 1
            return
        end

        local oldSelected = self.selected

        self.selected = self.selected + delta

        if self.selected < 1 then
            self.selected = 1
        end

        if self.selected > #self.packages then
            self.selected = #self.packages
        end

        if oldSelected ~= self.selected then
            self:resetDetails()
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

    function self:getSelectedPackage()
        return self.packages[self.selected]
    end

    function self:launchSelected()
        local package = self:getSelectedPackage()

        if not package then
            self.message = "No package selected."
            return
        end

        if package.id == "packages" then
            self.message = "Package Manager is already open."
            return
        end

        if not self.dataProvider:canLaunch(package) then
            self.message = "Cannot launch package: " .. tostring(package.status)
            return
        end

        local ok, result = self.ctx.appManager:launch(package.id, {
            "open",
            package.id
        })

        if not ok then
            self.message = result or "Failed to launch package."
            return
        end

        self.message = "Returned from: " .. tostring(package.name)
        self:refresh()
    end

    function self:openInFiles()
        local package = self:getSelectedPackage()

        if not package then
            self.message = "No package selected."
            return
        end

        local ok, result = self.ctx.appManager:launch("files", {
            "open",
            "files",
            package.appDir
        })

        if not ok then
            self.message = result or "Failed to open files."
            return
        end

        self.message = "Returned from Files."
        self:refresh()
    end

    function self:createPackage()
        local ok, message = self.template:createInteractive()

        self.message = message or ""

        self:refresh()

        if ok then
            for index, package in ipairs(self.packages) do
                if string.find(message or "", package.id, 1, true) then
                    self.selected = index
                    self:resetDetails()
                    break
                end
            end
        end
    end

    function self:validateSelected()
        local ok, message = self.operations:validate(self:getSelectedPackage())
        self.message = message or (ok and "Package is valid." or "Package is invalid.")
        self:refresh()
    end

    function self:backupSelected()
        local ok, message = self.operations:backup(self:getSelectedPackage())
        self.message = message or (ok and "Backup created." or "Backup failed.")
        self:refresh()
    end

    function self:deleteSelected()
        local oldSelected = self.selected
        local ok, message = self.operations:delete(self:getSelectedPackage())

        self.message = message or (ok and "Package deleted." or "Delete failed.")

        self:refresh()

        if ok then
            self.selected = math.min(oldSelected, #self.packages)

            if self.selected < 1 then
                self.selected = 1
            end

            self:resetDetails()
        end
    end

    function self:repairSelected()
        local ok, message = self.operations:repair(self:getSelectedPackage())
        self.message = message or (ok and "Package repaired." or "Repair failed.")
        self:refresh()
        self:resetDetails()
    end

    function self:handleKey(key)
        if key == keys.q or key == keys.backspace or key == keys.escape then
            return "exit"
        end

        if key == keys.h then
            self.help:run()
            self.message = ""
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
            self:resetDetails()
            return nil
        end

        if key == keys["end"] then
            self.selected = #self.packages
            self:resetDetails()
            return nil
        end

        if key == keys.enter then
            self:launchSelected()
            return nil
        end

        if key == keys.v then
            self:validateSelected()
            return nil
        end

        if key == keys.b then
            self:backupSelected()
            return nil
        end

        if key == keys.d then
            self:deleteSelected()
            return nil
        end

        if key == keys.r then
            self:repairSelected()
            return nil
        end

        if key == keys.f then
            self:openInFiles()
            return nil
        end

        if key == keys.n then
            self:createPackage()
            return nil
        end

        return nil
    end

    function self:handleMouseScroll(direction, mouseX, mouseY)
        local delta = direction > 0 and 1 or -1

        if self.lastLayout and self.view:isInsideDetails(self.lastLayout, mouseX, mouseY) then
            self:scrollDetails(delta * 3)
            return
        end

        self:moveSelection(delta)
    end

    function self:handleMouseClick(button, mouseX, mouseY)
        if button ~= 1 then
            return "exit"
        end

        if not self.lastLayout then
            return nil
        end

        local index = self.view:hitTestList(self.lastLayout, mouseX, mouseY, #self.packages)

        if index then
            local wasSelected = index == self.selected

            self.selected = index

            if not wasSelected then
                self:resetDetails()
            end

            if wasSelected then
                self:launchSelected()
            end

            return nil
        end

        self:refresh()

        return nil
    end

    function self:draw()
        self.lastLayout = self.view:draw(self.packages, self.selected, {
            listScroll = self.listScroll,
            detailsScroll = self.detailsScroll,
            message = self.message
        }, self.summary)

        self.selected = self.lastLayout.selected or self.selected
        self.listScroll = self.lastLayout.listScroll or self.listScroll
        self.detailsScroll = self.lastLayout.detailsScroll or self.detailsScroll

        self.message = ""
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
                self:handleMouseScroll(a, b, c)
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

return PackagesApp