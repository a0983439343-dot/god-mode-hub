local Performance = {
    Connections = {},
    LowQuality = false,
    Stats = {
        FPS = 0,
        Ping = 0
    }
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local StatsService = game:GetService("Stats")

local Player = Players.LocalPlayer

local function addConnection(self, connection)
    table.insert(self.Connections, connection)
    return connection
end

local function simplifyPart(item)
    if item:IsA("BasePart") then
        item.Material = Enum.Material.SmoothPlastic
        item.CastShadow = false
    elseif item:IsA("Decal") or item:IsA("Texture") then
        item.Transparency = 1
    elseif item:IsA("ParticleEmitter") or item:IsA("Trail") or item:IsA("Beam") then
        item.Enabled = false
    elseif item:IsA("SurfaceAppearance") then
        item:Destroy()
    end
end

local function scanLowQuality()
    task.spawn(function()
        local descendants = Workspace:GetDescendants()
        for i, item in ipairs(descendants) do
            if i % 100 == 0 then
                task.wait()
            end
            simplifyPart(item)
        end

        local lightingDescendants = Lighting:GetDescendants()
        for i, item in ipairs(lightingDescendants) do
            if i % 100 == 0 then
                task.wait()
            end
            if item:IsA("PostEffect") then
                item.Enabled = false
            end
        end
    end)
end

local function extremeCleanup()
    task.spawn(function()
        local descendants = Workspace:GetDescendants()
        for i, item in ipairs(descendants) do
            if i % 100 == 0 then
                task.wait()
            end
            if item:IsA("Texture") or item:IsA("Decal") or item:IsA("SurfaceAppearance") then
                item:Destroy()
            elseif item:IsA("ParticleEmitter") or item:IsA("Beam") or item:IsA("Trail") then
                item.Enabled = false
            end
        end
    end)
end

local function readPing()
    local ok, network = pcall(function()
        return StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    if ok then
        return math.floor(network)
    end
    return 0
end

function Performance:Init(context)
    Player = context.Player
    local tab = context.Tab

    local fpsLabel = tab:CreateLabel("FPS: 0")
    local pingLabel = tab:CreateLabel("Ping: 0 ms")

    addConnection(self, RunService.RenderStepped:Connect(function(dt)
        if dt > 0 then
            local fps = math.floor(1 / dt + 0.5)
            self.Stats.FPS = fps
            fpsLabel:Set("FPS: " .. tostring(fps))
        end
    end))

    addConnection(self, RunService.Heartbeat:Connect(function()
        local ping = readPing()
        self.Stats.Ping = ping
        pingLabel:Set("Ping: " .. tostring(ping) .. " ms")
    end))

    tab:CreateSection("Quality")
    tab:CreateToggle({
        Name = "Low Quality Mode",
        CurrentValue = false,
        Flag = "DeveloperLowQuality",
        Callback = function(value)
            self.LowQuality = value
            if value then
                scanLowQuality()
            end
        end
    })

    tab:CreateButton({
        Name = "Extreme Texture Cleanup",
        Callback = function()
            extremeCleanup()
        end
    })

    tab:CreateButton({
        Name = "Apply Low Quality Scan",
        Callback = function()
            scanLowQuality()
        end
    })

    tab:CreateSection("Performance")
    tab:CreateButton({
        Name = "Refresh Performance",
        Callback = function()
            self.Stats.Ping = readPing()
        end
    })
end

function Performance:Cleanup()
    for i = #self.Connections, 1, -1 do
        pcall(function()
            self.Connections[i]:Disconnect()
        end)
        self.Connections[i] = nil
    end
end

return Performance
