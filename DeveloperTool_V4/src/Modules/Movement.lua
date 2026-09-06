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
    BodyVelocity = nil
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local Keys = {}
local Character

local function addConnection(self, connection)
    table.insert(self.Connections, connection)
    return connection
end

local function getCharacter()
    Character = Player.Character or Player.CharacterAdded:Wait()
    return Character
end

local function getRoot()
    local character = getCharacter()
    return character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local character = getCharacter()
    return character:FindFirstChildOfClass("Humanoid")
end

local function clearFlightForce()
    if Movement.BodyVelocity then
        pcall(function()
            Movement.BodyVelocity:Destroy()
        end)
        Movement.BodyVelocity = nil
    end
end

local function stopFlight()
    Movement.Flying = false
    clearFlightForce()
    local humanoid = getHumanoid()
    if humanoid then
        humanoid.AutoRotate = true
    end
end

local function startCFrameFlight()
    Movement.Flying = true
    clearFlightForce()
    local humanoid = getHumanoid()
    if humanoid then
        humanoid.AutoRotate = false
    end
end

local function startLinearVelocityFlight()
    local root = getRoot()
    if not root then
        return
    end
    clearFlightForce()
    local attachment = root:FindFirstChild("DeveloperFlightAttachment") or Instance.new("Attachment")
    attachment.Name = "DeveloperFlightAttachment"
    attachment.Parent = root
    local linear = Instance.new("LinearVelocity")
    linear.Name = "DeveloperFlightLinearVelocity"
    linear.Attachment0 = attachment
    linear.RelativeTo = Enum.ActuatorRelativeTo.World
    linear.MaxForce = math.huge
    linear.VectorVelocity = Vector3.zero
    linear.Parent = root
    Movement.BodyVelocity = linear
    Movement.Flying = true
    local humanoid = getHumanoid()
    if humanoid then
        humanoid.AutoRotate = false
    end
end

local function setFlight(enabled)
    if enabled then
        if Movement.FlightMode == "CFrame" then
            startCFrameFlight()
        else
            startLinearVelocityFlight()
        end
    else
        stopFlight()
    end
end

local function movementVector(camera)
    local forward = 0
    local side = 0
    local vertical = 0

    if Keys.W then
        forward += 1
    end
    if Keys.S then
        forward -= 1
    end
    if Keys.D then
        side += 1
    end
    if Keys.A then
        side -= 1
    end
    if Keys.Space then
        vertical += 1
    end
    if Keys.LeftControl then
        vertical -= 1
    end

    local flatForward = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
    local flatRight = Vector3.new(camera.CFrame.RightVector.X, 0, camera.CFrame.RightVector.Z)
    if flatForward.Magnitude > 0 then
        flatForward = flatForward.Unit
    end
    if flatRight.Magnitude > 0 then
        flatRight = flatRight.Unit
    end

    local vector = flatForward * forward + flatRight * side + Vector3.yAxis * vertical
    if vector.Magnitude > 1 then
        vector = vector.Unit
    end
    return vector
end

local function updateFlight(dt)
    if not Movement.Flying then
        return
    end

    local root = getRoot()
    local humanoid = getHumanoid()
    local camera = Workspace.CurrentCamera

    if not root or not humanoid or not camera then
        return
    end

    local vector = movementVector(camera) * Movement.FlightSpeed

    if Movement.FlightMode == "CFrame" then
        local facing = camera.CFrame.LookVector
        local target = root.Position + vector * dt
        local look = Vector3.new(facing.X, 0, facing.Z)
        if look.Magnitude < 0.01 then
            look = Vector3.new(0, 0, -1)
        else
            look = look.Unit
        end
        root.CFrame = CFrame.lookAt(target, target + look)
        root.AssemblyLinearVelocity = Vector3.zero
    elseif Movement.BodyVelocity then
        Movement.BodyVelocity.VectorVelocity = vector
        local look = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
        if look.Magnitude > 0.01 then
            root.CFrame = CFrame.lookAt(root.Position, root.Position + look.Unit)
        end
    end
end

