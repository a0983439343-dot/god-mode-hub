local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local existing = PlayerGui:FindFirstChild("DeveloperTool_V4")
if existing then
    existing:Destroy()
end

local Cleanup = require(script.src.Core.Cleanup)
local Movement = require(script.src.Modules.Movement)
local Visuals = require(script.src.Modules.Visuals)
local ESP = require(script.src.Modules.ESP)
local Teleport = require(script.src.Modules.Teleport)
local Performance = require(script.src.Modules.Performance)

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
    Name = "Developer Test Panel V4",
    LoadingTitle = "Developer Test Panel V4",
    LoadingSubtitle = "Roblox Studio Developer Tools",
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

Tab = nil
