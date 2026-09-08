local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local CREATOR_NAME = "jdkdkdkdkekejekeieke"
local GET_KEY_URL = "https://devtool-key-system.a0983439343.workers.dev/"
local API_URL = "https://devtool-key-system.a0983439343.workers.dev/api/verify"
local MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/a0983439343-dot/god-mode-hub/main/DeveloperTool_V5/main.lua"

local Player = Players.LocalPlayer

local function getRequestFunction()
    if type(request) == "function" then
        return request
    end
    if type(http_request) == "function" then
        return http_request
    end
    if type(syn) == "table" and type(syn.request) == "function" then
        return syn.request
    end
    if type(fluxus) == "table" and type(fluxus.request) == "function" then
        return fluxus.request
    end
    if type(http) == "table" and type(http.request) == "function" then
        return http.request
    end
    return nil
end

local function getHttpGet()
    if game and type(game.HttpGet) == "function" then
        return function(url)
            return game:HttpGet(url)
        end
    end

    local requestFunction = getRequestFunction()
    if requestFunction then
        return function(url)
            local response = requestFunction({
                Url = url,
                Method = "GET",
                Headers = {
                    ["Accept"] = "*/*"
                }
            })

            if type(response) ~= "table" then
                error("HTTP 回應無效")
            end

            local statusCode = tonumber(response.StatusCode or response.Status or 0)
            local body = response.Body

            if statusCode ~= 0 and (statusCode < 200 or statusCode >= 300) then
                error("HTTP 狀態碼: " .. tostring(statusCode))
            end

            if type(body) ~= "string" or body == "" then
                error("HTTP 回應內容為空")
            end

            return body
        end
    end

    return nil
end

local function getLoadFunction()
    if type(loadstring) == "function" then
        return loadstring
    end
    if type(load) == "function" then
        return load
    end
    return nil
end

local function loadDeveloperTool()
    local success, result = pcall(function()
        local httpGet = getHttpGet()
        if not httpGet then
            error("找不到 HTTP 請求函式")
        end

        local source = httpGet(MAIN_SCRIPT_URL)

        if type(source) ~= "string" or source == "" then
            error("主程式內容為空")
        end

        if source:sub(1, 1) == "<" then
            error("GitHub 回傳的不是 Lua 程式碼")
        end

        local loadFunction = getLoadFunction()
        if not loadFunction then
            error("此執行環境不支援 loadstring 或 load")
        end

        local func, err = loadFunction(source)
        if type(func) ~= "function" then
            error(tostring(err or "Lua 編譯失敗"))
        end

        return func()
    end)

    if not success then
        warn("載入失敗: " .. tostring(result))
        return false
    end

    return true
end

if Player and Player.Name == CREATOR_NAME then
    loadDeveloperTool()
    return
end

local oldGui = CoreGui:FindFirstChild("DeveloperToolV5_KeySystem")
if oldGui then
    oldGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeveloperToolV5_KeySystem"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 17, 23)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -130)
MainFrame.Size = UDim2.new(0, 320, 0, 260)

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = MainFrame

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(40, 46, 56)
Stroke.Thickness = 1
Stroke.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Parent = MainFrame
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 0, 0, 5)
Title.Size = UDim2.new(1, 0, 0, 45)
Title.Font = Enum.Font.GothamBold
Title.Text = "DeveloperTool V5"
Title.TextColor3 = Color3.fromRGB(88, 166, 255)
Title.TextSize = 20

local KeyInput = Instance.new("TextBox")
KeyInput.Name = "KeyInput"
KeyInput.Parent = MainFrame
KeyInput.BackgroundColor3 = Color3.fromRGB(13, 17, 23)
KeyInput.BorderSizePixel = 0
KeyInput.Position = UDim2.new(0.1, 0, 0.23, 0)
KeyInput.Size = UDim2.new(0.8, 0, 0, 38)
KeyInput.ClearTextOnFocus = false
KeyInput.Font = Enum.Font.Code
KeyInput.PlaceholderText = "請輸入 Key..."
KeyInput.Text = ""
KeyInput.TextColor3 = Color3.fromRGB(126, 231, 135)
KeyInput.TextSize = 14

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 6)
InputCorner.Parent = KeyInput

local InputStroke = Instance.new("UIStroke")
InputStroke.Color = Color3.fromRGB(40, 46, 56)
InputStroke.Parent = KeyInput

local GetKeyBtn = Instance.new("TextButton")
GetKeyBtn.Name = "GetKeyBtn"
GetKeyBtn.Parent = MainFrame
GetKeyBtn.BackgroundColor3 = Color3.fromRGB(33, 38, 45)
GetKeyBtn.BorderSizePixel = 0
GetKeyBtn.Position = UDim2.new(0.1, 0, 0.43, 0)
GetKeyBtn.Size = UDim2.new(0.8, 0, 0, 36)
GetKeyBtn.Font = Enum.Font.Gotham
GetKeyBtn.Text = "取得 Key (複製連結)"
GetKeyBtn.TextColor3 = Color3.fromRGB(201, 209, 217)
GetKeyBtn.TextSize = 14

