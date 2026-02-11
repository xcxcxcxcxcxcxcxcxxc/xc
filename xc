-- bypasses ac (very simple script)
pcall(function()
    local replicatedFirst = game:GetService("ReplicatedFirst")
    for _, child in pairs(replicatedFirst:GetChildren()) do
        if child:IsA("LocalScript") then child.Enabled = false child:Destroy() end
    end
    local analytics = replicatedFirst:FindFirstChild("AnalyticsPipelineController")
    if analytics then analytics:Destroy() end
end)

-- Roblox Script with LinoriaLib UI
-- Features: Aimbot, ESP, Triggerbot, FOV Circle

local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Settings
local Settings = {
    Aimbot = {
        Enabled = false,
        TeamCheck = true,
        VisibleCheck = true,
        TargetPart = "Head",
        Smoothness = 1,
        FOV = 100,
        ShowFOV = true,
        Keybind = Enum.KeyCode.E
    },
    ESP = {
        Enabled = false,
        TeamCheck = true,
        ShowNames = true,
        ShowBoxes = true,
        ShowHealth = true,
        ShowDistance = true,
        TextSize = 14,
        BoxColor = Color3.fromRGB(255, 255, 255),
        NameColor = Color3.fromRGB(255, 255, 255),
        HealthColor = Color3.fromRGB(0, 255, 0)
    },
    Triggerbot = {
        Enabled = false,
        Delay = 0.1,
        TeamCheck = true
    }
}

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.NumSides = 50
FOVCircle.Radius = Settings.Aimbot.FOV
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Visible = Settings.Aimbot.ShowFOV
FOVCircle.Filled = false
FOVCircle.Transparency = 1

-- ESP Storage
local ESPObjects = {}

-- Utility Functions
local function IsTeamMate(player)
    if not Settings.Aimbot.TeamCheck and not Settings.ESP.TeamCheck then return false end
    return player.Team == LocalPlayer.Team
end

local function IsVisible(targetPart)
    if not Settings.Aimbot.VisibleCheck then return true end
    
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * 500
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    
    local result = Workspace:Raycast(origin, direction, raycastParams)
    
    if result then
        local hitPart = result.Instance
        return hitPart:IsDescendantOf(targetPart.Parent)
    end
    
    return false
end

local function GetClosestPlayerToCursor()
    local closestPlayer = nil
    local shortestDistance = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if Settings.Aimbot.TeamCheck and IsTeamMate(player) then continue end
            
            local character = player.Character
            local targetPart = character:FindFirstChild(Settings.Aimbot.TargetPart) or character:FindFirstChild("HumanoidRootPart")
            
            if targetPart then
                if Settings.Aimbot.VisibleCheck and not IsVisible(targetPart) then continue end
                
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                
                if onScreen then
                    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
                    local targetPos = Vector2.new(screenPos.X, screenPos.Y)
                    local distance = (mousePos - targetPos).Magnitude
                    
                    if distance < Settings.Aimbot.FOV and distance < shortestDistance then
                        closestPlayer = player
                        shortestDistance = distance
                    end
                end
            end
        end
    end
    
    return closestPlayer
end

-- Aimbot Function
local function Aimbot()
    if not Settings.Aimbot.Enabled then return end
    
    local target = GetClosestPlayerToCursor()
    
    if target and target.Character then
        local targetPart = target.Character:FindFirstChild(Settings.Aimbot.TargetPart) or target.Character:FindFirstChild("HumanoidRootPart")
        
        if targetPart then
            local targetPos = Camera:WorldToViewportPoint(targetPart.Position)
            local mousePos = Vector2.new(Mouse.X, Mouse.Y)
            local targetVector = Vector2.new(targetPos.X, targetPos.Y)
            
            local smoothness = Settings.Aimbot.Smoothness
            local newPos = mousePos:Lerp(targetVector, 1 / smoothness)
            
            mousemoverel((newPos.X - mousePos.X), (newPos.Y - mousePos.Y))
        end
    end
end

