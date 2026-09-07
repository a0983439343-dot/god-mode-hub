-- DeveloperTool V5 | Visuals
local Visuals = {
    Connections = {},
    Fullbright = false,
    RemoveAtmosphere = false,
    RemovePostEffects = false,
    FreeCam = false,
    FOV = 70,
    OriginalLighting = nil,
    OriginalFOV = nil,
    AtmosphereBackup = {},
    PostEffectsBackup = {},
    FreeCamBackup = nil,
    FreeCamPosition = nil,
    FreeCamYaw = 0,
    FreeCamPitch = 0,
    FreeCamInputConnection = nil,
    FreeCamRenderConnection = nil,
    AtmosphereConnection = nil,
    PostEffectConnection = nil,
    Shared = nil,
    Alive = false,
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local Keys = {}

local function disconnect(connection)
    if connection then
        pcall(function()
            connection:Disconnect()
        end)
    end
end

local function addConnection(self, connection)
    if connection then
        table.insert(self.Connections, connection)
    end
    return connection
end

local function getCamera()
    return Workspace.CurrentCamera
end

local function backupFOV(self)
    if self.OriginalFOV ~= nil then
        return
    end

    local camera = getCamera()
    self.OriginalFOV = camera and camera.FieldOfView or 70
    self.FOV = self.OriginalFOV
end

local function backupLighting(self)
    if self.OriginalLighting then
        return
    end

    self.OriginalLighting = {
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        FogEnd = Lighting.FogEnd,
        GlobalShadows = Lighting.GlobalShadows,
        ExposureCompensation = Lighting.ExposureCompensation,
    }
end

local function setFullbright(self, enabled)
    backupFOV(self)

    if enabled then
        backupLighting(self)
        self.Fullbright = true
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.ExposureCompensation = 0
        return
    end

    self.Fullbright = false
    if self.OriginalLighting then
        pcall(function()
            Lighting.Brightness = self.OriginalLighting.Brightness
            Lighting.ClockTime = self.OriginalLighting.ClockTime
            Lighting.FogEnd = self.OriginalLighting.FogEnd
            Lighting.GlobalShadows = self.OriginalLighting.GlobalShadows
            Lighting.ExposureCompensation = self.OriginalLighting.ExposureCompensation
        end)
    end
end

local function disableAtmosphereItem(self, item)
    if not item:IsA("Atmosphere") then
        return
    end

    if self.AtmosphereBackup[item] == nil then
        self.AtmosphereBackup[item] = item.Enabled
    end
    item.Enabled = false
end

local function restoreAtmosphere(self)
    for item, original in pairs(self.AtmosphereBackup) do
        if item and item.Parent then
            pcall(function()
                item.Enabled = original
            end)
        end
    end
    table.clear(self.AtmosphereBackup)
end

local function stopAtmosphereWatcher(self)
    disconnect(self.AtmosphereConnection)
    self.AtmosphereConnection = nil
end

local function setRemoveAtmosphere(self, enabled)
    self.RemoveAtmosphere = enabled
    stopAtmosphereWatcher(self)

    if not enabled then
        restoreAtmosphere(self)
        return
    end

    for _, item in ipairs(Lighting:GetDescendants()) do
        disableAtmosphereItem(self, item)
    end

    self.AtmosphereConnection = Lighting.DescendantAdded:Connect(function(item)
        if self.Alive and self.RemoveAtmosphere then
            disableAtmosphereItem(self, item)
        end
    end)
end

local function isPostEffect(item)
    return item:IsA("BloomEffect")
        or item:IsA("BlurEffect")
        or item:IsA("ColorCorrectionEffect")
        or item:IsA("DepthOfFieldEffect")
        or item:IsA("SunRaysEffect")
        or item:IsA("ColorGradingEffect")
end

local function disablePostEffectItem(self, item)
    if not isPostEffect(item) then
        return
    end

    if self.PostEffectsBackup[item] == nil then
        self.PostEffectsBackup[item] = item.Enabled
    end
    item.Enabled = false
end

local function restorePostEffects(self)
    for item, original in pairs(self.PostEffectsBackup) do
        if item and item.Parent then
            pcall(function()
                item.Enabled = original
            end)
        end
    end
    table.clear(self.PostEffectsBackup)
end

local function stopPostEffectWatcher(self)
    disconnect(self.PostEffectConnection)
    self.PostEffectConnection = nil
end

local function setRemovePostEffects(self, enabled)
    self.RemovePostEffects = enabled
    stopPostEffectWatcher(self)

    if not enabled then
        restorePostEffects(self)
        return
    end

    for _, item in ipairs(Lighting:GetDescendants()) do
        disablePostEffectItem(self, item)
    end

    self.PostEffectConnection = Lighting.DescendantAdded:Connect(function(item)
        if self.Alive and self.RemovePostEffects then
            disablePostEffectItem(self, item)
        end
    end)
end

local function stopFreeCamConnections(self)
    disconnect(self.FreeCamInputConnection)
    disconnect(self.FreeCamRenderConnection)
    self.FreeCamInputConnection = nil
    self.FreeCamRenderConnection = nil
end

local function rotationCFrame(self)
    return CFrame.fromOrientation(self.FreeCamPitch, self.FreeCamYaw, 0)
end

local function stopFreeCam(self, notifyShared)
    if not self.FreeCam then
        stopFreeCamConnections(self)
        if notifyShared and self.Shared then
            self.Shared.FreeCamActive = false
        end
        return
    end

    self.FreeCam = false
    stopFreeCamConnections(self)

    local camera = getCamera()
    local backup = self.FreeCamBackup
    if camera then
        if backup then
            camera.CFrame = backup.CFrame
            camera.FieldOfView = backup.FieldOfView
            camera.CameraType = backup.CameraType
            if backup.CameraSubject and backup.CameraSubject.Parent then
                camera.CameraSubject = backup.CameraSubject
            else
                local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    camera.CameraSubject = humanoid
                end
            end
        else
            camera.CameraType = Enum.CameraType.Custom
            local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                camera.CameraSubject = humanoid
            end
        end
    end

    self.FreeCamBackup = nil
    self.FreeCamPosition = nil

    if self.Shared then
        self.Shared.FreeCamActive = false
    end
end

local function startFreeCam(self)
    if self.Shared and self.Shared.FlightActive and self.Shared.StopFlight then
        pcall(self.Shared.StopFlight)
    end

    local camera = getCamera()
    if not camera then
        return
    end

    stopFreeCam(self, false)
    backupFOV(self)

    self.FreeCam = true
    if self.Shared then
        self.Shared.FreeCamActive = true
    end

    self.FreeCamBackup = {
        CFrame = camera.CFrame,
        FieldOfView = camera.FieldOfView,
        CameraType = camera.CameraType,
        CameraSubject = camera.CameraSubject,
    }

    local rx, ry = camera.CFrame:ToOrientation()
    self.FreeCamPitch = math.clamp(rx, math.rad(-89), math.rad(89))
    self.FreeCamYaw = ry
    self.FreeCamPosition = camera.CFrame.Position
    camera.CameraType = Enum.CameraType.Scriptable

    self.FreeCamInputConnection = UserInputService.InputChanged:Connect(function(input)
        if not self.FreeCam then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement then
            self.FreeCamYaw -= input.Delta.X * 0.0025
            self.FreeCamPitch = math.clamp(
                self.FreeCamPitch - input.Delta.Y * 0.0025,
                math.rad(-89),
                math.rad(89)
            )
        elseif input.UserInputType == Enum.UserInputType.Touch then
            self.FreeCamYaw -= input.Delta.X * 0.004
            self.FreeCamPitch = math.clamp(
                self.FreeCamPitch - input.Delta.Y * 0.004,
                math.rad(-89),
                math.rad(89)
            )
        end
    end)

    self.FreeCamRenderConnection = RunService.RenderStepped:Connect(function(dt)
        if not self.Alive or not self.FreeCam then
            return
        end

        local currentCamera = getCamera()
        if not currentCamera then
            return
        end

        local rotation = rotationCFrame(self)
        local forward = (Keys.W and 1 or 0) + (Keys.S and -1 or 0)
        local side = (Keys.D and 1 or 0) + (Keys.A and -1 or 0)
        local vertical = (Keys.Space and 1 or 0)
        if Keys.LeftControl or Keys.RightControl then
            vertical -= 1
        end

        local move = rotation.LookVector * forward
            + rotation.RightVector * side
            + Vector3.yAxis * vertical

        if move.Magnitude > 1 then
            move = move.Unit
        end

        local speed = (Keys.LeftShift or Keys.RightShift) and 180 or 70
        self.FreeCamPosition += move * speed * dt
        currentCamera.CFrame = CFrame.new(self.FreeCamPosition) * rotation
        currentCamera.CameraType = Enum.CameraType.Scriptable
    end)
end

function Visuals:Init(context)
    Player = context.Player
    self.Shared = context.Shared or {}
    self.Alive = true
    backupFOV(self)

    addConnection(self, UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not self.Alive then
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

    local tab = context.Tab
    tab:CreateSection("光照")
    tab:CreateToggle({
        Name = "全亮",
        CurrentValue = false,
        Flag = "DeveloperV5Fullbright",
        Callback = function(value)
            setFullbright(self, value)
        end,
    })

    tab:CreateToggle({
        Name = "移除大氣效果",
        CurrentValue = false,
        Flag = "DeveloperV5RemoveAtmosphere",
        Callback = function(value)
            setRemoveAtmosphere(self, value)
        end,
    })

    tab:CreateToggle({
        Name = "停用後製效果",
        CurrentValue = false,
        Flag = "DeveloperV5PostEffects",
        Callback = function(value)
            setRemovePostEffects(self, value)
        end,
    })

    tab:CreateSection("鏡頭")
    tab:CreateToggle({
        Name = "自由鏡頭",
        CurrentValue = false,
        Flag = "DeveloperV5FreeCam",
        Callback = function(value)
            if value then
                startFreeCam(self)
            else
                stopFreeCam(self, true)
            end
        end,
    })

    tab:CreateInput({
        Name = "視野角度",
        CurrentValue = tostring(self.FOV),
        PlaceholderText = "輸入視野角度（40～120）",
        RemoveTextAfterFocusLost = false,
        Flag = "DeveloperV5FOV",
        Callback = function(value)
            local number = tonumber(value)
            if not number then
                return
            end

            self.FOV = math.clamp(number, 40, 120)
            local camera = getCamera()
            if camera then
                camera.FieldOfView = self.FOV
            end
        end,
    })

    tab:CreateButton({
        Name = "重設鏡頭",
        Callback = function()
            stopFreeCam(self, true)
            local camera = getCamera()
            if camera then
                camera.FieldOfView = self.OriginalFOV or 70
                camera.CameraType = Enum.CameraType.Custom
                local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    camera.CameraSubject = humanoid
                end
            end
            self.FOV = self.OriginalFOV or 70
        end,
    })

    self.Shared.StopFreeCam = function()
        stopFreeCam(self, true)
    end
end

function Visuals:Cleanup()
    if not self.Alive then
        return
    end

    self.Alive = false
    stopFreeCam(self, true)
    stopAtmosphereWatcher(self)
    stopPostEffectWatcher(self)

    setFullbright(self, false)
    setRemoveAtmosphere(self, false)
    setRemovePostEffects(self, false)

    local camera = getCamera()
    if camera and self.OriginalFOV then
        camera.FieldOfView = self.OriginalFOV
    end

    for i = #self.Connections, 1, -1 do
        disconnect(self.Connections[i])
        self.Connections[i] = nil
    end

    table.clear(Keys)
    table.clear(self.AtmosphereBackup)
    table.clear(self.PostEffectsBackup)
    self.OriginalLighting = nil
    self.OriginalFOV = nil
    self.FreeCamBackup = nil
    self.FreeCamPosition = nil

    if self.Shared then
        self.Shared.FreeCamActive = false
        self.Shared.StopFreeCam = nil
    end
end

return Visuals
