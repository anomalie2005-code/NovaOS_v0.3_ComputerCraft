local TaskService = {}

function TaskService.new()
    local self = {}

    self.nextId = 1
    self.tasks = {}

    function self:create(name, kind, status)
        local task = {
            id = self.nextId,
            name = name or "task-" .. tostring(self.nextId),
            kind = kind or "generic",
            status = status or "created",
            createdAt = os.clock()
        }

        self.tasks[task.id] = task
        self.nextId = self.nextId + 1

        return task
    end

    function self:setStatus(id, status)
        local task = self.tasks[id]

        if not task then
            return false, "Task not found: " .. tostring(id)
        end

        task.status = status

        return true
    end

    function self:remove(id)
        if not self.tasks[id] then
            return false, "Task not found: " .. tostring(id)
        end

        self.tasks[id] = nil

        return true
    end

    function self:list()
        local result = {}

        for _, task in pairs(self.tasks) do
            table.insert(result, task)
        end

        table.sort(result, function(a, b)
            return a.id < b.id
        end)

        return result
    end

    function self:count()
        local count = 0

        for _, _ in pairs(self.tasks) do
            count = count + 1
        end

        return count
    end

    return self
end

return TaskService
