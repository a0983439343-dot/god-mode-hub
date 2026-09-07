local Cleanup = {}
Cleanup.__index = Cleanup

function Cleanup.new(name)
    local self = setmetatable({}, Cleanup)
    self.Name = name or "Cleanup"
    self.Connections = {}
    self.Instances = {}
    self.Functions = {}
    self.Alive = true
    return self
end

function Cleanup:AddConnection(connection)
    if connection then
        table.insert(self.Connections, connection)
    end
    return connection
end

function Cleanup:AddInstance(instance)
    if instance then
        table.insert(self.Instances, instance)
    end
    return instance
end

function Cleanup:Add(callback)
    if type(callback) == "function" then
        table.insert(self.Functions, callback)
    end
    return callback
end

function Cleanup:Cleanup()
    if not self.Alive then
        return
    end
    self.Alive = false

    for i = #self.Connections, 1, -1 do
        local item = self.Connections[i]
        if item then
            pcall(function()
                item:Disconnect()
            end)
        end
        self.Connections[i] = nil
    end

    for i = #self.Functions, 1, -1 do
        local callback = self.Functions[i]
        pcall(callback)
        self.Functions[i] = nil
    end

    for i = #self.Instances, 1, -1 do
        local item = self.Instances[i]
        if item then
            pcall(function()
                item:Destroy()
            end)
        end
        self.Instances[i] = nil
    end
end

return Cleanup
