local AsyncTasks = {}

function AddAsyncTask()
    table.insert(AsyncTasks, {
        state = 0,
        think = {},
        timer = 0,
        Think = function(self)
            if #self.think > 0 then
                if self.state > #self.think then
                    self:__finish()
                    return
                end
                local status = self.think[self.state]()
                if status == 0 then--success
                    self.timer = now
                    self.state = self.state + 1
                elseif status == 1 and now > self.timer + 5000 then--waiting
                    self:__finish()
                end
                return
            end
        end,
        Start = function(self, think)
            if #self.think > 0 then
                return false
            end
            self.state = 1
            self.think = think
            self.timer = now
            return true
        end,
        __finish = function(self)
            self.state = 0
            self.think = {}
            self.timer = 0
        end,
    })
    return AsyncTasks[#AsyncTasks]
end

macro(100, function()
    for _, async_task in ipairs(AsyncTasks) do
        async_task:Think()
    end
end)