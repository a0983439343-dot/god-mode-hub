-- DeveloperTool V5 | ESP
local ESP = {
    Connections = {},
    PlayerConnections = {},
    Highlights = {},
    EnabledPlayers = false,
    EnabledNPCs = false,
    Alive = false,
    NPCColor = Color3.fromRGB(255, 120, 120),
    PlayerColor = Color3.fromRGB(80, 170, 255)
}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

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

local function isPlayerCharacter(model)
    return model and model:IsA("Model") and Players:GetPlayerFromCharacter(model) ~= nil
end

local function removeHighlight(self, target)
    local highlight = self.Highlights[target]
    if highlight then
        pcall(function()
            highlight:Destroy()
        end)
        self.Highlights[target] = nil
    end
end

local function hasHumanoidRoot(model)
    if not model or not model:IsA("Model") then
        return false
    end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    return humanoid ~= nil and root ~= nil and humanoid.Health > 0
end

local function createHighlight(self, target, color)
    if not self.Alive or not target or not target.Parent then
        return
    end
    if not target:IsDescendantOf(Workspace) then
        return
    end

    local old = self.Highlights[target]
    if old and old.Parent then
        old.FillColor = color
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "DeveloperESP"
    highlight.Adornee = target
    highlight.FillColor = color
    highlight.FillTransparency = 0.65
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = target

    self.Highlights[target] = highlight
end

local function refreshPlayer(self, player)
    if player == LocalPlayer then
        return
    end

    local character = player.Character
    if self.EnabledPlayers and character and hasHumanoidRoot(character) then
        createHighlight(self, character, self.PlayerColor)
    else
        if character then
            removeHighlight(self, character)
        end
    end
end

local function refreshNPC(self, model)
    if not self.EnabledNPCs or not model or not model:IsA("Model") then
        if model then
            removeHighlight(self, model)
        end
        return
    end

    if isPlayerCharacter(model) then
        return
    end

    if hasHumanoidRoot(model) then
        createHighlight(self, model, self.NPCColor)
    else
        removeHighlight(self, model)
    end
end

local function refreshAllPlayers(self)
    for _, player in ipairs(Players:GetPlayers()) do
        refreshPlayer(self, player)
    end
end

local function refreshAllNPCs(self)
    for _, item in ipairs(Workspace:GetDescendants()) do
        if not self.Alive or not self.EnabledNPCs then
            return
        end
        if item:IsA("Model") and hasHumanoidRoot(item) and not isPlayerCharacter(item) then
            refreshNPC(self, item)
        end
    end
end

local function clearCategory(self, predicate)
    for target in pairs(self.Highlights) do
        if predicate(target) then
            removeHighlight(self, target)
        end
    end
end

local function disconnectPlayerConnections(self, player)
    local list = self.PlayerConnections[player]
    if list then
        for _, connection in ipairs(list) do
            disconnect(connection)
        end
        self.PlayerConnections[player] = nil
    end
end

local function bindPlayer(self, player)
    disconnectPlayerConnections(self, player)
    if player == LocalPlayer then
        return
    end

    local list = {}
    self.PlayerConnections[player] = list

    table.insert(list, player.CharacterAdded:Connect(function(character)
        task.defer(function()
            if self.Alive and self.EnabledPlayers and character.Parent then
                refreshPlayer(self, player)
            end
        end)
    end))

    table.insert(list, player.CharacterRemoving:Connect(function(character)
        removeHighlight(self, character)
    end))
end

function ESP:Init(context)
    LocalPlayer = context.Player
    self.Alive = true

    local tab = context.Tab

    tab:CreateSection("玩家與 NPC 透視")
    tab:CreateToggle({
        Name = "玩家高亮",
        CurrentValue = false,
        Flag = "DeveloperV5PlayerESP",
        Callback = function(value)
            self.EnabledPlayers = value
            if value then
                refreshAllPlayers(self)
            else
                clearCategory(self, function(target)
                    return Players:GetPlayerFromCharacter(target) ~= nil
                end)
            end
        end
    })

    tab:CreateToggle({
        Name = "NPC 高亮",
        CurrentValue = false,
        Flag = "DeveloperV5NPCESP",
        Callback = function(value)
            self.EnabledNPCs = value
            if value then
                task.spawn(function()
                    if not self.Alive then
                        return
                    end
                    refreshAllNPCs(self)
                end)
            else
                clearCategory(self, function(target)
                    return target:IsA("Model") and Players:GetPlayerFromCharacter(target) == nil
                end)
            end
        end
    })

    tab:CreateButton({
        Name = "重新掃描場景",
        Callback = function()
            if self.EnabledPlayers then
                refreshAllPlayers(self)
            end
            if self.EnabledNPCs then
                task.spawn(function()
                    if self.Alive then
                        refreshAllNPCs(self)
                    end
                end)
            end
        end
    })

    addConnection(self, Players.PlayerAdded:Connect(function(player)
        bindPlayer(self, player)
        task.defer(function()
            if self.Alive and self.EnabledPlayers then
                refreshPlayer(self, player)
            end
        end)
    end))

    addConnection(self, Players.PlayerRemoving:Connect(function(player)
        if player.Character then
            removeHighlight(self, player.Character)
        end
        disconnectPlayerConnections(self, player)
    end))

    addConnection(self, Workspace.DescendantAdded:Connect(function(item)
        if not self.EnabledNPCs then
            return
        end

        local model = item:IsA("Model") and item or item:FindFirstAncestorOfClass("Model")
        if not model then
            return
        end

        task.defer(function()
            if self.Alive and model.Parent then
                refreshNPC(self, model)
            end
        end)
    end))

    addConnection(self, Workspace.DescendantRemoving:Connect(function(item)
        removeHighlight(self, item)
    end))

    for _, player in ipairs(Players:GetPlayers()) do
        bindPlayer(self, player)
    end

    tab:CreateSection("玩家傳送")
    local playerNames = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(playerNames, player.Name)
        end
    end
    table.sort(playerNames)

    local dropdown = tab:CreateDropdown({
        Name = "玩家",
        Options = playerNames,
        CurrentOption = playerNames[1] and {playerNames[1]} or {},
        MultipleOptions = false,
        Flag = "DeveloperV5PlayerTeleportTarget",
        Callback = function(option)
            self.SelectedPlayer = option and option[1] or nil
        end
    })
    self.SelectedPlayer = playerNames[1]

    tab:CreateButton({
        Name = "傳送到玩家",
        Callback = function()
            local target = self.SelectedPlayer and Players:FindFirstChild(self.SelectedPlayer)
            local targetRoot = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
            local ownRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot and ownRoot then
                ownRoot.CFrame = targetRoot.CFrame + Vector3.new(0, 4, 0)
            end
        end
    })

    tab:CreateButton({
        Name = "重新整理玩家列表",
        Callback = function()
            local names = {}
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    table.insert(names, player.Name)
                end
            end
            table.sort(names)
            pcall(function()
                tab:RefreshDropdown("DeveloperV5PlayerTeleportTarget", names)
            end)
        end
    })
end

function ESP:Cleanup()
    if not self.Alive then
        return
    end

    self.Alive = false
    self.EnabledPlayers = false
    self.EnabledNPCs = false

    for target in pairs(self.Highlights) do
        removeHighlight(self, target)
    end

    for player in pairs(self.PlayerConnections) do
        disconnectPlayerConnections(self, player)
    end

    for i = #self.Connections, 1, -1 do
        disconnect(self.Connections[i])
        self.Connections[i] = nil
    end

    table.clear(self.Highlights)
    table.clear(self.PlayerConnections)
end

return ESP
