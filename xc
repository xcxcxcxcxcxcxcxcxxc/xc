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
    Title = 'XC Script Hub',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
    Main = Window:AddTab('Main'),
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
        collectConnection = RunService.RenderStepped:Connect(function()
            local character = Players.LocalPlayer.Character
            if not character then return end
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local humanoid = character:FindFirstChild("Humanoid")
            local needsHealth = humanoid and humanoid.Health < humanoid.MaxHealth
            
            for _, obj in workspace:GetChildren() do
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
-- CHARM CHANGER SECTION
-- ============================================
local CharmBox = Tabs.Main:AddLeftGroupbox('Charm Changer')

-- List of all available charms
local charmList = {
    "Unranked",
    "Bronze 1", "Bronze 2", "Bronze 3",
    "Silver 1", "Silver 2", "Silver 3",
    "Gold 1", "Gold 2", "Gold 3",
    "Platinum 1", "Platinum 2", "Platinum 3",
    "Diamond 1", "Diamond 2", "Diamond 3",
    "Onyx 1", "Onyx 2", "Onyx 3",
    "Nemesis", "Archnemesis"
}

-- Current selected charms
local season0Charm = "Unranked"
local season1Charm = "Unranked"

-- Charm script functions
local function completelyHide(model)
    for _, child in pairs(model:GetDescendants()) do
        if child:IsA("BasePart") then
            child.Transparency = 1
            child.CanCollide = false
            child.Size = Vector3.new(0, 0, 0)
        end
        if child:IsA("Decal") or child:IsA("Texture") then
            child.Transparency = 1
        end
        if child:IsA("SurfaceGui") or child:IsA("BillboardGui") then
            child.Enabled = false
        end
        if child:IsA("ParticleEmitter") or child:IsA("Beam") then
            child.Enabled = false
        end
    end
    
    if model:IsA("BasePart") then
        model.Transparency = 1
        model.CanCollide = false
        model.Size = Vector3.new(0, 0, 0)
    end
end

local function makeVisible(model)
    for _, child in pairs(model:GetDescendants()) do
        if child:IsA("BasePart") then
            child.Transparency = 0
        end
        if child:IsA("Decal") or child:IsA("Texture") then
            child.Transparency = 0
        end
        if child:IsA("SurfaceGui") or child:IsA("BillboardGui") then
            child.Enabled = true
        end
        if child:IsA("ParticleEmitter") or child:IsA("Beam") then
            child.Enabled = true
        end
    end
end

local function findRankInExtra(seasonFolder, rankName)
    if seasonFolder.Extra and seasonFolder.Extra:FindFirstChild(rankName) then
        return seasonFolder.Extra:FindFirstChild(rankName)
    end
    return nil
end

local function applyRank(seasonFolder, rankName, seasonNumber)
    -- Force hide problematic parts
    if seasonFolder:FindFirstChild("Rank") then
        completelyHide(seasonFolder.Rank)
        seasonFolder.Rank:Destroy()
    end
    
    if seasonFolder:FindFirstChild("Primary") then
        completelyHide(seasonFolder.Primary)
    end
    
    if seasonFolder.Extra and seasonFolder.Extra:FindFirstChild("Unranked") then
        completelyHide(seasonFolder.Extra.Unranked)
    end
    
    -- Check for Rank in all descendants
    for _, child in pairs(seasonFolder:GetDescendants()) do
        if child.Name == "Rank" and child ~= seasonFolder:FindFirstChild("Rank") then
            completelyHide(child)
            child:Destroy()
        end
    end
    
    -- Keep Hook visible
    if seasonFolder:FindFirstChild("Hook") then
        makeVisible(seasonFolder.Hook)
    end
    
    -- Remove old clones
    for _, child in pairs(seasonFolder:GetChildren()) do
        if child.Name:find("_Active") then
            child:Destroy()
        end
    end
    
    -- Hide all default charms except Hook
    for _, child in pairs(seasonFolder:GetChildren()) do
        if child.Name ~= "Extra" and child.Name ~= "Hook" then
            completelyHide(child)
        end
    end
    
    -- Hide Unranked in Extra
    if seasonFolder.Extra and seasonFolder.Extra:FindFirstChild("Unranked") then
        completelyHide(seasonFolder.Extra.Unranked)
    end
    
    -- Find and clone desired rank
    local desiredRank = findRankInExtra(seasonFolder, rankName)
    
    if desiredRank then
        local rankClone = desiredRank:Clone()
        rankClone.Name = rankName .. "_Active"
        rankClone.Parent = seasonFolder
        makeVisible(rankClone)
        print("[Charm Mod] Applied " .. rankName .. " to Season " .. seasonNumber)
    else
        warn("[Charm Mod] Rank not found: " .. rankName)
    end
end

local function unlockSeason(seasonFolder)
    for _, child in pairs(seasonFolder:GetDescendants()) do
        if child:IsA("BoolValue") then
            if child.Name:lower():find("lock") and not child.Name:lower():find("unlock") then
                child.Value = false
            elseif child.Name:lower():find("unlock") then
                child.Value = true
            end
        end
        if child:IsA("IntValue") then
            if child.Name:lower():find("lock") then
                child.Value = 0
            elseif child.Name:lower():find("unlock") then
                child.Value = 1
            end
        end
    end
end

local function applySeason0Charm()
    pcall(function()
        local season0 = Players.LocalPlayer.PlayerScripts.Assets.Charms["Season 0"]
        unlockSeason(season0)
        applyRank(season0, season0Charm, 0)
    end)
end

local function applySeason1Charm()
    pcall(function()
        local season1 = Players.LocalPlayer.PlayerScripts.Assets.Charms["Season 1"]
        unlockSeason(season1)
        applyRank(season1, season1Charm, 1)
    end)
end

-- Season 0 Dropdown
CharmBox:AddLabel('Season 0 Charms:')
CharmBox:AddDropdown('Season0Charm', {
    Values = charmList,
    Default = 1, -- Unranked
    Multi = false,
    Text = 'Season 0 Rank',
    Tooltip = 'Select your Season 0 charm',
    Callback = function(Value)
        season0Charm = Value
        applySeason0Charm()
    end
})

CharmBox:AddDivider()

-- Season 1 Dropdown
CharmBox:AddLabel('Season 1 Charms:')
CharmBox:AddDropdown('Season1Charm', {
    Values = charmList,
    Default = 1, -- Unranked
    Multi = false,
    Text = 'Season 1 Rank',
    Tooltip = 'Select your Season 1 charm',
    Callback = function(Value)
        season1Charm = Value
        applySeason1Charm()
    end
})

CharmBox:AddDivider()

CharmBox:AddButton({
    Text = 'Apply All Charms',
    Func = function()
        applySeason0Charm()
        task.wait(0.1)
        applySeason1Charm()
        print('[Charm Mod] All charms applied!')
    end,
    Tooltip = 'Manually reapply both charms'
})

CharmBox:AddLabel('Note: Changes are client-side\nonly (only you see them)', true)

-- Auto-reapply on character spawn
Players.LocalPlayer.CharacterAdded:Connect(function()
    task.wait(2)
    applySeason0Charm()
    task.wait(0.1)
    applySeason1Charm()
    print('[Charm Mod] Charms reapplied after spawn')
end)

-- Monitor for Rank cubes reappearing
task.spawn(function()
    while task.wait(10) do
        pcall(function()
            local season0 = Players.LocalPlayer.PlayerScripts.Assets.Charms["Season 0"]
            if season0:FindFirstChild("Rank") then
                season0.Rank:Destroy()
            end
        end)
        
        pcall(function()
            local season1 = Players.LocalPlayer.PlayerScripts.Assets.Charms["Season 1"]
            if season1:FindFirstChild("Rank") then
                season1.Rank:Destroy()
            end
        end)
    end
end)

-- ============================================
-- AIMBOT SECTION
-- ============================================
local AimbotBox = Tabs.Main:AddLeftGroupbox('Aimbot')

-- Aimbot variables
local aimbotEnabled = false
local aimbotSmoothness = 50
local aimbotConnection = nil
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
            local head = character:FindFirstChild("Head")
            
            if humanoid and humanoid.Health > 0 and head then
                local screenPoint, onScreen = camera:WorldToViewportPoint(head.Position)
                
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
    
    local targetHead = target.Character:FindFirstChild("Head")
    if not targetHead then return end
    
    local camera = workspace.CurrentCamera
    local targetPosition = targetHead.Position
    
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
AimbotBox:AddLabel('Hold keybind to aim at\nclosest enemy to crosshair', true)

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

Library:SetWatermarkVisibility(true)

local FrameTimer = tick()
local FrameCounter = 0
local FPS = 60

local WatermarkConnection = RunService.RenderStepped:Connect(function()
    FrameCounter += 1
    
    if (tick() - FrameTimer) >= 1 then
        FPS = FrameCounter
        FrameTimer = tick()
        FrameCounter = 0
    end
    
    Library:SetWatermark(('XC Script Hub | %s fps | %s ms'):format(
        math.floor(FPS),
        math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())
    ))
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
    
    -- Clean up teleport
    if isTeleporting then
        toggleTeleportMode(false)
    end
    
    print('Unloaded!')
    Library.Unloaded = true
end)

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
