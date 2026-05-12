local TasksData = {}

local function formatAge(createdAt)
    local now = os.clock()
    local seconds = math.floor(now - tonumber(createdAt or now))

    if seconds < 0 then
        seconds = 0
    end

    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60

    if hours > 0 then
        return tostring(hours) .. "h " .. tostring(minutes) .. "m"
    end

    if minutes > 0 then
        return tostring(minutes) .. "m " .. tostring(secs) .. "s"
    end

    return tostring(secs) .. "s"
end

function TasksData.new(ctx)
    local self = {}

    self.ctx = ctx

    function self:getTasks()
        local result = {}

        if self.ctx.services and self.ctx.services.tasks then
            local tasks = self.ctx.services.tasks:list()

            for _, task in ipairs(tasks) do
                table.insert(result, {
                    id = task.id or 0,
                    name = task.name or "unknown",
                    kind = task.kind or "generic",
                    status = task.status or "unknown",
                    createdAt = task.createdAt or os.clock(),
                    age = formatAge(task.createdAt)
                })
            end
        else
            table.insert(result, {
                id = 0,
                name = "TaskService",
                kind = "system",
                status = "not loaded",
                createdAt = os.clock(),
                age = "0s"
            })
        end

        table.sort(result, function(a, b)
            return tonumber(a.id or 0) < tonumber(b.id or 0)
        end)

        return result
    end

    function self:getInfo()
        local tasks = self:getTasks()

        local statusCounts = {}

        for _, task in ipairs(tasks) do
            local status = tostring(task.status or "unknown")
            statusCounts[status] = (statusCounts[status] or 0) + 1
        end

        return {
            total = #tasks,
            statusCounts = statusCounts
        }
    end

    return self
end

return TasksData