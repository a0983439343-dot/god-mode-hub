local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local existing = PlayerGui:FindFirstChild("DeveloperTool_V4")
if existing then
    existing:Destroy()
end

local baseUrl = "https://raw.githubusercontent.com/a0983439343-dot/god-mode-hub/refs/heads/main/DeveloperTool_V4/"

local Cleanup = loadstring(game:HttpGet(baseUrl .. "src/Core/Cleanup.lua"))()
local Movement = loadstring(game:HttpGet(baseUrl .. "src/Modules/Movement.lua"))()
local Visuals = loadstring(game:HttpGet(baseUrl .. "src/Modules/Visuals.lua"))()
local ESP = loadstring(game:HttpGet(baseUrl .. "src/Modules/ESP.lua"))()
local Teleport = loadstring(game:HttpGet(baseUrl .. "src/Modules/Teleport.lua"))()
local Performance = loadstring(game:HttpGet(baseUrl .. "src/Modules/Performance.lua"))()

local State = Cleanup.new("DeveloperTool_V4")

local Rayfield
local ok, result = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if ok then
    Rayfield = result
end

if not Rayfield then
    return
end

local Window = Rayfield:CreateWindow({
    Name = "Developer Test Panel V4",
    LoadingTitle = "Developer Test Panel V4",
    LoadingSubtitle = "Roblox Studio Developer Tools",
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
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
    pcall(function()
        moduleObject:Init(context)
    end)
end

local MovementTab = Window:CreateTab("Movement", 4483362458)
local VisualsTab = Window:CreateTab("Visuals", 4483362458)
local ESPTab = Window:CreateTab("ESP", 4483362458)
local TeleportTab = Window:CreateTab("Teleport", 4483362458)
local PerformanceTab = Window:CreateTab("Performance", 4483362458)

bindModule(Movement, MovementTab)
bindModule(Visuals, VisualsTab)
bindModule(ESP, ESPTab)
bindModule(Teleport, TeleportTab)
bindModule(Performance, PerformanceTab)

State:Add(function()
    if Rayfield then
        pcall(function() Rayfield:Destroy() end)
    end
end)

State:Add(function() pcall(function() Movement:Cleanup() end) end)
State:Add(function() pcall(function() Visuals:Cleanup() end) end)
State:Add(function() pcall(function() ESP:Cleanup() end) end)
State:Add(function() pcall(function() Teleport:Cleanup() end) end)
State:Add(function() pcall(function() Performance:Cleanup() end) end)

_G.DeveloperTool_V4_Cleanup = function()
    State:Cleanup()
end
