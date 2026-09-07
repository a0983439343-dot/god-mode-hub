local Visuals = {
    Connections = {},
    Fullbright = false,
    AtmosphereBackup = {},
    PostEffectsBackup = {},
    FreeCam = false,
    FOV = 70
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Keys = {}

local function addConnection(self, connection)
    table.insert(self.Connections, connection)
    return connection
end

local function applyFullbright(enabled)
    Visuals.Fullbright = enabled
    if enabled then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.ExposureCompensation = 0
    else
        Lighting.Brightness = 2
        Lighting.GlobalShadows = true
        Lighting.ExposureCompensation = 0
    end
end

local function clearAtmosphere(enabled)
    if enabled then
        task.spawn(function()
            local descendants = Lighting:GetDescendants()
            for i, item in ipairs(descendants) do
                if i % 100 == 0 then
                    task.wait()
                end
                if item:IsA("Atmosphere") then
                    item.Enabled = false
                end
            end
        end)
    else
        task.spawn(function()
            local descendants = Lighting:GetDescendants()
            for i, item in ipairs(descendants) do
                if i % 100 == 0 then
                    task.wait()
                end
                if item:IsA("Atmosphere") then
                    item.Enabled = true
                end
            end
        end)
    end
end

local function setPostEffects(enabled)
    task.spawn(function()
        local descendants = Lighting:GetDescendants()
        for i, item in ipairs(descendants) do
            if i % 100 == 0 then
                task.wait()
            end
            if item:IsA("BloomEffect") or item:IsA("BlurEffect") or item:IsA("ColorCorrectionEffect") or item:IsA("DepthOfFieldEffect") or item:IsA("SunRaysEffect") then
                item.Enabled = not enabled
            end
        end
    end)
end

local function setFreeCam(enabled)
    Visuals.FreeCam = enabled
    Camera = Workspace.CurrentCamera
    if enabled then
        Camera.CameraType = Enum.CameraType.Scriptable
    else
        Camera.CameraType = Enum.CameraType.Custom
        local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            Camera.CameraSubject = humanoid
        end
    end
end

function Visuals:Init(context)
    Player = context.Player
    local tab = context.Tab

    addConnection(self, UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            Keys[input.KeyCode.Name] = true
        end
    end))

    addConnection(self, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            Keys[input.KeyCode.Name] = false
        end
    end))

    addConnection(self, RunService.RenderStepped:Connect(function(dt)
        if not self.FreeCam then
            return
        end
        Camera = Workspace.CurrentCamera
        if not Camera then
            return
        end
        local forward = Keys.W and 1 or Keys.S and -1 or 0
        local side = Keys.D and 1 or Keys.A and -1 or 0
        local up = Keys.Space and 1 or Keys.LeftControl and -1 or 0
        local move = Vector3.new(side, up, -forward)
        if move.Magnitude > 1 then
            move = move.Unit
        end
        local speed = 70
        if Keys.LeftShift then
            speed = 180
        end
        Camera.CFrame = Camera.CFrame + Camera.CFrame:VectorToWorldSpace(move) * speed * dt
    end))

    tab:CreateSection("光照")
    tab:CreateToggle({
        Name = "全亮",
        CurrentValue = false,
        Flag = "DeveloperFullbright",
        Callback = function(value)
            applyFullbright(value)
        end
    })

    tab:CreateToggle({
        Name = "移除大氣效果",
        CurrentValue = false,
        Flag = "DeveloperRemoveAtmosphere",
        Callback = function(value)
            clearAtmosphere(value)
        end
    })

    tab:CreateToggle({
        Name = "停用後製效果",
        CurrentValue = false,
        Flag = "DeveloperPostEffects",
        Callback = function(value)
            setPostEffects(value)
        end
    })

    tab:CreateSection("鏡頭")
    tab:CreateToggle({
        Name = "自由鏡頭",
        CurrentValue = false,
        Flag = "DeveloperFreeCam",
        Callback = function(value)
            setFreeCam(value)
        end
    })

    tab:CreateInput({
        Name = "視野角度",
        CurrentValue = tostring(self.FOV),
        PlaceholderText = "輸入視野角度（40～120）",
        RemoveTextAfterFocusLost = false,
        Flag = "DeveloperFOV",
        Callback = function(value)
            local number = tonumber(value)
            if number then
                self.FOV = math.clamp(number, 40, 120)
                Camera = Workspace.CurrentCamera
                if Camera then
                    Camera.FieldOfView = self.FOV
                end
            end
        end
    })

    tab:CreateButton({
        Name = "重設鏡頭",
        Callback = function()
            Camera = Workspace.CurrentCamera
            if Camera then
                Camera.FieldOfView = 70
                Camera.CameraType = Enum.CameraType.Custom
            end
        end
    })
end

function Visuals:Cleanup()
    setFreeCam(false)
    applyFullbright(false)
    setPostEffects(false)
    clearAtmosphere(false)
    for i = #self.Connections, 1, -1 do
        pcall(function()
            self.Connections[i]:Disconnect()
        end)
        self.Connections[i] = nil
    end
end

return Visuals
