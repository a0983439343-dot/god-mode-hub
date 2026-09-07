local Teleport = {
    Connections = {},
    Bookmarks = {},
    CenterRayDistance = 1000
}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer

local function addConnection(self, connection)
    table.insert(self.Connections, connection)
    return connection
end

local function getRoot()
    local character = Player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function teleportToCFrame(cf)
    local root = getRoot()
    if root then
        root.CFrame = cf + Vector3.new(0, 4, 0)
    end
end

local function centerRayTeleport()
    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end
    local viewport = camera.ViewportSize
    local center = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
    local ray = camera:ViewportPointToRay(center.X, center.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {Player.Character}
    local result = Workspace:Raycast(ray.Origin, ray.Direction * Teleport.CenterRayDistance, params)
    if result then
        teleportToCFrame(CFrame.new(result.Position, result.Position + camera.CFrame.LookVector))
    end
end

local function spawnTeleport()
    local location = Player.RespawnLocation
    if location and location:IsA("BasePart") then
        teleportToCFrame(location.CFrame)
        return
    end
    local root = getRoot()
    if root then
        local spawn = Workspace:FindFirstChildOfClass("SpawnLocation")
        if spawn then
            teleportToCFrame(spawn.CFrame)
        end
    end
end

function Teleport:Init(context)
    Player = context.Player
    local tab = context.Tab

    addConnection(self, UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end
        if input.KeyCode == Enum.KeyCode.T then
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
    local xValue = 0
    local yValue = 10
    local zValue = 0

    tab:CreateInput({
        Name = "X 座標",
        PlaceholderText = "輸入 X 座標",
        RemoveTextAfterFocusLost = false,
        Callback = function(value)
            xValue = tonumber(value) or 0
        end
    })

    tab:CreateInput({
        Name = "Y 座標",
        PlaceholderText = "輸入 Y 座標",
        RemoveTextAfterFocusLost = false,
        Callback = function(value)
            yValue = tonumber(value) or 10
        end
    })

    tab:CreateInput({
        Name = "Z 座標",
        PlaceholderText = "輸入 Z 座標",
        RemoveTextAfterFocusLost = false,
        Callback = function(value)
            zValue = tonumber(value) or 0
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
            self.PendingBookmark = tostring(value)
        end
    })

    tab:CreateButton({
        Name = "儲存目前位置",
        Callback = function()
            local root = getRoot()
            if root and self.PendingBookmark and self.PendingBookmark ~= "" then
                self.Bookmarks[self.PendingBookmark] = root.CFrame
            end
        end
    })

    tab:CreateDropdown({
        Name = "選擇書籤",
        Options = {},
        CurrentOption = {},
        MultipleOptions = false,
        Flag = "DeveloperBookmark",
        Callback = function(option)
            self.SelectedBookmark = option[1]
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
            context.Tab:RefreshDropdown("DeveloperBookmark", names)
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
            context.Tab:RefreshDropdown("DeveloperBookmark", {})
        end
    })
end

function Teleport:Cleanup()
    for i = #self.Connections, 1, -1 do
        pcall(function()
            self.Connections[i]:Disconnect()
        end)
        self.Connections[i] = nil
    end
    table.clear(self.Bookmarks)
end

return Teleport
