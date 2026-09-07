local Visuals = {
    Connections = {},

    Fullbright = false,
    NoAtmosphere = false,
    NoPostEffects = false,

    FreeCam = false,

    FOV = 70,
    FreeCamSpeed = 70,
    FreeCamFastSpeed = 180,

    Player = nil,
    PlayerGui = nil,
    State = nil,
    RunService = nil,
    Rayfield = nil,
    Window = nil,
    Tab = nil,

    OriginalLighting = {},
    OriginalAtmosphere = {},
    OriginalPostEffects = {},

    OriginalCameraType = nil,
    OriginalCameraSubject = nil,
    OriginalCameraCFrame = nil,
    OriginalFOV = nil,

    FreeCamPosition = nil,
    FreeCamYaw = 0,
    FreeCamPitch = 0,

    MouseSensitivity = 0.0025,

    _keys = {},
    _mouseLocked = false,
    _destroyed = false,
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

----------------------------------------------------------------
-- 工具
----------------------------------------------------------------

local function disconnect(connection)
    if connection then
        pcall(function()
            connection:Disconnect()
        end)
    end
end

local function getHumanoid(player)
    player = player or Visuals.Player or Players.LocalPlayer

    if not player then
        return nil
    end

    local character = player.Character

    if not character then
        return nil
    end

    return character:FindFirstChildOfClass("Humanoid")
end

local function clamp(value, minValue, maxValue)
    return math.clamp(value, minValue, maxValue)
end

local function getCamera()
    return Workspace.CurrentCamera
end

----------------------------------------------------------------
-- Fullbright
----------------------------------------------------------------

function Visuals:EnableFullbright()
    if self.Fullbright then
        return
    end

    self.Fullbright = true

    self.OriginalLighting.Brightness = Lighting.Brightness
    self.OriginalLighting.ClockTime = Lighting.ClockTime
    self.OriginalLighting.FogEnd = Lighting.FogEnd
    self.OriginalLighting.GlobalShadows = Lighting.GlobalShadows
    self.OriginalLighting.ExposureCompensation = Lighting.ExposureCompensation

    pcall(function()
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.ExposureCompensation = 0
    end)
end

function Visuals:DisableFullbright()
    if not self.Fullbright then
        return
    end

    self.Fullbright = false

    pcall(function()
        if self.OriginalLighting.Brightness ~= nil then
            Lighting.Brightness = self.OriginalLighting.Brightness
        end

        if self.OriginalLighting.ClockTime ~= nil then
            Lighting.ClockTime = self.OriginalLighting.ClockTime
        end

        if self.OriginalLighting.FogEnd ~= nil then
            Lighting.FogEnd = self.OriginalLighting.FogEnd
        end

        if self.OriginalLighting.GlobalShadows ~= nil then
            Lighting.GlobalShadows = self.OriginalLighting.GlobalShadows
        end

        if self.OriginalLighting.ExposureCompensation ~= nil then
            Lighting.ExposureCompensation =
                self.OriginalLighting.ExposureCompensation
        end
    end)
end

function Visuals:SetFullbright(enabled)
    enabled = enabled == true

    if enabled then
        self:EnableFullbright()
    else
        self:DisableFullbright()
    end
end

----------------------------------------------------------------
-- Atmosphere
----------------------------------------------------------------

function Visuals:SetNoAtmosphere(enabled)
    enabled = enabled == true

    if enabled then
        self.NoAtmosphere = true

        for _, object in ipairs(Lighting:GetDescendants()) do
            if object:IsA("Atmosphere") then
                if self.OriginalAtmosphere[object] == nil then
                    self.OriginalAtmosphere[object] = object.Enabled
                end

                pcall(function()
                    object.Enabled = false
                end)
            end
        end
    else
        self.NoAtmosphere = false

        for object, originalValue in pairs(self.OriginalAtmosphere) do
            if object and object.Parent then
                pcall(function()
                    object.Enabled = originalValue
                end)
            end

            self.OriginalAtmosphere[object] = nil
        end
    end
end

function Visuals:UpdateAtmosphere()
    if not self.NoAtmosphere then
        return
    end

    for _, object in ipairs(Lighting:GetDescendants()) do
        if object:IsA("Atmosphere") then
            if self.OriginalAtmosphere[object] == nil then
                self.OriginalAtmosphere[object] = object.Enabled
            end

            pcall(function()
                object.Enabled = false
            end)
        end
    end
end

----------------------------------------------------------------
-- 後製效果
----------------------------------------------------------------

function Visuals:SetNoPostEffects(enabled)
    enabled = enabled == true

    local postEffectClasses = {
        BloomEffect = true,
        BlurEffect = true,
        ColorCorrectionEffect = true,
        DepthOfFieldEffect = true,
        SunRaysEffect = true,
    }

    if enabled then
        self.NoPostEffects = true

        for _, object in ipairs(Lighting:GetDescendants()) do
            if postEffectClasses[object.ClassName] then
                if self.OriginalPostEffects[object] == nil then
                    self.OriginalPostEffects[object] = object.Enabled
                end

                pcall(function()
                    object.Enabled = false
                end)
            end
        end
    else
        self.NoPostEffects = false

        for object, originalValue in pairs(self.OriginalPostEffects) do
            if object and object.Parent then
                pcall(function()
                    object.Enabled = originalValue
                end)
            end

            self.OriginalPostEffects[object] = nil
        end
    end
end

function Visuals:UpdatePostEffects()
    if not self.NoPostEffects then
        return
    end

    local postEffectClasses = {
        BloomEffect = true,
        BlurEffect = true,
        ColorCorrectionEffect = true,
        DepthOfFieldEffect = true,
        SunRaysEffect = true,
    }

    for _, object in ipairs(Lighting:GetDescendants()) do
        if postEffectClasses[object.ClassName] then
            if self.OriginalPostEffects[object] == nil then
                self.OriginalPostEffects[object] = object.Enabled
            end

            pcall(function()
                object.Enabled = false
            end)
        end
    end
end

----------------------------------------------------------------
-- FreeCam
----------------------------------------------------------------

function Visuals:GetCurrentCharacterCamera()
    local camera = getCamera()

    if not camera then
        return nil
    end

    return camera
end

function Visuals:GetFreeCamDirection()
    local camera = getCamera()

    if not camera then
        return Vector3.zero
    end

    local direction = Vector3.zero

    if self._keys.W then
        direction += Vector3.new(0, 0, -1)
    end

    if self._keys.S then
        direction += Vector3.new(0, 0, 1)
    end

    if self._keys.A then
        direction += Vector3.new(-1, 0, 0)
    end

    if self._keys.D then
        direction += Vector3.new(1, 0, 0)
    end

    if self._keys.Space then
        direction += Vector3.new(0, 1, 0)
    end

    if self._keys.LeftControl or self._keys.RightControl then
        direction += Vector3.new(0, -1, 0)
    end

    return direction
end

function Visuals:UpdateFreeCam(dt)
    if not self.FreeCam then
        return
    end

    local camera = getCamera()

    if not camera then
        return
    end

    if not self.FreeCamPosition then
        self.FreeCamPosition = camera.CFrame.Position
    end

    ------------------------------------------------------------
    -- 依照 FreeCam 本身的 Yaw / Pitch 建立旋轉
    ------------------------------------------------------------

    local rotation =
        CFrame.Angles(0, self.FreeCamYaw, 0)
        * CFrame.Angles(self.FreeCamPitch, 0, 0)

    local forward = rotation.LookVector
    local right = rotation.RightVector

    local movement = Vector3.zero

    if self._keys.W then
        movement += forward
    end

    if self._keys.S then
        movement -= forward
    end

    if self._keys.A then
        movement -= right
    end

    if self._keys.D then
        movement += right
    end

    ------------------------------------------------------------
    -- 垂直移動不依賴角色
    ------------------------------------------------------------

    if self._keys.Space then
        movement += Vector3.yAxis
    end

    if self._keys.LeftControl or self._keys.RightControl then
        movement -= Vector3.yAxis
    end

    if movement.Magnitude > 0 then
        movement = movement.Unit

        local speed = self.FreeCamSpeed

        if self._keys.LeftShift or self._keys.RightShift then
            speed = self.FreeCamFastSpeed
        end

        self.FreeCamPosition += movement * speed * dt
    end

    ------------------------------------------------------------
    -- 只改 Camera
    -- 完全不碰 HumanoidRootPart
    ------------------------------------------------------------

    pcall(function()
        camera.CFrame =
            CFrame.new(self.FreeCamPosition)
            * CFrame.Angles(self.FreeCamPitch, self.FreeCamYaw, 0)
    end)
end

function Visuals:StartFreeCam()
    if self.FreeCam then
        return
    end

    local camera = getCamera()

    if not camera then
        return
    end

    self.FreeCam = true

    ------------------------------------------------------------
    -- 備份 Camera
    ------------------------------------------------------------

    self.OriginalCameraType = camera.CameraType
    self.OriginalCameraSubject = camera.CameraSubject
    self.OriginalCameraCFrame = camera.CFrame
    self.OriginalFOV = camera.FieldOfView

    ------------------------------------------------------------
    -- 初始位置取 Camera
    ------------------------------------------------------------

    self.FreeCamPosition = camera.CFrame.Position

    ------------------------------------------------------------
    -- 從現在 Camera 的旋轉取得初始 Yaw / Pitch
    ------------------------------------------------------------

    local lookVector = camera.CFrame.LookVector

    self.FreeCamYaw =
        math.atan2(-lookVector.X, -lookVector.Z)

    self.FreeCamPitch =
        math.asin(
            clamp(
                lookVector.Y,
                -1,
                1
            )
        )

    ------------------------------------------------------------
    -- Scriptable 之後角色不再控制 Camera
    ------------------------------------------------------------

    pcall(function()
        camera.CameraType = Enum.CameraType.Scriptable
    end)

    ------------------------------------------------------------
    -- 不鎖滑鼠
    -- 保留 MouseMovement 事件正常工作
    ------------------------------------------------------------

    self._mouseLocked = UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter

    pcall(function()
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end)
end

function Visuals:StopFreeCam()
    if not self.FreeCam then
        return
    end

    local camera = getCamera()

    self.FreeCam = false

    if camera then
        pcall(function()
            camera.CameraType =
                self.OriginalCameraType
                or Enum.CameraType.Custom
        end)

        --------------------------------------------------------
        -- 恢復角色作為 CameraSubject
        --------------------------------------------------------

        local humanoid = getHumanoid()

        if humanoid then
            pcall(function()
                camera.CameraSubject = humanoid
            end)
        elseif self.OriginalCameraSubject then
            pcall(function()
                camera.CameraSubject = self.OriginalCameraSubject
            end)
        end

        if self.OriginalFOV then
            pcall(function()
                camera.FieldOfView = self.OriginalFOV
            end)
        end
    end

    self.FreeCamPosition = nil

    ------------------------------------------------------------
    -- 清除按鍵狀態
    ------------------------------------------------------------

    self._keys = {}

    pcall(function()
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end)
end

function Visuals:SetFreeCam(enabled)
    enabled = enabled == true

    if enabled then
        self:StartFreeCam()
    else
        self:StopFreeCam()
    end
end

----------------------------------------------------------------
-- FOV
----------------------------------------------------------------

function Visuals:SetFOV(value)
    value = tonumber(value)

    if not value then
        return
    end

    self.FOV = clamp(value, 1, 120)

    local camera = getCamera()

    if camera then
        pcall(function()
            camera.FieldOfView = self.FOV
        end)
    end
end

----------------------------------------------------------------
-- UI
----------------------------------------------------------------

function Visuals:CreateUI()
    local tab = self.Tab

    if not tab then
        return
    end

    ------------------------------------------------------------
    -- Fullbright
    ------------------------------------------------------------

    tab:CreateToggle({
        Name = "夜視 / 全亮",
        CurrentValue = false,
        Flag = "Developer_Fullbright",
        Callback = function(value)
            self:SetFullbright(value)
        end,
    })

    ------------------------------------------------------------
    -- Atmosphere
    ------------------------------------------------------------

    tab:CreateToggle({
        Name = "移除大氣效果",
        CurrentValue = false,
        Flag = "Developer_NoAtmosphere",
        Callback = function(value)
            self:SetNoAtmosphere(value)
        end,
    })

    ------------------------------------------------------------
    -- Post Effects
    ------------------------------------------------------------

    tab:CreateToggle({
        Name = "移除後製效果",
        CurrentValue = false,
        Flag = "Developer_NoPostEffects",
        Callback = function(value)
            self:SetNoPostEffects(value)
        end,
    })

    ------------------------------------------------------------
    -- FreeCam
    ------------------------------------------------------------

    tab:CreateToggle({
        Name = "自由視角",
        CurrentValue = false,
        Flag = "Developer_FreeCam",
        Callback = function(value)
            self:SetFreeCam(value)
        end,
    })

    tab:CreateInput({
        Name = "自由視角速度",
        CurrentValue = tostring(self.FreeCamSpeed),
        PlaceholderText = "輸入 1~1000",
        RemoveTextAfterFocusLost = false,
        Flag = "Developer_FreeCamSpeed",
        Callback = function(value)
            local number = tonumber(value)

            if number then
                self.FreeCamSpeed = clamp(number, 1, 1000)
            end
        end,
    })

    tab:CreateInput({
        Name = "自由視角加速速度",
        CurrentValue = tostring(self.FreeCamFastSpeed),
        PlaceholderText = "輸入 1~3000",
        RemoveTextAfterFocusLost = false,
        Flag = "Developer_FreeCamFastSpeed",
        Callback = function(value)
            local number = tonumber(value)

            if number then
                self.FreeCamFastSpeed = clamp(number, 1, 3000)
            end
        end,
    })

    tab:CreateInput({
        Name = "視野 FOV",
        CurrentValue = tostring(self.FOV),
        PlaceholderText = "輸入 1~120",
        RemoveTextAfterFocusLost = false,
        Flag = "Developer_FOV",
        Callback = function(value)
            self:SetFOV(value)
        end,
    })

    ------------------------------------------------------------
    -- 重置視覺
    ------------------------------------------------------------

    tab:CreateButton({
        Name = "重置視覺設定",
        Callback = function()
            self:SetFullbright(false)
            self:SetNoAtmosphere(false)
            self:SetNoPostEffects(false)
            self:SetFOV(70)
        end,
    })
end

----------------------------------------------------------------
-- Init
----------------------------------------------------------------

function Visuals:Init(context)
    if self._destroyed then
        return
    end

    self.Player = context.Player or Players.LocalPlayer
    self.PlayerGui = context.PlayerGui
    self.State = context.State
    self.RunService = context.RunService or RunService
    self.Rayfield = context.Rayfield
    self.Window = context.Window
    self.Tab = context.Tab

    local camera = getCamera()

    if camera then
        self.OriginalFOV = camera.FieldOfView
        self.FOV = camera.FieldOfView
    end

    ------------------------------------------------------------
    -- 鍵盤輸入
    ------------------------------------------------------------

    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end

        local key = input.KeyCode

        if key == Enum.KeyCode.W then
            self._keys.W = true

        elseif key == Enum.KeyCode.S then
            self._keys.S = true

        elseif key == Enum.KeyCode.A then
            self._keys.A = true

        elseif key == Enum.KeyCode.D then
            self._keys.D = true

        elseif key == Enum.KeyCode.Space then
            self._keys.Space = true

        elseif key == Enum.KeyCode.LeftControl then
            self._keys.LeftControl = true

        elseif key == Enum.KeyCode.RightControl then
            self._keys.RightControl = true

        elseif key == Enum.KeyCode.LeftShift then
            self._keys.LeftShift = true

        elseif key == Enum.KeyCode.RightShift then
            self._keys.RightShift = true
        end
    end))

    table.insert(self.Connections, UserInputService.InputEnded:Connect(function(input)
        local key = input.KeyCode

        if key == Enum.KeyCode.W then
            self._keys.W = false

        elseif key == Enum.KeyCode.S then
            self._keys.S = false

        elseif key == Enum.KeyCode.A then
            self._keys.A = false

        elseif key == Enum.KeyCode.D then
            self._keys.D = false

        elseif key == Enum.KeyCode.Space then
            self._keys.Space = false

        elseif key == Enum.KeyCode.LeftControl then
            self._keys.LeftControl = false

        elseif key == Enum.KeyCode.RightControl then
            self._keys.RightControl = false

        elseif key == Enum.KeyCode.LeftShift then
            self._keys.LeftShift = false

        elseif key == Enum.KeyCode.RightShift then
            self._keys.RightShift = false
        end
    end))

    ------------------------------------------------------------
    -- 滑鼠視角
    ------------------------------------------------------------

    table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input)
        if not self.FreeCam then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end

        local delta = input.Delta

        self.FreeCamYaw -= delta.X * self.MouseSensitivity
        self.FreeCamPitch -= delta.Y * self.MouseSensitivity

        --------------------------------------------------------
        -- 防止翻轉過頭
        --------------------------------------------------------

        self.FreeCamPitch = clamp(
            self.FreeCamPitch,
            math.rad(-89),
            math.rad(89)
        )
    end))

    ------------------------------------------------------------
    -- 每幀更新
    ------------------------------------------------------------

    table.insert(self.Connections, RunService.RenderStepped:Connect(function(dt)
        if self._destroyed then
            return
        end

        self:UpdateFreeCam(dt)
        self:UpdateAtmosphere()
        self:UpdatePostEffects()

        --------------------------------------------------------
        -- FreeCam 開啟後
        -- 不碰角色位置
        --------------------------------------------------------

        if self.FreeCam then
            local camera = getCamera()

            if camera and camera.CameraType ~= Enum.CameraType.Scriptable then
                pcall(function()
                    camera.CameraType = Enum.CameraType.Scriptable
                end)
            end
        end
    end))

    ------------------------------------------------------------
    -- 角色重生
    ------------------------------------------------------------

    if self.Player then
        table.insert(self.Connections, self.Player.CharacterAdded:Connect(function()
            task.wait(0.2)

            if self._destroyed then
                return
            end

            ----------------------------------------------------
            -- FreeCam 不應該因為玩家重生而消失
            -- 但 CameraSubject 不可以重新搶回控制
            ----------------------------------------------------

            if self.FreeCam then
                local camera = getCamera()

                if camera then
                    pcall(function()
                        camera.CameraType = Enum.CameraType.Scriptable
                    end)
                end
            end
        end))
    end

    self:CreateUI()
