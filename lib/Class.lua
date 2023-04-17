function Class(...)
    local cls = {}
    cls.__index = cls
    function cls:New(...)
        local instance = setmetatable({}, cls)
        cls.__init(instance, ...)
        return instance
    end

    cls.__call = function(_, ...)
        return cls:New(...)
    end
    return setmetatable(cls, {
        __call = cls.__call,
    })
end