-- ESP Functions
local function CreateESP(player)
    if ESPObjects[player] then return end
    
    local drawings = {}
    
    local function newDrawing(class)
        local drawing = Drawing.new(class)
        table.insert(drawings, drawing)
        return drawing
    end
    
    local box = newDrawing("Square")
    box.Thickness = 2
    box.Filled = false
    box.Color = Color3.fromRGB(255, 255, 255)
    box.Visible = false
    box.ZIndex = 2
    
    local nameLabel = newDrawing("Text")
    nameLabel.Size = 14
    nameLabel.Center = true
    nameLabel.Outline = true
    nameLabel.Color = Color3.fromRGB(255, 255, 255)
    nameLabel.Visible = false
    nameLabel.ZIndex = 2
    
    local healthLabel = newDrawing("Text")
    healthLabel.Size = 14
    healthLabel.Center = true
    healthLabel.Outline = true
    healthLabel.Color = Color3.fromRGB(0, 255, 0)
    healthLabel.Visible = false
    healthLabel.ZIndex = 2
    
    local distanceLabel = newDrawing("Text")
    distanceLabel.Size = 14
    distanceLabel.Center = true
    distanceLabel.Outline = true
    distanceLabel.Color = Color3.fromRGB(255, 255, 255)
    distanceLabel.Visible = false
    distanceLabel.ZIndex = 2
    
    local healthBarOutline = newDrawing("Square")
    healthBarOutline.Thickness = 3
    healthBarOutline.Filled = true
    healthBarOutline.Color = Color3.fromRGB(0, 0, 0)
    healthBarOutline.Visible = false
    healthBarOutline.ZIndex = 1
    
    local healthBar = newDrawing("Square")
    healthBar.Thickness = 1
    healthBar.Filled = true
    healthBar.Color = Color3.fromRGB(0, 255, 0)
    healthBar.Visible = false
    healthBar.ZIndex = 2
    
    ESPObjects[player] = {
        drawings = drawings,
        box = box,
        name = nameLabel,
        health = healthLabel,
        distance = distanceLabel,
        healthBarOutline = healthBarOutline,
        healthBar = healthBar
    }
end

local function RemoveESP(player)
    local esp = ESPObjects[player]
    if esp then
        for _, drawing in ipairs(esp.drawings) do
            drawing:Remove()
        end
        ESPObjects[player] = nil
    end
end

local function UpdateESP()
    for player, esp in pairs(ESPObjects) do
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid") and character:FindFirstChild("Head") then
            local humanoid = character.Humanoid
            local rootPart = character.HumanoidRootPart
            local head = character.Head
            
            if humanoid.Health <= 0 then
                for _, drawing in ipairs(esp.drawings) do
                    drawing.Visible = false
                end
                continue
            end
            
            if Settings.ESP.TeamCheck and player.Team == LocalPlayer.Team then
                for _, drawing in ipairs(esp.drawings) do
                    drawing.Visible = false
                end
                continue
            end
            
            local rootPos, rootVis = Camera:WorldToViewportPoint(rootPart.Position)
            local headPos = Camera:WorldToViewportPoint(head.Position)
            local legPos = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))
            
            if rootVis then
                local height = (headPos.Y - legPos.Y)
                local width = height / 2
                
                -- Box
                if Settings.ESP.Enabled and Settings.ESP.ShowBoxes then
                    esp.box.Size = Vector2.new(width, height)
                    esp.box.Position = Vector2.new(rootPos.X - width / 2, rootPos.Y - height / 2)
                    esp.box.Visible = true
                else
                    esp.box.Visible = false
                end
                
                -- Name
                if Settings.ESP.Enabled and Settings.ESP.ShowNames then
                    esp.name.Text = player.Name
                    esp.name.Position = Vector2.new(rootPos.X, headPos.Y - 20)
                    esp.name.Size = Settings.ESP.TextSize
                    esp.name.Visible = true
                else
                    esp.name.Visible = false
                end
                
                -- Health
                if Settings.ESP.Enabled and Settings.ESP.ShowHealth then
                    local healthPercent = math.floor((humanoid.Health / humanoid.MaxHealth) * 100)
                    esp.health.Text = tostring(healthPercent) .. "%"
                    esp.health.Position = Vector2.new(rootPos.X, legPos.Y + 5)
                    esp.health.Size = Settings.ESP.TextSize
                    
                    if healthPercent > 75 then
                        esp.health.Color = Color3.fromRGB(0, 255, 0)
                        esp.healthBar.Color = Color3.fromRGB(0, 255, 0)
                    elseif healthPercent > 50 then
                        esp.health.Color = Color3.fromRGB(255, 255, 0)
                        esp.healthBar.Color = Color3.fromRGB(255, 255, 0)
                    elseif healthPercent > 25 then
                        esp.health.Color = Color3.fromRGB(255, 165, 0)
                        esp.healthBar.Color = Color3.fromRGB(255, 165, 0)
                    else
                        esp.health.Color = Color3.fromRGB(255, 0, 0)
                        esp.healthBar.Color = Color3.fromRGB(255, 0, 0)
                    end
                    
                    esp.health.Visible = true
                    
                    -- Health Bar
                    local barHeight = height * (healthPercent / 100)
                    esp.healthBarOutline.Size = Vector2.new(4, height + 2)
                    esp.healthBarOutline.Position = Vector2.new(rootPos.X - width / 2 - 7, rootPos.Y - height / 2 - 1)
                    esp.healthBar.Size = Vector2.new(2, barHeight)
                    esp.healthBar.Position = Vector2.new(rootPos.X - width / 2 - 6, rootPos.Y + height / 2 - barHeight)
                    esp.healthBarOutline.Visible = true
                    esp.healthBar.Visible = true
                else
                    esp.health.Visible = false
                    esp.healthBarOutline.Visible = false
                    esp.healthBar.Visible = false
                end
                
                -- Distance
                if Settings.ESP.Enabled and Settings.ESP.ShowDistance and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local distance = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude)
                    esp.distance.Text = tostring(distance) .. " studs"
                    esp.distance.Position = Vector2.new(rootPos.X, legPos.Y + 20)
                    esp.distance.Size = Settings.ESP.TextSize
                    esp.distance.Visible = true
                else
                    esp.distance.Visible = false
                end
            else
                for _, drawing in ipairs(esp.drawings) do
                    drawing.Visible = false
                end
            end
        else
            for _, drawing in ipairs(esp.drawings) do
                drawing.Visible = false
            end
        end
    end
