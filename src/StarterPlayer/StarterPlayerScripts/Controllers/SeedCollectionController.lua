--[[
    SeedCollectionController.lua - UNIFIED NOTIFICATION SYSTEM
    Client-side controller for seed collection mechanics
    
    ✅ FIXES APPLIED:
    1. Removed premature "Seed Collected" notification on join
    2. Added seed icon to proximity notification
    3. Added rarity-based border color to proximity notification
    4. Added smooth fade-in animation for proximity notification
    5. Unified proximity and collection notifications (transforms on collect)
    6. Proper seed data lookup from Seeds.lua config
    
    Features:
    - Click-to-collect interface
    - Collection visual feedback with seed icons
    - Seed highlighting with rarity-based borders
    - Smooth notification transitions
    - Distance validation
]]

local SeedCollectionController = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Configuration
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = {
    Seeds = require(Shared.Config.Seeds),
}

-- Constants
local SEED_TAG = "SeedSpawn"
local COLLECTION_RANGE = 15
local HIGHLIGHT_RANGE = 20

-- Rarity Colors (matching Seeds.lua rarity system)
local RARITY_COLORS = {
    common = Color3.fromRGB(100, 200, 100),
    uncommon = Color3.fromRGB(100, 100, 255),
    rare = Color3.fromRGB(200, 100, 255),
    epic = Color3.fromRGB(255, 165, 0),
    legendary = Color3.fromRGB(255, 50, 50)
}

-- State
local player = Players.LocalPlayer
local character = nil
local humanoidRootPart = nil
local mouse = player:GetMouse()
local nearbySeeds = {}
local highlightedSeed = nil
local currentSeedData = nil -- ✅ Store current seed config
local isCollecting = false
local isNotificationShowing = false

-- RemoteEvents
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local CollectSeedEvent = RemoteEvents:WaitForChild("CollectSeed")
local SeedCollectedEvent = RemoteEvents:WaitForChild("SeedCollected")

-- UI
local playerGui = player:WaitForChild("PlayerGui")
local notificationGui = nil
local promptBorder = nil
local isTransitioning = false

-- ============================
-- INITIALIZATION
-- ============================

function SeedCollectionController.Init()
    print("🌱 Initializing Seed Collection Controller...")
    
    -- Setup character tracking
    SeedCollectionController._SetupCharacter()
    
    -- Setup seed tracking
    SeedCollectionController._SetupSeedTracking()
    
    -- Setup UI
    SeedCollectionController._CreateUI()
    
    -- Setup input handling
    SeedCollectionController._SetupInput()
    
    -- ✅ FIX: Only listen for server-confirmed collections (not auto-firing on join)
    SeedCollectedEvent.OnClientEvent:Connect(function(seedInfo)
        if seedInfo and seedInfo.seedId then
            SeedCollectionController._OnSeedCollected(seedInfo)
        end
    end)
    
    print("✅ Seed Collection Controller initialized")
end

function SeedCollectionController.Start()
    print("🌱 Starting Seed Collection Controller...")
    
    -- Start proximity detection loop
    task.spawn(function()
        SeedCollectionController._ProximityLoop()
    end)
    
    print("✅ Seed Collection Controller started")
end

-- ============================
-- CHARACTER SETUP
-- ============================

function SeedCollectionController._SetupCharacter()
    local function onCharacterAdded(char)
        character = char
        humanoidRootPart = char:WaitForChild("HumanoidRootPart")
    end
    
    if player.Character then
        onCharacterAdded(player.Character)
    end
    
    player.CharacterAdded:Connect(onCharacterAdded)
end

-- ============================
-- SEED TRACKING
-- ============================

function SeedCollectionController._SetupSeedTracking()
    -- Track existing seeds
    for _, seed in ipairs(CollectionService:GetTagged(SEED_TAG)) do
        SeedCollectionController._OnSeedAdded(seed)
    end
    
    -- Track new seeds
    CollectionService:GetInstanceAddedSignal(SEED_TAG):Connect(function(seed)
        SeedCollectionController._OnSeedAdded(seed)
    end)
    
    -- Cleanup removed seeds
    CollectionService:GetInstanceRemovedSignal(SEED_TAG):Connect(function(seed)
        SeedCollectionController._OnSeedRemoved(seed)
    end)
end

function SeedCollectionController._OnSeedAdded(seed: Instance)
    nearbySeeds[seed] = true
end

