local Class = {}

function Class.create(parent)
    local class = {}

    class.__index = class

    if parent then
        setmetatable(class, {
            __index = parent
        })

        class.super = parent
    end

    function class:new(...)
        local instance = setmetatable({}, class)

        if instance.init then
            instance:init(...)
        end

        return instance
    end

    return class
end

return Class