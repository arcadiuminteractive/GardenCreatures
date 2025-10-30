--[[
    SeedCollectionController.lua - IMPROVED VERSION
    Client-side controller for seed collection mechanics
    
    ✅ IMPROVEMENTS:
    1. Fixed premature "Seed Collected" notification on join
    2. Added seed icon display in notifications
    3. Added rarity-colored glowing border to collection prompt
    4. Added rarity text to notifications
    
    Features:
    - Click-to-collect interface
    - Collection visual feedback with seed icons
    - Seed highlighting with rarity-based borders
    - Collection notifications with rarity indicators
    - Distance validation
]]

local SeedCollectionController = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Constants
local SEED_TAG = "SeedSpawn"
local COLLECTION_RANGE = 15
local HIGHLIGHT_RANGE = 20

-- Rarity Colors
local RARITY_COLORS = {
    common = Color3.fromRGB(100, 200, 100),
    uncommon = Color3.fromRGB(100, 100, 255),
    rare = Color3.fromRGB(200, 100, 255),
    legendary = Color3.fromRGB(255, 50, 50)
}

-- State
local player = Players.LocalPlayer
local character = nil
local humanoidRootPart = nil
local mouse = player:GetMouse()
local nearbySeeds = {}
local highlightedSeed = nil
local isCollecting = false

-- RemoteEvents
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local CollectSeedEvent = RemoteEvents:WaitForChild("CollectSeed")
local SeedCollectedEvent = RemoteEvents:WaitForChild("SeedCollected")

