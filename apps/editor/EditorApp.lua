local EditorBuffer = dofile("apps/editor/EditorBuffer.lua")
local EditorView = dofile("apps/editor/EditorView.lua")
local EditorDialogs = dofile("apps/editor/EditorDialogs.lua")

local EditorApp = {}

local function getStartFile(ctx, args)
    if type(args) == "table" then
        if args[3] and args[3] ~= "" then
            return ctx.filesystem:resolve(args[3])
        end

        if args[2] and args[2] ~= "" and args[2] ~= "editor" then
            return ctx.filesystem:resolve(args[2])
        end
    end

    return ctx.filesystem:resolve("untitled.txt")
end

local function changeExtension(path, extension)
    if not extension then
        return path
    end

    path = tostring(path or "untitled.txt")
    extension = tostring(extension or "")

    if extension == "" then
        return path
    end

    if string.sub(extension, 1, 1) ~= "." then
        extension = "." .. extension
    end

    local dir = fs.getDir(path)
    local name = fs.getName(path)
    local base = string.gsub(name, "%.[^%.]+$", "")

    if base == "" then
        base = name
    end

    local newName = base .. extension

    if dir and dir ~= "" then
        return fs.combine(dir, newName)
    end

    return newName
end

local function normalizeNewlines(text)
    text = tostring(text or "")
    text = string.gsub(text, "\r\n", "\n")
    text = string.gsub(text, "\r", "\n")
    return text
end

local function decodeNovaPaste(text)
    text = tostring(text or "")
    text = string.gsub(text, "\\r\\n", "\n")
    text = string.gsub(text, "\\n", "\n")
    text = string.gsub(text, "\\t", "    ")
    return text
end

local function isModifierKey(key)
    local variants = {
        "leftCtrl",
        "rightCtrl",
        "leftControl",
        "rightControl",
        "leftCommand",
        "rightCommand",
        "leftMeta",
        "rightMeta",
        "leftSuper",
        "rightSuper"
    }

    for _, name in ipairs(variants) do
        if keys[name] and key == keys[name] then
            return true
        end
    end

    return false
end

local function isKeyName(key, name)
    return keys[name] and key == keys[name]
end

local function normalizeSelection(selection)
    if not selection then
        return nil
    end

    local aLine = selection.startLine
    local aCol = selection.startCol
    local bLine = selection.endLine
    local bCol = selection.endCol

    if not aLine or not aCol or not bLine or not bCol then
        return nil
    end

    if aLine > bLine or (aLine == bLine and aCol > bCol) then
        return {
            startLine = bLine,
            startCol = bCol,
            endLine = aLine,
            endCol = aCol
        }
    end

    return {
        startLine = aLine,
        startCol = aCol,
        endLine = bLine,
        endCol = bCol
    }
end

