local PeripheralService = {}

function PeripheralService.new()
    local self = {}

    function self:list()
        local result = {}
        local names = peripheral.getNames()

        table.sort(names)

        for _, name in ipairs(names) do
            local kind = peripheral.getType(name) or "unknown"

            table.insert(result, {
                name = name,
                type = kind,
                status = "online"
            })
        end

        return result
    end

    function self:count()
        return #self:list()
    end

    function self:findByType(targetType)
        local result = {}

        for _, item in ipairs(self:list()) do
            if item.type == targetType then
                table.insert(result, item)
            end
        end

        return result
    end

    function self:hasType(targetType)
        return #self:findByType(targetType) > 0
    end

    function self:getSummary()
        local summary = {}

        for _, item in ipairs(self:list()) do
            summary[item.type] = (summary[item.type] or 0) + 1
        end

        return summary
    end

    return self
end

return PeripheralService
