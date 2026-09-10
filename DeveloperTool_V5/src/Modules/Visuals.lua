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
    ZoomMinDistance = 0.5,
    ZoomDistance = 12,
    ZoomStep = 60,
    OriginalZoomDistance = nil,
    ZoomConnection = nil,
    ZoomPropertyConnection1 = nil,
    ZoomPropertyConnection2 = nil,
    ZoomRenderConnection = nil,
    ZoomActionBound = false,
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
    RealisticLighting = false,
    RealisticLightingBackup = nil,
    RealisticAtmosphere = nil,
    RealisticColorCorrection = nil,
    RealisticBloom = nil,
    RealisticSunRays = nil,
    RealisticDepthOfField = nil,
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
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
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        ColorShift_Top = Lighting.ColorShift_Top,
        ColorShift_Bottom = Lighting.ColorShift_Bottom,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
        ShadowSoftness = Lighting.ShadowSoftness,
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

    if self.RealisticLighting then
        return
    end

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

            Lighting.ColorShift_Top =
                self.OriginalLighting.ColorShift_Top

            Lighting.ColorShift_Bottom =
                self.OriginalLighting.ColorShift_Bottom

            Lighting.EnvironmentDiffuseScale =
                self.OriginalLighting.EnvironmentDiffuseScale

            Lighting.EnvironmentSpecularScale =
                self.OriginalLighting.EnvironmentSpecularScale

            Lighting.ShadowSoftness =
                self.OriginalLighting.ShadowSoftness
        end)
    end
end

local function disableAtmosphereItem(self, item)
    if not item or not item:IsA("Atmosphere") then
        return
    end

    if self.AtmosphereBackup[item] == nil then
        self.AtmosphereBackup[item] = item.Parent
    end

    pcall(function()
        item.Parent = nil
    end)
end