function EditorApp.new(ctx, args)
    local self = {}

    self.ctx = ctx
    self.args = args or {}

    self.filePath = getStartFile(ctx, args)
    self.buffer = EditorBuffer.new(self.filePath)
    self.view = EditorView.new(ctx)
    self.dialogs = EditorDialogs.new(ctx)

    self.cursorLine = 1
    self.cursorCol = 1
    self.scrollLine = 1
    self.scrollCol = 1
    self.message = ""
    self.lastLayout = nil

    self.selection = nil
    self.draggingSelection = false
    self.dragAnchor = nil

    self.clipboardText = ""
    self.modifierDown = false

    function self:clampCursor()
        if self.cursorLine < 1 then
            self.cursorLine = 1
        end

        if self.cursorLine > self.buffer:lineCount() then
            self.cursorLine = self.buffer:lineCount()
        end

        local line = self.buffer:getLine(self.cursorLine)

        if self.cursorCol < 1 then
            self.cursorCol = 1
        end

        if self.cursorCol > #line + 1 then
            self.cursorCol = #line + 1
        end
    end

    function self:clearSelection()
        self.selection = nil
        self.draggingSelection = false
        self.dragAnchor = nil
    end

    function self:hasSelection()
        local selection = normalizeSelection(self.selection)

        if not selection then
            return false
        end

        return not (
            selection.startLine == selection.endLine
            and selection.startCol == selection.endCol
        )
    end

    function self:setSelection(startLine, startCol, endLine, endCol)
        self.selection = {
            startLine = startLine,
            startCol = startCol,
            endLine = endLine,
            endCol = endCol
        }
    end

    function self:selectAll()
        local lastLine = self.buffer:lineCount()
        local lastCol = #self.buffer:getLine(lastLine) + 1

        self:setSelection(1, 1, lastLine, lastCol)

        self.cursorLine = lastLine
        self.cursorCol = lastCol
        self.message = "Selected all"
    end

    function self:selectLine(line)
        if line < 1 then
            line = 1
        end

        if line > self.buffer:lineCount() then
            line = self.buffer:lineCount()
        end

        local length = #self.buffer:getLine(line)

        self:setSelection(line, 1, line, length + 1)

        self.cursorLine = line
        self.cursorCol = length + 1
        self.message = "Selected line " .. tostring(line)
    end

    function self:selectWord(line, col)
        if line < 1 or line > self.buffer:lineCount() then
            return
        end

        local text = self.buffer:getLine(line)

        if text == "" then
            self:selectLine(line)
            return
        end

        if col < 1 then
            col = 1
        end

        if col > #text then
            col = #text
        end

        local function isWordChar(ch)
            return string.match(ch, "[%w_]") ~= nil
        end

        local startCol = col
        local endCol = col

        while startCol > 1 and isWordChar(string.sub(text, startCol - 1, startCol - 1)) do
            startCol = startCol - 1
        end

        while endCol <= #text and isWordChar(string.sub(text, endCol, endCol)) do
            endCol = endCol + 1
        end

        if startCol == endCol then
            self:setSelection(line, col, line, col + 1)
        else
            self:setSelection(line, startCol, line, endCol)
        end

        self.cursorLine = line
        self.cursorCol = endCol
        self.message = "Selected word"
    end

    function self:getSelectedText()
        local selection = normalizeSelection(self.selection)

        if not selection then
            return ""
        end

        if selection.startLine == selection.endLine then
            local line = self.buffer:getLine(selection.startLine)
            return string.sub(line, selection.startCol, selection.endCol - 1)
        end

        local lines = {}

        local firstLine = self.buffer:getLine(selection.startLine)
        table.insert(lines, string.sub(firstLine, selection.startCol))

        for lineIndex = selection.startLine + 1, selection.endLine - 1 do
            table.insert(lines, self.buffer:getLine(lineIndex))
        end

        local lastLine = self.buffer:getLine(selection.endLine)
        table.insert(lines, string.sub(lastLine, 1, selection.endCol - 1))

        return table.concat(lines, "\n")
    end

    function self:copySelection()
        if not self:hasSelection() then
            self.message = "Nothing selected"
            return
        end

        self.clipboardText = self:getSelectedText()

        if not fs.exists("data") then
            fs.makeDir("data")
        end

        local handle = fs.open("data/editor_clipboard.txt", "w")

        if handle then
            handle.write(self.clipboardText)
            handle.close()
        end

        self.message = "Copied selection"
    end

    function self:deleteSelection()
        local selection = normalizeSelection(self.selection)

        if not selection then
            return false
        end

        if selection.startLine == selection.endLine then
            local line = self.buffer:getLine(selection.startLine)
            local before = string.sub(line, 1, selection.startCol - 1)
            local after = string.sub(line, selection.endCol)

            self.buffer:setLine(selection.startLine, before .. after)

            self.cursorLine = selection.startLine
            self.cursorCol = selection.startCol
            self:clearSelection()

            return true
        end

        local firstLine = self.buffer:getLine(selection.startLine)
        local lastLine = self.buffer:getLine(selection.endLine)

        local before = string.sub(firstLine, 1, selection.startCol - 1)
        local after = string.sub(lastLine, selection.endCol)

        self.buffer.lines[selection.startLine] = before .. after

        for index = selection.endLine, selection.startLine + 1, -1 do
            table.remove(self.buffer.lines, index)
        end

        self.buffer.modified = true

        self.cursorLine = selection.startLine
        self.cursorCol = selection.startCol
        self:clearSelection()

        return true
    end

    function self:cutSelection()
        if not self:hasSelection() then
            self.message = "Nothing selected"
            return
        end

        self:copySelection()
        self:deleteSelection()
        self.message = "Cut selection"
    end

    function self:ensureCursorVisible()
        if not self.lastLayout then
            return
        end

        local layout = self.lastLayout

        if self.cursorLine < self.scrollLine then
            self.scrollLine = self.cursorLine
        end

        if self.cursorLine > self.scrollLine + layout.textH - 1 then
            self.scrollLine = self.cursorLine - layout.textH + 1
        end

        if self.cursorCol < self.scrollCol then
            self.scrollCol = self.cursorCol
        end

        if self.cursorCol > self.scrollCol + layout.contentW - 1 then
            self.scrollCol = self.cursorCol - layout.contentW + 1
        end

        if self.scrollLine < 1 then
            self.scrollLine = 1
        end

        if self.scrollCol < 1 then
            self.scrollCol = 1
        end
    end

    function self:draw()
        self:clampCursor()

        self.lastLayout = self.view:draw(self.filePath, self.buffer, {
            cursorLine = self.cursorLine,
            cursorCol = self.cursorCol,
            scrollLine = self.scrollLine,
            scrollCol = self.scrollCol,
            message = self.message,
            selection = self.selection
        })

        self:ensureCursorVisible()
        self.message = ""
    end

    function self:writeBufferToPath(targetPath)
        self.filePath = targetPath
        self.buffer.filePath = targetPath

        local ok, message = self.buffer:save()

        if ok then
            self.message = "Saved as " .. fs.getName(self.filePath)

            if self.ctx.logger then
                self.ctx.logger:info("File saved: " .. tostring(self.filePath))
            end
        else
            self.message = message or "Save failed."
        end

        return ok
    end

    function self:save()
        local extension = self.dialogs:chooseFormat(self.filePath)

        if extension == nil then
            self.message = "Save cancelled."
            return
        end

        local newPath = changeExtension(self.filePath, extension)

        if fs.exists(newPath) and newPath ~= self.filePath then
            local replace = self.dialogs:confirm(
                "Replace file",
                "File exists. Replace " .. fs.getName(newPath) .. "?"
            )

            if not replace then
                self.message = "Save cancelled: file exists"
                return
            end
        end

        self:writeBufferToPath(newPath)
    end

    function self:saveAs()
        while true do
            local value = self.dialogs:input(
                "Save As",
                "New file path:",
                "Example: /home/user/new-file.lua",
                self.filePath
            )

            if not value then
                self.message = "Save As cancelled."
                return
            end

            local targetPath = self.ctx.filesystem:resolve(value)
            local extension = self.dialogs:chooseFormat(targetPath)

            if extension == nil then
                self.message = "Save As cancelled."
                return
            end

            targetPath = changeExtension(targetPath, extension)

            if fs.exists(targetPath) and targetPath ~= self.filePath then
                local replace = self.dialogs:confirm(
                    "Replace file",
                    "File exists. Replace " .. fs.getName(targetPath) .. "?"
                )

                if replace then
                    self:writeBufferToPath(targetPath)
                    self.message = "Replaced " .. fs.getName(self.filePath)
                    return
                end

                self.dialogs:message(
                    "Choose another name",
                    "File was not replaced. Enter another file name.",
                    self.ctx.theme.warning
                )
            else
                self:writeBufferToPath(targetPath)
                return
            end
        end
    end

    function self:exit()
        if self.buffer.modified then
            local saveFirst = self.dialogs:confirm("Unsaved changes", "Save before exit?")

            if saveFirst then
                self:save()

                if self.buffer.modified then
                    return nil
                end
            end
        end

        term.setCursorBlink(false)
        return "exit"
    end

    function self:find()
        local query = self.dialogs:input("Find", "Search text:", "Text to find", "")

        if not query then
            self.message = "Find cancelled."
            return
        end

        local result = self.buffer:find(query, self.cursorLine, self.cursorCol + 1)

        if not result then
            result = self.buffer:find(query, 1, 1)
        end

        if not result then
            self.message = "Not found: " .. query
            return
        end

        self.cursorLine = result.line
        self.cursorCol = result.col
        self:setSelection(result.line, result.col, result.line, result.finishCol + 1)
        self.message = "Found: " .. query
        self:ensureCursorVisible()
    end

    function self:goToLine()
        local value = self.dialogs:input(
            "Go to line",
            "Line number:",
            "1 - " .. tostring(self.buffer:lineCount()),
            tostring(self.cursorLine)
        )

        if not value then
            self.message = "Go to line cancelled."
            return
        end

        local line = tonumber(value)

        if not line then
            self.message = "Invalid line number."
            return
        end

        if line < 1 then
            line = 1
        end

        if line > self.buffer:lineCount() then
            line = self.buffer:lineCount()
        end

        self.cursorLine = line
        self.cursorCol = 1
        self:clearSelection()
        self.message = "Line: " .. tostring(line)
        self:ensureCursorVisible()
    end

    function self:insertCharSafe(ch)
        ch = tostring(ch or "")

        if ch == "" then
            return
        end

        if self:hasSelection() then
            self:deleteSelection()
        end

        if ch == "\n" then
            self.cursorLine, self.cursorCol = self.buffer:newLine(self.cursorLine, self.cursorCol)
            return
        end

        if ch == "\t" then
            self:insertText("    ")
            return
        end

        self.cursorLine, self.cursorCol = self.buffer:insertChar(self.cursorLine, self.cursorCol, ch)
    end

    function self:insertText(text)
        text = normalizeNewlines(text)

        for index = 1, #text do
            local ch = string.sub(text, index, index)
            self:insertCharSafe(ch)
        end

        self:clampCursor()
        self:ensureCursorVisible()
    end

    function self:insertPastedText(text)
        text = normalizeNewlines(text)

        if text == "" then
            return
        end

        if self:hasSelection() then
            self:deleteSelection()
        end

        local lineCountBefore = self.buffer:lineCount()
        local startLine = self.cursorLine

        local currentLine = self.buffer:getLine(self.cursorLine)
        local beforeCursor = string.sub(currentLine, 1, self.cursorCol - 1)
        local afterCursor = string.sub(currentLine, self.cursorCol)

        local pastedLines = {}

        for line in string.gmatch(text .. "\n", "(.-)\n") do
            table.insert(pastedLines, line)
        end

        if #pastedLines == 0 then
            return
        end

        if #pastedLines == 1 then
            local newLine = beforeCursor .. pastedLines[1] .. afterCursor
            self.buffer:setLine(self.cursorLine, newLine)
            self.cursorCol = #beforeCursor + #pastedLines[1] + 1
            self:clearSelection()
            self:clampCursor()
            self:ensureCursorVisible()
            return
        end

        self.buffer:setLine(self.cursorLine, beforeCursor .. pastedLines[1])

        local insertAt = self.cursorLine + 1

        for index = 2, #pastedLines - 1 do
            table.insert(self.buffer.lines, insertAt, pastedLines[index])
            insertAt = insertAt + 1
        end

        table.insert(self.buffer.lines, insertAt, pastedLines[#pastedLines] .. afterCursor)

        self.buffer.modified = true

        self.cursorLine = startLine + #pastedLines - 1
        self.cursorCol = #pastedLines[#pastedLines] + 1

        local addedLines = self.buffer:lineCount() - lineCountBefore

        self.message = "Pasted " .. tostring(#pastedLines) .. " lines"

        if addedLines > 0 then
            self.message = self.message .. " (+" .. tostring(addedLines) .. ")"
        end

        self:clearSelection()
        self:clampCursor()
        self:ensureCursorVisible()
    end

    function self:novaPasteMode()
        local text = self.dialogs:input(
            "NovaPaste",
            "Paste escaped text:",
            "Use \\n for new lines, \\t for tabs",
            ""
        )

        if not text then
            self.message = "NovaPaste cancelled"
            return
        end

        self:insertPastedText(decodeNovaPaste(text))
        self.message = "NovaPaste inserted"
    end

    function self:importFromFile()
        local path = self.dialogs:input(
            "Import file",
            "File path:",
            "Example: /home/user/code.lua",
            ""
        )

        if not path then
            self.message = "Import cancelled"
            return
        end

        path = self.ctx.filesystem:resolve(path)

        if not fs.exists(path) then
            self.message = "File not found: " .. path
            return
        end

        if fs.isDir(path) then
            self.message = "Cannot import directory"
            return
        end

        local handle = fs.open(path, "r")

        if not handle then
            self.message = "Cannot open file"
            return
        end

        local content = handle.readAll() or ""
        handle.close()

        self:insertPastedText(content)
        self.message = "Imported: " .. fs.getName(path)
    end

    function self:pasteInternalClipboard()
        local text = self.clipboardText

        if (not text or text == "") and fs.exists("data/editor_clipboard.txt") then
            local handle = fs.open("data/editor_clipboard.txt", "r")

            if handle then
                text = handle.readAll() or ""
                handle.close()
            end
        end

        if not text or text == "" then
            self.message = "Clipboard is empty"
            return
        end

        self:insertPastedText(text)
        self.message = "Pasted clipboard"
    end

    function self:handleChar(ch)
        self:insertCharSafe(ch)
    end

    function self:handlePaste(text)
        local normalized = normalizeNewlines(text)

        self:insertPastedText(normalized)
        self.message = "External paste received. If only first line appears, use F5 or F6."
    end

    function self:handleShortcut(key)
        if not self.modifierDown then
            return false
        end

        if isKeyName(key, "a") then
            self:selectAll()
            return true
        end

        if isKeyName(key, "c") then
            self:copySelection()
            return true
        end

        if isKeyName(key, "x") then
            self:cutSelection()
            return true
        end

        if isKeyName(key, "v") then
            self:pasteInternalClipboard()
            return true
        end

        if isKeyName(key, "s") then
            self:save()
            return true
        end

        return false
    end

    function self:handleKey(key)
        if isModifierKey(key) then
            self.modifierDown = true
            return nil
        end

        if self:handleShortcut(key) then
            return nil
        end

        if key == keys.f2 then
            self:save()
            return nil
        end

        if key == keys.f3 then
            self:find()
            return nil
        end

        if key == keys.f4 then
            self:goToLine()
            return nil
        end

        if key == keys.f5 then
            self:novaPasteMode()
            return nil
        end

        if key == keys.f6 then
            self:importFromFile()
            return nil
        end

        if key == keys.f7 then
            self:saveAs()
            return nil
        end

        if key == keys.h then
            self.dialogs:help()
            return nil
        end

        if key == keys.f10 or key == keys.escape then
            return self:exit()
        end

        if key == keys.enter then
            if self:hasSelection() then
                self:deleteSelection()
            end

            self.cursorLine, self.cursorCol = self.buffer:newLine(self.cursorLine, self.cursorCol)
            return nil
        end

        if key == keys.tab then
            self:insertText("    ")
            return nil
        end

        if key == keys.backspace then
            if self:hasSelection() then
                self:deleteSelection()
            else
                self.cursorLine, self.cursorCol = self.buffer:backspace(self.cursorLine, self.cursorCol)
            end

            return nil
        end

        if key == keys.delete then
            if self:hasSelection() then
                self:deleteSelection()
            else
                self.cursorLine, self.cursorCol = self.buffer:delete(self.cursorLine, self.cursorCol)
            end

            return nil
        end

        if key == keys.up then
            self.cursorLine = self.cursorLine - 1
            self:clearSelection()
            self:clampCursor()
            return nil
        end

        if key == keys.down then
            self.cursorLine = self.cursorLine + 1
            self:clearSelection()
            self:clampCursor()
            return nil
        end

        if key == keys.left then
            if self.cursorCol > 1 then
                self.cursorCol = self.cursorCol - 1
            elseif self.cursorLine > 1 then
                self.cursorLine = self.cursorLine - 1
                self.cursorCol = #self.buffer:getLine(self.cursorLine) + 1
            end

            self:clearSelection()
            self:clampCursor()
            return nil
        end

        if key == keys.right then
            local line = self.buffer:getLine(self.cursorLine)

            if self.cursorCol <= #line then
                self.cursorCol = self.cursorCol + 1
            elseif self.cursorLine < self.buffer:lineCount() then
                self.cursorLine = self.cursorLine + 1
                self.cursorCol = 1
            end

            self:clearSelection()
            self:clampCursor()
            return nil
        end

        if key == keys.home then
            self.cursorCol = 1
            self:clearSelection()
            return nil
        end

        if key == keys["end"] then
            self.cursorCol = #self.buffer:getLine(self.cursorLine) + 1
            self:clearSelection()
            return nil
        end

        if key == keys.pageUp then
            local amount = self.lastLayout and self.lastLayout.textH or 8
            self.cursorLine = self.cursorLine - amount
            self:clearSelection()
            self:clampCursor()
            return nil
        end

        if key == keys.pageDown then
            local amount = self.lastLayout and self.lastLayout.textH or 8
            self.cursorLine = self.cursorLine + amount
            self:clearSelection()
            self:clampCursor()
            return nil
        end

        return nil
    end

    function self:handleKeyUp(key)
        if isModifierKey(key) then
            self.modifierDown = false
        end
    end

    function self:handleMouseScroll(direction)
        if direction > 0 then
            self.scrollLine = self.scrollLine + 3
        else
            self.scrollLine = self.scrollLine - 3
        end

        if self.scrollLine < 1 then
            self.scrollLine = 1
        end

        local maxScroll = math.max(1, self.buffer:lineCount())

        if self.scrollLine > maxScroll then
            self.scrollLine = maxScroll
        end
    end

    function self:handleMouseClick(button, mouseX, mouseY)
        if not self.lastLayout then
            return nil
        end

        local lineNumber = self.view:hitTestLineNumber(self.lastLayout, mouseX, mouseY, self.scrollLine)

        if button == 1 and lineNumber then
            self:selectLine(lineNumber)
            return nil
        end

        local line, col = self.view:hitTestText(self.lastLayout, mouseX, mouseY, self.scrollLine, self.scrollCol)

        if button == 1 and line then
            self.cursorLine = line
            self.cursorCol = col
            self:clampCursor()

            self.draggingSelection = true
            self.dragAnchor = {
                line = self.cursorLine,
                col = self.cursorCol
            }

            self:clearSelection()

            return nil
        end

        if button ~= 1 and line then
            self:selectWord(line, col)
            return nil
        end

        if button ~= 1 then
            return self:exit()
        end

        return nil
    end

    function self:handleMouseDrag(button, mouseX, mouseY)
        if button ~= 1 then
            return nil
        end

        if not self.draggingSelection or not self.dragAnchor or not self.lastLayout then
            return nil
        end

        local line, col = self.view:hitTestText(self.lastLayout, mouseX, mouseY, self.scrollLine, self.scrollCol)

        if not line then
            return nil
        end

        self.cursorLine = line
        self.cursorCol = col
        self:clampCursor()

        self:setSelection(
            self.dragAnchor.line,
            self.dragAnchor.col,
            self.cursorLine,
            self.cursorCol
        )

        return nil
    end

    function self:handleMouseUp()
        self.draggingSelection = false
        self.dragAnchor = nil
    end

    function self:run()
        local ok, message = self.buffer:load()

        if not ok then
            self.dialogs:message("Editor", message or "Failed to load file.", self.ctx.theme.error)
            return false
        end

        while true do
            self:ensureCursorVisible()
            self:draw()

            local event, a, b, c = os.pullEvent()

            if event == "char" then
                if not self.modifierDown then
                    self:handleChar(a)
                end

            elseif event == "paste" then
                self:handlePaste(a)

            elseif event == "key" then
                local result = self:handleKey(a)

                if result == "exit" then
                    return true
                end

            elseif event == "key_up" then
                self:handleKeyUp(a)

            elseif event == "mouse_scroll" then
                self:handleMouseScroll(a)

            elseif event == "mouse_click" then
                local result = self:handleMouseClick(a, b, c)

                if result == "exit" then
                    return true
                end

            elseif event == "mouse_drag" then
                self:handleMouseDrag(a, b, c)

            elseif event == "mouse_up" then
                self:handleMouseUp()
            end
        end
    end

    return self
end

return EditorApp