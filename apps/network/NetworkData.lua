local NetworkData = {}

function NetworkData.new(ctx)
    local self = {}

    self.ctx = ctx

    function self:getComputerLabel()
        local label = os.getComputerLabel()

        if label and label ~= "" then
            return label
        end

        return "computer-" .. tostring(os.getComputerID())
    end

    function self:getStatus()
        if self.ctx.services and self.ctx.services.rednet then
            return self.ctx.services.rednet:getStatus()
        end

        return {
            available = false,
            reason = "Rednet service is not loaded.",
            modems = {}
        }
    end

    function self:getModems()
        local status = self:getStatus()
        return status.modems or {}
    end

    function self:openFirst()
        if self.ctx.services and self.ctx.services.rednet then
            return self.ctx.services.rednet:openFirst()
        end

        return false, "Rednet service is not loaded."
    end

    function self:closeAll()
        if self.ctx.services and self.ctx.services.rednet then
            return self.ctx.services.rednet:closeAll()
        end

        return false, "Rednet service is not loaded."
    end

    function self:hasOpenModem()
        local modems = self:getModems()

        for _, modem in ipairs(modems) do
            if modem.open then
                return true
            end
        end

        return false
    end

    function self:collect()
        local status = self:getStatus()

        local rows = {
            { label = "Computer ID", value = tostring(os.getComputerID()) },
            { label = "Label", value = self:getComputerLabel() },
            { label = "Rednet", value = status.available and "available" or "unavailable" },
            { label = "Status", value = status.reason or "unknown" },
            { label = "Modems", value = tostring(#(status.modems or {})) }
        }

        return {
            status = status,
            rows = rows,
            modems = status.modems or {}
        }
    end

    return self
end

return NetworkData