local function applyCharacterSettings()
    local humanoid = getHumanoid()
    if humanoid then
        humanoid.WalkSpeed = Movement.Speed
        humanoid.UseJumpPower = true
        humanoid.JumpPower = Movement.JumpPower
    end
    Workspace.Gravity = Movement.Gravity
end

function Movement:Init(context)
    Player = context.Player

    local playerGui = context.PlayerGui
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

    addConnection(self, RunService.RenderStepped:Connect(updateFlight))

    addConnection(self, Player.CharacterAdded:Connect(function()
        task.wait(0.5)
        applyCharacterSettings()
        if self.Flying then
            setFlight(true)
        end
    end))

    getCharacter()
    applyCharacterSettings()

    tab:CreateSection("Flight")
    tab:CreateDropdown({
        Name = "Flight Mode",
        Options = {"CFrame", "LinearVelocity"},
        CurrentOption = {"CFrame"},
        MultipleOptions = false,
        Flag = "DeveloperFlightMode",
        Callback = function(option)
            self.FlightMode = option[1]
            if self.Flying then
                setFlight(false)
                setFlight(true)
            end
        end
    })

    tab:CreateSlider({
        Name = "Flight Speed",
        Range = {10, 300},
        Increment = 5,
        Suffix = " studs/s",
        CurrentValue = self.FlightSpeed,
        Flag = "DeveloperFlightSpeed",
        Callback = function(value)
            self.FlightSpeed = value
        end
    })

    tab:CreateToggle({
        Name = "Fly",
        CurrentValue = false,
        Flag = "DeveloperFly",
        Callback = function(value)
            setFlight(value)
        end
    })

    tab:CreateSection("Character")
    tab:CreateToggle({
        Name = "Noclip",
        CurrentValue = false,
        Flag = "DeveloperNoclip",
        Callback = function(value)
            self.Noclip = value
        end
    })

    tab:CreateToggle({
        Name = "Infinite Jump",
        CurrentValue = false,
        Flag = "DeveloperInfiniteJump",
        Callback = function(value)
            self.InfiniteJump = value
        end
    })

    tab:CreateSlider({
        Name = "Walk Speed",
        Range = {0, 250},
        Increment = 1,
        Suffix = " studs/s",
        CurrentValue = self.Speed,
        Flag = "DeveloperWalkSpeed",
        Callback = function(value)
            self.Speed = value
            applyCharacterSettings()
        end
    })

    tab:CreateSlider({
        Name = "Jump Power",
        Range = {0, 250},
        Increment = 1,
        Suffix = " power",
        CurrentValue = self.JumpPower,
        Flag = "DeveloperJumpPower",
        Callback = function(value)
            self.JumpPower = value
            applyCharacterSettings()
        end
    })

    tab:CreateSlider({
        Name = "Gravity",
        Range = {0, 400},
        Increment = 1,
        Suffix = " gravity",
        CurrentValue = self.Gravity,
        Flag = "DeveloperGravity",
        Callback = function(value)
            self.Gravity = value
            Workspace.Gravity = value
        end
    })

    addConnection(self, UserInputService.JumpRequest:Connect(function()
        if self.InfiniteJump then
            local humanoid = getHumanoid()
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end))

    addConnection(self, RunService.Stepped:Connect(function()
        if not self.Noclip then
            return
        end
        local character = Player.Character
        if not character then
            return
        end
        for i, item in ipairs(character:GetDescendants()) do
            if i % 100 == 0 then
                task.wait()
            end
            if item:IsA("BasePart") then
                item.CanCollide = false
            end
        end
    end))

    tab:CreateButton({
        Name = "Reset Movement Settings",
        Callback = function()
            self.Speed = 16
            self.JumpPower = 50
            self.Gravity = 196.2
            applyCharacterSettings()
        end
    })
end

function Movement:Cleanup()
    stopFlight()
    for i = #self.Connections, 1, -1 do
        pcall(function()
            self.Connections[i]:Disconnect()
        end)
        self.Connections[i] = nil
    end
    clearFlightForce()
    if Workspace then
        Workspace.Gravity = 196.2
    end
end

return Movement