end

-- Triggerbot
local triggerDebounce = false
local function Triggerbot()
    if not Settings.Triggerbot.Enabled or triggerDebounce then return end
    
    local target = Mouse.Target
    if target and target.Parent:FindFirstChild("Humanoid") then
        local player = Players:GetPlayerFromCharacter(target.Parent)
        if player and player ~= LocalPlayer then
            if Settings.Triggerbot.TeamCheck and IsTeamMate(player) then return end
            
            triggerDebounce = true
            mouse1click()
            wait(Settings.Triggerbot.Delay)
            triggerDebounce = false
        end
    end
end

-- Create ESP for all players
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESP(player)
    end
end

-- Player events
Players.PlayerAdded:Connect(function(player)
    CreateESP(player)
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

-- Create UI
local Window = Library:CreateWindow({
    Title = 'zzzzz',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
    Combat = Window:AddTab('Combat'),
    Visuals = Window:AddTab('Visuals'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

-- Combat Tab
local AimbotBox = Tabs.Combat:AddLeftGroupbox('Aimbot')

AimbotBox:AddToggle('AimbotEnabled', {
    Text = 'Enable Aimbot',
    Default = false,
    Tooltip = 'Toggle aimbot on/off',
    Callback = function(Value)
        Settings.Aimbot.Enabled = Value
    end
})

AimbotBox:AddToggle('AimbotTeamCheck', {
    Text = 'Team Check',
    Default = true,
    Tooltip = 'Don\'t aim at teammates',
    Callback = function(Value)
        Settings.Aimbot.TeamCheck = Value
    end
})

AimbotBox:AddToggle('AimbotVisibleCheck', {
    Text = 'Visible Check',
    Default = true,
    Tooltip = 'Only aim at visible players',
    Callback = function(Value)
        Settings.Aimbot.VisibleCheck = Value
    end
})

AimbotBox:AddDropdown('AimbotTargetPart', {
    Values = {'Head', 'HumanoidRootPart', 'UpperTorso', 'LowerTorso'},
    Default = 1,
    Multi = false,
    Text = 'Target Part',
    Tooltip = 'Which body part to aim at',
    Callback = function(Value)
        Settings.Aimbot.TargetPart = Value
    end
})

AimbotBox:AddSlider('AimbotSmoothness', {
    Text = 'Smoothness',
    Default = 1,
    Min = 1,
    Max = 10,
    Rounding = 1,
    Compact = false,
    Callback = function(Value)
        Settings.Aimbot.Smoothness = Value
    end
})

AimbotBox:AddSlider('AimbotFOV', {
    Text = 'FOV',
    Default = 100,
    Min = 10,
    Max = 500,
    Rounding = 0,
    Compact = false,
    Callback = function(Value)
        Settings.Aimbot.FOV = Value
        FOVCircle.Radius = Value
    end
})

AimbotBox:AddToggle('ShowFOV', {
    Text = 'Show FOV Circle',
    Default = true,
    Tooltip = 'Display FOV circle',
    Callback = function(Value)
        Settings.Aimbot.ShowFOV = Value
        FOVCircle.Visible = Value
    end
})

local TriggerbotBox = Tabs.Combat:AddRightGroupbox('Triggerbot')

TriggerbotBox:AddToggle('TriggerbotEnabled', {
    Text = 'Enable Triggerbot',
    Default = false,
    Tooltip = 'Auto-shoot when hovering over enemies',
    Callback = function(Value)
        Settings.Triggerbot.Enabled = Value
    end
})

TriggerbotBox:AddToggle('TriggerbotTeamCheck', {
    Text = 'Team Check',
    Default = true,
    Tooltip = 'Don\'t shoot teammates',
    Callback = function(Value)
        Settings.Triggerbot.TeamCheck = Value
    end
})

TriggerbotBox:AddSlider('TriggerbotDelay', {
    Text = 'Delay (seconds)',
    Default = 0.1,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Compact = false,
    Callback = function(Value)
        Settings.Triggerbot.Delay = Value
    end
})

-- Visuals Tab
local ESPBox = Tabs.Visuals:AddLeftGroupbox('ESP')

ESPBox:AddToggle('ESPEnabled', {
    Text = 'Enable ESP',
    Default = false,
    Tooltip = 'Toggle ESP on/off',
    Callback = function(Value)
        Settings.ESP.Enabled = Value
    end
})

ESPBox:AddToggle('ESPTeamCheck', {
    Text = 'Team Check',
    Default = true,
    Tooltip = 'Don\'t show ESP for teammates',
    Callback = function(Value)
        Settings.ESP.TeamCheck = Value
    end
})

ESPBox:AddToggle('ESPNames', {
    Text = 'Show Names',
    Default = true,
    Tooltip = 'Display player names',
    Callback = function(Value)
        Settings.ESP.ShowNames = Value
    end
})

ESPBox:AddToggle('ESPBoxes', {
    Text = 'Show Boxes',
    Default = true,
    Tooltip = 'Display bounding boxes',
    Callback = function(Value)
        Settings.ESP.ShowBoxes = Value
    end
})

ESPBox:AddToggle('ESPHealth', {
    Text = 'Show Health',
    Default = true,
    Tooltip = 'Display health bars',
    Callback = function(Value)
        Settings.ESP.ShowHealth = Value
    end
})

ESPBox:AddToggle('ESPDistance', {
    Text = 'Show Distance',
    Default = true,
    Tooltip = 'Display distance in studs',
    Callback = function(Value)
        Settings.ESP.ShowDistance = Value
    end
})

ESPBox:AddSlider('ESPTextSize', {
    Text = 'Text Size',
    Default = 14,
    Min = 10,
    Max = 24,
    Rounding = 0,
    Compact = false,
    Callback = function(Value)
        Settings.ESP.TextSize = Value
    end
})

-- UI Settings
local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')

MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu keybind' })

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()

SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

ThemeManager:SetFolder('zzzzzz')
SaveManager:SetFolder('zzzzzz/specific-game')

SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])

SaveManager:LoadAutoloadConfig()

-- Main Loop
RunService.RenderStepped:Connect(function()
    -- Update FOV Circle position
    FOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y)
    
    -- Run Aimbot
    Aimbot()
    
    -- Update ESP
    UpdateESP()
    
    -- Run Triggerbot
    Triggerbot()
end)
