local EditorView = {}

local function cutText(text, maxLength)
    text = tostring(text or "")

    if maxLength <= 0 then
        return ""
    end

    if #text <= maxLength then
        return text
    end

    return string.sub(text, 1, maxLength)
end

local function padLeft(text, width)
    text = tostring(text or "")

    if #text >= width then
        return string.sub(text, 1, width)
    end

    return string.rep(" ", width - #text) .. text
end

local function writeAt(x, y, text, foreground, background)
    if background then
        term.setBackgroundColor(background)
    end

    if foreground then
        term.setTextColor(foreground)
    end

    term.setCursorPos(x, y)
    term.write(tostring(text or ""))
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

local function getSelectedRangeForLine(selection, lineIndex, lineLength)
    selection = normalizeSelection(selection)

    if not selection then
        return nil
    end

    if lineIndex < selection.startLine or lineIndex > selection.endLine then
        return nil
    end

    local fromCol = 1
    local toCol = lineLength + 1

    if lineIndex == selection.startLine then
        fromCol = selection.startCol
    end

    if lineIndex == selection.endLine then
        toCol = selection.endCol
    end

    if fromCol < 1 then
        fromCol = 1
    end

    if toCol < fromCol then
        return nil
    end

    return fromCol, toCol
end

function EditorView.new(ctx)
    local self = {}

    self.ctx = ctx

    function self:getLayout()
        local width, height = term.getSize()

        local boxX = 2
        local boxY = 2
        local boxW = width - 2
        local boxH = height - 3

        local textX = boxX + 2
        local textY = boxY + 5
        local textW = boxW - 4
        local textH = boxH - 9

        if textW < 10 then
            textW = 10
        end

        if textH < 3 then
            textH = 3
        end

        local lineNumberW = 4
        local contentX = textX + lineNumberW + 1
        local contentW = textW - lineNumberW - 1

        if contentW < 5 then
            contentW = 5
        end

        return {
            width = width,
            height = height,

            boxX = boxX,
            boxY = boxY,
            boxW = boxW,
            boxH = boxH,

            textX = textX,
            textY = textY,
            textW = textW,
            textH = textH,

            lineNumberW = lineNumberW,
            contentX = contentX,
            contentW = contentW
        }
    end

    function self:drawHeader(layout, filePath, buffer, cursorLine, cursorCol, message, selection)
        local Box = self.ctx.ui.Box
        local theme = self.ctx.theme

        local fileName = filePath and fs.getName(filePath) or "untitled"
        local state = buffer.modified and "modified" or "saved"

        if selection then
            state = state .. " | selected"
        end

        Box.draw(self.ctx, layout.boxX, layout.boxY, layout.boxW, layout.boxH, "Editor: " .. fileName)

        local pathText = "File: " .. tostring(filePath or "untitled")
        Box.writeInside(self.ctx, layout.boxX, layout.boxY, layout.boxW, 2, cutText(pathText, layout.boxW - 4), theme.accent2)

        local statusText =
            "Ln " ..
            tostring(cursorLine) ..
            ", Col " ..
            tostring(cursorCol) ..
            " | " ..
            tostring(buffer:lineCount()) ..
            " lines | " ..
            state

        if message and message ~= "" then
            Box.writeInside(self.ctx, layout.boxX, layout.boxY, layout.boxW, 3, cutText(message, layout.boxW - 4), theme.warning)
        else
            Box.writeInside(self.ctx, layout.boxX, layout.boxY, layout.boxW, 3, statusText, buffer.modified and theme.warning or theme.muted)
        end

        Box.drawSeparator(self.ctx, layout.boxX, layout.boxY + 4, layout.boxW)
    end

    function self:drawContentWithSelection(layout, y, lineIndex, line, scrollCol, selection)
        local theme = self.ctx.theme
        local selectedFrom, selectedTo = getSelectedRangeForLine(selection, lineIndex, #line)

        if not selectedFrom then
            writeAt(
                layout.contentX,
                y,
                cutText(string.sub(line, scrollCol), layout.contentW),
                theme.foreground,
                theme.background
            )

            return
        end

        for screenOffset = 0, layout.contentW - 1 do
            local col = scrollCol + screenOffset
            local ch = string.sub(line, col, col)

            if ch == "" then
                ch = " "
            end

            local selected = col >= selectedFrom and col < selectedTo

            if selected then
                writeAt(layout.contentX + screenOffset, y, ch, colors.black, theme.accent)
            else
                writeAt(layout.contentX + screenOffset, y, ch, theme.foreground, theme.background)
            end
        end
    end

    function self:drawText(layout, buffer, scrollLine, scrollCol, cursorLine, selection)
        local theme = self.ctx.theme

        for row = 1, layout.textH do
            local lineIndex = scrollLine + row - 1
            local y = layout.textY + row - 1
            local line = buffer:getLine(lineIndex)

            writeAt(layout.textX, y, string.rep(" ", layout.textW), theme.foreground, theme.background)

            if line then
                local lineNumberColor = theme.muted

                if lineIndex == cursorLine then
                    lineNumberColor = theme.accent2
                end

                writeAt(layout.textX, y, padLeft(tostring(lineIndex), layout.lineNumberW), lineNumberColor, theme.background)
                writeAt(layout.textX + layout.lineNumberW, y, " ", theme.muted, theme.background)

                self:drawContentWithSelection(layout, y, lineIndex, line, scrollCol, selection)
            end
        end
    end

    function self:drawFooter(layout, filePath)
        local Box = self.ctx.ui.Box
        local StatusBar = self.ctx.ui.StatusBar

        Box.footer(
            self.ctx,
            layout.boxX,
            layout.boxY,
            layout.boxW,
            layout.boxH,
            "F2 save  F5 paste  F6 import  F7 save as  Ctrl+A/C/V"
        )

        StatusBar.drawBottom(self.ctx, "NovaOS / Editor", fs.getName(filePath or "untitled"))
    end

    function self:draw(filePath, buffer, state)
        local theme = self.ctx.theme

        state = state or {}

        local layout = self:getLayout()

        self.ctx.screen:clear(theme.background, theme.text)

        self:drawHeader(
            layout,
            filePath,
            buffer,
            state.cursorLine or 1,
            state.cursorCol or 1,
            state.message or "",
            state.selection
        )

        self:drawText(
            layout,
            buffer,
            state.scrollLine or 1,
            state.scrollCol or 1,
            state.cursorLine or 1,
            state.selection
        )

        self:drawFooter(layout, filePath)

        local cursorScreenY = layout.textY + (state.cursorLine or 1) - (state.scrollLine or 1)
        local cursorScreenX = layout.contentX + (state.cursorCol or 1) - (state.scrollCol or 1)

        if cursorScreenY >= layout.textY
            and cursorScreenY < layout.textY + layout.textH
            and cursorScreenX >= layout.contentX
            and cursorScreenX < layout.contentX + layout.contentW then
            term.setCursorPos(cursorScreenX, cursorScreenY)
            term.setCursorBlink(true)
        else
            term.setCursorBlink(false)
        end

        return layout
    end

    function self:hitTestText(layout, mouseX, mouseY, scrollLine, scrollCol)
        if mouseX < layout.contentX or mouseX >= layout.contentX + layout.contentW then
            return nil
        end

        if mouseY < layout.textY or mouseY >= layout.textY + layout.textH then
            return nil
        end

        local line = scrollLine + (mouseY - layout.textY)
        local col = scrollCol + (mouseX - layout.contentX)

        return line, col
    end

    function self:hitTestLineNumber(layout, mouseX, mouseY, scrollLine)
        if mouseX < layout.textX or mouseX >= layout.textX + layout.lineNumberW then
            return nil
        end

        if mouseY < layout.textY or mouseY >= layout.textY + layout.textH then
            return nil
        end

        return scrollLine + (mouseY - layout.textY)
    end

    function self:isInsideTextArea(layout, mouseX, mouseY)
        return mouseX >= layout.textX
            and mouseX < layout.textX + layout.textW
            and mouseY >= layout.textY
            and mouseY < layout.textY + layout.textH
    end

    return self
end

return EditorView