local function restoreAtmosphere(self)
    for item, originalParent in pairs(self.AtmosphereBackup) do
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
        local descendants = Lighting:GetDescendants()

        for i = 1, #descendants do
            if not self.Alive or not self.RemoveAtmosphere then
                return
            end

            disableAtmosphereItem(self, descendants[i])

            if i % 100 == 0 then
                task.wait()
            end
        end
    end)

    self.AtmosphereConnection =
        Lighting.DescendantAdded:Connect(function(item)
            if self.Alive and self.RemoveAtmosphere then
                task.defer(function()
                    if self.Alive and self.RemoveAtmosphere then
                        disableAtmosphereItem(self, item)
                    end
                end)
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

    pcall(function()
        item.Enabled = false
    end)
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

    task.spawn(function()
        local descendants = Lighting:GetDescendants()

        for i = 1, #descendants do
            if not self.Alive or not self.RemovePostEffects then
                return
            end

            disablePostEffectItem(self, descendants[i])

            if i % 100 == 0 then
                task.wait()
            end
        end
    end)

    self.PostEffectConnection =
        Lighting.DescendantAdded:Connect(function(item)
            if self.Alive and self.RemovePostEffects then
                task.defer(function()
                    if self.Alive and self.RemovePostEffects then
                        disablePostEffectItem(self, item)
                    end
                end)
            end
        end)
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
        self.ZoomDistance =
            math.clamp(
                (camera.CFrame.Position - root.Position).Magnitude,
                self.ZoomMinDistance,
                self.ZoomMaxDistance
            )
    end

    self.OriginalZoomDistance =
        self.ZoomDistance
end

local function getMousePosition()
    local position =
        UserInputService:GetMouseLocation()

    return position.X, position.Y
end

local function isMouseOverGui()
    local x, y = getMousePosition()

    local objects = {}

    pcall(function()
        objects =
            GuiService:GetGuiObjectsAtPosition(
                x,
                y
            )
    end)

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

local function stopZoomWatcher(self)
    disconnect(self.ZoomConnection)
    disconnect(self.ZoomPropertyConnection1)
    disconnect(self.ZoomPropertyConnection2)
    disconnect(self.ZoomRenderConnection)

    if self.ZoomActionBound then
        pcall(function()
            ContextActionService:UnbindAction(
                "DeveloperV5ZoomWheel"
            )
        end)

        self.ZoomActionBound = false
    end

    self.ZoomConnection = nil
    self.ZoomPropertyConnection1 = nil
    self.ZoomPropertyConnection2 = nil
    self.ZoomRenderConnection = nil
end

local function setZoomDistance(self, distance)
    self.ZoomDistance =
        math.clamp(
            distance,
            self.ZoomMinDistance,
            self.ZoomMaxDistance
        )

    pcall(function()
        Player.CameraMinZoomDistance =
            self.ZoomDistance

        Player.CameraMaxZoomDistance =
            self.ZoomDistance
    end)
end

local function enforceZoomLimit(self)
    if not self.Alive or not self.ZoomUnlock then
        return
    end

    pcall(function()
        Player.CameraMode =
            Enum.CameraMode.Classic

        Player.CameraMinZoomDistance =
            self.ZoomDistance

        Player.CameraMaxZoomDistance =
            self.ZoomDistance
    end)
end

local function zoomAction(self, actionName, inputState, inputObject)
    if not self.Alive
        or not self.ZoomUnlock
    then
        return Enum.ContextActionResult.Pass
    end

    if inputObject.UserInputType
        ~= Enum.UserInputType.MouseWheel
    then
        return Enum.ContextActionResult.Pass
    end

    if inputState
        ~= Enum.UserInputState.Change
    then
        return Enum.ContextActionResult.Sink
    end

    if isMouseOverGui() then
        return Enum.ContextActionResult.Sink
    end

    local delta =
        inputObject.Position.Z

    if delta == 0 then
        return Enum.ContextActionResult.Sink
    end

    local nextDistance =
        self.ZoomDistance
        - delta * self.ZoomStep

    setZoomDistance(
        self,
        nextDistance
    )

    return Enum.ContextActionResult.Sink
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

            Player.CameraMode =
                self.OriginalCameraMode
                or Enum.CameraMode.Classic
        end)

        return
    end

    local camera = getCamera()
    local root = getRoot()

    if camera and root then
        self.ZoomDistance =
            math.clamp(
                (camera.CFrame.Position - root.Position).Magnitude,
                self.ZoomMinDistance,
                self.ZoomMaxDistance
            )
    end

    enforceZoomLimit(self)

    ContextActionService:BindActionAtPriority(
        "DeveloperV5ZoomWheel",
        function(actionName, inputState, inputObject)
            return zoomAction(
                self,
                actionName,
                inputState,
                inputObject
            )
        end,
        false,
        3000,
        Enum.UserInputType.MouseWheel
    )

    self.ZoomActionBound = true

    self.ZoomPropertyConnection1 =
        Player:GetPropertyChangedSignal(
            "CameraMinZoomDistance"
        ):Connect(function()
            if self.Alive and self.ZoomUnlock then
                enforceZoomLimit(self)
            end
        end)

    self.ZoomPropertyConnection2 =
        Player:GetPropertyChangedSignal(
            "CameraMaxZoomDistance"
        ):Connect(function()
            if self.Alive and self.ZoomUnlock then
                enforceZoomLimit(self)
            end
        end)

    self.ZoomConnection =
        RunService.Heartbeat:Connect(function()
            if self.Alive and self.ZoomUnlock then
                if math.abs(
                    Player.CameraMinZoomDistance
                    - self.ZoomDistance
                ) > 0.01
                    or math.abs(
                        Player.CameraMaxZoomDistance
                        - self.ZoomDistance
                    ) > 0.01
                then
                    enforceZoomLimit(self)
                end
            end
        end)

    self.ZoomRenderConnection =
        RunService:BindToRenderStep(
            "DeveloperV5ZoomRender",
            Enum.RenderPriority.Camera.Value + 1,
            function()
                if not self.Alive
                    or not self.ZoomUnlock
                then
                    return
                end

                local currentCamera =
                    getCamera()

                if not currentCamera then
                    return
                end

                if currentCamera.CameraType
                    == Enum.CameraType.Scriptable
                then
                    return
                end

                local focus =
                    currentCamera.Focus.Position

                local cameraCFrame =
                    currentCamera.CFrame

                local lookVector =
                    cameraCFrame.LookVector

                local newPosition =
                    focus
                    - lookVector * self.ZoomDistance

                currentCamera.CFrame =
                    CFrame.lookAt(
                        newPosition,
                        newPosition + lookVector,
                        cameraCFrame.UpVector
                    )
            end
        )