end

----------------------------------------------------------------
-- Cleanup
----------------------------------------------------------------

function Visuals:Cleanup()
    if self._destroyed then
        return
    end

    self._destroyed = true

    ------------------------------------------------------------
    -- 關閉 FreeCam
    ------------------------------------------------------------

    self:StopFreeCam()

    ------------------------------------------------------------
    -- 還原 Fullbright
    ------------------------------------------------------------

    self:DisableFullbright()

    ------------------------------------------------------------
    -- 還原 Atmosphere
    ------------------------------------------------------------

    self:SetNoAtmosphere(false)

    ------------------------------------------------------------
    -- 還原後製
    ------------------------------------------------------------

    self:SetNoPostEffects(false)

    ------------------------------------------------------------
    -- 還原 FOV
    ------------------------------------------------------------

    local camera = getCamera()

    if camera and self.OriginalFOV then
        pcall(function()
            camera.FieldOfView = self.OriginalFOV
        end)
    end

    ------------------------------------------------------------
    -- 清除輸入
    ------------------------------------------------------------

    self._keys = {}

    ------------------------------------------------------------
    -- 斷開連線
    ------------------------------------------------------------

    for _, connection in ipairs(self.Connections) do
        disconnect(connection)
    end

    self.Connections = {}
end

return Visuals
