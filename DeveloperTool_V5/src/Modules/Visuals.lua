local Visuals = {
    Connections = {},
    Fullbright = false,
    RemoveAtmosphere = false,
    RemovePostEffects = false,
    FreeCam = false,
    FOV = 70,
    OriginalLighting = nil,
    OriginalFOV = nil,
    OriginalCameraMinZoomDistance = nil,
    OriginalCameraMaxZoomDistance = nil,
    OriginalCameraMode = nil,
    ZoomUnlock = false,
    ZoomMaxDistance = 10000,
    ZoomDistance = 12,
    ZoomStep = 100,
    OriginalZoomDistance = nil,
    ZoomConnection = nil,
    ZoomPropertyConnection1 = nil,
    ZoomPropertyConnection2 = nil,
    ZoomRenderConnection = nil,
    FreeCamCharacter = nil,
    FreeCamCharacterCFrame = nil,
    FreeCamHumanoidBackup = nil,
    AtmosphereBackup = {},
    PostEffectsBackup = {},
    FreeCamBackup = nil,
    FreeCamPosition = nil,
    FreeCamYaw = 0,
    FreeCamPitch = 0,
    FreeCamInputConnection = nil,
    FreeCamInputBeganConnection = nil,
    FreeCamInputEndedConnection = nil,
    FreeCamRenderConnection = nil,
    AtmosphereConnection = nil,
    PostEffectConnection = nil,
    Shared = nil,
    Alive = false,
    FreeCamRotating = false,
    ObjectRadar = false,
    ObjectRadarMode = "全部物件",
    ObjectRadarMax = 80,
    ObjectRadarDistance = 250,
    ObjectRadarRefresh = 1.5,
    ObjectRadarConnection = nil,
    ObjectRadarFolder = nil,
    ObjectRadarCache = {},
    LightingStudio = false,
    LightingStudioBrightness = 3,
    LightingStudioExposure = 0,
    LightingStudioClockTime = 14,
    LightingStudioShadow = true,
    LightingStudioBloom = false,
    LightingStudioColor = false,
    LightingStudioSunRays = false,
    LightingStudioDepth = false,
    LightingStudioBlur = false,
    LightingStudioBloomEffect = nil,
    LightingStudioColorEffect = nil,
    LightingStudioSunEffect = nil,
    LightingStudioDepthEffect = nil,
    LightingStudioBlurEffect = nil,
    LightingStudioBackup = nil,
    OriginalMouseBehavior = Enum.MouseBehavior.Default
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
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

local function getCharacter()
    return Player.Character
end

local function getHumanoid()
    local character = getCharacter()

    if not character then
        return nil
    end

    return character:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local character = getCharacter()

    if not character then
        return nil
    end

    return character:FindFirstChild("HumanoidRootPart")
end

local function isMouseOverGui()
    local mousePosition =
        UserInputService:GetMouseLocation()

    local ok, objects =
        pcall(function()
            return GuiService:GetGuiObjectsAtPosition(
                mousePosition.X,
                mousePosition.Y
            )
        end)

    if not ok or not objects then
        return false
    end

    for _, object in ipairs(objects) do
        if object
            and object:IsA("GuiObject")
            and object.Visible
        then
            return true
        end
    end

    return false
end

local function backupFOV(self)
    if self.OriginalFOV ~= nil then
        return
    end

    local camera = getCamera()

    self.OriginalFOV =
        camera and camera.FieldOfView or 70

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
        ExposureCompensation =
            Lighting.ExposureCompensation,
        Ambient = Lighting.Ambient,
        OutdoorAmbient =
            Lighting.OutdoorAmbient
    }
end

local function setFullbright(self, enabled)
    if enabled then
        backupLighting(self)

        self.Fullbright = true

        pcall(function()
            Lighting.Brightness = 3
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.ExposureCompensation = 0
        end)

        return
    end

    self.Fullbright = false

    if self.OriginalLighting then
        pcall(function()
            Lighting.Brightness =
                self.OriginalLighting.Brightness

            Lighting.ClockTime =
                self.OriginalLighting.ClockTime

            Lighting.FogEnd =
                self.OriginalLighting.FogEnd

            Lighting.GlobalShadows =
                self.OriginalLighting.GlobalShadows

            Lighting.ExposureCompensation =
                self.OriginalLighting.ExposureCompensation

            Lighting.Ambient =
                self.OriginalLighting.Ambient

            Lighting.OutdoorAmbient =
                self.OriginalLighting.OutdoorAmbient
        end)
    end
end

local function disableAtmosphereItem(self, item)
    if not item or not item:IsA("Atmosphere") then
        return
    end

    if self.AtmosphereBackup[item] == nil then
        self.AtmosphereBackup[item] =
            item.Parent
    end

    pcall(function()
        item.Parent = nil
    end)
end