function SeedCollectionController._OnSeedRemoved(seed: Instance)
    nearbySeeds[seed] = nil
    
    if highlightedSeed == seed then
        highlightedSeed = nil
        currentSeedData = nil
        SeedCollectionController._HideNotification()
    end
end

-- ============================
-- PROXIMITY DETECTION
-- ============================

function SeedCollectionController._ProximityLoop()
    while true do
        task.wait(0.1) -- Check 10 times per second
        
        if not humanoidRootPart then
            task.wait(1)
            continue
        end
        
        local currentNearby = {}
        local closestSeed = nil
        local closestDistance = math.huge
        
        -- Check all seeds with the tag
        for _, seed in ipairs(CollectionService:GetTagged(SEED_TAG)) do
            if seed and seed.Parent then
                local seedPart = seed:FindFirstChild("SeedPart")
                
                if seedPart then
                    local distance = (humanoidRootPart.Position - seedPart.Position).Magnitude
                    
                    -- Track nearby seeds
                    if distance <= HIGHLIGHT_RANGE then
                        currentNearby[seed] = true
                        
                        -- Find closest for highlighting
                        if distance < closestDistance and distance <= COLLECTION_RANGE then
                            closestDistance = distance
                            closestSeed = seed
                        end
                    end
                end
            end
        end
        
        nearbySeeds = currentNearby
        
        -- Update highlighted seed
        if closestSeed ~= highlightedSeed then
            highlightedSeed = closestSeed
            
            if highlightedSeed then
                -- ✅ Get seed config for icon and rarity
                local seedId = highlightedSeed.Name
                currentSeedData = SeedCollectionController._GetSeedConfig(seedId)
                SeedCollectionController._ShowProximityNotification(highlightedSeed, currentSeedData)
            else
                currentSeedData = nil
                SeedCollectionController._HideNotification()
            end
        end
    end
end

-- ============================
-- SEED CONFIG LOOKUP
-- ============================

function SeedCollectionController._GetSeedConfig(seedId: string): any?
    for _, seed in ipairs(Config.Seeds.seeds) do
        if seed.id == seedId then
            return seed
        end
    end
    return nil
end

-- ============================
-- UI MANAGEMENT
-- ============================

function SeedCollectionController._CreateUI()
    -- Create unified notification UI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SeedNotificationUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 200
    screenGui.Parent = playerGui
    
    -- Main notification frame
    local notifFrame = Instance.new("Frame")
    notifFrame.Name = "NotificationFrame"
    notifFrame.Size = UDim2.new(0, 300, 0, 90)
    notifFrame.Position = UDim2.new(0.5, 0, 0.15, 0)
    notifFrame.AnchorPoint = Vector2.new(0.5, 0)
    notifFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    notifFrame.BackgroundTransparency = 1
    notifFrame.BorderSizePixel = 0
    notifFrame.Visible = false
    notifFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = notifFrame
    
    -- ✅ Glowing border with rarity color
    local border = Instance.new("UIStroke")
    border.Name = "RarityBorder"
    border.Thickness = 3
    border.Color = Color3.fromRGB(100, 200, 100) -- Default green
    border.Transparency = 0
    border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    border.Parent = notifFrame
    promptBorder = border
    
    -- Icon frame
    local iconFrame = Instance.new("Frame")
    iconFrame.Name = "IconFrame"
    iconFrame.Size = UDim2.new(0, 60, 0, 60)
    iconFrame.Position = UDim2.new(0, 15, 0.5, 0)
    iconFrame.AnchorPoint = Vector2.new(0, 0.5)
    iconFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    iconFrame.BorderSizePixel = 0
    iconFrame.Parent = notifFrame
    
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 10)
    iconCorner.Parent = iconFrame
    
    -- ✅ ImageLabel for seed icon
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0.85, 0, 0.85, 0)
    icon.Position = UDim2.new(0.5, 0, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = ""
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Parent = iconFrame
    
    -- Fallback emoji
    local emojiIcon = Instance.new("TextLabel")
    emojiIcon.Name = "EmojiIcon"
    emojiIcon.Size = UDim2.new(1, 0, 1, 0)
    emojiIcon.BackgroundTransparency = 1
    emojiIcon.Text = "🌱"
    emojiIcon.TextScaled = true
    emojiIcon.Visible = false
    emojiIcon.Parent = iconFrame
    
    -- Title label (main text)
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -90, 0, 30)
    titleLabel.Position = UDim2.new(0, 80, 0, 15)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 20
    titleLabel.Text = "Collect Seed"
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextYAlignment = Enum.TextYAlignment.Top
    titleLabel.Parent = notifFrame
    
    -- Detail label (seed name)
    local detailLabel = Instance.new("TextLabel")
    detailLabel.Name = "Detail"
    detailLabel.Size = UDim2.new(1, -90, 0, 22)
    detailLabel.Position = UDim2.new(0, 80, 0, 42)
    detailLabel.BackgroundTransparency = 1
    detailLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    detailLabel.Font = Enum.Font.Gotham
    detailLabel.TextSize = 16
    detailLabel.Text = ""
    detailLabel.TextXAlignment = Enum.TextXAlignment.Left
    detailLabel.TextYAlignment = Enum.TextYAlignment.Top
    detailLabel.Parent = notifFrame
    
    -- Rarity label
    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Name = "Rarity"
    rarityLabel.Size = UDim2.new(1, -90, 0, 18)
    rarityLabel.Position = UDim2.new(0, 80, 0, 65)
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    rarityLabel.Font = Enum.Font.GothamBold
    rarityLabel.TextSize = 14
    rarityLabel.Text = "COMMON"
    rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
    rarityLabel.TextYAlignment = Enum.TextYAlignment.Top
    rarityLabel.Parent = notifFrame
    
    notificationGui = notifFrame
    
    -- ✅ Start pulsing animation for border
    task.spawn(function()
        SeedCollectionController._PulseBorder()
    end)
