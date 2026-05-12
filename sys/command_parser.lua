local CommandParser = {}

function CommandParser.parse(input)
    input = tostring(input or "")

    local args = {}
    local current = ""
    local quote = nil
    local escaped = false
    local tokenStarted = false

    for index = 1, #input do
        local ch = string.sub(input, index, index)

        if escaped then
            current = current .. ch
            tokenStarted = true
            escaped = false
        elseif ch == "\\" then
            escaped = true
            tokenStarted = true
        elseif quote then
            if ch == quote then
                quote = nil
            else
                current = current .. ch
            end

            tokenStarted = true
        elseif ch == "\"" or ch == "'" then
            quote = ch
            tokenStarted = true
        elseif ch == " " or ch == "\t" then
            if tokenStarted then
                table.insert(args, current)
                current = ""
                tokenStarted = false
            end
        else
            current = current .. ch
            tokenStarted = true
        end
    end

    if escaped then
        current = current .. "\\"
        tokenStarted = true
    end

    if quote then
        return nil, "Unclosed quote: " .. quote
    end

    if tokenStarted then
        table.insert(args, current)
    end

    return args, nil
end

function CommandParser.join(args, startIndex)
    args = args or {}
    startIndex = startIndex or 1

    local result = {}

    for index = startIndex, #args do
        table.insert(result, tostring(args[index] or ""))
    end

    return table.concat(result, " ")
end

return CommandParser