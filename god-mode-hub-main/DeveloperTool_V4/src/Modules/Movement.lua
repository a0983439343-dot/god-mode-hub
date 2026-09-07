local Movement = {
    Connections = {},
    CharacterConnections = {},

    Noclip = false,
    InfiniteJump = false,

    FlightMode = "CFrame",
    Flying = false,

    Speed = 16,
    JumpPower = 50,
    Gravity = 196.2,
    FlightSpeed = 70,

    BodyVelocity = nil,
    LinearVelocity = nil,
    FlightAttachment = nil,

    OriginalCanCollide = {},
    OriginalGravity = nil,

    Player = nil,
    PlayerGui = nil,
    State = nil,
    RunService = nil,
    Rayfield = nil,
    Window = nil,
    Tab = nil,

    _character = nil,
    _humanoid = nil,
    _root = nil,

    _keys = {},
    _destroyed = false,
}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
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

local function safeDestroy(instance)
    if instance then
        pcall(function()
            instance:Destroy()
        end)
    end
end

local function getCharacter()
    local player = Movement.Player or Players.LocalPlayer
    if not player then
        return nil
    end

    local character = player.Character
    if character and character.Parent then
        return character
    end

    return nil
end

local function getHumanoid()
    local character = getCharacter()
    if not character then
        return nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        return humanoid
    end

    return nil
end

local function getRoot()
    local character = getCharacter()
    if not character then
        return nil
    end

    local root =
        character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")

    return root
end

local function parseNumber(value, fallback)
    local number = tonumber(value)

    if number == nil then
        return fallback
    end

    return number
end

local function clampNumber(value, minimum, maximum)
    return math.clamp(value, minimum, maximum)
end

----------------------------------------------------------------
-- 角色設定
----------------------------------------------------------------

function Movement:ApplyCharacterSettings()
    local humanoid = getHumanoid()
    if not humanoid then
        return
    end

    pcall(function()
        humanoid.WalkSpeed = self.Speed
    end)

    pcall(function()
        if humanoid.UseJumpPower then
            humanoid.JumpPower = self.JumpPower
        else
            humanoid.JumpHeight = math.clamp(self.JumpPower / 7, 1, 30)
        end
    end)

    if self.OriginalGravity == nil then
        self.OriginalGravity = Workspace.Gravity
    end

    pcall(function()
        Workspace.Gravity = self.Gravity
    end)
end

----------------------------------------------------------------
-- Noclip
----------------------------------------------------------------

function Movement:SetNoclip(enabled)
    enabled = enabled == true

    self.Noclip = enabled

    local character = getCharacter()
    if not character then
        return
    end

    if enabled then
        for _, object in ipairs(character:GetDescendants()) do
            if object:IsA("BasePart") then
                if self.OriginalCanCollide[object] == nil then
                    self.OriginalCanCollide[object] = object.CanCollide
                end

                pcall(function()
                    object.CanCollide = false
                end)
            end
        end
    else
        for object, originalValue in pairs(self.OriginalCanCollide) do
            if object and object.Parent then
                pcall(function()
                    object.CanCollide = originalValue
                end)
            end

            self.OriginalCanCollide[object] = nil
        end
    end
end

function Movement:UpdateNoclip()
    if not self.Noclip then
        return
    end

    local character = getCharacter()
    if not character then
        return
    end

    for _, object in ipairs(character:GetDescendants()) do
        if object:IsA("BasePart") then
            if self.OriginalCanCollide[object] == nil then
                self.OriginalCanCollide[object] = object.CanCollide
            end

            if object.CanCollide then
                pcall(function()
                    object.CanCollide = false
                end)
            end
        end
    end
end

----------------------------------------------------------------
-- Infinite Jump
----------------------------------------------------------------

function Movement:SetInfiniteJump(enabled)
    self.InfiniteJump = enabled == true
end