end

-- ✅ Pulsing animation for border
function SeedCollectionController._PulseBorder()
    while true do
        if notificationGui.Visible and not isTransitioning then
            -- Pulse in
            local pulseIn = TweenService:Create(
                promptBorder,
                TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                { Thickness = 5 }
            )
            pulseIn:Play()
            pulseIn.Completed:Wait()
            
            -- Pulse out
            local pulseOut = TweenService:Create(
                promptBorder,
                TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                { Thickness = 3 }
            )
            pulseOut:Play()
            pulseOut.Completed:Wait()
        else
            task.wait(0.5)
        end
    end
end

-- ✅ Show proximity notification with fade-in
function SeedCollectionController._ShowProximityNotification(seedModel: Instance, seedConfig: any?)
    if not notificationGui or isNotificationShowing or isTransitioning then return end
    
    isNotificationShowing = true
    
    -- Get seed info
    local seedName = "Unknown Seed"
    local rarity = "common"
    local iconId = ""
    
    if seedConfig then
        seedName = seedConfig.name or seedModel.Name:gsub("_", " ")
        rarity = seedConfig.rarity or "common"
        iconId = seedConfig.icon or ""
    else
        seedName = seedModel.Name:gsub("_", " ")
    end
    
    local rarityLower = rarity:lower()
    
    -- Update UI elements
    local titleLabel = notificationGui:FindFirstChild("Title")
    local detailLabel = notificationGui:FindFirstChild("Detail")
    local rarityLabel = notificationGui:FindFirstChild("Rarity")
    local iconFrame = notificationGui:FindFirstChild("IconFrame")
    
    if titleLabel then
        titleLabel.Text = "Collect Seed"
    end
    
    if detailLabel then
        detailLabel.Text = seedName
    end
    
    if rarityLabel then
        rarityLabel.Text = rarity:upper()
        rarityLabel.TextColor3 = RARITY_COLORS[rarityLower] or Color3.fromRGB(100, 255, 100)
    end
    
    -- ✅ Update border color based on rarity
    if promptBorder and RARITY_COLORS[rarityLower] then
        promptBorder.Color = RARITY_COLORS[rarityLower]
    end
    
    -- ✅ Update seed icon
    if iconFrame then
        local icon = iconFrame:FindFirstChild("Icon")
        local emojiIcon = iconFrame:FindFirstChild("EmojiIcon")
        
        if icon and emojiIcon then
            if iconId and iconId ~= "" and iconId ~= "rbxassetid://0" then
                icon.Image = iconId
                icon.Visible = true
                emojiIcon.Visible = false
            else
                icon.Visible = false
                emojiIcon.Visible = true
            end
        end
        
        -- Color icon frame by rarity
        iconFrame.BackgroundColor3 = RARITY_COLORS[rarityLower] or Color3.fromRGB(60, 60, 60)
    end
    
    -- ✅ Fade in animation
    notificationGui.BackgroundTransparency = 1
    notificationGui.Position = UDim2.new(0.5, 0, 0.1, 0)
    notificationGui.Visible = true
    
    local fadeIn = TweenService:Create(
        notificationGui,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            BackgroundTransparency = 0.1,
            Position = UDim2.new(0.5, 0, 0.15, 0)
        }
    )
    fadeIn:Play()
