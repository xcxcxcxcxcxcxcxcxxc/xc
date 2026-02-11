-- LinoriaLib UI Integration Script
-- Combines auto-collect ammo/health and void spam teleport features

-- Bypass AC (runs first)
pcall(function()
    local replicatedFirst = game:GetService("ReplicatedFirst")
    for _, child in pairs(replicatedFirst:GetChildren()) do
        if child:IsA("LocalScript") then child.Enabled = false child:Destroy() end
    end
    local analytics = replicatedFirst:FindFirstChild("AnalyticsPipelineController")
    if analytics then analytics:Destroy() end
end)

local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Window = Library:CreateWindow({
    Title = 'claude code baby',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
    Main = Window:AddTab('Main'),
    Settings = Window:AddTab('Settings'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

-- ============================================
-- AUTO COLLECT SECTION
-- ============================================
local AutoCollectBox = Tabs.Main:AddLeftGroupbox('Auto Collect')

-- Variables for auto collect
local collectHealth = false
local collectAmmo = false
local collectConnection = nil

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Function to start/stop auto collect
local function updateAutoCollect()
    -- Disconnect existing connection if any
    if collectConnection then
        collectConnection:Disconnect()
        collectConnection = nil
    end
    
    -- Only create connection if at least one is enabled
    if collectHealth or collectAmmo then
        collectConnection = RunService.Heartbeat:Connect(function()
            local character = Players.LocalPlayer.Character
            if not character then return end
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local humanoid = character:FindFirstChild("Humanoid")
            local needsHealth = humanoid and humanoid.Health < humanoid.MaxHealth
            
            -- Cache workspace children to avoid repeated calls
            local workspaceChildren = workspace:GetChildren()
            for i = 1, #workspaceChildren do
                local obj = workspaceChildren[i]
                if obj.Name == "_drop" and obj:IsA("BasePart") then
                    if (collectHealth and obj:FindFirstChild("Health") and needsHealth) or 
                       (collectAmmo and obj:FindFirstChild("Ammo")) then
                        firetouchinterest(hrp, obj, 0)
                        firetouchinterest(hrp, obj, 1)
                    end
                end
            end
        end)
    end
end

AutoCollectBox:AddToggle('CollectHealth', {
    Text = 'Auto Collect Health',
    Default = false,
    Tooltip = 'Automatically collect health drops',
    Callback = function(Value)
        collectHealth = Value
        updateAutoCollect()
    end
})

AutoCollectBox:AddLabel('Keybind'):AddKeyPicker('HealthKeybind', {
    Default = 'None',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'Health collect keybind',
    NoUI = false,
    Callback = function(Value)
        collectHealth = Value
        updateAutoCollect()
    end
})

AutoCollectBox:AddDivider()

AutoCollectBox:AddToggle('CollectAmmo', {
    Text = 'Auto Collect Ammo',
    Default = false,
    Tooltip = 'Automatically collect ammo drops',
    Callback = function(Value)
        collectAmmo = Value
        updateAutoCollect()
    end
})

AutoCollectBox:AddLabel('Keybind'):AddKeyPicker('AmmoKeybind', {
    Default = 'None',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'Ammo collect keybind',
    NoUI = false,
    Callback = function(Value)
        collectAmmo = Value
        updateAutoCollect()
    end
})

AutoCollectBox:AddDivider()
AutoCollectBox:AddLabel('Note: Both can be enabled at once!')

-- ============================================
-- AIMBOT SECTION
-- ============================================
local AimbotBox = Tabs.Main:AddLeftGroupbox('Aimbot')

-- Aimbot variables
local aimbotEnabled = false
local aimbotSmoothness = 50
local aimbotConnection = nil
local aimbotTarget = "Head" -- Head or HumanoidRootPart
local UserInputService = game:GetService("UserInputService")

-- Function to get the closest player
local function getClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local localPlayer = Players.LocalPlayer
    local camera = workspace.CurrentCamera
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local character = player.Character
            local humanoid = character:FindFirstChild("Humanoid")
            local targetPart = character:FindFirstChild(aimbotTarget)
            
            if humanoid and humanoid.Health > 0 and targetPart then
                local screenPoint, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                
                if onScreen then
                    local mouseLocation = UserInputService:GetMouseLocation()
                    local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - mouseLocation).Magnitude
                    
                    if distance < shortestDistance then
                        closestPlayer = player
                        shortestDistance = distance
                    end
                end
            end
        end
    end
    
    return closestPlayer
end

-- Function to aim at target
local function aimAtTarget()
    if not aimbotEnabled then return end
    
    local target = getClosestPlayer()
    if not target or not target.Character then return end
    
    local targetPart = target.Character:FindFirstChild(aimbotTarget)
    if not targetPart then return end
    
    local camera = workspace.CurrentCamera
    local targetPosition = targetPart.Position
    
    -- Calculate smoothness (inverse relationship - lower smoothness = faster aim)
    local smoothFactor = (101 - aimbotSmoothness) / 100
    
    -- Get current camera CFrame and target CFrame
    local currentCFrame = camera.CFrame
    local targetCFrame = CFrame.new(camera.CFrame.Position, targetPosition)
    
    -- Lerp between current and target based on smoothness
    camera.CFrame = currentCFrame:Lerp(targetCFrame, smoothFactor)
end

-- Start/stop aimbot
local function updateAimbot()
    if aimbotConnection then
        aimbotConnection:Disconnect()
        aimbotConnection = nil
    end
    
    if aimbotEnabled then
        aimbotConnection = RunService.RenderStepped:Connect(function()
            aimAtTarget()
        end)
    end
end

AimbotBox:AddToggle('AimbotEnabled', {
    Text = 'Enable Aimbot',
    Default = false,
    Tooltip = 'Toggle aimbot on/off',
    Callback = function(Value)
        aimbotEnabled = Value
        updateAimbot()
    end
})

AimbotBox:AddLabel('Keybind'):AddKeyPicker('AimbotKeybind', {
    Default = 'H',
    SyncToggleState = true,
    Mode = 'Hold',
    Text = 'Aimbot keybind',
    NoUI = false,
    Callback = function(Value)
        aimbotEnabled = Value
        updateAimbot()
    end
})

AimbotBox:AddDivider()

AimbotBox:AddSlider('AimbotSmoothness', {
    Text = 'Smoothness',
    Default = 50,
    Min = 1,
    Max = 100,
    Rounding = 0,
    Compact = false,
    Tooltip = '1 = Very fast, 100 = Very slow/smooth',
    Callback = function(Value)
        aimbotSmoothness = Value
    end
})

AimbotBox:AddDivider()

AimbotBox:AddDropdown('AimbotTarget', {
    Values = { 'Head', 'HumanoidRootPart' },
    Default = 1, -- Head
    Multi = false,
    Text = 'Target Part',
    Tooltip = 'Choose where to aim (Head or Torso)',
    Callback = function(Value)
        aimbotTarget = Value
    end
})

AimbotBox:AddDivider()
AimbotBox:AddLabel('Hold keybind to aim at\nclosest enemy to crosshair', true)

-- ============================================
-- ESP SECTION
-- ============================================
local ESPBox = Tabs.Main:AddRightGroupbox('ESP')

-- ESP variables
local espEnabled = false
local showBoxes = true
local showNames = true
local showHealth = true
local showDistance = true
local showTracers = false
local espColor = Color3.fromRGB(255, 0, 0)
local espConnections = {}
local espObjects = {}
local espUpdateRate = 2 -- Update every N frames for performance

-- Function to create ESP for a player
local function createESP(player)
    if player == Players.LocalPlayer then return end
    
    local espFolder = Instance.new("Folder")
    espFolder.Name = "ESP_" .. player.Name
    espFolder.Parent = game.CoreGui
    
    espObjects[player] = espFolder
    
    -- Box ESP
    local boxESP = Drawing.new("Square")
    boxESP.Visible = false
    boxESP.Color = espColor
    boxESP.Thickness = 2
    boxESP.Transparency = 1
    boxESP.Filled = false
    
    -- Name ESP
    local nameESP = Drawing.new("Text")
    nameESP.Visible = false
    nameESP.Color = espColor
    nameESP.Size = 18
    nameESP.Center = true
    nameESP.Outline = true
    nameESP.Font = 2
    nameESP.Text = player.Name
    
    -- Health ESP
    local healthESP = Drawing.new("Text")
    healthESP.Visible = false
    healthESP.Color = Color3.fromRGB(0, 255, 0)
    healthESP.Size = 16
    healthESP.Center = true
    healthESP.Outline = true
    healthESP.Font = 2
    
    -- Distance ESP
    local distanceESP = Drawing.new("Text")
    distanceESP.Visible = false
    distanceESP.Color = Color3.fromRGB(255, 255, 255)
    distanceESP.Size = 14
    distanceESP.Center = true
    distanceESP.Outline = true
    distanceESP.Font = 2
    
    -- Tracer ESP
    local tracerESP = Drawing.new("Line")
    tracerESP.Visible = false
    tracerESP.Color = espColor
    tracerESP.Thickness = 1
    tracerESP.Transparency = 1
    
    -- Health Bar
    local healthBarOutline = Drawing.new("Square")
    healthBarOutline.Visible = false
    healthBarOutline.Color = Color3.fromRGB(0, 0, 0)
    healthBarOutline.Thickness = 1
    healthBarOutline.Transparency = 1
    healthBarOutline.Filled = false
    
    local healthBarFill = Drawing.new("Square")
    healthBarFill.Visible = false
    healthBarFill.Color = Color3.fromRGB(0, 255, 0)
    healthBarFill.Thickness = 1
    healthBarFill.Transparency = 0.5
    healthBarFill.Filled = true
    
    local frameCount = 0
    
    local function updateESP()
        frameCount = frameCount + 1
        if frameCount % espUpdateRate ~= 0 then return end
        
        if not espEnabled then
            boxESP.Visible = false
            nameESP.Visible = false
            healthESP.Visible = false
            distanceESP.Visible = false
            tracerESP.Visible = false
            healthBarOutline.Visible = false
            healthBarFill.Visible = false
            return
        end
        
        local character = player.Character
        if not character then
            boxESP.Visible = false
            nameESP.Visible = false
            healthESP.Visible = false
            distanceESP.Visible = false
            tracerESP.Visible = false
            healthBarOutline.Visible = false
            healthBarFill.Visible = false
            return
        end
        
        local humanoid = character:FindFirstChild("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        
        if not rootPart or not humanoid or humanoid.Health <= 0 then
            boxESP.Visible = false
            nameESP.Visible = false
            healthESP.Visible = false
            distanceESP.Visible = false
            tracerESP.Visible = false
            healthBarOutline.Visible = false
            healthBarFill.Visible = false
            return
        end
        
        local camera = workspace.CurrentCamera
        local vector, onScreen = camera:WorldToViewportPoint(rootPart.Position)
        
        if onScreen then
            local head = character:FindFirstChild("Head")
            local headPos = head and head.Position or rootPart.Position + Vector3.new(0, 2, 0)
            local legPos = rootPart.Position - Vector3.new(0, 3, 0)
            
            local topVector = camera:WorldToViewportPoint(headPos)
            local bottomVector = camera:WorldToViewportPoint(legPos)
            
            local height = math.abs(topVector.Y - bottomVector.Y)
            local width = height / 2
            
            -- Update Box ESP
            if showBoxes then
                boxESP.Size = Vector2.new(width, height)
                boxESP.Position = Vector2.new(vector.X - width / 2, vector.Y - height / 2)
                boxESP.Color = espColor
                boxESP.Visible = true
            else
                boxESP.Visible = false
            end
            
            -- Update Name ESP
            if showNames then
                nameESP.Position = Vector2.new(vector.X, topVector.Y - 20)
                nameESP.Color = espColor
                nameESP.Text = player.Name
                nameESP.Visible = true
            else
                nameESP.Visible = false
            end
            
            -- Calculate distance
            local distance = (Players.LocalPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
            
            -- Update Health ESP
            if showHealth then
                local healthPercent = math.floor((humanoid.Health / humanoid.MaxHealth) * 100)
                healthESP.Position = Vector2.new(vector.X, bottomVector.Y + 5)
                healthESP.Text = healthPercent .. "%"
                
                -- Color based on health
                if healthPercent > 75 then
                    healthESP.Color = Color3.fromRGB(0, 255, 0)
                elseif healthPercent > 50 then
                    healthESP.Color = Color3.fromRGB(255, 255, 0)
                elseif healthPercent > 25 then
                    healthESP.Color = Color3.fromRGB(255, 165, 0)
                else
                    healthESP.Color = Color3.fromRGB(255, 0, 0)
                end
                healthESP.Visible = true
                
                -- Health bar
                healthBarOutline.Size = Vector2.new(4, height)
                healthBarOutline.Position = Vector2.new(vector.X - width / 2 - 6, vector.Y - height / 2)
                healthBarOutline.Visible = true
                
                local healthHeight = height * (humanoid.Health / humanoid.MaxHealth)
                healthBarFill.Size = Vector2.new(2, healthHeight)
                healthBarFill.Position = Vector2.new(vector.X - width / 2 - 5, vector.Y + height / 2 - healthHeight)
                healthBarFill.Color = healthESP.Color
                healthBarFill.Visible = true
            else
                healthESP.Visible = false
                healthBarOutline.Visible = false
                healthBarFill.Visible = false
            end
            
            -- Update Distance ESP
            if showDistance then
                distanceESP.Position = Vector2.new(vector.X, bottomVector.Y + 20)
                distanceESP.Text = math.floor(distance) .. " studs"
                distanceESP.Visible = true
            else
                distanceESP.Visible = false
            end
            
            -- Update Tracer ESP
            if showTracers then
                local screenSize = camera.ViewportSize
                tracerESP.From = Vector2.new(screenSize.X / 2, screenSize.Y)
                tracerESP.To = Vector2.new(vector.X, vector.Y)
                tracerESP.Color = espColor
                tracerESP.Visible = true
            else
                tracerESP.Visible = false
            end
        else
            boxESP.Visible = false
            nameESP.Visible = false
            healthESP.Visible = false
            distanceESP.Visible = false
            tracerESP.Visible = false
            healthBarOutline.Visible = false
            healthBarFill.Visible = false
        end
    end
    
    local connection = RunService.Heartbeat:Connect(updateESP)
    espConnections[player] = {
        connection = connection,
        drawings = {boxESP, nameESP, healthESP, distanceESP, tracerESP, healthBarOutline, healthBarFill}
    }
end

-- Function to remove ESP for a player
local function removeESP(player)
    if espConnections[player] then
        espConnections[player].connection:Disconnect()
        for _, drawing in pairs(espConnections[player].drawings) do
            drawing:Remove()
        end
        espConnections[player] = nil
    end
    
    if espObjects[player] then
        espObjects[player]:Destroy()
        espObjects[player] = nil
    end
end

-- Function to update all ESP
local function updateAllESP()
    for player, _ in pairs(espConnections) do
        if not player or not player.Parent then
            removeESP(player)
        end
    end
end

-- Initialize ESP for existing players
local function initializeESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            createESP(player)
        end
    end
end

-- ESP Toggles and Settings
ESPBox:AddToggle('ESPEnabled', {
    Text = 'Enable ESP',
    Default = false,
    Tooltip = 'Toggle ESP on/off',
    Callback = function(Value)
        espEnabled = Value
        if espEnabled then
            initializeESP()
        else
            for player, _ in pairs(espConnections) do
                removeESP(player)
            end
        end
    end
})

ESPBox:AddLabel('Keybind'):AddKeyPicker('ESPKeybind', {
    Default = 'None',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'ESP keybind',
    NoUI = false,
    Callback = function(Value)
        espEnabled = Value
        if espEnabled then
            initializeESP()
        else
            for player, _ in pairs(espConnections) do
                removeESP(player)
            end
        end
    end
})

ESPBox:AddDivider()

ESPBox:AddToggle('ShowBoxes', {
    Text = 'Show Boxes',
    Default = true,
    Tooltip = 'Show box around players',
    Callback = function(Value)
        showBoxes = Value
    end
})

ESPBox:AddToggle('ShowNames', {
    Text = 'Show Names',
    Default = true,
    Tooltip = 'Show player names',
    Callback = function(Value)
        showNames = Value
    end
})

ESPBox:AddToggle('ShowHealth', {
    Text = 'Show Health',
    Default = true,
    Tooltip = 'Show player health percentage and bar',
    Callback = function(Value)
        showHealth = Value
    end
})

ESPBox:AddToggle('ShowDistance', {
    Text = 'Show Distance',
    Default = true,
    Tooltip = 'Show distance to players',
    Callback = function(Value)
        showDistance = Value
    end
})

ESPBox:AddToggle('ShowTracers', {
    Text = 'Show Tracers',
    Default = false,
    Tooltip = 'Show lines to players',
    Callback = function(Value)
        showTracers = Value
    end
})

ESPBox:AddDivider()

ESPBox:AddLabel('ESP Color'):AddColorPicker('ESPColor', {
    Default = Color3.fromRGB(255, 0, 0),
    Title = 'ESP Color',
    Callback = function(Value)
        espColor = Value
    end
})

ESPBox:AddDivider()
ESPBox:AddLabel('ESP shows through walls\nand updates in real-time', true)

-- Player events
Players.PlayerAdded:Connect(function(player)
    if espEnabled and player ~= Players.LocalPlayer then
        task.wait(1)
        createESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

-- ============================================
-- VOID SPAM TELEPORT SECTION
-- ============================================
local TeleportBox = Tabs.Main:AddRightGroupbox('Void Spam Teleport')

-- Variables for teleport
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local isTeleporting = false
local teleportLoop = nil
local minDistance = 500
local maxDistance = 10000
local teleportDelay = 0.1

-- Function to perform a single teleport
local function teleportOnce()
    if not character or not humanoidRootPart then 
        return 
    end
    
    local currentPosition = humanoidRootPart.Position
    local randomAngle = math.random() * math.pi * 2
    local randomDistance = math.random(minDistance, maxDistance)
    
    local newX = currentPosition.X + math.cos(randomAngle) * randomDistance
    local newZ = currentPosition.Z + math.sin(randomAngle) * randomDistance
    local newY = currentPosition.Y + 100
    
    humanoidRootPart.CFrame = CFrame.new(newX, newY, newZ)
end

-- Toggle teleport function
local function toggleTeleportMode(value)
    isTeleporting = value
    
    if isTeleporting then
        print("Starting continuous teleport...")
        print("Distance range: " .. minDistance .. " to " .. maxDistance .. " studs")
        print("Teleport delay: " .. teleportDelay .. " seconds")
        
        teleportLoop = task.spawn(function()
            while isTeleporting do
                teleportOnce()
                task.wait(teleportDelay)
            end
        end)
    else
        print("Stopping teleport...")
        isTeleporting = false
    end
end

TeleportBox:AddToggle('VoidSpam', {
    Text = 'Enable Void Spam',
    Default = false,
    Tooltip = 'Toggle continuous random teleportation',
    Callback = function(Value)
        toggleTeleportMode(Value)
    end
})

TeleportBox:AddLabel('Keybind'):AddKeyPicker('VoidSpamKeybind', {
    Default = 'P',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'Void spam keybind',
    NoUI = false,
    Callback = function(Value)
        toggleTeleportMode(Value)
    end
})

TeleportBox:AddDivider()

TeleportBox:AddSlider('MinDistance', {
    Text = 'Min Distance',
    Default = 500,
    Min = 100,
    Max = 5000,
    Rounding = 0,
    Compact = false,
    Callback = function(Value)
        minDistance = Value
        -- Make sure min doesn't exceed max
        if minDistance > maxDistance then
            Options.MaxDistance:SetValue(minDistance)
        end
    end
})

TeleportBox:AddSlider('MaxDistance', {
    Text = 'Max Distance',
    Default = 10000,
    Min = 500,
    Max = 20000,
    Rounding = 0,
    Compact = false,
    Callback = function(Value)
        maxDistance = Value
        -- Make sure max doesn't go below min
        if maxDistance < minDistance then
            Options.MinDistance:SetValue(maxDistance)
        end
    end
})

TeleportBox:AddSlider('TeleportDelay', {
    Text = 'Teleport Delay (seconds)',
    Default = 0.1,
    Min = 0.01,
    Max = 2,
    Rounding = 2,
    Compact = false,
    Callback = function(Value)
        teleportDelay = Value
    end
})

TeleportBox:AddDivider()
TeleportBox:AddLabel('Teleports to random locations\nwithin the distance range', true)

-- Handle character respawns
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")
    
    -- If teleporting was active, restart it
    if isTeleporting then
        local wasActive = isTeleporting
        toggleTeleportMode(false)
        task.wait(0.5)
        if wasActive then
            toggleTeleportMode(true)
        end
    end
end)

-- ============================================
-- LIBRARY SETTINGS
-- ============================================

local showWatermark = true

Library:SetWatermarkVisibility(showWatermark)

local FrameTimer = tick()
local FrameCounter = 0
local FPS = 60

local WatermarkConnection = RunService.Heartbeat:Connect(function()
    if not showWatermark then return end
    
    FrameCounter = FrameCounter + 1
    
    if (tick() - FrameTimer) >= 1 then
        FPS = FrameCounter
        FrameTimer = tick()
        FrameCounter = 0
        
        Library:SetWatermark(('XC Script Hub | %s fps | %s ms'):format(
            math.floor(FPS),
            math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())
        ))
    end
end)

Library.KeybindFrame.Visible = true

Library:OnUnload(function()
    WatermarkConnection:Disconnect()
    
    -- Clean up auto collect
    if collectConnection then
        collectConnection:Disconnect()
    end
    
    -- Clean up aimbot
    if aimbotConnection then
        aimbotConnection:Disconnect()
    end
    
    -- Clean up ESP
    for player, _ in pairs(espConnections) do
        removeESP(player)
    end
    
    -- Clean up teleport
    if isTeleporting then
        toggleTeleportMode(false)
    end
    
    print('Unloaded!')
    Library.Unloaded = true
end)

-- ============================================
-- SETTINGS TAB
-- ============================================
local SettingsGroup = Tabs.Settings:AddLeftGroupbox('Performance & Display')

SettingsGroup:AddToggle('ShowWatermark', {
    Text = 'Show FPS/Ping Watermark',
    Default = true,
    Tooltip = 'Toggle FPS and ping display',
    Callback = function(Value)
        showWatermark = Value
        Library:SetWatermarkVisibility(Value)
    end
})

SettingsGroup:AddDivider()

SettingsGroup:AddSlider('ESPUpdateRate', {
    Text = 'ESP Update Rate',
    Default = 2,
    Min = 1,
    Max = 5,
    Rounding = 0,
    Tooltip = 'Higher = Better performance, Lower = Smoother ESP (1-5 frames)',
    Callback = function(Value)
        espUpdateRate = Value
    end
})

SettingsGroup:AddDivider()

SettingsGroup:AddLabel('Keybind Modes Info:', true)
SettingsGroup:AddLabel('Toggle: Press once to turn on/off\nHold: Only active while holding\nAlways: Always active', true)

local KeybindInfoGroup = Tabs.Settings:AddRightGroupbox('Keybind Info')
KeybindInfoGroup:AddLabel('Right-click any keybind to\nchange its mode:', true)
KeybindInfoGroup:AddDivider()
KeybindInfoGroup:AddLabel('• Toggle - Press to turn on/off')
KeybindInfoGroup:AddLabel('• Hold - Only active while held')
KeybindInfoGroup:AddLabel('• Always - Always active')

-- ============================================
-- UI SETTINGS TAB
-- ============================================
local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')

MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { 
    Default = 'End', 
    NoUI = true, 
    Text = 'Menu keybind' 
})

Library.ToggleKeybind = Options.MenuKeybind

-- Theme and Save Manager setup
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

ThemeManager:SetFolder('XCScriptHub')
SaveManager:SetFolder('XCScriptHub/configs')

SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])

SaveManager:LoadAutoloadConfig()

print('XC Script Hub loaded successfully!')
print('Press END to toggle menu')