end

local function stopFreeCamConnections(self)
    disconnect(self.FreeCamInputConnection)
    disconnect(self.FreeCamInputBeganConnection)
    disconnect(self.FreeCamInputEndedConnection)
    disconnect(self.FreeCamRenderConnection)

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
    local humanoid =
        self.FreeCamHumanoidBackup
        and self.FreeCamHumanoidBackup.Humanoid

    local backup =
        self.FreeCamHumanoidBackup

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
    setMouseNormal()

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
    backupFOV(self)

    self.FreeCam = true
    self.FreeCamRotating = false

    if self.Shared then
        self.Shared.FreeCamActive = true
    end

    self.FreeCamBackup = {
        CFrame = camera.CFrame,
        FieldOfView = camera.FieldOfView,
        CameraType = camera.CameraType,
        CameraSubject = camera.CameraSubject,
    }

    local character = Player.Character

    local humanoid =
        character
        and character:FindFirstChildOfClass(
            "Humanoid"
        )

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
            AutoRotate = humanoid.AutoRotate,
        }

        humanoid.WalkSpeed = 0

        if humanoid.UseJumpPower then
            humanoid.JumpPower = 0
        else
            humanoid.JumpHeight = 0
        end

        humanoid.AutoRotate = false
        humanoid:Move(Vector3.zero, false)
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

                if input.UserInputType ==
                    Enum.UserInputType.MouseButton2
                then
                    self.FreeCamRotating = true
                    setMouseRotate()
                    return
                end

                if processed then
                    return
                end

                if input.UserInputType ==
                    Enum.UserInputType.Keyboard
                then
                    Keys[input.KeyCode.Name] =
                        true
                end
            end
        )

    self.FreeCamInputEndedConnection =
        UserInputService.InputEnded:Connect(
            function(input)
                if input.UserInputType ==
                    Enum.UserInputType.MouseButton2
                then
                    self.FreeCamRotating = false
                    setMouseNormal()
                    return
                end

                if input.UserInputType ==
                    Enum.UserInputType.Keyboard
                then
                    Keys[input.KeyCode.Name] =
                        false
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

                if input.UserInputType ==
                    Enum.UserInputType.MouseMovement
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
                    rotation.LookVector * forward
                    + rotation.RightVector * side
                    + Vector3.yAxis * vertical

                if move.Magnitude > 1 then
                    move = move.Unit
                end

                local speed =
                    (Keys.LeftShift
                        or Keys.RightShift)
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

local function objectRadarClassMatch(self, object)
    if self.ObjectRadarMode == "全部物件" then
        return true
    end

    if self.ObjectRadarMode == "模型" then
        return object:IsA("Model")
    end

    if self.ObjectRadarMode == "零件" then
        return object:IsA("BasePart")
    end

    if self.ObjectRadarMode == "NPC" then
        return object:IsA("Model")
            and object:FindFirstChildOfClass(
                "Humanoid"
            ) ~= nil
            and not Players:GetPlayerFromCharacter(
                object
            )
    end

    if self.ObjectRadarMode == "工具" then
        return object:IsA("Tool")
    end

    if self.ObjectRadarMode == "互動物件" then
        return object:IsA("ProximityPrompt")
            or object:IsA("ClickDetector")
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
    table.clear(self.ObjectRadarCache)
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

        if root
            and root:IsA("BasePart")
        then
            return root.Position
        end

        local success, pivot =
            pcall(function()
                return object:GetPivot()
            end)

        if success and pivot then
            return pivot.Position
        end
    end

    local parent =
        object.Parent

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

        if root
            and root:IsA("BasePart")
        then
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

        if object ~= self.ObjectRadarFolder
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

                        self.ObjectRadarCache[
                            #self.ObjectRadarCache + 1
                        ] = {
                            Object = object,
                            Marker = marker
                        }

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

        if marker and marker.Parent then
            pcall(function()
                marker:Destroy()
            end)
        end
    end
end

local function stopObjectRadar(self)
    if self.ObjectRadarConnection then
        pcall(function()
            task.cancel(
                self.ObjectRadarConnection
            )
        end)
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

local function backupRealisticLighting(self)
    if self.RealisticLightingBackup then
        return
    end

    self.RealisticLightingBackup = {
        Brightness = Lighting.Brightness,
        ExposureCompensation =
            Lighting.ExposureCompensation,
        ClockTime = Lighting.ClockTime,
        GlobalShadows = Lighting.GlobalShadows,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        ColorShift_Top =
            Lighting.ColorShift_Top,
        ColorShift_Bottom =
            Lighting.ColorShift_Bottom,
        EnvironmentDiffuseScale =
            Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale =
            Lighting.EnvironmentSpecularScale,
        ShadowSoftness =
            Lighting.ShadowSoftness,
        FogEnd = Lighting.FogEnd,
        PrioritizeLightingQuality =
            Lighting.PrioritizeLightingQuality,
    }
end

local function createRealisticEffect(
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
        "DeveloperV5_Realistic_" ..
        className

    effect.Parent =
        Lighting

    self[field] = effect

    return effect
end

local function configureRealisticLighting(self)
    if not self.RealisticLighting then
        return
    end

    backupRealisticLighting(self)

    pcall(function()
        Lighting.Brightness = 2
        Lighting.ExposureCompensation = 0.05
        Lighting.GlobalShadows = true
        Lighting.EnvironmentDiffuseScale = 1
        Lighting.EnvironmentSpecularScale = 1
        Lighting.ShadowSoftness = 0.15
        Lighting.FogEnd = 100000
        Lighting.PrioritizeLightingQuality = true
    end)

    pcall(function()
        Lighting.Ambient =
            Color3.fromRGB(
                38,
                42,
                46
            )

        Lighting.OutdoorAmbient =
            Color3.fromRGB(
                70,
                74,
                78
            )

        Lighting.ColorShift_Top =
            Color3.fromRGB(
                255,
                250,
                240
            )

        Lighting.ColorShift_Bottom =
            Color3.fromRGB(
                205,
                215,
                225
            )
    end)

    pcall(function()
        Lighting.LightingStyle =
            Enum.LightingStyle.Realistic
    end)

    if self.RealisticAtmosphere
        and self.RealisticAtmosphere.Parent
    then
        self.RealisticAtmosphere:Destroy()
    end

    local atmosphere =
        Instance.new("Atmosphere")

    atmosphere.Name =
        "DeveloperV5_Realistic_Atmosphere"

    atmosphere.Density = 0.12
    atmosphere.Offset = 0.05
    atmosphere.Haze = 0.28
    atmosphere.Glare = 0.12
    atmosphere.Color =
        Color3.fromRGB(
            205,
            218,
            235
        )

    atmosphere.Decay =
        Color3.fromRGB(
            120,
            125,
            135
        )

    atmosphere.Parent =
        Lighting

    self.RealisticAtmosphere =
        atmosphere

    local colorCorrection =
        createRealisticEffect(
            self,
            "ColorCorrectionEffect",
            "RealisticColorCorrection"
        )

    colorCorrection.Brightness = 0.015
    colorCorrection.Contrast = 0.08
    colorCorrection.Saturation = 0.04
    colorCorrection.TintColor =
        Color3.fromRGB(
            255,
            250,
            245
        )

    colorCorrection.Enabled = true

    local bloom =
        createRealisticEffect(
            self,
            "BloomEffect",
            "RealisticBloom"
        )

    bloom.Intensity = 0.22
    bloom.Size = 20
    bloom.Threshold = 0.9
    bloom.Enabled = true

    local sunRays =
        createRealisticEffect(
            self,
            "SunRaysEffect",
            "RealisticSunRays"
        )

    sunRays.Intensity = 0.08
    sunRays.Spread = 0.55
    sunRays.Enabled = true

    local depth =
        createRealisticEffect(
            self,
            "DepthOfFieldEffect",
            "RealisticDepthOfField"
        )

    depth.FocusDistance = 55
    depth.InFocusRadius = 45
    depth.NearIntensity = 0
    depth.FarIntensity = 0.08
    depth.Enabled = true

    task.spawn(function()
        local descendants =
            Workspace:GetDescendants()

        for i = 1, #descendants do
            if not self.Alive
                or not self.RealisticLighting
            then
                return
            end

            local object =
                descendants[i]

            if object:IsA("BasePart") then
                pcall(function()
                    object.CastShadow = true
                end)
            end

            if i % 250 == 0 then
                task.wait()
            end
        end
    end)
end

local function destroyRealisticEffect(
    self,
    field
)
    local effect =
        self[field]

    if effect then
        pcall(function()
            effect:Destroy()
        end)

        self[field] = nil
    end
end

local function restoreRealisticLighting(self)
    destroyRealisticEffect(
        self,
        "RealisticColorCorrection"
    )

    destroyRealisticEffect(
        self,
        "RealisticBloom"
    )

    destroyRealisticEffect(
        self,
        "RealisticSunRays"
    )

    destroyRealisticEffect(
        self,
        "RealisticDepthOfField"
    )

    if self.RealisticAtmosphere then
        pcall(function()
            self.RealisticAtmosphere:Destroy()
        end)

        self.RealisticAtmosphere = nil
    end

    if self.RealisticLightingBackup then
        pcall(function()
            Lighting.Brightness =
                self.RealisticLightingBackup.Brightness

            Lighting.ExposureCompensation =
                self.RealisticLightingBackup.ExposureCompensation

            Lighting.ClockTime =
                self.RealisticLightingBackup.ClockTime

            Lighting.GlobalShadows =
                self.RealisticLightingBackup.GlobalShadows

            Lighting.Ambient =
                self.RealisticLightingBackup.Ambient

            Lighting.OutdoorAmbient =
                self.RealisticLightingBackup.OutdoorAmbient

            Lighting.ColorShift_Top =
                self.RealisticLightingBackup.ColorShift_Top

            Lighting.ColorShift_Bottom =
                self.RealisticLightingBackup.ColorShift_Bottom

            Lighting.EnvironmentDiffuseScale =
                self.RealisticLightingBackup.EnvironmentDiffuseScale

            Lighting.EnvironmentSpecularScale =
                self.RealisticLightingBackup.EnvironmentSpecularScale

            Lighting.ShadowSoftness =
                self.RealisticLightingBackup.ShadowSoftness

            Lighting.FogEnd =
                self.RealisticLightingBackup.FogEnd

            Lighting.PrioritizeLightingQuality =
                self.RealisticLightingBackup.PrioritizeLightingQuality
        end)
    end

    self.RealisticLightingBackup = nil
end

local function setRealisticLighting(
    self,
    enabled
)
    self.RealisticLighting =
        enabled == true

    if self.RealisticLighting then
        if self.Fullbright then
            self.Fullbright = false
        end

        if self.RemoveAtmosphere then
            self.RemoveAtmosphere = false
            stopAtmosphereWatcher(self)
            restoreAtmosphere(self)
        end

        if self.RemovePostEffects then
            self.RemovePostEffects = false
            stopPostEffectWatcher(self)
            restorePostEffects(self)
        end

        configureRealisticLighting(self)
    else
        restoreRealisticLighting(self)
    end
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
            setObjectRadar(self, value)
        end,
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
        end,
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
        end,
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
        end,
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
        end,
    })

    tab:CreateButton({
        Name = "立即偵測",
        Callback = function()
            if self.ObjectRadar then
                task.spawn(function()
                    buildObjectRadar(self)
                end)
            end
        end,
    })

    tab:CreateButton({
        Name = "清除偵測標記",
        Callback = function()
            clearObjectRadar(self)
        end,
    })
