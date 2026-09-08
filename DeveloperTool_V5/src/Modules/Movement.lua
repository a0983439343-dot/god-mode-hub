-- DeveloperTool V5 | Movement
local Movement = {
    Connections = {},
    FlightConnection = nil,
    NoclipConnection = nil,
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
    FlightAttachment = nil,
    OriginalGravity = nil,
    OriginalCharacterSettings = {},
    OriginalCanCollide = {},
    Shared = nil,
    Alive = false
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local Keys = {}

local function addConnection(self, connection)
    if connection then
        table.insert(self.Connections, connection)
    end
    return connection
end

local function disconnect(connection)
    if connection then
        pcall(function()
            connection:Disconnect()
        end)
    end
end

local function getCharacter()
    return Player and Player.Character
end

local function getRoot()
    local character = getCharacter()
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local character = getCharacter()
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function backupHumanoid(self, humanoid)
    if not humanoid or self.OriginalCharacterSettings[humanoid] then
        return
    end

    self.OriginalCharacterSettings[humanoid] = {
        WalkSpeed = humanoid.WalkSpeed,
        UseJumpPower = humanoid.UseJumpPower,
        JumpPower = humanoid.JumpPower,
        JumpHeight = humanoid.JumpHeight,
        AutoRotate = humanoid.AutoRotate
    }
end

local function restoreHumanoid(self, humanoid)
    local original = humanoid and self.OriginalCharacterSettings[humanoid]
    if not humanoid or not original then
        return
    end

    pcall(function()
        humanoid.WalkSpeed = original.WalkSpeed
        humanoid.UseJumpPower = original.UseJumpPower
        humanoid.JumpPower = original.JumpPower
        humanoid.JumpHeight = original.JumpHeight
        humanoid.AutoRotate = original.AutoRotate
    end)
end

local function clearFlightForce(self)
    if self.BodyVelocity then
        pcall(function()
            self.BodyVelocity:Destroy()
        end)
        self.BodyVelocity = nil
    end

    if self.FlightAttachment then
        pcall(function()
            self.FlightAttachment:Destroy()
        end)
        self.FlightAttachment = nil
    end
end

local function stopFlight(self, notifyShared)
    self.Flying = false
    disconnect(self.FlightConnection)
    self.FlightConnection = nil
    clearFlightForce(self)

    local humanoid = getHumanoid()
    if humanoid then
        backupHumanoid(self, humanoid)
        humanoid.AutoRotate = self.OriginalCharacterSettings[humanoid].AutoRotate
    end

    if notifyShared and self.Shared then
        self.Shared.FlightActive = false
    end
end

local function movementVector(camera)
    local forward = 0
    local side = 0
    local vertical = 0

    if Keys.W then forward += 1 end
    if Keys.S then forward -= 1 end
    if Keys.D then side += 1 end
    if Keys.A then side -= 1 end
    if Keys.Space then vertical += 1 end
    if Keys.LeftControl or Keys.RightControl then vertical -= 1 end

    local look = camera.CFrame.LookVector
    local right = camera.CFrame.RightVector

    local vector = look * forward + right * side + Vector3.yAxis * vertical
    if vector.Magnitude > 1 then
        vector = vector.Unit
    end
    return vector
end

local function updateFlight(self, dt)
    if not self.Flying or (self.Shared and self.Shared.FreeCamActive) then
        return
    end

    local root = getRoot()
    local humanoid = getHumanoid()
    local camera = Workspace.CurrentCamera

    if not root or not humanoid or not camera or humanoid.Health <= 0 then
        stopFlight(self, true)
        return
    end

    local vector = movementVector(camera)
    local velocity = vector * self.FlightSpeed

    if self.FlightMode == "CFrame" then
        local target = root.Position + velocity * dt
        local facing = camera.CFrame.LookVector
        local look = Vector3.new(facing.X, 0, facing.Z)

        if look.Magnitude < 0.01 then
            look = Vector3.new(0, 0, -1)
        else
            look = look.Unit
        end

        root.CFrame = CFrame.lookAt(target, target + look)
        root.AssemblyLinearVelocity = Vector3.zero
    elseif self.BodyVelocity then
        self.BodyVelocity.VectorVelocity = velocity

        local facing = camera.CFrame.LookVector
        local look = Vector3.new(facing.X, 0, facing.Z)
        if look.Magnitude > 0.01 then
            root.CFrame = CFrame.lookAt(root.Position, root.Position + look.Unit)
        end
    end
end

local function startFlight(self)
    if self.Shared and self.Shared.FreeCamActive and self.Shared.StopFreeCam then
        pcall(self.Shared.StopFreeCam)
    end

    local humanoid = getHumanoid()
    if not humanoid or humanoid.Health <= 0 then
        self.Flying = false
        return
    end

    self.Flying = true
    self.Shared.FlightActive = true

    disconnect(self.FlightConnection)
    self.FlightConnection = nil
    clearFlightForce(self)

    backupHumanoid(self, humanoid)
    humanoid.AutoRotate = false

    if self.FlightMode == "LinearVelocity" then
        local root = getRoot()
        if not root then
            self.Flying = false
            self.Shared.FlightActive = false
            return
        end

        local attachment = Instance.new("Attachment")
        attachment.Name = "DeveloperFlightAttachment"
        attachment.Parent = root

        local linear = Instance.new("LinearVelocity")
        linear.Name = "DeveloperFlightLinearVelocity"
        linear.Attachment0 = attachment
        linear.RelativeTo = Enum.ActuatorRelativeTo.World
        linear.MaxForce = math.huge
        linear.VectorVelocity = Vector3.zero
        linear.Parent = root

        self.FlightAttachment = attachment
        self.BodyVelocity = linear
    end

    self.FlightConnection = RunService.RenderStepped:Connect(function(dt)
        updateFlight(self, dt)
    end)
end

local function setFlight(self, enabled)
    if enabled then
        startFlight(self)
    else
        stopFlight(self, true)
    end
end

local function applyCharacterSettings(self)
    local humanoid = getHumanoid()
    if not humanoid or humanoid.Health <= 0 then
        return
    end

    backupHumanoid(self, humanoid)

    humanoid.WalkSpeed = self.Speed
    if humanoid.UseJumpPower then
        humanoid.JumpPower = self.JumpPower
    else
        humanoid.JumpHeight = math.clamp(self.JumpPower / 7, 0, 100)
    end

    Workspace.Gravity = self.Gravity
end

local function startNoclip(self)
    disconnect(self.NoclipConnection)
    self.NoclipConnection = nil

    self.NoclipConnection = RunService.Stepped:Connect(function()
        if not self.Noclip then
            return
        end

        local character = getCharacter()
        if not character then
            return
        end

        for _, item in ipairs(character:GetDescendants()) do
            if item:IsA("BasePart") then
                if self.OriginalCanCollide[item] == nil then
                    self.OriginalCanCollide[item] = item.CanCollide
                end
                item.CanCollide = false
            end
        end
    end)
end

local function restoreNoclip(self)
    for part, original in pairs(self.OriginalCanCollide) do
        if part and part.Parent then
            pcall(function()
                part.CanCollide = original
            end)
        end
    end
    table.clear(self.OriginalCanCollide)
end

function Movement:Init(context)
    Player = context.Player
    self.Shared = context.Shared or {}
    self.Alive = true
    self.OriginalGravity = Workspace.Gravity
    self.Gravity = Workspace.Gravity

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

    addConnection(self, UserInputService.JumpRequest:Connect(function()
        if not self.InfiniteJump then
            return
        end

        local humanoid = getHumanoid()
        if humanoid and humanoid.Health > 0 then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end))

    addConnection(self, Player.CharacterAdded:Connect(function(character)
        task.defer(function()
            if not self.Alive or character ~= Player.Character then
                return
            end

            local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
            if humanoid then
                backupHumanoid(self, humanoid)
                applyCharacterSettings(self)
            end

            if self.Noclip then
                restoreNoclip(self)
                startNoclip(self)
            end

            if self.Flying then
                setFlight(self, true)
            end
        end)
    end))

    local tab = context.Tab
    tab:CreateSection("飛行")
    tab:CreateDropdown({
        Name = "飛行模式",
        Options = {"座標模式", "線性速度"},
        CurrentOption = {"座標模式"},
        MultipleOptions = false,
        Flag = "DeveloperV5FlightMode",
        Callback = function(option)
            local selected = option and option[1]
            self.FlightMode = selected == "線性速度" and "LinearVelocity" or "CFrame"
            if self.Flying then
                setFlight(self, false)
                setFlight(self, true)
            end
        end
    })

    tab:CreateInput({
        Name = "飛行速度",
        CurrentValue = tostring(self.FlightSpeed),
        PlaceholderText = "輸入飛行速度（10～300）",
        RemoveTextAfterFocusLost = false,
        Flag = "DeveloperV5FlightSpeed",
        Callback = function(value)
            local number = tonumber(value)
            if number then
                self.FlightSpeed = math.clamp(number, 10, 300)
            end
        end
    })

    tab:CreateToggle({
        Name = "飛行",
        CurrentValue = false,
        Flag = "DeveloperV5Fly",
        Callback = function(value)
            setFlight(self, value)
        end
    })

    tab:CreateSection("角色")
    tab:CreateToggle({
        Name = "穿牆",
        CurrentValue = false,
        Flag = "DeveloperV5Noclip",
        Callback = function(value)
            self.Noclip = value
            if value then
                startNoclip(self)
            else
                disconnect(self.NoclipConnection)
                self.NoclipConnection = nil
                restoreNoclip(self)
            end
        end
    })

    tab:CreateToggle({
        Name = "無限跳躍",
        CurrentValue = false,
        Flag = "DeveloperV5InfiniteJump",
        Callback = function(value)
            self.InfiniteJump = value
        end
    })

    tab:CreateInput({
        Name = "移動速度",
        CurrentValue = tostring(self.Speed),
        PlaceholderText = "輸入移動速度（0～250）",
        RemoveTextAfterFocusLost = false,
        Flag = "DeveloperV5WalkSpeed",
        Callback = function(value)
            local number = tonumber(value)
            if number then
                self.Speed = math.clamp(number, 0, 250)
                applyCharacterSettings(self)
            end
        end
    })

    tab:CreateInput({
        Name = "跳躍力",
        CurrentValue = tostring(self.JumpPower),
        PlaceholderText = "輸入跳躍力（0～250）",
        RemoveTextAfterFocusLost = false,
        Flag = "DeveloperV5JumpPower",
        Callback = function(value)
            local number = tonumber(value)
            if number then
                self.JumpPower = math.clamp(number, 0, 250)
                applyCharacterSettings(self)
            end
        end
    })

    tab:CreateInput({
        Name = "重力",
        CurrentValue = tostring(self.Gravity),
        PlaceholderText = "輸入重力（0～400）",
        RemoveTextAfterFocusLost = false,
        Flag = "DeveloperV5Gravity",
        Callback = function(value)
            local number = tonumber(value)
            if number then
                self.Gravity = math.clamp(number, 0, 400)
                Workspace.Gravity = self.Gravity
            end
        end
    })

    tab:CreateButton({
        Name = "重設移動設定",
        Callback = function()
            self.Speed = 16
            self.JumpPower = 50
            self.Gravity = self.OriginalGravity or 196.2
            applyCharacterSettings(self)
        end
    })

    self.Shared.StopFlight = function()
        stopFlight(self, true)
    end

    if self.Shared.FreeCamActive then
        self.Shared.StopFreeCam()
    end

    local humanoid = getHumanoid()
    if humanoid then
        backupHumanoid(self, humanoid)
        applyCharacterSettings(self)
    end
end

function Movement:Cleanup()
    if not self.Alive then
        return
    end

    self.Alive = false
    stopFlight(self, true)

    disconnect(self.NoclipConnection)
    self.NoclipConnection = nil
    self.Noclip = false
    restoreNoclip(self)

    local humanoid = getHumanoid()
    if humanoid then
        restoreHumanoid(self, humanoid)
    end

    if self.OriginalGravity ~= nil then
        Workspace.Gravity = self.OriginalGravity
    end

    for _, connection in ipairs(self.CharacterConnections) do
        disconnect(connection)
    end
    table.clear(self.CharacterConnections)

    for i = #self.Connections, 1, -1 do
        disconnect(self.Connections[i])
        self.Connections[i] = nil
    end

    for humanoidObject in pairs(self.OriginalCharacterSettings) do
        self.OriginalCharacterSettings[humanoidObject] = nil
    end

    table.clear(Keys)

    if self.Shared then
        self.Shared.FlightActive = false
        if self.Shared.StopFlight == self then
            self.Shared.StopFlight = nil
        end
        self.Shared.StopFlight = nil
    end
end

return Movement