-- UI
local playerGui = player:WaitForChild("PlayerGui")
local seedPrompt = nil
local notificationGui = nil
local promptBorder = nil -- ✅ NEW: Reference to the glowing border

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
    
    -- ✅ FIX: Listen for collection success from server
    -- Only triggers when server actually confirms a collection
    SeedCollectedEvent.OnClientEvent:Connect(function(seedInfo)
        SeedCollectionController._OnSeedCollected(seedInfo)
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
    -- Add to tracking (could add visual effects here)
    nearbySeeds[seed] = true
end

function SeedCollectionController._OnSeedRemoved(seed: Instance)
    nearbySeeds[seed] = nil
    
    if highlightedSeed == seed then
        highlightedSeed = nil
        SeedCollectionController._HidePrompt()
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
                SeedCollectionController._ShowPrompt(highlightedSeed)
            else
                SeedCollectionController._HidePrompt()
            end
        end
    end
end

-- ============================
-- UI MANAGEMENT
-- ============================

function SeedCollectionController._CreateUI()
    -- Create seed collection prompt
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SeedCollectionUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    local prompt = Instance.new("Frame")
    prompt.Name = "CollectionPrompt"
    prompt.Size = UDim2.new(0, 200, 0, 60)
    prompt.Position = UDim2.new(0.5, 0, 0.8, 0)
    prompt.AnchorPoint = Vector2.new(0.5, 0.5)
    prompt.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    prompt.BackgroundTransparency = 0.2
    prompt.BorderSizePixel = 0
    prompt.Visible = false
    prompt.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = prompt
    
    -- ✅ NEW: Create glowing border using UIStroke
    local border = Instance.new("UIStroke")
    border.Name = "RarityBorder"
    border.Thickness = 3
    border.Color = Color3.fromRGB(100, 255, 100) -- Default green
    border.Transparency = 0
    border.Parent = prompt
    promptBorder = border
    
    -- ✅ NEW: Add pulsing glow effect
    task.spawn(function()
        while true do
            if prompt.Visible then
                -- Pulse the border
                local pulseIn = TweenService:Create(border, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Thickness = 5
                })
                pulseIn:Play()
                pulseIn.Completed:Wait()
                
                local pulseOut = TweenService:Create(border, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Thickness = 3
                })
                pulseOut:Play()
                pulseOut.Completed:Wait()
            else
                task.wait(0.5)
            end
        end
    end)
    
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 40, 0, 40)
    icon.Position = UDim2.new(0, 10, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.BackgroundTransparency = 1
    icon.Text = "🌱"
    icon.TextScaled = true
    icon.Parent = prompt
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 50, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 18
    label.Text = "Click to collect!"
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = prompt
    
    seedPrompt = prompt
    
    -- ✅ Create notification system
    SeedCollectionController._CreateNotificationUI(screenGui)
end

function SeedCollectionController._CreateNotificationUI(screenGui: ScreenGui)
    local notifFrame = Instance.new("Frame")
    notifFrame.Name = "NotificationFrame"
    notifFrame.Size = UDim2.new(0, 300, 0, 80)
    notifFrame.Position = UDim2.new(0.5, 0, 0.1, 0)
    notifFrame.AnchorPoint = Vector2.new(0.5, 0)
    notifFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    notifFrame.BackgroundTransparency = 1 -- Hidden by default
    notifFrame.BorderSizePixel = 0
    notifFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = notifFrame
    
    -- ✅ NEW: Icon now uses ImageLabel for seed icons
    local iconFrame = Instance.new("Frame")
    iconFrame.Name = "IconFrame"
    iconFrame.Size = UDim2.new(0, 50, 0, 50)
    iconFrame.Position = UDim2.new(0, 15, 0.5, 0)
    iconFrame.AnchorPoint = Vector2.new(0, 0.5)
    iconFrame.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    iconFrame.BorderSizePixel = 0
    iconFrame.Parent = notifFrame
    
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 8)
    iconCorner.Parent = iconFrame
    
    -- ImageLabel for seed icon
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0.8, 0, 0.8, 0)
    icon.Position = UDim2.new(0.5, 0, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = "" -- Will be set dynamically
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Parent = iconFrame
    
    -- Fallback emoji text (if no image available)
    local emojiIcon = Instance.new("TextLabel")
    emojiIcon.Name = "EmojiIcon"
    emojiIcon.Size = UDim2.new(1, 0, 1, 0)
    emojiIcon.BackgroundTransparency = 1
    emojiIcon.Text = "✅"
    emojiIcon.TextScaled = true
    emojiIcon.Visible = false -- Hidden by default
    emojiIcon.Parent = iconFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -80, 0, 25)
    titleLabel.Position = UDim2.new(0, 70, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 20
    titleLabel.Text = "Seed Collected!"
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = notifFrame
    
    local detailLabel = Instance.new("TextLabel")
    detailLabel.Name = "Detail"
    detailLabel.Size = UDim2.new(1, -80, 0, 20)
    detailLabel.Position = UDim2.new(0, 70, 0, 35)
    detailLabel.BackgroundTransparency = 1
    detailLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    detailLabel.Font = Enum.Font.SourceSans
    detailLabel.TextSize = 16
    detailLabel.Text = "Common Seed"
    detailLabel.TextXAlignment = Enum.TextXAlignment.Left
    detailLabel.Parent = notifFrame
    
    -- ✅ NEW: Rarity text label
    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Name = "rarity"
    rarityLabel.Size = UDim2.new(1, -80, 0, 18)
    rarityLabel.Position = UDim2.new(0, 70, 0, 55)
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    rarityLabel.Font = Enum.Font.SourceSansBold
    rarityLabel.TextSize = 14
    rarityLabel.Text = "common"
    rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
    rarityLabel.Parent = notifFrame
    
    notificationGui = notifFrame
end

function SeedCollectionController._ShowPrompt(seedModel: Instance)
    if not seedPrompt then return end
    
    local seedName = seedModel.Name or "Seed"
    local label = seedPrompt:FindFirstChild("Label")
    if label then
        label.Text = "Collect " .. seedName:gsub("_", " ")
    end
    
    -- ✅ NEW: Update border color based on seed rarity
    local rarity = SeedCollectionController._GetSeedRarity(seedModel)
    if promptBorder and RARITY_COLORS[rarity] then
        promptBorder.Color = RARITY_COLORS[rarity]
    end
    
    seedPrompt.Visible = true
end

function SeedCollectionController._HidePrompt()
    if seedPrompt then
        seedPrompt.Visible = false
    end
end

-- ✅ NEW: Helper function to get seed rarity
function SeedCollectionController._GetSeedRarity(seedModel: Instance): string
    -- Try to get rarity from SeedData attribute
    local rarity = seedModel:GetAttribute("rarity")
    if rarity then
        return rarity:lower()
    end
    
    -- Try to get from SeedData child
    local seedData = seedModel:FindFirstChild("SeedData")
    if seedData then
        local rarityValue = seedData:FindFirstChild("rarity")
        if rarityValue and rarityValue:IsA("StringValue") then
            return rarityValue.Value:lower()
        end
    end
    
    -- Default to common
    return "common"
end

-- ✅ IMPROVED: Show notification when seed is collected
function SeedCollectionController._ShowNotification(seedInfo: any)
    if not notificationGui then return end
    
    -- Update notification text
    local titleLabel = notificationGui:FindFirstChild("Title")
    local detailLabel = notificationGui:FindFirstChild("Detail")
    local rarityLabel = notificationGui:FindFirstChild("rarity")
    local iconFrame = notificationGui:FindFirstChild("IconFrame")
    
    if titleLabel then
        titleLabel.Text = "Seed Collected!"
    end
    
    local seedName = seedInfo.seedName or "Seed"
    local rarity = seedInfo.rarity or "common"
    local rarityLower = rarity:lower()
    
    if detailLabel then
        detailLabel.Text = seedName:gsub("_", " ")
        detailLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
    
    -- ✅ NEW: Update rarity label
    if rarityLabel then
        rarityLabel.Text = rarity:upper()
        
        -- Color by rarity
        if RARITY_COLORS[rarityLower] then
            rarityLabel.TextColor3 = RARITY_COLORS[rarityLower]
        else
            rarityLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        end
    end
    
    -- ✅ NEW: Update seed icon
    if iconFrame then
        local icon = iconFrame:FindFirstChild("Icon")
        local emojiIcon = iconFrame:FindFirstChild("EmojiIcon")
        
        if icon and emojiIcon then
            -- Try to use the seed's icon if available
            local iconId = seedInfo.icon or seedInfo.iconId
            
            if iconId and iconId ~= "" then
                -- Set the image
                icon.Image = iconId
                icon.Visible = true
                emojiIcon.Visible = false
            else
                -- Fallback to emoji
                icon.Visible = false
                emojiIcon.Visible = true
                emojiIcon.Text = "🌱"
            end
        end
        
        -- Color the icon frame border by rarity
        if RARITY_COLORS[rarityLower] then
            iconFrame.BackgroundColor3 = RARITY_COLORS[rarityLower]
        end
    end
    
    -- Animate in
    notificationGui.BackgroundTransparency = 1
    notificationGui.Position = UDim2.new(0.5, 0, 0, 0)
    
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local tween1 = TweenService:Create(notificationGui, tweenInfo, {
        BackgroundTransparency = 0.1,
        Position = UDim2.new(0.5, 0, 0.1, 0)
    })
    tween1:Play()
    
    -- Hold for 2 seconds
    task.wait(2)
    
    -- Animate out
    local tweenInfo2 = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local tween2 = TweenService:Create(notificationGui, tweenInfo2, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0, 0)
    })
    tween2:Play()
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
    
    -- Mobile tap (touch)
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
    if isCollecting then return end
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

-- ✅ FIX: Called when server confirms collection
-- This is the ONLY place a notification should appear
function SeedCollectionController._OnSeedCollected(seedInfo: any)
    print("✅ Seed collected on client:", seedInfo.seedName)
    
    -- Show notification
    SeedCollectionController._ShowNotification(seedInfo)
    
    -- Could trigger other effects here (particles, sounds, etc.)
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
    if seedPrompt then
        seedPrompt:Destroy()
    end
    
    if notificationGui then
        notificationGui:Destroy()
    end
end

return SeedCollectionController