local Class = require("sys.class")

local History = Class.create()

function History:init(path)
    self.path = path or "data/history.lua"
    self.items = {}
    self:load()
end

function History:load()
    if not fs.exists("data") then
        fs.makeDir("data")
    end

    if not fs.exists(self.path) then
        self:save()
        return
    end

    local ok, data = pcall(dofile, self.path)

    if ok and type(data) == "table" then
        self.items = data
    else
        self.items = {}
        self:save()
    end
end

function History:save()
    local handle = fs.open(self.path, "w")

    if not handle then
        return
    end

    handle.write("return ")
    handle.write(textutils.serialize(self.items))
    handle.close()
end

function History:add(command)
    if not command or command == "" then
        return
    end

    if self.items[#self.items] == command then
        return
    end

    table.insert(self.items, command)

    while #self.items > 50 do
        table.remove(self.items, 1)
    end

    self:save()
end

function History:get()
    return self.items
end

return History