----------------------------------------------------------------
-- 飛行
----------------------------------------------------------------

function Movement:ClearFlightForce()
    safeDestroy(self.LinearVelocity)
    safeDestroy(self.BodyVelocity)
    safeDestroy(self.FlightAttachment)

    self.LinearVelocity = nil
    self.BodyVelocity = nil
    self.FlightAttachment = nil
end

function Movement:CreateLinearVelocity(root)
    self:ClearFlightForce()

    local attachment = Instance.new("Attachment")
    attachment.Name = "DeveloperFlightAttachment"
    attachment.Parent = root

    local linearVelocity = Instance.new("LinearVelocity")
    linearVelocity.Name = "DeveloperFlightLinearVelocity"
    linearVelocity.Attachment0 = attachment
    linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
    linearVelocity.MaxForce = math.huge
    linearVelocity.VectorVelocity = Vector3.zero
    linearVelocity.Parent = root

    self.FlightAttachment = attachment
    self.LinearVelocity = linearVelocity

    return linearVelocity
end

function Movement:CreateBodyVelocity(root)
    self:ClearFlightForce()

    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Name = "DeveloperFlightBodyVelocity"
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.P = 10000
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.Parent = root

    self.BodyVelocity = bodyVelocity

    return bodyVelocity
end

function Movement:GetFlightDirection(camera)
    if not camera then
        return Vector3.zero
    end

    local direction = Vector3.zero

    ------------------------------------------------------------
    -- 相機自己的 Forward / Right
    -- 不再把 Y 軸砍掉，因此可以真正上下飛
    ------------------------------------------------------------

    if self._keys.W then
        direction += camera.CFrame.LookVector
    end

    if self._keys.S then
        direction -= camera.CFrame.LookVector
    end

    if self._keys.D then
        direction += camera.CFrame.RightVector
    end

    if self._keys.A then
        direction -= camera.CFrame.RightVector
    end

    ------------------------------------------------------------
    -- 垂直移動
    ------------------------------------------------------------

    if self._keys.Space then
        direction += Vector3.yAxis
    end

    if self._keys.LeftControl or self._keys.RightControl then
        direction -= Vector3.yAxis
    end

    if direction.Magnitude > 0 then
        direction = direction.Unit
    end

    return direction
end

function Movement:StartFlight()
    if self.Flying then
        return
    end

    local root = getRoot()
    if not root then
        return
    end

    self.Flying = true

    pcall(function()
        if self.FlightMode == "LinearVelocity" then
            self:CreateLinearVelocity(root)
        else
            self:ClearFlightForce()
        end
    end)

    local humanoid = getHumanoid()
    if humanoid then
        pcall(function()
            humanoid.AutoRotate = false
        end)
    end
end

function Movement:StopFlight()
    if not self.Flying and not self.LinearVelocity and not self.BodyVelocity then
        return
    end

    self.Flying = false
    self:ClearFlightForce()

    local humanoid = getHumanoid()

    if humanoid then
        pcall(function()
            humanoid.AutoRotate = true
        end)
    end
end

function Movement:SetFlight(enabled)
    enabled = enabled == true

    if enabled then
        self:StartFlight()
    else
        self:StopFlight()
    end
end

function Movement:UpdateFlight()
    if not self.Flying then
        return
    end

    local root = getRoot()
    if not root then
        return
    end

    local humanoid = getHumanoid()
    local camera = Workspace.CurrentCamera

    if not camera then
        return
    end

    local direction = self:GetFlightDirection(camera)
    local velocity = direction * self.FlightSpeed

    ------------------------------------------------------------
    -- LinearVelocity 模式
    ------------------------------------------------------------

    if self.FlightMode == "LinearVelocity" then
        if not self.LinearVelocity
            or not self.LinearVelocity.Parent
            or self.LinearVelocity.Parent ~= root then

            self:CreateLinearVelocity(root)
        end

        pcall(function()
            self.LinearVelocity.VectorVelocity = velocity
        end)

    ------------------------------------------------------------
    -- CFrame 模式
    ------------------------------------------------------------

    else
        if direction.Magnitude > 0 then
            local newPosition = root.Position + velocity * (1 / 60)

            pcall(function()
                root.CFrame = CFrame.new(
                    newPosition,
                    newPosition + camera.CFrame.LookVector
                )
            end)
        end

        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    end

    if humanoid then
        pcall(function()
            humanoid.AutoRotate = false
        end)
    end
