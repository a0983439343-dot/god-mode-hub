-- DeveloperTool V5 | Performance
local Performance = {
    Connections = {},
    OptimizationConnections = {},
    LowQuality = false,
    Alive = false,
    Stats = {
        FPS = 0,
        Ping = 0
    },
    Backups = {}
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local StatsService = game:GetService("Stats")

local Player = Players.LocalPlayer

local function disconnect(connection)
    if connection then
        pcall(function()
            connection:Disconnect()
        end)
    end
end

local function addConnection(self, connection, optimization)
    if not connection then
        return nil
    end
    if optimization then
        table.insert(self.OptimizationConnections, connection)
    else
        table.insert(self.Connections, connection)
    end
    return connection
end

local function backup(self, item)
    if self.Backups[item] then
        return self.Backups[item]
    end

    local state = {}
    if item:IsA("BasePart") then
        state.Material = item.Material
        state.CastShadow = item.CastShadow
    elseif item:IsA("Decal") or item:IsA("Texture") then
        state.Transparency = item.Transparency
    elseif item:IsA("ParticleEmitter") or item:IsA("Trail") or item:IsA("Beam") then
        state.Enabled = item.Enabled
    elseif item:IsA("PostEffect") then
        state.Enabled = item.Enabled
    else
        return nil
    end

    self.Backups[item] = state
    return state
end

local function simplifyItem(self, item)
    local state = backup(self, item)
    if not state then
        return
    end

    if item:IsA("BasePart") then
        item.Material = Enum.Material.SmoothPlastic
        item.CastShadow = false
    elseif item:IsA("Decal") or item:IsA("Texture") then
        item.Transparency = 1
    elseif item:IsA("ParticleEmitter") or item:IsA("Trail") or item:IsA("Beam") then
        item.Enabled = false
    elseif item:IsA("PostEffect") then
        item.Enabled = false
    end
end

local function restoreAll(self)
    for item, state in pairs(self.Backups) do
        if item and item.Parent then
            pcall(function()
                if item:IsA("BasePart") then
                    item.Material = state.Material
                    item.CastShadow = state.CastShadow
                elseif item:IsA("Decal") or item:IsA("Texture") then
                    item.Transparency = state.Transparency
                elseif item:IsA("ParticleEmitter") or item:IsA("Trail") or item:IsA("Beam") then
                    item.Enabled = state.Enabled
                elseif item:IsA("PostEffect") then
                    item.Enabled = state.Enabled
                end
            end)
        end
    end
    table.clear(self.Backups)
end

local function scanLowQuality(self)
    if not self.LowQuality or not self.Alive then
        return
    end

    for _, item in ipairs(Workspace:GetDescendants()) do
        if not self.Alive or not self.LowQuality then
            return
        end
        simplifyItem(self, item)
    end

    for _, item in ipairs(Lighting:GetDescendants()) do
        if not self.Alive or not self.LowQuality then
            return
        end
        simplifyItem(self, item)
    end
end

local function readPing()
    local ok, network = pcall(function()
        return StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    if ok and type(network) == "number" then
        return math.max(0, math.floor(network + 0.5))
    end
    return 0
end

local function setLowQuality(self, enabled)
    self.LowQuality = enabled

    for i = #self.OptimizationConnections, 1, -1 do
        disconnect(self.OptimizationConnections[i])
        self.OptimizationConnections[i] = nil
    end

    if not enabled then
        restoreAll(self)
        return
    end

    task.spawn(function()
        scanLowQuality(self)
    end)

    addConnection(self, Workspace.DescendantAdded:Connect(function(item)
        if self.Alive and self.LowQuality then
            simplifyItem(self, item)
        end
    end), true)

    addConnection(self, Lighting.DescendantAdded:Connect(function(item)
        if self.Alive and self.LowQuality then
            simplifyItem(self, item)
        end
    end), true)
end

function Performance:Init(context)
    Player = context.Player
    self.Alive = true

    local tab = context.Tab
    local fpsLabel = tab:CreateLabel("幀數：0")
    local pingLabel = tab:CreateLabel("延遲：0 毫秒")

    local fpsAccumulator = 0
    local frameAccumulator = 0
    local pingAccumulator = 0

    addConnection(self, RunService.RenderStepped:Connect(function(dt)
        frameAccumulator += 1
        fpsAccumulator += dt

        if fpsAccumulator >= 0.25 then
            local fps = math.floor(frameAccumulator / fpsAccumulator + 0.5)
            self.Stats.FPS = fps
            frameAccumulator = 0
            fpsAccumulator = 0
            pcall(function()
                fpsLabel:Set("幀數：" .. tostring(fps))
            end)
        end
    end))

    addConnection(self, RunService.Heartbeat:Connect(function(dt)
        pingAccumulator += dt
        if pingAccumulator < 0.5 then
            return
        end
        pingAccumulator = 0

        self.Stats.Ping = readPing()
        pcall(function()
            pingLabel:Set("延遲：" .. tostring(self.Stats.Ping) .. " 毫秒")
        end)
    end))

    tab:CreateSection("畫質")
    tab:CreateToggle({
        Name = "低畫質模式",
        CurrentValue = false,
        Flag = "DeveloperV5LowQuality",
        Callback = function(value)
            setLowQuality(self, value)
        end
    })

    tab:CreateButton({
        Name = "套用低畫質掃描",
        Callback = function()
            if self.LowQuality then
                task.spawn(function()
                    scanLowQuality(self)
                end)
            end
        end
    })

    tab:CreateButton({
        Name = "恢復原始畫質",
        Callback = function()
            setLowQuality(self, false)
        end
    })

    tab:CreateButton({
        Name = "重新整理效能資訊",
        Callback = function()
            self.Stats.Ping = readPing()
            pcall(function()
                pingLabel:Set("延遲：" .. tostring(self.Stats.Ping) .. " 毫秒")
            end)
        end
    })
end

function Performance:Cleanup()
    if not self.Alive then
        return
    end

    self.Alive = false
    self.LowQuality = false

    for i = #self.OptimizationConnections, 1, -1 do
        disconnect(self.OptimizationConnections[i])
        self.OptimizationConnections[i] = nil
    end

    restoreAll(self)

    for i = #self.Connections, 1, -1 do
        disconnect(self.Connections[i])
        self.Connections[i] = nil
    end
end

return Performance
