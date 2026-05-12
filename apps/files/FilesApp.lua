local FileScanner = dofile("apps/files/FileScanner.lua")
local FileActions = dofile("apps/files/FileActions.lua")
local FilePreview = dofile("apps/files/FilePreview.lua")
local FileDialogs = dofile("apps/files/FileDialogs.lua")
local FileOperations = dofile("apps/files/FileOperations.lua")
local FileHelp = dofile("apps/files/FileHelp.lua")

local FilesApp = {}

local function getStartPath(ctx, args)
    if type(args) == "table" then
        if args[3] and args[3] ~= "" then
            return ctx.filesystem:resolve(args[3])
        end

        if args[2] and args[2] ~= "" and args[2] ~= "files" then
            return ctx.filesystem:resolve(args[2])
        end
    end

    return ctx.filesystem.currentDir or ctx.config.homeDir
end

function FilesApp.new(ctx, args)
    local self = {}

    self.ctx = ctx
    self.args = args or {}

    self.scanner = FileScanner.new()
    self.actions = FileActions.new(ctx)
    self.dialogs = FileDialogs.new(ctx)
    self.operations = FileOperations.new(ctx, self.dialogs)
    self.preview = FilePreview.new(ctx, self.actions)
    self.help = FileHelp.new(ctx)

    self.currentPath = getStartPath(ctx, self.args)

    if not fs.exists(self.currentPath) or not fs.isDir(self.currentPath) then
        self.currentPath = ctx.filesystem.currentDir or ctx.config.homeDir
    end

    self.selected = 1
    self.message = ""

    function self:getSelectedEntry(entries)
        return entries[self.selected]
    end

    function self:setMessage(message)
        self.message = tostring(message or "")
    end

    function self:showOperationResult(ok, message)
        if ok then
            self:setMessage(message or "Done.")
        else
            self:setMessage(message or "Operation failed.")
        end
    end

    function self:draw(entries)
        local ctx = self.ctx
        local Box = ctx.ui.Box
        local List = ctx.ui.List
        local StatusBar = ctx.ui.StatusBar
        local theme = ctx.theme

        ctx.screen:clear(theme.background, theme.text)

        local width, height = term.getSize()

        local boxX = 2
        local boxY = 2
        local boxW = width - 2
        local boxH = height - 3

        Box.draw(ctx, boxX, boxY, boxW, boxH, "Files")
        Box.writeInside(ctx, boxX, boxY, boxW, 2, "Path: " .. ctx.filesystem:display(self.currentPath), theme.accent2)

        if self.message ~= "" then
            Box.writeInside(ctx, boxX, boxY, boxW, 3, self.message, theme.warning)
        else
            Box.writeInside(ctx, boxX, boxY, boxW, 3, "Enter: open   H: help   Q: quit", theme.muted)
        end

        Box.drawSeparator(ctx, boxX, boxY + 4, boxW)

        local listX = boxX + 2
        local listY = boxY + 5
        local listW = boxW - 4
        local listH = boxH - 8

        self.selected = List.clamp(self.selected, #entries)

        local scroll = List.getScroll(self.selected, listH, #entries)

        List.draw(ctx, {
            x = listX,
            y = listY,
            width = listW,
            height = listH,
            items = entries,
            selected = self.selected,
            scroll = scroll,
            emptyText = "(empty directory)"
        })

        Box.footer(
            ctx,
            boxX,
            boxY,
            boxW,
            boxH,
            "Enter: open   H: help   Q: quit"
        )

        StatusBar.drawBottom(ctx, "NovaOS / Files", ctx.filesystem:display(self.currentPath))

        return {
            listX = listX,
            listY = listY,
            listW = listW,
            listH = listH,
            scroll = scroll
        }
    end

    function self:goUp()
        self.currentPath = self.scanner:getParent(self.currentPath)
        self.selected = 1
        self.message = ""
    end

    function self:openSelected(entries)
        local entry = self:getSelectedEntry(entries)
        local action = self.actions:openEntry(entry)

        if not action then
            return
        end

        if action.type == "change_directory" then
            self.currentPath = action.path
            self.selected = 1
            self.message = ""
        elseif action.type == "preview_file" then
            self.preview:run(action.path)
            self.message = ""
        end
    end

    function self:editSelected(entries)
        local entry = self:getSelectedEntry(entries)

        if not entry then
            self:setMessage("No file selected.")
            return
        end

        if entry.kind ~= "file" then
            self:setMessage("Selected item is not a file.")
            return
        end

        local ok, message = self.actions:editFile(entry.path)

        if not ok then
            self:setMessage(message or "Cannot open editor.")
        else
            self:setMessage("Returned from editor.")
        end
    end

    function self:createFile()
        local ok, message = self.operations:createFile(self.currentPath)
        self:showOperationResult(ok, message)
    end

    function self:createDirectory()
        local ok, message = self.operations:createDirectory(self.currentPath)
        self:showOperationResult(ok, message)
    end

    function self:renameSelected(entries)
        local ok, message = self.operations:rename(self:getSelectedEntry(entries))
        self:showOperationResult(ok, message)
    end

    function self:deleteSelected(entries)
        local ok, message = self.operations:delete(self:getSelectedEntry(entries))
        self:showOperationResult(ok, message)

        if ok then
            self.selected = math.max(1, self.selected - 1)
        end
    end

    function self:copySelected(entries)
        local ok, message = self.operations:copy(self:getSelectedEntry(entries), self.currentPath)
        self:showOperationResult(ok, message)
    end

    function self:moveSelected(entries)
        local ok, message = self.operations:move(self:getSelectedEntry(entries), self.currentPath)
        self:showOperationResult(ok, message)

        if ok then
            self.selected = math.max(1, self.selected - 1)
        end
    end

    function self:handleKey(key, entries)
        if key == keys.q or key == keys.escape then
            self.ctx.filesystem.currentDir = self.currentPath
            return "exit"
        end

        if key == keys.h then
            self.help:run()
            self.message = ""
            return nil
        end

        if key == keys.up then
            self.selected = self.ctx.ui.List.move(self.selected, -1, #entries)
            self.message = ""
            return nil
        end

        if key == keys.down then
            self.selected = self.ctx.ui.List.move(self.selected, 1, #entries)
            self.message = ""
            return nil
        end

        if key == keys.pageUp then
            for _ = 1, 8 do
                self.selected = self.ctx.ui.List.move(self.selected, -1, #entries)
            end

            self.message = ""
            return nil
        end

        if key == keys.pageDown then
            for _ = 1, 8 do
                self.selected = self.ctx.ui.List.move(self.selected, 1, #entries)
            end

            self.message = ""
            return nil
        end

        if key == keys.backspace or key == keys.left then
            self:goUp()
            return nil
        end

        if key == keys.enter then
            self:openSelected(entries)
            return nil
        end

        if key == keys.e then
            self:editSelected(entries)
            return nil
        end

        if key == keys.n then
            self:createFile()
            return nil
        end

        if key == keys.d then
            self:createDirectory()
            return nil
        end

        if key == keys.r then
            self:renameSelected(entries)
            return nil
        end

        if key == keys.x or key == keys.delete then
            self:deleteSelected(entries)
            return nil
        end

        if key == keys.c then
            self:copySelected(entries)
            return nil
        end

        if key == keys.m then
            self:moveSelected(entries)
            return nil
        end

        return nil
    end

    function self:handleMouseScroll(direction, entries)
        if direction > 0 then
            self.selected = self.ctx.ui.List.move(self.selected, 1, #entries)
        else
            self.selected = self.ctx.ui.List.move(self.selected, -1, #entries)
        end

        self.message = ""
    end

    function self:handleMouseClick(button, mouseX, mouseY, entries, layout)
        if button ~= 1 then
            self:goUp()
            return
        end

        local index = self.ctx.ui.List.hitTest({
            x = layout.listX,
            y = layout.listY,
            width = layout.listW,
            height = layout.listH,
            scroll = layout.scroll,
            count = #entries
        }, mouseX, mouseY)

        if index then
            local wasSelected = index == self.selected

            self.selected = index
            self.message = ""

            if wasSelected then
                self:openSelected(entries)
            end
        end
    end

    function self:run()
        while true do
            local entries = self.scanner:scan(self.currentPath)

            if self.selected > #entries then
                self.selected = #entries
            end

            if self.selected < 1 then
                self.selected = 1
            end

            local layout = self:draw(entries)

            local event, a, b, c = os.pullEvent()

            if event == "key" then
                local result = self:handleKey(a, entries)

                if result == "exit" then
                    return true
                end
            elseif event == "mouse_scroll" then
                self:handleMouseScroll(a, entries)
            elseif event == "mouse_click" then
                self:handleMouseClick(a, b, c, entries, layout)
            end
        end
    end

    return self
end

return FilesApp