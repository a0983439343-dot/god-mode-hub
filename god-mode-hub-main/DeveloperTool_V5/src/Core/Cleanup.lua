-- DeveloperTool V5 | Cleanup
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

local function disconnect(item)
    if item then
        pcall(function()
            item:Disconnect()
        end)
    end
end

local function destroy(item)
    if item then
        pcall(function()
            item:Destroy()
        end)
    end
end

function Cleanup:AddConnection(connection)
    if not self.Alive then
        disconnect(connection)
        return connection
    end
    if connection then
        table.insert(self.Connections, connection)
    end
    return connection
end

function Cleanup:AddInstance(instance)
    if not self.Alive then
        destroy(instance)
        return instance
    end
    if instance then
        table.insert(self.Instances, instance)
    end
    return instance
end

function Cleanup:Add(callback)
    if type(callback) ~= "function" then
        return callback
    end

    if not self.Alive then
        pcall(callback)
        return callback
    end

    table.insert(self.Functions, callback)
    return callback
end

function Cleanup:Cleanup()
    if not self.Alive then
        return
    end

    self.Alive = false

    for i = #self.Connections, 1, -1 do
        disconnect(self.Connections[i])
        self.Connections[i] = nil
    end

    for i = #self.Functions, 1, -1 do
        local callback = self.Functions[i]
        self.Functions[i] = nil
        pcall(callback)
    end

    for i = #self.Instances, 1, -1 do
        destroy(self.Instances[i])
        self.Instances[i] = nil
    end
end

return Cleanup
