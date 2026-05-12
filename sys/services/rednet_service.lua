local RednetService = {}

function RednetService.new()
    local self = {}

    function self:getModems()
        local result = {}

        for _, side in ipairs(peripheral.getNames()) do
            if peripheral.getType(side) == "modem" then
                table.insert(result, side)
            end
        end

        table.sort(result)

        return result
    end

    function self:isAvailable()
        return rednet ~= nil and #self:getModems() > 0
    end

    function self:openFirst()
        if not rednet then
            return false, "Rednet API is not available."
        end

        local modems = self:getModems()

        if #modems == 0 then
            return false, "No modem found."
        end

        for _, modem in ipairs(modems) do
            if not rednet.isOpen(modem) then
                rednet.open(modem)
            end

            if rednet.isOpen(modem) then
                return true, modem
            end
        end

        return false, "Failed to open modem."
    end

    function self:closeAll()
        if not rednet then
            return false, "Rednet API is not available."
        end

        for _, modem in ipairs(self:getModems()) do
            if rednet.isOpen(modem) then
                rednet.close(modem)
            end
        end

        return true
    end

    function self:getStatus()
        local result = {}

        if not rednet then
            return {
                available = false,
                reason = "Rednet API is not available.",
                modems = {}
            }
        end

        for _, modem in ipairs(self:getModems()) do
            table.insert(result, {
                name = modem,
                open = rednet.isOpen(modem)
            })
        end

        return {
            available = #result > 0,
            reason = #result > 0 and "ok" or "No modem found.",
            modems = result
        }
    end

    return self
end

return RednetService