end

local function createRealisticLightingControl(
    self,
    tab
)
    tab:CreateSection("寫實光影")

    tab:CreateToggle({
        Name = "寫實光影",
        CurrentValue = false,
        Flag = "DeveloperV5RealisticLighting",
        Callback = function(value)
            setRealisticLighting(
                self,
                value
            )
        end,
    })
end

function Visuals:Init(context)
    Player = context.Player
    self.Shared =
        context.Shared or {}

    self.Alive = true

    backupFOV(self)
    backupZoom(self)

    addConnection(
        self,
        Player.CharacterAdded:Connect(
            function()
                if self.FreeCam then
                    stopFreeCam(
                        self,
                        true
                    )
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
                            self.ZoomDistance =
                                math.clamp(
                                    (
                                        camera.CFrame.Position
                                        - root.Position
                                    ).Magnitude,
                                    self.ZoomMinDistance,
                                    self.ZoomMaxDistance
                                )
                        end

                        enforceZoomLimit(
                            self
                        )
                    end

                    if self.ObjectRadar then
                        task.spawn(function()
                            buildObjectRadar(
                                self
                            )
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

                if input.UserInputType ==
                    Enum.UserInputType.Keyboard
                then
                    Keys[input.KeyCode.Name] =
                        true
                end
            end
        )
    )

    addConnection(
        self,
        UserInputService.InputEnded:Connect(
            function(input)
                if input.UserInputType ==
                    Enum.UserInputType.Keyboard
                then
                    Keys[input.KeyCode.Name] =
                        false
                end
            end
        )
    )

    local tab =
        context.Tab

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
        end,
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
        end,
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
        end,
    })

    createRealisticLightingControl(
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
        end,
    })

    tab:CreateSlider({
        Name = "滾輪縮放幅度",
        Range = {10, 300},
        Increment = 10,
        CurrentValue =
            self.ZoomStep,
        Suffix = " studs",
        Flag = "DeveloperV5ZoomStep",
        Callback = function(value)
            self.ZoomStep =
                value
        end,
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
        end,
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
        end,
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
        Flag = "DeveloperV5ZoomMaxDistance",
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

            if self.ZoomUnlock then
                self.ZoomDistance =
                    math.min(
                        self.ZoomDistance,
                        self.ZoomMaxDistance
                    )

                enforceZoomLimit(
                    self
                )
            end
        end,
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

                if camera and root then
                    self.ZoomDistance =
                        math.clamp(
                            (
                                camera.CFrame.Position
                                - root.Position
                            ).Magnitude,
                            self.ZoomMinDistance,
                            self.ZoomMaxDistance
                        )
                end

                enforceZoomLimit(
                    self
                )
            end

            setMouseNormal()
        end,
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
                    buildObjectRadar(
                        self
                    )
                end)
            end
        end

    self.Shared.SetRealisticLighting =
        function(value)
            setRealisticLighting(
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

    self.RealisticLighting = false
    restoreRealisticLighting(self)

    pcall(function()
        Player.CameraMinZoomDistance =
            self.OriginalCameraMinZoomDistance

        Player.CameraMaxZoomDistance =
            self.OriginalCameraMaxZoomDistance

        Player.CameraMode =
            self.OriginalCameraMode
            or Enum.CameraMode.Classic
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

    pcall(function()
        RunService:UnbindFromRenderStep(
            "DeveloperV5ZoomRender"
        )
    end)

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
    self.RealisticLightingBackup = nil
    self.RealisticAtmosphere = nil
    self.RealisticColorCorrection = nil
    self.RealisticBloom = nil
    self.RealisticSunRays = nil
    self.RealisticDepthOfField = nil
    self.FreeCamRotating = false

    if self.Shared then
        self.Shared.FreeCamActive = false
        self.Shared.StopFreeCam = nil
        self.Shared.SetFreeCam = nil
        self.Shared.SetZoomUnlock = nil
        self.Shared.SetObjectRadar = nil
        self.Shared.RefreshObjectRadar = nil
        self.Shared.SetRealisticLighting = nil
    end
end

return Visuals
