local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local GLOBAL_KEY = "__DeveloperToolV5"

local OldRuntime = rawget(_G, GLOBAL_KEY)

if OldRuntime and type(OldRuntime.Cleanup) == "function" then
    pcall(OldRuntime.Cleanup)
end

local Runtime = {
    Alive = true,
    Connections = {},
    Modules = {},
    Rayfield = nil
}

_G[GLOBAL_KEY] = Runtime

local function disconnectAll()
    for i = #Runtime.Connections, 1, -1 do
        local connection = Runtime.Connections[i]

        if connection then
            pcall(function()
                connection:Disconnect()
            end)
        end

        Runtime.Connections[i] = nil
    end
end

local function cleanupModule(module)
    if not module then
        return
    end

    if type(module.Destroy) == "function" then
        pcall(function()
            module:Destroy()
        end)
    elseif type(module.Cleanup) == "function" then
        pcall(function()
            module:Cleanup()
        end)
    end
end

local function getRemoteModule(path)
    local baseUrl = "https://raw.githubusercontent.com/a0983439343-dot/god-mode-hub/main/DeveloperTool_V5/"
    local url = baseUrl .. path

    local success, result = pcall(function()
        local source = game:HttpGet(url)

        if type(source) ~= "string" or source == "" then
            error("遠端檔案內容為空")
        end

        source = source:gsub("\239\187\191", "")
        source = source:gsub("\194\160", " ")

        local fn, err = loadstring(source)

        if type(fn) ~= "function" then
            error(err or "無法編譯 Lua 模組")
        end

        local ok, module = pcall(fn)

        if not ok then
            error(module)
        end

        if type(module) ~= "table" then
            error("模組沒有回傳 table")
        end

        if type(module.Init) ~= "function" then
            error("模組缺少 Init 函式")
        end

        return module
    end)

    if not success then
        error("載入模組失敗 [" .. path .. "]\n" .. tostring(result))
    end

    return result
end

local function createRayfield()
    local success, result = pcall(function()
        local source = game:HttpGet("https://sirius.menu/rayfield")

        if type(source) ~= "string" or source == "" then
            error("Rayfield 原始碼為空")
        end

        source = source:gsub("\239\187\191", "")
        source = source:gsub("\194\160", " ")

        local fn, err = loadstring(source)

        if type(fn) ~= "function" then
            error(err or "Rayfield 編譯失敗")
        end

        local ok, rayfield = pcall(fn)

        if not ok then
            error(rayfield)
        end

        if not rayfield then
            error("Rayfield 回傳值無效")
        end

        return rayfield
    end)

    if not success then
        error("Rayfield 載入失敗\n" .. tostring(result))
    end

    return result
end

local Rayfield = createRayfield()

Runtime.Rayfield = Rayfield

local Window = Rayfield:CreateWindow({
    Name = "DeveloperTool V5",
    LoadingTitle = "DeveloperTool V5",
    LoadingSubtitle = "全中文開發者測試工具",
    ConfigurationSaving = {
        Enabled = false
    },
    KeySystem = false
})

local SharedData = {
    Version = "V5",
    Player = LocalPlayer,
    Runtime = Runtime
}

local MovementTab = Window:CreateTab("移動")
local VisualsTab = Window:CreateTab("視覺")
local ESPTab = Window:CreateTab("透視")
local TeleportTab = Window:CreateTab("傳送")
local PerformanceTab = Window:CreateTab("效能")

local ModulePaths = {
    Movement = "src/Modules/Movement.lua",
    Visuals = "src/Modules/Visuals.lua",
    ESP = "src/Modules/ESP.lua",
    Teleport = "src/Modules/Teleport.lua",
    Performance = "src/Modules/Performance.lua"
}

local ModuleObjects = {}

local function loadModule(name)
    local path = ModulePaths[name]
    local module = getRemoteModule(path)

    ModuleObjects[name] = module
    Runtime.Modules[name] = module

    return module
end

local MovementModule = loadModule("Movement")
local VisualsModule = loadModule("Visuals")
local ESPModule = loadModule("ESP")
local TeleportModule = loadModule("Teleport")
local PerformanceModule = loadModule("Performance")

local function initModule(name, module, tab)
    local success, result = pcall(function()
        module:Init({
            Player = LocalPlayer,
            Tab = tab,
            Shared = SharedData,
            Runtime = Runtime,
            Rayfield = Rayfield,
            Window = Window
        })
    end)

    if not success then
        error("初始化模組失敗 [" .. name .. "]\n" .. tostring(result))
    end
end

initModule("Movement", MovementModule, MovementTab)
initModule("Visuals", VisualsModule, VisualsTab)
initModule("ESP", ESPModule, ESPTab)
initModule("Teleport", TeleportModule, TeleportTab)
initModule("Performance", PerformanceModule, PerformanceTab)

local StatusTab = Window:CreateTab("系統")

StatusTab:CreateParagraph({
    Title = "DeveloperTool V5",
    Content = "模組化開發者測試工具\n目前已成功載入 5 個核心模組"
})

StatusTab:CreateParagraph({
    Title = "模組狀態",
    Content =
        "移動：已載入\n"
        .. "視覺：已載入\n"
        .. "透視：已載入\n"
        .. "傳送：已載入\n"
        .. "效能：已載入"
})

StatusTab:CreateButton({
    Name = "重新整理介面",
    Callback = function()
        pcall(function()
            if Rayfield.RefreshConfiguration then
                Rayfield:RefreshConfiguration()
            end
        end)
    end
})

StatusTab:CreateButton({
    Name = "清理舊測試物件",
    Callback = function()
        for name, module in pairs(ModuleObjects) do
            if module and type(module.ClearDebug) == "function" then
                pcall(function()
                    module:ClearDebug()
                end)
            elseif module and type(module.Clear) == "function" then
                pcall(function()
                    module:Clear()
                end)
            end
        end
    end
})

StatusTab:CreateButton({
    Name = "重新載入整個工具",
    Callback = function()
        local currentRuntime = rawget(_G, GLOBAL_KEY)

        if currentRuntime and type(currentRuntime.Cleanup) == "function" then
            pcall(currentRuntime.Cleanup)
        end

        task.wait(0.2)

        local ok, source = pcall(function()
            return game:HttpGet(
                "https://raw.githubusercontent.com/a0983439343-dot/god-mode-hub/main/DeveloperTool_V5/main.lua"
            )
        end)

        if not ok or type(source) ~= "string" then
            warn("重新載入失敗")
            return
        end

        source = source:gsub("\239\187\191", "")
        source = source:gsub("\194\160", " ")

        local fn, err = loadstring(source)

        if type(fn) ~= "function" then
            warn(err or "重新編譯失敗")
            return
        end

        local success, executeError = pcall(fn)

        if not success then
            warn(executeError)
        end
    end
})

function Runtime.Cleanup()
    if not Runtime.Alive then
        return
    end

    Runtime.Alive = false

    for name, module in pairs(Runtime.Modules) do
        cleanupModule(module)
        Runtime.Modules[name] = nil
    end

    disconnectAll()

    if Runtime.Rayfield then
        pcall(function()
            Runtime.Rayfield:Destroy()
        end)
    end

    Runtime.Rayfield = nil

    if _G[GLOBAL_KEY] == Runtime then
        _G[GLOBAL_KEY] = nil
    end
end

local ok, result = pcall(function()
    Rayfield:Notify({
        Title = "DeveloperTool V5",
        Content = "所有核心模組已成功載入",
        Duration = 3
    })
end)

if not ok then
    warn(result)
end
