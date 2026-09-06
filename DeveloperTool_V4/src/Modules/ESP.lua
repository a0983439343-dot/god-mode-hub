local ESP = {
    Connections = {},
    Highlights = {},
    EnabledPlayers = false,
    EnabledNPCs = false,
    HighlightColor = Color3.fromRGB(255, 170, 0)
}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local function addConnection(self, connection)
    table.insert(self.Connections, connection)
    return connection
end

local function removeHighlight(key)
    local item = ESP.Highlights[key]
    if item then
        pcall(function()
            item:Destroy()
        end)
        ESP.Highlights[key] = nil
    end
end

local function createHighlight(key, target, fillColor)
    if not target or not target:IsDescendantOf(Workspace) then
        return
    end
    removeHighlight(key)
    local highlight = Instance.new("Highlight")
    highlight.Name = "DeveloperESP"
    highlight.Adornee = target
    highlight.FillColor = fillColor or ESP.HighlightColor
    highlight.FillTransparency = 0.65
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = target
    ESP.Highlights[key] = highlight
end

local function scanPlayers()
    if not ESP.EnabledPlayers then
        return
    end
    task.spawn(function()
        local list = Players:GetPlayers()
        for i, player in ipairs(list) do
            if i % 100 == 0 then
                task.wait()
            end
            if player ~= LocalPlayer and player.Character then
                createHighlight("Player_" .. player.UserId, player.Character, Color3.fromRGB(80, 170, 255))
            end
        end
    end)
end

local function scanNPCs()
    if not ESP.EnabledNPCs then
        return
    end
    task.spawn(function()
        local descendants = Workspace:GetDescendants()
        for i, item in ipairs(descendants) do
            if i % 100 == 0 then
                task.wait()
            end
            if item:IsA("Model") and not Players:GetPlayerFromCharacter(item) then
                local humanoid = item:FindFirstChildOfClass("Humanoid")
                local root = item:FindFirstChild("HumanoidRootPart") or item.PrimaryPart
                if humanoid and root then
                    createHighlight("NPC_" .. item:GetDebugId(), item, Color3.fromRGB(255, 120, 120))
                end
            end
        end
    end)
end

local function clearPlayers()
    for key in pairs(ESP.Highlights) do
        if string.sub(key, 1, 7) == "Player_" then
            removeHighlight(key)
        end
    end
end

local function clearNPCs()
    for key in pairs(ESP.Highlights) do
        if string.sub(key, 1, 4) == "NPC_" then
            removeHighlight(key)
        end
    end
end

function ESP:Init(context)
    LocalPlayer = context.Player
    local tab = context.Tab

    tab:CreateSection("ESP")
    tab:CreateToggle({
        Name = "Player Highlight",
        CurrentValue = false,
        Flag = "DeveloperPlayerESP",
        Callback = function(value)
            self.EnabledPlayers = value
            if value then
                scanPlayers()
            else
                clearPlayers()
            end
        end
    })

    tab:CreateToggle({
        Name = "NPC Highlight",
        CurrentValue = false,
        Flag = "DeveloperNPCESP",
        Callback = function(value)
            self.EnabledNPCs = value
            if value then
                scanNPCs()
            else
                clearNPCs()
            end
        end
    })

    tab:CreateButton({
        Name = "Rescan Workspace",
        Callback = function()
            if self.EnabledPlayers then
                scanPlayers()
            end
            if self.EnabledNPCs then
                scanNPCs()
            end
        end
    })

    tab:CreateSection("Player Teleport")
    local playerNames = {}
    for i, player in ipairs(Players:GetPlayers()) do
        if i % 100 == 0 then
            task.wait()
        end
        if player ~= LocalPlayer then
            table.insert(playerNames, player.Name)
        end
    end

    local dropdown = tab:CreateDropdown({
        Name = "Player",
        Options = playerNames,
        CurrentOption = playerNames[1] and {playerNames[1]} or {},
        MultipleOptions = false,
        Flag = "DeveloperPlayerTeleportTarget",
        Callback = function()
        end
    })

    tab:CreateButton({
        Name = "Teleport To Player",
        Callback = function()
            local selected = dropdown.CurrentOption
            local targetName = selected and selected[1]
            if not targetName then
                return
            end
            local target = Players:FindFirstChild(targetName)
            local character = target and target.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local ownRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root and ownRoot then
                ownRoot.CFrame = root.CFrame + Vector3.new(0, 4, 0)
            end
        end
    })

    addConnection(self, Players.PlayerAdded:Connect(function(player)
        if self.EnabledPlayers then
            addConnection(self, player.CharacterAdded:Connect(function(character)
                task.wait(0.25)
                createHighlight("Player_" .. player.UserId, character, Color3.fromRGB(80, 170, 255))
            end))
        end
    end))

    addConnection(self, Players.PlayerRemoving:Connect(function(player)
        removeHighlight("Player_" .. player.UserId)
    end))

    addConnection(self, RunService.Heartbeat:Connect(function()
        if self.EnabledNPCs then
            return
        end
    end))
end

function ESP:Cleanup()
    for key in pairs(self.Highlights) do
        removeHighlight(key)
    end
    for i = #self.Connections, 1, -1 do
        pcall(function()
            self.Connections[i]:Disconnect()
        end)
        self.Connections[i] = nil
    end
end

return ESP