end

-- ✅ Transform notification to "Collected" state
function SeedCollectionController._TransformToCollected(seedInfo: any)
    if not notificationGui or not notificationGui.Visible then return end
    
    isTransitioning = true
    
    local titleLabel = notificationGui:FindFirstChild("Title")
    local detailLabel = notificationGui:FindFirstChild("Detail")
    
    -- Scale up animation
    local scaleUp = TweenService:Create(
        notificationGui,
        TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 320, 0, 95)
        }
    )
    scaleUp:Play()
    scaleUp.Completed:Wait()
    
    -- Update text
    if titleLabel then
        titleLabel.Text = "✓ Seed Collected!"
    end
    
    if detailLabel then
        detailLabel.Text = seedInfo.seedName or "Seed"
    end
    
    -- Hold for 2 seconds
    task.wait(2)
    
    -- Fade out
    SeedCollectionController._HideNotification()
    isTransitioning = false
end

-- ✅ Hide notification with fade-out
function SeedCollectionController._HideNotification()
    if not notificationGui or not notificationGui.Visible then return end
    
    local fadeOut = TweenService:Create(
        notificationGui,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 0, 0.1, 0)
        }
    )
    fadeOut:Play()
    fadeOut.Completed:Wait()
    
    notificationGui.Visible = false
    notificationGui.Size = UDim2.new(0, 300, 0, 90) -- Reset size
    isNotificationShowing = false
end

-- ============================
-- INPUT HANDLING
-- ============================

function SeedCollectionController._SetupInput()
    -- Mouse click
    mouse.Button1Down:Connect(function()
        if highlightedSeed and not isCollecting then
            SeedCollectionController._TryCollect(highlightedSeed)
        end
    end)
    
    -- Mobile tap
    UserInputService.TouchTap:Connect(function(touchPositions, processed)
        if processed then return end
        if highlightedSeed and not isCollecting then
            SeedCollectionController._TryCollect(highlightedSeed)
        end
    end)
    
    -- Keyboard shortcut (E key)
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        
        if input.KeyCode == Enum.KeyCode.E then
            if highlightedSeed and not isCollecting then
                SeedCollectionController._TryCollect(highlightedSeed)
            end
        end
    end)
end

-- ============================
-- COLLECTION
-- ============================

function SeedCollectionController._TryCollect(seedModel: Instance)
    if isCollecting or isTransitioning then return end
    if not seedModel or not seedModel.Parent then return end
    
    isCollecting = true
    
    -- Play collection animation on client
    SeedCollectionController._PlayCollectionEffect(seedModel)
    
    -- Request collection from server
    CollectSeedEvent:FireServer(seedModel)
    
    -- Cooldown
    task.wait(0.5)
    isCollecting = false
end

-- ✅ Called when server confirms collection
function SeedCollectionController._OnSeedCollected(seedInfo: any)
    print("✅ Seed collected confirmed by server:", seedInfo.seedName)
    
    -- ✅ Transform the proximity notification into collection notification
    SeedCollectionController._TransformToCollected(seedInfo)
    
    -- Reset state
    highlightedSeed = nil
    currentSeedData = nil
end

function SeedCollectionController._PlayCollectionEffect(seedModel: Instance)
    local seedPart = seedModel:FindFirstChild("SeedPart")
    if not seedPart then return end
    
    -- Create upward tween
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local goal = {
        Position = seedPart.Position + Vector3.new(0, 5, 0),
        Size = Vector3.new(0.1, 0.1, 0.1)
    }
    
    local tween = TweenService:Create(seedPart, tweenInfo, goal)
    tween:Play()
    
    -- Fade out highlight
    local highlight = seedModel:FindFirstChildWhichIsA("Highlight")
    if highlight then
        local fadeTween = TweenService:Create(highlight, tweenInfo, {
            FillTransparency = 1,
            OutlineTransparency = 1
        })
        fadeTween:Play()
    end
end

-- ============================
-- CLEANUP
-- ============================

function SeedCollectionController.Cleanup()
    if notificationGui then
        notificationGui:Destroy()
    end
end

return SeedCollectionController