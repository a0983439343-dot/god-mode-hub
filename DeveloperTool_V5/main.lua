local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local apiUrl = "https://devtool-key-system.a0983439343.workers.dev/api/verify"
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local KeyInput = Instance.new("TextBox")
local SubmitBtn = Instance.new("TextButton")
local StatusLabel = Instance.new("TextLabel")
ScreenGui.Name = "DeveloperToolV5_KeySystem"
ScreenGui.Parent = CoreGui
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 17, 23)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
MainFrame.Size = UDim2.new(0, 300, 0, 200)
Title.Name = "Title"
Title.Parent = MainFrame
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(1, 0, 0, 50)
Title.Font = Enum.Font.GothamBold
Title.Text = "DeveloperTool V5"
Title.TextColor3 = Color3.fromRGB(88, 166, 255)
Title.TextSize = 20
KeyInput.Name = "KeyInput"
KeyInput.Parent = MainFrame
KeyInput.BackgroundColor3 = Color3.fromRGB(13, 17, 23)
KeyInput.Position = UDim2.new(0.1, 0, 0.35, 0)
KeyInput.Size = UDim2.new(0.8, 0, 0, 40)
KeyInput.Font = Enum.Font.Code
KeyInput.PlaceholderText = "請輸入 Key..."
KeyInput.Text = ""
KeyInput.TextColor3 = Color3.fromRGB(126, 231, 135)
KeyInput.TextSize = 14
SubmitBtn.Name = "SubmitBtn"
SubmitBtn.Parent = MainFrame
SubmitBtn.BackgroundColor3 = Color3.fromRGB(35, 134, 54)
SubmitBtn.Position = UDim2.new(0.1, 0, 0.65, 0)
SubmitBtn.Size = UDim2.new(0.8, 0, 0, 40)
SubmitBtn.Font = Enum.Font.GothamBold
SubmitBtn.Text = "驗證"
SubmitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SubmitBtn.TextSize = 16
StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0.1, 0, 0.85, 0)
StatusLabel.Size = UDim2.new(0.8, 0, 0, 30)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = ""
StatusLabel.TextColor3 = Color3.fromRGB(139, 148, 158)
StatusLabel.TextSize = 12
local function loadDeveloperTool()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/a0983439343-dot/god-mode-hub/refs/heads/main/god-mode-hub-main/DeveloperTool_V5/loader.lua"))()
end
SubmitBtn.MouseButton1Click:Connect(function()
    local key = KeyInput.Text
    if key == "" then
        StatusLabel.Text = "輸入框是空的"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        return
    end
    StatusLabel.Text = "驗證中..."
    StatusLabel.TextColor3 = Color3.fromRGB(139, 148, 158)
    local success, result = pcall(function()
        return request({
            Url = apiUrl,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode({key = key})
        })
    end)
    if success and result and result.StatusCode == 200 then
        local data = HttpService:JSONDecode(result.Body)
        if data.valid then
            StatusLabel.Text = "驗證成功！"
            StatusLabel.TextColor3 = Color3.fromRGB(126, 231, 135)
            task.wait(1)
            ScreenGui:Destroy()
            loadDeveloperTool()
        else
            StatusLabel.Text = data.message or "驗證失敗"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
    else
        StatusLabel.Text = "API 連線失敗"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
end)
