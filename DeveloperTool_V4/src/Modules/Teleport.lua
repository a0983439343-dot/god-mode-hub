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

    tab:CreateSection("Quick Teleport")
    tab:CreateButton({
        Name = "Center Ray Teleport",
        Callback = function()
            centerRayTeleport()
        end
    })

    tab:CreateButton({
        Name = "Teleport To Spawn",
        Callback = function()
            spawnTeleport()
        end
    })

    tab:CreateSection("XYZ")
    local xValue = 0
    local yValue = 10
    local zValue = 0

    tab:CreateInput({
        Name = "X",
        PlaceholderText = "X",
        RemoveTextAfterFocusLost = false,
        Callback = function(value)
            xValue = tonumber(value) or 0
        end
    })

    tab:CreateInput({
        Name = "Y",
        PlaceholderText = "Y",
        RemoveTextAfterFocusLost = false,
        Callback = function(value)
            yValue = tonumber(value) or 10
        end
    })

    tab:CreateInput({
        Name = "Z",
        PlaceholderText = "Z",
        RemoveTextAfterFocusLost = false,
        Callback = function(value)
            zValue = tonumber(value) or 0
        end
    })

    tab:CreateButton({
        Name = "Teleport To XYZ",
        Callback = function()
            teleportToCFrame(CFrame.new(xValue, yValue, zValue))
        end
    })

    tab:CreateSection("Bookmarks")
    tab:CreateInput({
        Name = "Bookmark Name",
        PlaceholderText = "Name",
        RemoveTextAfterFocusLost = false,
        Callback = function(value)
            self.PendingBookmark = tostring(value)
        end
    })

    tab:CreateButton({
        Name = "Save Current Position",
        Callback = function()
            local root = getRoot()
            if root and self.PendingBookmark and self.PendingBookmark ~= "" then
                self.Bookmarks[self.PendingBookmark] = root.CFrame
            end
        end
    })

    tab:CreateDropdown({
        Name = "Bookmark",
        Options = {},
        CurrentOption = {},
        MultipleOptions = false,
        Flag = "DeveloperBookmark",
        Callback = function(option)
            self.SelectedBookmark = option[1]
        end
    })

    tab:CreateButton({
        Name = "Refresh Bookmark List",
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
        Name = "Teleport To Bookmark",
        Callback = function()
            local cf = self.SelectedBookmark and self.Bookmarks[self.SelectedBookmark]
            if cf then
                teleportToCFrame(cf)
            end
        end
    })

    tab:CreateButton({
        Name = "Clear All Bookmarks",
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
