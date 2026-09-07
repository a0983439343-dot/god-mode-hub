local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local BaseURL = "https://a0983439343-dot.github.io/god-mode-hub/DeveloperTool_V4/"

local existing = PlayerGui:FindFirstChild("DeveloperTool_V4")
if existing then
    existing:Destroy()
end

local function loadModule(path)
    local ok, result = pcall(function()
        local source = game:HttpGet(BaseURL .. path)
        local chunk = loadstring(source)
        if not chunk then
            error("Module compile failed: " .. path)
        end
        return chunk()
    end)
    if not ok then
        warn(result)
        return nil
    end
    return result
end

local Cleanup = loadModule("src/Core/Cleanup.lua")
local Movement = loadModule("src/Modules/Movement.lua")
local Visuals = loadModule("src/Modules/Visuals.lua")
local ESP = loadModule("src/Modules/ESP.lua")
local Teleport = loadModule("src/Modules/Teleport.lua")
local Performance = loadModule("src/Modules/Performance.lua")

if not Cleanup or not Movement or not Visuals or not ESP or not Teleport or not Performance then
    warn("DeveloperTool_V4 module load failed")
    return
end

local State = Cleanup.new("DeveloperTool_V4")

local Rayfield
local ok, result = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if ok then
    Rayfield = result
end

if not Rayfield then
    warn("Rayfield load failed")
    return
end

local Window = Rayfield:CreateWindow({
    Name = "開發者測試面板 V4",
    LoadingTitle = "開發者測試面板 V4",
    LoadingSubtitle = "Roblox Studio 開發者工具",
    ConfigurationSaving = {
        Enabled = false
    },
    Discord = {
        Enabled = false
    },
    KeySystem = false
})

local function bindModule(moduleObject, tab)
    local context = {
        Player = Player,
        PlayerGui = PlayerGui,
        State = State,
        RunService = RunService,
        Rayfield = Rayfield,
        Window = Window,
        Tab = tab
    }
    local okModule, err = pcall(function()
        moduleObject:Init(context)
    end)
    if not okModule then
        warn(err)
    end
end

local MovementTab = Window:CreateTab("移動", 4483362458)
local VisualsTab = Window:CreateTab("視覺", 4483362458)
local ESPTab = Window:CreateTab("ESP", 4483362458)
local TeleportTab = Window:CreateTab("傳送", 4483362458)
local PerformanceTab = Window:CreateTab("效能", 4483362458)

bindModule(Movement, MovementTab)
bindModule(Visuals, VisualsTab)
bindModule(ESP, ESPTab)
bindModule(Teleport, TeleportTab)
bindModule(Performance, PerformanceTab)

State:Add(function()
    if Rayfield then
        pcall(function()
            Rayfield:Destroy()
        end)
    end
end)

State:Add(function()
    pcall(function()
        Movement:Cleanup()
    end)
end)

State:Add(function()
    pcall(function()
        Visuals:Cleanup()
    end)
end)

State:Add(function()
    pcall(function()
        ESP:Cleanup()
    end)
end)

State:Add(function()
    pcall(function()
        Teleport:Cleanup()
    end)
end)

State:Add(function()
    pcall(function()
        Performance:Cleanup()
    end)
end)

_G.DeveloperTool_V4_Cleanup = function()
    State:Cleanup()
end