end

----------------------------------------------------------------
-- UI
----------------------------------------------------------------

function Movement:CreateUI()
    local tab = self.Tab
    if not tab then
        return
    end

    ------------------------------------------------------------
    -- 飛行
    ------------------------------------------------------------

    tab:CreateToggle({
        Name = "啟用飛行",
        CurrentValue = false,
        Flag = "Developer_Flight",
        Callback = function(value)
            self:SetFlight(value)
        end,
    })

    tab:CreateDropdown({
        Name = "飛行模式",
        Options = {
            "CFrame",
            "LinearVelocity",
        },
        CurrentOption = {
            self.FlightMode
        },
        MultipleOptions = false,
        Flag = "Developer_FlightMode",
        Callback = function(option)
            local selected

            if type(option) == "table" then
                selected = option[1]
            else
                selected = option
            end

            if selected == "CFrame" or selected == "LinearVelocity" then
                self.FlightMode = selected

                if self.Flying then
                    self:StopFlight()
                    task.wait()
                    self:StartFlight()
                end
            end
        end,
    })

    tab:CreateInput({
        Name = "飛行速度",
        CurrentValue = tostring(self.FlightSpeed),
        PlaceholderText = "輸入 1~1000",
        RemoveTextAfterFocusLost = false,
        Flag = "Developer_FlightSpeed",
        Callback = function(value)
            self.FlightSpeed = clampNumber(
                parseNumber(value, self.FlightSpeed),
                1,
                1000
            )
        end,
    })

    ------------------------------------------------------------
    -- 角色速度
    ------------------------------------------------------------

    tab:CreateInput({
        Name = "玩家速度",
        CurrentValue = tostring(self.Speed),
        PlaceholderText = "輸入 1~1000",
        RemoveTextAfterFocusLost = false,
        Flag = "Developer_WalkSpeed",
        Callback = function(value)
            self.Speed = clampNumber(
                parseNumber(value, self.Speed),
                1,
                1000
            )

            self:ApplyCharacterSettings()
        end,
    })

    tab:CreateInput({
        Name = "跳躍力",
        CurrentValue = tostring(self.JumpPower),
        PlaceholderText = "輸入 1~500",
        RemoveTextAfterFocusLost = false,
        Flag = "Developer_JumpPower",
        Callback = function(value)
            self.JumpPower = clampNumber(
                parseNumber(value, self.JumpPower),
                1,
                500
            )

            self:ApplyCharacterSettings()
        end,
    })

    tab:CreateInput({
        Name = "重力",
        CurrentValue = tostring(self.Gravity),
        PlaceholderText = "輸入 0~1000",
        RemoveTextAfterFocusLost = false,
        Flag = "Developer_Gravity",
        Callback = function(value)
            self.Gravity = clampNumber(
                parseNumber(value, self.Gravity),
                0,
                1000
            )

            self:ApplyCharacterSettings()
        end,
    })

    ------------------------------------------------------------
    -- Noclip
    ------------------------------------------------------------

    tab:CreateToggle({
        Name = "穿牆",
        CurrentValue = false,
        Flag = "Developer_Noclip",
        Callback = function(value)
            self:SetNoclip(value)
        end,
    })

    ------------------------------------------------------------
    -- 無限跳
    ------------------------------------------------------------

    tab:CreateToggle({
        Name = "無限跳",
        CurrentValue = false,
        Flag = "Developer_InfiniteJump",
        Callback = function(value)
            self:SetInfiniteJump(value)
        end,
    })

    ------------------------------------------------------------
    -- 重置
    ------------------------------------------------------------

    tab:CreateButton({
        Name = "重置移動設定",
        Callback = function()
            self.Speed = 16
            self.JumpPower = 50
            self.Gravity = self.OriginalGravity or 196.2
            self.FlightSpeed = 70

            self:ApplyCharacterSettings()
        end,
    })
