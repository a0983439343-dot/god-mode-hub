-- DeveloperTool V5 | Teleport
local Teleport = {
    Connections = {},
    Bookmarks = {},
    CenterRayDistance = 1000,
    SelectedBookmark = nil,
    PendingBookmark = nil,
    Alive = false
}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer

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

local function isAlive()
    local humanoid = getCharacter() and getCharacter():FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function teleportToCFrame(cf)
    local character = getCharacter()
    local root = getRoot()
    if not character or not root or not isAlive() then
        return false
    end

    pcall(function()
        character:PivotTo(cf + Vector3.new(0, 4, 0))
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)
    return true
end

local function centerRayTeleport()
    local camera = Workspace.CurrentCamera
    if not camera then
        return false
    end

    local viewport = camera.ViewportSize
    local ray = camera:ViewportPointToRay(viewport.X * 0.5, viewport.Y * 0.5)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {getCharacter()}

    local result = Workspace:Raycast(ray.Origin, ray.Direction * Teleport.CenterRayDistance, params)
    if not result then
        return false
    end

    local position = result.Position + result.Normal * 3 + Vector3.yAxis * 2
    local look = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
    if look.Magnitude < 0.01 then
        look = Vector3.new(0, 0, -1)
    else
        look = look.Unit
    end

    return teleportToCFrame(CFrame.lookAt(position, position + look))
end

local function spawnTeleport()
    local spawn = Player.RespawnLocation
    if spawn and spawn:IsA("SpawnLocation") then
        return teleportToCFrame(spawn.CFrame)
    end

    local firstSpawn = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
    if firstSpawn then
        return teleportToCFrame(firstSpawn.CFrame)
    end

    return false
end

function Teleport:Init(context)
    Player = context.Player
    self.Alive = true

    local tab = context.Tab

    addConnection(self, UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not self.Alive then
            return
        end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.T then
            centerRayTeleport()
        end
    end))

    tab:CreateSection("快速傳送")
    tab:CreateButton({
        Name = "準心位置傳送",
        Callback = function()
            centerRayTeleport()
        end
    })

    tab:CreateButton({
        Name = "傳送到出生點",
        Callback = function()
            spawnTeleport()
        end
    })

    tab:CreateSection("座標傳送")
    local xValue, yValue, zValue = 0, 10, 0

    tab:CreateInput({
        Name = "X 座標",
        CurrentValue = "0",
        PlaceholderText = "輸入 X 座標",
        RemoveTextAfterFocusLost = false,
        Callback = function(value)
            local number = tonumber(value)
            if number then xValue = math.clamp(number, -1000000, 1000000) end
        end
    })

    tab:CreateInput({
        Name = "Y 座標",
        CurrentValue = "10",
        PlaceholderText = "輸入 Y 座標",
        RemoveTextAfterFocusLost = false,
        Callback = function(value)
            local number = tonumber(value)
            if number then yValue = math.clamp(number, -1000000, 1000000) end
        end
    })

    tab:CreateInput({
        Name = "Z 座標",
        CurrentValue = "0",
        PlaceholderText = "輸入 Z 座標",
        RemoveTextAfterFocusLost = false,
        Callback = function(value)
            local number = tonumber(value)
            if number then zValue = math.clamp(number, -1000000, 1000000) end
        end
    })

    tab:CreateButton({
        Name = "傳送到指定座標",
        Callback = function()
            teleportToCFrame(CFrame.new(xValue, yValue, zValue))
        end
    })

    tab:CreateSection("位置書籤")
    tab:CreateInput({
        Name = "書籤名稱",
        PlaceholderText = "輸入書籤名稱",
        RemoveTextAfterFocusLost = false,
        Callback = function(value)
            self.PendingBookmark = tostring(value):sub(1, 40)
        end
    })

    tab:CreateButton({
        Name = "儲存目前位置",
        Callback = function()
            local root = getRoot()
            local name = self.PendingBookmark
            if root and name and name ~= "" then
                self.Bookmarks[name] = root.CFrame
            end
        end
    })

    tab:CreateDropdown({
        Name = "選擇書籤",
        Options = {},
        CurrentOption = {},
        MultipleOptions = false,
        Flag = "DeveloperV5Bookmark",
        Callback = function(option)
            self.SelectedBookmark = option and option[1] or nil
        end
    })

    tab:CreateButton({
        Name = "重新整理書籤列表",
        Callback = function()
            local names = {}
            for name in pairs(self.Bookmarks) do
                table.insert(names, name)
            end
            table.sort(names)
            pcall(function()
                tab:RefreshDropdown("DeveloperV5Bookmark", names)
            end)
        end
    })

    tab:CreateButton({
        Name = "傳送到書籤",
        Callback = function()
            local cf = self.SelectedBookmark and self.Bookmarks[self.SelectedBookmark]
            if cf then
                teleportToCFrame(cf)
            end
        end
    })

    tab:CreateButton({
        Name = "清除所有書籤",
        Callback = function()
            table.clear(self.Bookmarks)
            self.SelectedBookmark = nil
            pcall(function()
                tab:RefreshDropdown("DeveloperV5Bookmark", {})
            end)
        end
    })
end

function Teleport:Cleanup()
    if not self.Alive then
        return
    end

    self.Alive = false
    for i = #self.Connections, 1, -1 do
        disconnect(self.Connections[i])
        self.Connections[i] = nil
    end

    table.clear(self.Bookmarks)
    self.PendingBookmark = nil
    self.SelectedBookmark = nil
end

return Teleport
