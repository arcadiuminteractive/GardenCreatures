--[[
    SeedCollectionController.lua
    Client-side controller for seed collection mechanics
    
    Features:
    - Click-to-collect interface
    - Collection visual feedback
    - Seed highlighting
    - Collection notifications
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

-- UI
local playerGui = player:WaitForChild("PlayerGui")
local seedPrompt = nil

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
-- CHARACTER TRACKING
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
    -- Track new seeds
    CollectionService:GetInstanceAddedSignal(SEED_TAG):Connect(function(seedModel)
        SeedCollectionController._OnSeedAdded(seedModel)
    end)
    
    -- Track removed seeds
    CollectionService:GetInstanceRemovedSignal(SEED_TAG):Connect(function(seedModel)
        SeedCollectionController._OnSeedRemoved(seedModel)
    end)
    
    -- Setup existing seeds
    for _, seedModel in ipairs(CollectionService:GetTagged(SEED_TAG)) do
        SeedCollectionController._OnSeedAdded(seedModel)
    end
end

function SeedCollectionController._OnSeedAdded(seedModel: Instance)
    if not seedModel:IsA("Model") then return end
    
    -- Add highlight for better visibility
    local highlight = Instance.new("Highlight")
    highlight.Name = "SeedHighlight"
    highlight.Adornee = seedModel
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0.3
    highlight.Enabled = false -- Only show when nearby
    
    -- Color based on rarity
    local rarity = seedModel:GetAttribute("Rarity") or "Common"
    local rarityColors = {
        Common = Color3.fromRGB(200, 200, 200),
        Uncommon = Color3.fromRGB(100, 200, 100),
        Rare = Color3.fromRGB(100, 150, 255),
        Epic = Color3.fromRGB(200, 100, 255),
        Legendary = Color3.fromRGB(255, 200, 50),
    }
    highlight.FillColor = rarityColors[rarity] or rarityColors.Common
    highlight.OutlineColor = rarityColors[rarity] or rarityColors.Common
    highlight.Parent = seedModel
    
    -- Add billboard GUI with seed name
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "SeedLabel"
    billboard.Size = UDim2.new(0, 150, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = false -- Only show when nearby
    billboard.Parent = seedModel
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = billboard
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextScaled = true
    label.TextColor3 = rarityColors[rarity] or rarityColors.Common
    label.Font = Enum.Font.SourceSansBold
    label.Text = seedModel.Name
    label.Parent = frame
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 4)
    padding.PaddingBottom = UDim.new(0, 4)
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.Parent = label
end

function SeedCollectionController._OnSeedRemoved(seedModel: Instance)
    -- Cleanup handled by model destruction
    nearbySeeds[seedModel] = nil
    
    if highlightedSeed == seedModel then
        highlightedSeed = nil
        SeedCollectionController._HidePrompt()
    end
end

-- ============================
-- PROXIMITY DETECTION
-- ============================

function SeedCollectionController._ProximityLoop()
    while true do
        task.wait(0.5) -- Check twice per second
        
        if not character or not humanoidRootPart then
            task.wait(1)
            continue
        end
        
        -- Find nearby seeds
        local currentNearby = {}
        local closestSeed = nil
        local closestDistance = HIGHLIGHT_RANGE
        
        for _, seedModel in ipairs(CollectionService:GetTagged(SEED_TAG)) do
            if seedModel:IsA("Model") then
                local seedPart = seedModel:FindFirstChild("SeedPart")
                if seedPart then
                    local distance = (humanoidRootPart.Position - seedPart.Position).Magnitude
                    
                    if distance <= HIGHLIGHT_RANGE then
                        currentNearby[seedModel] = distance
                        
                        -- Show highlight
                        local highlight = seedModel:FindFirstChild("SeedHighlight")
                        if highlight then
                            highlight.Enabled = true
                        end
                        
                        -- Show label
                        local billboard = seedModel:FindFirstChild("SeedLabel")
                        if billboard then
                            billboard.Enabled = true
                        end
                        
                        -- Track closest for prompt
                        if distance < closestDistance and distance <= COLLECTION_RANGE then
                            closestSeed = seedModel
                            closestDistance = distance
                        end
                    else
                        -- Hide highlight if too far
                        local highlight = seedModel:FindFirstChild("SeedHighlight")
                        if highlight then
                            highlight.Enabled = false
                        end
                        
                        local billboard = seedModel:FindFirstChild("SeedLabel")
                        if billboard then
                            billboard.Enabled = false
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
end

function SeedCollectionController._ShowPrompt(seedModel: Instance)
    if not seedPrompt then return end
    
    local label = seedPrompt:FindFirstChild("Label")
    if label then
        local seedName = seedModel.Name
        local rarity = seedModel:GetAttribute("Rarity") or "Common"
        
        label.Text = string.format("Click to collect %s", seedName)
        
        -- Color based on rarity
        local rarityColors = {
            Common = Color3.fromRGB(200, 200, 200),
            Uncommon = Color3.fromRGB(100, 200, 100),
            Rare = Color3.fromRGB(100, 150, 255),
            Epic = Color3.fromRGB(200, 100, 255),
            Legendary = Color3.fromRGB(255, 200, 50),
        }
        label.TextColor3 = rarityColors[rarity] or rarityColors.Common
    end
    
    seedPrompt.Visible = true
    
    -- Animate in
    local tween = TweenService:Create(
        seedPrompt,
        TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        { Size = UDim2.new(0, 220, 0, 70) }
    )
    tween:Play()
end

function SeedCollectionController._HidePrompt()
    if not seedPrompt then return end
    
    -- Animate out
    local tween = TweenService:Create(
        seedPrompt,
        TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
        { Size = UDim2.new(0, 200, 0, 60) }
    )
    tween:Play()
    tween.Completed:Wait()
    
    seedPrompt.Visible = false
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
    
    -- Request collection from server
    CollectSeedEvent:FireServer(seedModel)
    
    -- Play collection animation
    SeedCollectionController._PlayCollectionEffect(seedModel)
    
    -- Cooldown
    task.wait(0.5)
    isCollecting = false
end

function SeedCollectionController._PlayCollectionEffect(seedModel: Instance)
    local seedPart = seedModel:FindFirstChild("SeedPart")
    if not seedPart then return end
    
    -- Create particle effect
    local particles = Instance.new("ParticleEmitter")
    particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    particles.Rate = 50
    particles.Lifetime = NumberRange.new(0.5, 1)
    particles.Speed = NumberRange.new(5, 10)
    particles.SpreadAngle = Vector2.new(360, 360)
    particles.Color = ColorSequence.new(seedPart.Color)
    particles.LightEmission = 1
    particles.Size = NumberSequence.new(0.5, 0)
    particles.Parent = seedPart
    
    -- Emit burst
    particles:Emit(20)
    
    -- Tween seed to player
    if humanoidRootPart then
        local tween = TweenService:Create(
            seedPart,
            TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
            {
                Position = humanoidRootPart.Position + Vector3.new(0, 2, 0),
                Size = Vector3.new(0.1, 0.1, 0.1),
                Transparency = 1
            }
        )
        tween:Play()
    end
    
    -- Cleanup
    task.delay(0.5, function()
        if particles then
            particles:Destroy()
        end
    end)
end

-- ============================
-- PUBLIC METHODS
-- ============================

function SeedCollectionController.GetNearbySeeds(): {Instance}
    local seeds = {}
    for seed, _ in pairs(nearbySeeds) do
        table.insert(seeds, seed)
    end
    return seeds
end

function SeedCollectionController.GetHighlightedSeed(): Instance?
    return highlightedSeed
end

print("✅ SeedCollectionController loaded")

return SeedCollectionController