end

----------------------------------------------------------------
-- Init
----------------------------------------------------------------

function Movement:Init(context)
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

    if self.OriginalGravity == nil then
        self.OriginalGravity = Workspace.Gravity
        self.Gravity = Workspace.Gravity
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
        end
    end))

    ------------------------------------------------------------
    -- 無限跳
    ------------------------------------------------------------

    table.insert(self.Connections, UserInputService.JumpRequest:Connect(function()
        if not self.InfiniteJump then
            return
        end

        local humanoid = getHumanoid()
        if humanoid then
            pcall(function()
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end)
        end
    end))

    ------------------------------------------------------------
    -- 角色重生
    ------------------------------------------------------------

    local player = self.Player

    if player then
        table.insert(self.CharacterConnections, player.CharacterAdded:Connect(function(character)
            self._character = character

            self._root = nil
            self._humanoid = nil

            ----------------------------------------------------
            -- 舊角色的飛行物件清理掉
            ----------------------------------------------------

            self:ClearFlightForce()

            task.wait(0.2)

            if self._destroyed then
                return
            end

            self:ApplyCharacterSettings()

            if self.Noclip then
                task.wait(0.1)
                self:SetNoclip(true)
            end

            if self.Flying then
                self:StartFlight()
            end
        end))
    end

    ------------------------------------------------------------
    -- RenderStepped
    ------------------------------------------------------------

    table.insert(self.Connections, RunService.RenderStepped:Connect(function()
        if self._destroyed then
            return
        end

        self:UpdateFlight()
        self:UpdateNoclip()
    end))

    self:ApplyCharacterSettings()
    self:CreateUI()
end

----------------------------------------------------------------
-- Cleanup
----------------------------------------------------------------

function Movement:Cleanup()
    if self._destroyed then
        return
    end

    self._destroyed = true

    ------------------------------------------------------------
    -- 關閉飛行
    ------------------------------------------------------------

    self.Flying = false
    self:ClearFlightForce()

    ------------------------------------------------------------
    -- 關閉 Noclip 並還原碰撞
    ------------------------------------------------------------

    self.Noclip = false

    for object, originalValue in pairs(self.OriginalCanCollide) do
        if object and object.Parent then
            pcall(function()
                object.CanCollide = originalValue
            end)
        end
    end

    self.OriginalCanCollide = {}

    ------------------------------------------------------------
    -- 還原角色
    ------------------------------------------------------------

    local humanoid = getHumanoid()

    if humanoid then
        pcall(function()
            humanoid.AutoRotate = true
            humanoid.WalkSpeed = 16

            if humanoid.UseJumpPower then
                humanoid.JumpPower = 50
            end
        end)
    end

    ------------------------------------------------------------
    -- 還原重力
    ------------------------------------------------------------

    if self.OriginalGravity ~= nil then
        pcall(function()
            Workspace.Gravity = self.OriginalGravity
        end)
    end

    ------------------------------------------------------------
    -- 清除輸入狀態
    ------------------------------------------------------------

    self._keys = {}

    ------------------------------------------------------------
    -- 斷開連線
    ------------------------------------------------------------

    for _, connection in ipairs(self.Connections) do
        disconnect(connection)
    end

    for _, connection in ipairs(self.CharacterConnections) do
        disconnect(connection)
    end

    self.Connections = {}
    self.CharacterConnections = {}
end

return Movement