local function restoreAtmosphere(self)
    for item, originalParent
        in pairs(self.AtmosphereBackup)
    do
        if item and originalParent then
            pcall(function()
                item.Parent = originalParent
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

    task.spawn(function()
        local descendants =
            Lighting:GetDescendants()

        for i = 1, #descendants do
            if not self.Alive
                or not self.RemoveAtmosphere
            then
                return
            end

            disableAtmosphereItem(
                self,
                descendants[i]
            )

            if i % 100 == 0 then
                task.wait()
            end
        end
    end)

    self.AtmosphereConnection =
        Lighting.DescendantAdded:Connect(
            function(item)
                if self.Alive
                    and self.RemoveAtmosphere
                then
                    task.defer(function()
                        if self.Alive
                            and self.RemoveAtmosphere
                        then
                            disableAtmosphereItem(
                                self,
                                item
                            )
                        end
                    end)
                end
            end
        )
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
        self.PostEffectsBackup[item] =
            item.Enabled
    end

    pcall(function()
        item.Enabled = false
    end)
end

local function restorePostEffects(self)
    for item, original
        in pairs(self.PostEffectsBackup)
    do
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

    task.spawn(function()
        local descendants =
            Lighting:GetDescendants()

        for i = 1, #descendants do
            if not self.Alive
                or not self.RemovePostEffects
            then
                return
            end

            disablePostEffectItem(
                self,
                descendants[i]
            )

            if i % 100 == 0 then
                task.wait()
            end
        end
    end)

    self.PostEffectConnection =
        Lighting.DescendantAdded:Connect(
            function(item)
                if self.Alive
                    and self.RemovePostEffects
                then
                    task.defer(function()
                        if self.Alive
                            and self.RemovePostEffects
                        then
                            disablePostEffectItem(
                                self,
                                item
                            )
                        end
                    end)
                end
            end
        )
end

local function backupZoom(self)
    if self.OriginalCameraMinZoomDistance ~= nil then
        return
    end

    self.OriginalCameraMinZoomDistance =
        Player.CameraMinZoomDistance

    self.OriginalCameraMaxZoomDistance =
        Player.CameraMaxZoomDistance

    self.OriginalCameraMode =
        Player.CameraMode

    local camera = getCamera()
    local root = getRoot()

    if camera and root then
        local focusPosition =
            root.Position + Vector3.new(0, 2, 0)

        self.ZoomDistance =
            math.clamp(
                (
                    camera.CFrame.Position
                    - focusPosition
                ).Magnitude,
                0.5,
                self.ZoomMaxDistance
            )
    end

    self.OriginalZoomDistance =
        self.ZoomDistance
end

local function stopZoomWatcher(self)
    disconnect(self.ZoomConnection)
    disconnect(self.ZoomPropertyConnection1)
    disconnect(self.ZoomPropertyConnection2)

    if self.ZoomRenderConnection then
        pcall(function()
            RunService:UnbindFromRenderStep(
                "DeveloperV5_CustomZoom"
            )
        end)
    end

    self.ZoomConnection = nil
    self.ZoomPropertyConnection1 = nil
    self.ZoomPropertyConnection2 = nil
    self.ZoomRenderConnection = nil
end

local function enforceZoomLimit(self)
    if not self.Alive
        or not self.ZoomUnlock
    then
        return
    end

    pcall(function()
        if Player.CameraMinZoomDistance ~= 0.5 then
            Player.CameraMinZoomDistance = 0.5
        end

        if Player.CameraMaxZoomDistance
            ~= self.ZoomMaxDistance
        then
            Player.CameraMaxZoomDistance =
                self.ZoomMaxDistance
        end

        if Player.CameraMode
            ~= Enum.CameraMode.Classic
        then
            Player.CameraMode =
                Enum.CameraMode.Classic
        end
    end)
end

local function customZoomRender(self)
    if not self.Alive
        or not self.ZoomUnlock
        or self.FreeCam
    then
        return
    end

    local camera = getCamera()
    local root = getRoot()

    if not camera or not root then
        return
    end

    if camera.CameraType
        == Enum.CameraType.Scriptable
    then
        return
    end

    local focusPosition =
        root.Position + Vector3.new(0, 2, 0)

    local direction =
        camera.CFrame.LookVector

    if direction.Magnitude <= 0 then
        return
    end

    local targetPosition =
        focusPosition
        - direction.Unit * self.ZoomDistance

    local targetCFrame =
        CFrame.lookAt(
            targetPosition,
            focusPosition
        )

    pcall(function()
        camera.CFrame = targetCFrame
    end)
end

local function applyZoomStep(self, direction)
    if not self.Alive
        or not self.ZoomUnlock
        or self.FreeCam
    then
        return
    end

    if isMouseOverGui() then
        return
    end

    local camera = getCamera()
    local root = getRoot()

    if not camera or not root then
        return
    end

    local focusPosition =
        root.Position + Vector3.new(0, 2, 0)

    local currentDistance =
        (
            camera.CFrame.Position
            - focusPosition
        ).Magnitude

    if currentDistance > 0.5
        and currentDistance
            < self.ZoomMaxDistance + 1
    then
        self.ZoomDistance =
            currentDistance
    end

    self.ZoomDistance =
        math.clamp(
            self.ZoomDistance
                + direction * self.ZoomStep,
            0.5,
            self.ZoomMaxDistance
        )
end

local function setZoomUnlock(self, enabled)
    backupZoom(self)
    stopZoomWatcher(self)

    self.ZoomUnlock =
        enabled == true

    if not self.ZoomUnlock then
        pcall(function()
            Player.CameraMinZoomDistance =
                self.OriginalCameraMinZoomDistance

            Player.CameraMaxZoomDistance =
                self.OriginalCameraMaxZoomDistance

            if self.OriginalCameraMode then
                Player.CameraMode =
                    self.OriginalCameraMode
            end
        end)

        return
    end

    local camera = getCamera()
    local root = getRoot()

    if camera and root then
        local focusPosition =
            root.Position + Vector3.new(0, 2, 0)

        self.ZoomDistance =
            math.clamp(
                (
                    camera.CFrame.Position
                    - focusPosition
                ).Magnitude,
                0.5,
                self.ZoomMaxDistance
            )
    end

    enforceZoomLimit(self)

    self.ZoomPropertyConnection1 =
        Player:GetPropertyChangedSignal(
            "CameraMinZoomDistance"
        ):Connect(function()
            if self.Alive
                and self.ZoomUnlock
            then
                pcall(function()
                    if Player.CameraMinZoomDistance
                        ~= 0.5
                    then
                        Player.CameraMinZoomDistance = 0.5
                    end
                end)
            end
        end)

    self.ZoomPropertyConnection2 =
        Player:GetPropertyChangedSignal(
            "CameraMaxZoomDistance"
        ):Connect(function()
            if self.Alive
                and self.ZoomUnlock
            then
                pcall(function()
                    if Player.CameraMaxZoomDistance
                        ~= self.ZoomMaxDistance
                    then
                        Player.CameraMaxZoomDistance =
                            self.ZoomMaxDistance
                    end
                end)
            end
        end)

    self.ZoomConnection =
        UserInputService.InputChanged:Connect(
            function(input)
                if not self.Alive
                    or not self.ZoomUnlock
                    or self.FreeCam
                then
                    return
                end

                if input.UserInputType
                    ~= Enum.UserInputType.MouseWheel
                then
                    return
                end

                if isMouseOverGui() then
                    return
                end

                local wheel =
                    input.Position.Z

                if wheel > 0 then
                    applyZoomStep(
                        self,
                        -1
                    )
                elseif wheel < 0 then
                    applyZoomStep(
                        self,
                        1
                    )
                end
            end
        )

    pcall(function()
        RunService:UnbindFromRenderStep(
            "DeveloperV5_CustomZoom"
        )
    end)

    RunService:BindToRenderStep(
        "DeveloperV5_CustomZoom",
        Enum.RenderPriority.Camera.Value + 1,
        function()
            customZoomRender(self)
        end
    )

    self.ZoomRenderConnection = true
end

local function stopFreeCamConnections(self)
    disconnect(
        self.FreeCamInputConnection
    )

    disconnect(
        self.FreeCamInputBeganConnection
    )

    disconnect(
        self.FreeCamInputEndedConnection
    )

    disconnect(
        self.FreeCamRenderConnection
    )

    self.FreeCamInputConnection = nil
    self.FreeCamInputBeganConnection = nil
    self.FreeCamInputEndedConnection = nil
    self.FreeCamRenderConnection = nil
end

local function rotationCFrame(self)
    return CFrame.fromOrientation(
        self.FreeCamPitch,
        self.FreeCamYaw,
        0
    )
end

local function restoreFreeCamCharacter(self)
    local backup =
        self.FreeCamHumanoidBackup

    local humanoid =
        backup and backup.Humanoid

    if humanoid
        and humanoid.Parent
        and backup
    then
        pcall(function()
            humanoid.WalkSpeed =
                backup.WalkSpeed

            humanoid.JumpPower =
                backup.JumpPower

            humanoid.JumpHeight =
                backup.JumpHeight

            humanoid.UseJumpPower =
                backup.UseJumpPower

            humanoid.AutoRotate =
                backup.AutoRotate
        end)
    end

    self.FreeCamHumanoidBackup = nil
    self.FreeCamCharacter = nil
    self.FreeCamCharacterCFrame = nil
end

local function setMouseNormal()
    pcall(function()
        UserInputService.MouseBehavior =
            Enum.MouseBehavior.Default

        UserInputService.MouseIconEnabled =
            true
    end)
end

local function setMouseRotate()
    pcall(function()
        UserInputService.MouseBehavior =
            Enum.MouseBehavior.LockCenter

        UserInputService.MouseIconEnabled =
            false
    end)
end

local function stopFreeCam(self, notifyShared)
    self.FreeCam = false
    self.FreeCamRotating = false

    stopFreeCamConnections(self)

    pcall(function()
        UserInputService.MouseBehavior =
            self.OriginalMouseBehavior
    end)

    pcall(function()
        UserInputService.MouseIconEnabled = true
    end)

    local camera = getCamera()
    local backup = self.FreeCamBackup

    if camera then
        if backup then
            pcall(function()
                camera.CFrame =
                    backup.CFrame

                camera.FieldOfView =
                    backup.FieldOfView

                camera.CameraType =
                    backup.CameraType

                if backup.CameraSubject
                    and backup.CameraSubject.Parent
                then
                    camera.CameraSubject =
                        backup.CameraSubject
                else
                    local humanoid =
                        getHumanoid()

                    if humanoid then
                        camera.CameraSubject =
                            humanoid
                    end
                end
            end)
        else
            pcall(function()
                camera.CameraType =
                    Enum.CameraType.Custom
            end)

            local humanoid =
                getHumanoid()

            if humanoid then
                pcall(function()
                    camera.CameraSubject =
                        humanoid
                end)
            end
        end
    end

    restoreFreeCamCharacter(self)

    self.FreeCamBackup = nil
    self.FreeCamPosition = nil

    if notifyShared and self.Shared then
        self.Shared.FreeCamActive = false
    end
end

local function startFreeCam(self)
    if self.Shared
        and self.Shared.FlightActive
        and self.Shared.StopFlight
    then
        pcall(self.Shared.StopFlight)
    end

    local camera = getCamera()

    if not camera then
        return
    end

    stopFreeCam(self, false)

    self.OriginalMouseBehavior =
        UserInputService.MouseBehavior

    self.FreeCam = true
    self.FreeCamRotating = false

    if self.Shared then
        self.Shared.FreeCamActive = true
    end

    self.FreeCamBackup = {
        CFrame = camera.CFrame,
        FieldOfView = camera.FieldOfView,
        CameraType = camera.CameraType,
        CameraSubject = camera.CameraSubject
    }

    local character =
        Player.Character

    local humanoid =
        character
        and character:FindFirstChildOfClass("Humanoid")

    local root =
        character
        and character:FindFirstChild(
            "HumanoidRootPart"
        )

    if humanoid
        and root
        and humanoid.Health > 0
    then
        self.FreeCamCharacter =
            character

        self.FreeCamCharacterCFrame =
            root.CFrame

        self.FreeCamHumanoidBackup = {
            Humanoid = humanoid,
            WalkSpeed = humanoid.WalkSpeed,
            JumpPower = humanoid.JumpPower,
            JumpHeight = humanoid.JumpHeight,
            UseJumpPower = humanoid.UseJumpPower,
            AutoRotate = humanoid.AutoRotate
        }

        humanoid.WalkSpeed = 0

        if humanoid.UseJumpPower then
            humanoid.JumpPower = 0
        else
            humanoid.JumpHeight = 0
        end

        humanoid.AutoRotate = false
        humanoid:Move(
            Vector3.zero,
            false
        )
    end

    local rx, ry =
        camera.CFrame:ToOrientation()

    self.FreeCamPitch =
        math.clamp(
            rx,
            math.rad(-89),
            math.rad(89)
        )

    self.FreeCamYaw = ry

    self.FreeCamPosition =
        camera.CFrame.Position

    camera.CameraType =
        Enum.CameraType.Scriptable

    setMouseNormal()

    self.FreeCamInputBeganConnection =
        UserInputService.InputBegan:Connect(
            function(input, processed)
                if not self.Alive
                    or not self.FreeCam
                then
                    return
                end

                if input.UserInputType
                    == Enum.UserInputType.MouseButton2
                then
                    self.FreeCamRotating = true
                    setMouseRotate()
                    return
                end

                if processed then
                    return
                end

                if input.UserInputType
                    == Enum.UserInputType.Keyboard
                then
                    Keys[
                        input.KeyCode.Name
                    ] = true
                end
            end
        )

    self.FreeCamInputEndedConnection =
        UserInputService.InputEnded:Connect(
            function(input)
                if input.UserInputType
                    == Enum.UserInputType.MouseButton2
                then
                    self.FreeCamRotating = false
                    setMouseNormal()
                    return
                end

                if input.UserInputType
                    == Enum.UserInputType.Keyboard
                then
                    Keys[
                        input.KeyCode.Name
                    ] = false
                end
            end
        )

    self.FreeCamInputConnection =
        UserInputService.InputChanged:Connect(
            function(input)
                if not self.Alive
                    or not self.FreeCam
                    or not self.FreeCamRotating
                then
                    return
                end

                if input.UserInputType
                    == Enum.UserInputType.MouseMovement
                then
                    self.FreeCamYaw -=
                        input.Delta.X * 0.0025

                    self.FreeCamPitch =
                        math.clamp(
                            self.FreeCamPitch
                                - input.Delta.Y * 0.0025,
                            math.rad(-89),
                            math.rad(89)
                        )
                elseif input.UserInputType
                    == Enum.UserInputType.Touch
                then
                    self.FreeCamYaw -=
                        input.Delta.X * 0.004

                    self.FreeCamPitch =
                        math.clamp(
                            self.FreeCamPitch
                                - input.Delta.Y * 0.004,
                            math.rad(-89),
                            math.rad(89)
                        )
                end
            end
        )

    self.FreeCamRenderConnection =
        RunService.RenderStepped:Connect(
            function(dt)
                if not self.Alive
                    or not self.FreeCam
                then
                    return
                end

                local currentCamera =
                    getCamera()

                if not currentCamera then
                    return
                end

                local lockedCharacter =
                    self.FreeCamCharacter

                local lockedRoot =
                    lockedCharacter
                    and lockedCharacter:FindFirstChild(
                        "HumanoidRootPart"
                    )

                local lockedHumanoid =
                    lockedCharacter
                    and lockedCharacter:FindFirstChildOfClass(
                        "Humanoid"
                    )

                if lockedRoot
                    and self.FreeCamCharacterCFrame
                then
                    pcall(function()
                        lockedRoot.CFrame =
                            self.FreeCamCharacterCFrame

                        lockedRoot.AssemblyLinearVelocity =
                            Vector3.zero

                        lockedRoot.AssemblyAngularVelocity =
                            Vector3.zero
                    end)

                    if lockedHumanoid
                        and lockedHumanoid.Health > 0
                    then
                        lockedHumanoid:Move(
                            Vector3.zero,
                            false
                        )
                    end
                end

                local rotation =
                    rotationCFrame(self)

                local forward =
                    (Keys.W and 1 or 0)
                    + (Keys.S and -1 or 0)

                local side =
                    (Keys.D and 1 or 0)
                    + (Keys.A and -1 or 0)

                local vertical =
                    Keys.Space and 1 or 0

                if Keys.LeftControl
                    or Keys.RightControl
                then
                    vertical -= 1
                end

                local move =
                    rotation.LookVector
                    * forward
                    + rotation.RightVector
                    * side
                    + Vector3.yAxis
                    * vertical

                if move.Magnitude > 1 then
                    move = move.Unit
                end

                local speed =
                    (
                        Keys.LeftShift
                        or Keys.RightShift
                    )
                    and 180
                    or 70

                self.FreeCamPosition +=
                    move * speed * dt

                currentCamera.CFrame =
                    CFrame.new(
                        self.FreeCamPosition
                    ) * rotation

                currentCamera.CameraType =
                    Enum.CameraType.Scriptable

                if self.FreeCamRotating then
                    if UserInputService.MouseBehavior
                        ~= Enum.MouseBehavior.LockCenter
                    then
                        setMouseRotate()
                    end
                else
                    if UserInputService.MouseBehavior
                        ~= Enum.MouseBehavior.Default
                    then
                        setMouseNormal()
                    end
                end
            end
        )
end

local function objectRadarClassMatch(
    self,
    object
)
    if self.ObjectRadarMode ==
        "全部物件"
    then
        return true
    end

    if self.ObjectRadarMode ==
        "模型"
    then
        return object:IsA("Model")
    end

    if self.ObjectRadarMode ==
        "零件"
    then
        return object:IsA("BasePart")
    end

    if self.ObjectRadarMode ==
        "NPC"
    then
        return object:IsA("Model")
            and object:FindFirstChildOfClass(
                "Humanoid"
            ) ~= nil
            and not Players:GetPlayerFromCharacter(
                object
            )
    end

    if self.ObjectRadarMode ==
        "工具"
    then
        return object:IsA("Tool")
    end

    if self.ObjectRadarMode ==
        "互動物件"
    then
        return object:IsA("ProximityPrompt")
            or object:IsA("ClickDetector")
            or object:IsA("TouchTransmitter")
    end

    return true
end

local function clearObjectRadar(self)
    if self.ObjectRadarFolder then
        pcall(function()
            self.ObjectRadarFolder:Destroy()
        end)
    end

    self.ObjectRadarFolder = nil

    table.clear(
        self.ObjectRadarCache
    )
end

local function getObjectPosition(object)
    if object:IsA("BasePart") then
        return object.Position
    end

    if object:IsA("Model") then
        local primary =
            object.PrimaryPart

        if primary then
            return primary.Position
        end

        local root =
            object:FindFirstChild(
                "HumanoidRootPart"
            )

        if root and root:IsA("BasePart") then
            return root.Position
        end
    end

    local parent = object.Parent

    if parent
        and parent:IsA("BasePart")
    then
        return parent.Position
    end

    if parent
        and parent:IsA("Model")
    then
        local root =
            parent:FindFirstChild(
                "HumanoidRootPart"
            )
            or parent.PrimaryPart

        if root and root:IsA("BasePart") then
            return root.Position
        end
    end

    return nil
end

local function buildObjectRadar(self)
    if not self.ObjectRadar
        or not self.Alive
    then
        return
    end

    local root = getRoot()

    if not root then
        return
    end

    if not self.ObjectRadarFolder then
        self.ObjectRadarFolder =
            Instance.new("Folder")

        self.ObjectRadarFolder.Name =
            "DeveloperV5_ObjectRadar"

        self.ObjectRadarFolder.Parent =
            Workspace
    end

    local oldMarkers =
        self.ObjectRadarCache

    self.ObjectRadarCache = {}

    local descendants =
        Workspace:GetDescendants()

    local found = 0

    for i = 1, #descendants do
        if not self.Alive
            or not self.ObjectRadar
        then
            return
        end

        if found >= self.ObjectRadarMax then
            break
        end

        local object =
            descendants[i]

        if object
            ~= self.ObjectRadarFolder
            and not object:IsDescendantOf(
                self.ObjectRadarFolder
            )
            and object ~= getCharacter()
        then
            if objectRadarClassMatch(
                self,
                object
            ) then
                local position =
                    getObjectPosition(object)

                if position then
                    local distance =
                        (
                            position
                            - root.Position
                        ).Magnitude

                    if distance <=
                        self.ObjectRadarDistance
                    then
                        local marker =
                            Instance.new("Part")

                        marker.Name =
                            "雷達標記"

                        marker.Shape =
                            Enum.PartType.Ball

                        marker.Size =
                            Vector3.new(
                                0.35,
                                0.35,
                                0.35
                            )

                        marker.Position =
                            position

                        marker.Anchored = true
                        marker.CanCollide = false
                        marker.CanTouch = false
                        marker.CanQuery = false
                        marker.CastShadow = false
                        marker.Material =
                            Enum.Material.Neon

                        marker.Parent =
                            self.ObjectRadarFolder

                        table.insert(
                            self.ObjectRadarCache,
                            {
                                Object = object,
                                Marker = marker
                            }
                        )

                        found += 1
                    end
                end
            end
        end

        if i % 100 == 0 then
            task.wait()
        end
    end

    for _, item in ipairs(oldMarkers) do
        local marker =
            item
            and item.Marker

        if marker
            and marker.Parent
        then
            pcall(function()
                marker:Destroy()
            end)
        end
    end
end

local function stopObjectRadar(self)
    if self.ObjectRadarConnection then
        task.cancel(
            self.ObjectRadarConnection
        )
    end

    self.ObjectRadarConnection = nil

    clearObjectRadar(self)
end

local function startObjectRadar(self)
    stopObjectRadar(self)

    if not self.ObjectRadar then
        return
    end

    self.ObjectRadarConnection =
        task.spawn(function()
            while self.Alive
                and self.ObjectRadar
            do
                buildObjectRadar(self)

                task.wait(
                    self.ObjectRadarRefresh
                )
            end
        end)
end

local function setObjectRadar(self, enabled)
    self.ObjectRadar =
        enabled == true

    if self.ObjectRadar then
        startObjectRadar(self)
    else
        stopObjectRadar(self)
    end
end

local function backupLightingStudio(self)
    if self.LightingStudioBackup then
        return
    end

    self.LightingStudioBackup = {
        Brightness =
            Lighting.Brightness,

        ExposureCompensation =
            Lighting.ExposureCompensation,

        ClockTime =
            Lighting.ClockTime,

        GlobalShadows =
            Lighting.GlobalShadows,

        Ambient =
            Lighting.Ambient,

        OutdoorAmbient =
            Lighting.OutdoorAmbient
    }
end

local function removeLightingEffect(
    self,
    field
)
    local effect = self[field]

    if effect then
        pcall(function()
            effect:Destroy()
        end)

        self[field] = nil
    end
end

local function createLightingEffect(
    self,
    className,
    field
)
    if self[field]
        and self[field].Parent
    then
        return self[field]
    end

    local effect =
        Instance.new(className)

    effect.Name =
        "DeveloperV5_" .. className

    effect.Parent = Lighting

    self[field] = effect

    return effect
end

local function updateLightingStudio(self)
    if not self.LightingStudio then
        return
    end

    backupLightingStudio(self)

    pcall(function()
        Lighting.Brightness =
            self.LightingStudioBrightness

        Lighting.ExposureCompensation =
            self.LightingStudioExposure

        Lighting.ClockTime =
            self.LightingStudioClockTime

        Lighting.GlobalShadows =
            self.LightingStudioShadow
    end)

    if self.LightingStudioBloom then
        local effect =
            createLightingEffect(
                self,
                "BloomEffect",
                "LightingStudioBloomEffect"
            )

        effect.Intensity = 1.2
        effect.Size = 24
        effect.Threshold = 1
        effect.Enabled = true
    else
        removeLightingEffect(
            self,
            "LightingStudioBloomEffect"
        )
    end

    if self.LightingStudioColor then
        local effect =
            createLightingEffect(
                self,
                "ColorCorrectionEffect",
                "LightingStudioColorEffect"
            )

        effect.Brightness = 0.05
        effect.Contrast = 0.1
        effect.Saturation = 0.05

        effect.TintColor =
            Color3.fromRGB(
                255,
                245,
                230
            )

        effect.Enabled = true
    else
        removeLightingEffect(
            self,
            "LightingStudioColorEffect"
        )
    end

    if self.LightingStudioSunRays then
        local effect =
            createLightingEffect(
                self,
                "SunRaysEffect",
                "LightingStudioSunEffect"
            )

        effect.Intensity = 0.15
        effect.Spread = 0.8
        effect.Enabled = true
    else
        removeLightingEffect(
            self,
            "LightingStudioSunEffect"
        )
    end

    if self.LightingStudioDepth then
        local effect =
            createLightingEffect(
                self,
                "DepthOfFieldEffect",
                "LightingStudioDepthEffect"
            )

        effect.FocusDistance = 50
        effect.InFocusRadius = 35
        effect.NearIntensity = 0.05
        effect.FarIntensity = 0.15
        effect.Enabled = true
    else
        removeLightingEffect(
            self,
            "LightingStudioDepthEffect"
        )
    end

    if self.LightingStudioBlur then
        local effect =
            createLightingEffect(
                self,
                "BlurEffect",
                "LightingStudioBlurEffect"
            )

        effect.Size = 2
        effect.Enabled = true
    else
        removeLightingEffect(
            self,
            "LightingStudioBlurEffect"
        )
    end
end

local function restoreLightingStudio(self)
    removeLightingEffect(
        self,
        "LightingStudioBloomEffect"
    )

    removeLightingEffect(
        self,
        "LightingStudioColorEffect"
    )

    removeLightingEffect(
        self,
        "LightingStudioSunEffect"
    )

    removeLightingEffect(
        self,
        "LightingStudioDepthEffect"
    )

    removeLightingEffect(
        self,
        "LightingStudioBlurEffect"
    )

    if self.LightingStudioBackup then
        pcall(function()
            Lighting.Brightness =
                self.LightingStudioBackup.Brightness

            Lighting.ExposureCompensation =
                self.LightingStudioBackup.ExposureCompensation

            Lighting.ClockTime =
                self.LightingStudioBackup.ClockTime

            Lighting.GlobalShadows =
                self.LightingStudioBackup.GlobalShadows

            Lighting.Ambient =
                self.LightingStudioBackup.Ambient

            Lighting.OutdoorAmbient =
                self.LightingStudioBackup.OutdoorAmbient
        end)
    end

    self.LightingStudioBackup = nil
end

local function setLightingStudio(
    self,
    enabled
)
    self.LightingStudio =
        enabled == true

    if self.LightingStudio then
        updateLightingStudio(self)
    else
        restoreLightingStudio(self)
    end
end

local function createLightingControls(
    self,
    tab
)
    tab:CreateSection("高級光影")

    tab:CreateToggle({
        Name = "光影工作室",
        CurrentValue = false,
        Flag = "DeveloperV5LightingStudio",
        Callback = function(value)
            setLightingStudio(
                self,
                value
            )
        end
    })

    tab:CreateToggle({
        Name = "柔和光暈",
        CurrentValue = false,
        Flag = "DeveloperV5SoftBloom",
        Callback = function(value)
            self.LightingStudioBloom =
                value

            updateLightingStudio(self)
        end
    })

    tab:CreateToggle({
        Name = "電影色調",
        CurrentValue = false,
        Flag = "DeveloperV5CinemaColor",
        Callback = function(value)
            self.LightingStudioColor =
                value

            updateLightingStudio(self)
        end
    })

    tab:CreateToggle({
        Name = "陽光光束",
        CurrentValue = false,
        Flag = "DeveloperV5SunRays",
        Callback = function(value)
            self.LightingStudioSunRays =
                value

            updateLightingStudio(self)
        end
    })

    tab:CreateToggle({
        Name = "景深效果",
        CurrentValue = false,
        Flag = "DeveloperV5DepthOfField",
        Callback = function(value)
            self.LightingStudioDepth =
                value

            updateLightingStudio(self)
        end
    })

    tab:CreateToggle({
        Name = "柔焦效果",
        CurrentValue = false,
        Flag = "DeveloperV5SoftBlur",
        Callback = function(value)
            self.LightingStudioBlur =
                value

            updateLightingStudio(self)
        end
    })

    tab:CreateToggle({
        Name = "強化陰影",
        CurrentValue = true,
        Flag = "DeveloperV5EnhancedShadow",
        Callback = function(value)
            self.LightingStudioShadow =
                value

            updateLightingStudio(self)
        end
    })

    tab:CreateSlider({
        Name = "光影亮度",
        Range = {0, 10},
        Increment = 0.1,
        CurrentValue =
            self.LightingStudioBrightness,
        Suffix = "",
        Flag = "DeveloperV5LightingBrightness",
        Callback = function(value)
            self.LightingStudioBrightness =
                value

            updateLightingStudio(self)
        end
    })

    tab:CreateSlider({
        Name = "曝光強度",
        Range = {-5, 5},
        Increment = 0.1,
        CurrentValue =
            self.LightingStudioExposure,
        Suffix = "",
        Flag = "DeveloperV5LightingExposure",
        Callback = function(value)
            self.LightingStudioExposure =
                value

            updateLightingStudio(self)
        end
    })

    tab:CreateSlider({
        Name = "世界時間",
        Range = {0, 24},
        Increment = 0.1,
        CurrentValue =
            self.LightingStudioClockTime,
        Suffix = "",
        Flag = "DeveloperV5LightingTime",
        Callback = function(value)
            self.LightingStudioClockTime =
                value

            updateLightingStudio(self)
        end
    })

    tab:CreateButton({
        Name = "套用光影設定",
        Callback = function()
            updateLightingStudio(self)
        end
    })

    tab:CreateButton({
        Name = "還原光影",
        Callback = function()
            self.LightingStudio = false
            restoreLightingStudio(self)
        end
    })
end

local function createObjectRadarControls(
    self,
    tab
)
    tab:CreateSection("物件雷達")

    tab:CreateToggle({
        Name = "場景物件雷達",
        CurrentValue = false,
        Flag = "DeveloperV5ObjectRadar",
        Callback = function(value)
            setObjectRadar(
                self,
                value
            )
        end
    })

    tab:CreateDropdown({
        Name = "偵測類型",
        Options = {
            "全部物件",
            "模型",
            "零件",
            "NPC",
            "工具",
            "互動物件"
        },
        CurrentOption = {
            "全部物件"
        },
        MultipleOptions = false,
        Flag = "DeveloperV5ObjectRadarType",
        Callback = function(options)
            self.ObjectRadarMode =
                options[1]
                or "全部物件"

            if self.ObjectRadar then
                task.spawn(function()
                    buildObjectRadar(self)
                end)
            end
        end
    })

    tab:CreateSlider({
        Name = "偵測距離",
        Range = {25, 2000},
        Increment = 25,
        CurrentValue =
            self.ObjectRadarDistance,
        Suffix = "",
        Flag = "DeveloperV5RadarDistance",
        Callback = function(value)
            self.ObjectRadarDistance =
                value
        end
    })

    tab:CreateSlider({
        Name = "最大標記數",
        Range = {10, 150},
        Increment = 10,
        CurrentValue =
            self.ObjectRadarMax,
        Suffix = "",
        Flag = "DeveloperV5RadarMax",
        Callback = function(value)
            self.ObjectRadarMax =
                value
        end
    })

    tab:CreateSlider({
        Name = "掃描間隔",
        Range = {0.5, 5},
        Increment = 0.5,
        CurrentValue =
            self.ObjectRadarRefresh,
        Suffix = " 秒",
        Flag = "DeveloperV5RadarRefresh",
        Callback = function(value)
            self.ObjectRadarRefresh =
                value

            if self.ObjectRadar then
                startObjectRadar(self)
            end
        end
    })

    tab:CreateButton({
        Name = "立即偵測",
        Callback = function()
            if self.ObjectRadar then
                task.spawn(function()
                    buildObjectRadar(self)
                end)
            end
        end
    })

    tab:CreateButton({
        Name = "清除偵測標記",
        Callback = function()
            clearObjectRadar(self)
        end
    })
end

function Visuals:Init(context)
    Player = context.Player
    self.Shared = context.Shared or {}
    self.Alive = true

    backupFOV(self)
    backupZoom(self)

    addConnection(
        self,
        Player.CharacterAdded:Connect(
            function()
                if self.FreeCam then
                    stopFreeCam(self, true)
                end

                task.defer(function()
                    if not self.Alive then
                        return
                    end

                    if self.ZoomUnlock then
                        local camera =
                            getCamera()

                        local root =
                            getRoot()

                        if camera and root then
                            local focusPosition =
                                root.Position
                                + Vector3.new(0, 2, 0)

                            self.ZoomDistance =
                                math.clamp(
                                    (
                                        camera.CFrame.Position
                                        - focusPosition
                                    ).Magnitude,
                                    0.5,
                                    self.ZoomMaxDistance
                                )
                        end

                        enforceZoomLimit(self)
                    end

                    if self.ObjectRadar then
                        task.spawn(function()
                            buildObjectRadar(self)
                        end)
                    end
                end)
            end
        )
    )

    addConnection(
        self,
        UserInputService.InputBegan:Connect(
            function(input, processed)
                if processed
                    or not self.Alive
                then
                    return
                end

                if self.FreeCam then
                    return
                end

                if input.UserInputType
                    == Enum.UserInputType.Keyboard
                then
                    Keys[
                        input.KeyCode.Name
                    ] = true
                end
            end
        )
    )

    addConnection(
        self,
        UserInputService.InputEnded:Connect(
            function(input)
                if input.UserInputType
                    == Enum.UserInputType.Keyboard
                then
                    Keys[
                        input.KeyCode.Name
                    ] = false
                end
            end
        )
    )

    local tab = context.Tab

    tab:CreateSection("光照")

    tab:CreateToggle({
        Name = "全亮",
        CurrentValue = false,
        Flag = "DeveloperV5Fullbright",
        Callback = function(value)
            setFullbright(
                self,
                value
            )
        end
    })

    tab:CreateToggle({
        Name = "移除大氣效果",
        CurrentValue = false,
        Flag = "DeveloperV5RemoveAtmosphere",
        Callback = function(value)
            setRemoveAtmosphere(
                self,
                value
            )
        end
    })

    tab:CreateToggle({
        Name = "停用後製效果",
        CurrentValue = false,
        Flag = "DeveloperV5PostEffects",
        Callback = function(value)
            setRemovePostEffects(
                self,
                value
            )
        end
    })

    createLightingControls(
        self,
        tab
    )

    createObjectRadarControls(
        self,
        tab
    )

    tab:CreateSection("鏡頭")

    tab:CreateToggle({
        Name = "解鎖視角縮放限制",
        CurrentValue = false,
        Flag = "DeveloperV5ZoomUnlock",
        Callback = function(value)
            setZoomUnlock(
                self,
                value
            )
        end
    })

    tab:CreateToggle({
        Name = "自由鏡頭",
        CurrentValue = false,
        Flag = "DeveloperV5FreeCam",
        Callback = function(value)
            if value then
                startFreeCam(self)
            else
                stopFreeCam(
                    self,
                    true
                )
            end
        end
    })

    tab:CreateInput({
        Name = "視野角度",
        CurrentValue =
            tostring(self.FOV),
        PlaceholderText =
            "輸入視野角度（40～120）",
        RemoveTextAfterFocusLost = false,
        Flag = "DeveloperV5FOV",
        Callback = function(value)
            local number =
                tonumber(value)

            if not number then
                return
            end

            self.FOV =
                math.clamp(
                    number,
                    40,
                    120
                )

            local camera =
                getCamera()

            if camera then
                camera.FieldOfView =
                    self.FOV
            end
        end
    })

    tab:CreateInput({
        Name = "最大縮放距離",
        CurrentValue =
            tostring(
                self.ZoomMaxDistance
            ),
        PlaceholderText =
            "例如 10000",
        RemoveTextAfterFocusLost = false,
        Flag =
            "DeveloperV5ZoomMaxDistance",
        Callback = function(value)
            local number =
                tonumber(value)

            if not number then
                return
            end

            self.ZoomMaxDistance =
                math.clamp(
                    number,
                    10,
                    100000
                )

            if self.ZoomDistance
                > self.ZoomMaxDistance
            then
                self.ZoomDistance =
                    self.ZoomMaxDistance
            end

            if self.ZoomUnlock then
                enforceZoomLimit(self)
            end
        end
    })

    tab:CreateSlider({
        Name = "滾輪縮放幅度",
        Range = {10, 1000},
        Increment = 10,
        CurrentValue =
            self.ZoomStep,
        Suffix = " studs",
        Flag =
            "DeveloperV5ZoomStep",
        Callback = function(value)
            self.ZoomStep = value
        end
    })

    tab:CreateButton({
        Name = "重設鏡頭",
        Callback = function()
            stopFreeCam(
                self,
                true
            )

            local camera =
                getCamera()

            if camera then
                camera.FieldOfView =
                    self.OriginalFOV
                    or 70

                camera.CameraType =
                    Enum.CameraType.Custom

                local humanoid =
                    getHumanoid()

                if humanoid then
                    camera.CameraSubject =
                        humanoid
                end
            end

            self.FOV =
                self.OriginalFOV
                or 70

            if self.ZoomUnlock then
                local root =
                    getRoot()

                local camera =
                    getCamera()

                if root and camera then
                    local focusPosition =
                        root.Position
                        + Vector3.new(0, 2, 0)

                    self.ZoomDistance =
                        math.clamp(
                            (
                                camera.CFrame.Position
                                - focusPosition
                            ).Magnitude,
                            0.5,
                            self.ZoomMaxDistance
                        )
                end

                enforceZoomLimit(self)
            end

            setMouseNormal()
        end
    })

    self.Shared.StopFreeCam =
        function()
            stopFreeCam(
                self,
                true
            )
        end

    self.Shared.SetFreeCam =
        function(value)
            if value then
                startFreeCam(self)
            else
                stopFreeCam(
                    self,
                    true
                )
            end
        end

    self.Shared.SetZoomUnlock =
        function(value)
            setZoomUnlock(
                self,
                value
            )
        end

    self.Shared.SetObjectRadar =
        function(value)
            setObjectRadar(
                self,
                value
            )
        end

    self.Shared.RefreshObjectRadar =
        function()
            if self.ObjectRadar then
                task.spawn(function()
                    buildObjectRadar(self)
                end)
            end
        end

    self.Shared.SetLightingStudio =
        function(value)
            setLightingStudio(
                self,
                value
            )
        end
end

function Visuals:Cleanup()
    if not self.Alive then
        return
    end

    self.Alive = false

    stopFreeCam(
        self,
        true
    )

    stopAtmosphereWatcher(self)
    stopPostEffectWatcher(self)
    stopZoomWatcher(self)
    stopObjectRadar(self)

    setFullbright(
        self,
        false
    )

    setRemoveAtmosphere(
        self,
        false
    )

    setRemovePostEffects(
        self,
        false
    )

    self.LightingStudio = false

    restoreLightingStudio(self)

    pcall(function()
        Player.CameraMinZoomDistance =
            self.OriginalCameraMinZoomDistance

        Player.CameraMaxZoomDistance =
            self.OriginalCameraMaxZoomDistance

        if self.OriginalCameraMode then
            Player.CameraMode =
                self.OriginalCameraMode
        end
    end)

    setMouseNormal()

    local camera =
        getCamera()

    if camera
        and self.OriginalFOV
    then
        camera.FieldOfView =
            self.OriginalFOV

        camera.CameraType =
            Enum.CameraType.Custom

        local humanoid =
            getHumanoid()

        if humanoid then
            camera.CameraSubject =
                humanoid
        end
    end

    clearObjectRadar(self)

    for i = #self.Connections, 1, -1 do
        disconnect(
            self.Connections[i]
        )

        self.Connections[i] = nil
    end

    table.clear(Keys)
    table.clear(
        self.AtmosphereBackup
    )
    table.clear(
        self.PostEffectsBackup
    )
    table.clear(
        self.ObjectRadarCache
    )

    self.OriginalLighting = nil
    self.OriginalFOV = nil
    self.OriginalCameraMinZoomDistance = nil
    self.OriginalCameraMaxZoomDistance = nil
    self.OriginalCameraMode = nil
    self.OriginalZoomDistance = nil
    self.FreeCamBackup = nil
    self.FreeCamPosition = nil
    self.ZoomConnection = nil
    self.ZoomPropertyConnection1 = nil
    self.ZoomPropertyConnection2 = nil
    self.ZoomRenderConnection = nil
    self.ObjectRadarConnection = nil
    self.LightingStudioBackup = nil
    self.FreeCamRotating = false

    pcall(function()
        RunService:UnbindFromRenderStep(
            "DeveloperV5_CustomZoom"
        )
    end)

    if self.Shared then
        self.Shared.FreeCamActive = false
        self.Shared.StopFreeCam = nil
        self.Shared.SetFreeCam = nil
        self.Shared.SetZoomUnlock = nil
        self.Shared.SetObjectRadar = nil
        self.Shared.RefreshObjectRadar = nil
        self.Shared.SetLightingStudio = nil
    end
end

return Visuals