local GetKeyCorner = Instance.new("UICorner")
GetKeyCorner.CornerRadius = UDim.new(0, 6)
GetKeyCorner.Parent = GetKeyBtn

local SubmitBtn = Instance.new("TextButton")
SubmitBtn.Name = "SubmitBtn"
SubmitBtn.Parent = MainFrame
SubmitBtn.BackgroundColor3 = Color3.fromRGB(35, 134, 54)
SubmitBtn.BorderSizePixel = 0
SubmitBtn.Position = UDim2.new(0.1, 0, 0.62, 0)
SubmitBtn.Size = UDim2.new(0.8, 0, 0, 38)
SubmitBtn.Font = Enum.Font.GothamBold
SubmitBtn.Text = "驗證"
SubmitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SubmitBtn.TextSize = 16

local SubmitCorner = Instance.new("UICorner")
SubmitCorner.CornerRadius = UDim.new(0, 6)
SubmitCorner.Parent = SubmitBtn

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0.05, 0, 0.82, 0)
StatusLabel.Size = UDim2.new(0.9, 0, 0, 35)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = ""
StatusLabel.TextColor3 = Color3.fromRGB(139, 148, 158)
StatusLabel.TextSize = 12
StatusLabel.TextWrapped = true

local verifying = false
local loaded = false

local function setStatus(text, color)
    StatusLabel.Text = tostring(text)
    StatusLabel.TextColor3 = color
end

local function verifyKey()
    if verifying or loaded then
        return
    end

    local key = tostring(KeyInput.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")

    if key == "" then
        setStatus("請先輸入 Key", Color3.fromRGB(255, 80, 80))
        return
    end

    local requestFunction = getRequestFunction()

    if not requestFunction then
        setStatus("環境不支援 HTTP Request", Color3.fromRGB(255, 80, 80))
        return
    end

    verifying = true
    SubmitBtn.Text = "驗證中..."
    SubmitBtn.Active = false

    local success, response = pcall(function()
        return requestFunction({
            Url = API_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Accept"] = "application/json"
            },
            Body = HttpService:JSONEncode({
                key = key
            })
        })
    end)

    if not success or type(response) ~= "table" then
        verifying = false
        SubmitBtn.Text = "驗證"
        SubmitBtn.Active = true
        setStatus("API 連線失敗", Color3.fromRGB(255, 80, 80))
        return
    end

    local statusCode = tonumber(response.StatusCode or response.Status or 0)
    local body = tostring(response.Body or "")

    if statusCode ~= 0 and (statusCode < 200 or statusCode >= 300) then
        verifying = false
        SubmitBtn.Text = "驗證"
        SubmitBtn.Active = true
        setStatus("API 回應錯誤: " .. tostring(statusCode), Color3.fromRGB(255, 80, 80))
        return
    end

    local decodeSuccess, data = pcall(function()
        return HttpService:JSONDecode(body)
    end)

    if decodeSuccess and type(data) == "table" and data.valid == true then
        loaded = true
        verifying = false
        setStatus("驗證成功！", Color3.fromRGB(126, 231, 135))
        SubmitBtn.Text = "成功"

        task.wait(0.8)

        if ScreenGui and ScreenGui.Parent then
            ScreenGui:Destroy()
        end

        loadDeveloperTool()
        return
    end

    verifying = false
    SubmitBtn.Text = "驗證"
    SubmitBtn.Active = true

    if decodeSuccess and type(data) == "table" and data.message then
        setStatus(tostring(data.message), Color3.fromRGB(255, 80, 80))
    else
        setStatus("Key 驗證失敗", Color3.fromRGB(255, 80, 80))
    end
end

GetKeyBtn.Activated:Connect(function()
    local clipboardFunction = nil

    if type(setclipboard) == "function" then
        clipboardFunction = setclipboard
    elseif type(toclipboard) == "function" then
        clipboardFunction = toclipboard
    end

    if clipboardFunction then
        local success = pcall(function()
            clipboardFunction(GET_KEY_URL)
        end)

        if success then
            setStatus("已複製取 Key 網址！", Color3.fromRGB(126, 231, 135))
        else
            setStatus("複製失敗", Color3.fromRGB(255, 80, 80))
        end
    else
        print(GET_KEY_URL)
        setStatus("已將網址輸出到主控台", Color3.fromRGB(126, 231, 135))
    end
end)

SubmitBtn.Activated:Connect(verifyKey)

KeyInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        verifyKey()
    end
end)
