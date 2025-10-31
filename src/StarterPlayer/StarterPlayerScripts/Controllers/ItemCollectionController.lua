--[[
    ItemCollectionController.lua - REFACTORED WITH FIX FOR NEW ITEM SYSTEM
    Client-side controller for item collection mechanics
    
    ✅ FIXES APPLIED:
    1. Validation check to prevent premature "Item Collected" notification on join
    2. Proximity notification now shows actual item icon from Items.lua config
    3. Border color dynamically matches item rarity
    4. Smooth fade-in animation for proximity notification
    5. Unified notification system that transforms from proximity to collected state
    
    Features:
    - Click-to-collect interface
    - Collection visual feedback with actual item icons
    - Item highlighting with rarity-based borders
    - Collection notifications with rarity indicators
    - Distance validation
]]

local ItemCollectionController = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Constants
local ITEM_TAG = "ItemSpawn"
local COLLECTION_RANGE = 15
local HIGHLIGHT_RANGE = 20
local PROXIMITY_CHECK_INTERVAL = 0.1 -- 10 Hz for smooth detection

-- Rarity Colors (matching Items.lua config)
local RARITY_COLORS = {
    common = Color3.fromRGB(100, 200, 100),      -- Green
    uncommon = Color3.fromRGB(100, 100, 255),    -- Blue
    rare = Color3.fromRGB(200, 100, 255),        -- Purple
    epic = Color3.fromRGB(255, 165, 0),          -- Orange
    legendary = Color3.fromRGB(255, 50, 50)      -- Red
}

-- State Management
local player = Players.LocalPlayer
local character = nil
local humanoidRootPart = nil
local mouse = player:GetMouse()
local nearbyItems = {}
local highlightedItem = nil
local isCollecting = false
local isNotificationShowing = false
local isTransitioning = false
local currentItemData = nil

-- RemoteEvents
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local CollectItemEvent = RemoteEvents:WaitForChild("CollectItem")
local ItemCollectedEvent = RemoteEvents:WaitForChild("ItemCollected")

-- Config
local Items = require(ReplicatedStorage.Shared.Config.Items)

-- UI References
local playerGui = player:WaitForChild("PlayerGui")
local itemPrompt = nil
local notificationGui = nil
local promptBorder = nil

-- ============================
-- INITIALIZATION
-- ============================

function ItemCollectionController.Init()
    print("🌱 Initializing Item Collection Controller...")
    
    ItemCollectionController._SetupCharacter()
    ItemCollectionController._SetupItemTracking()
    ItemCollectionController._CreateUI()
    ItemCollectionController._SetupInput()
    
    -- ✅ FIX 1: Added validation to prevent premature notifications
    ItemCollectedEvent.OnClientEvent:Connect(function(itemInfo)
        -- Only fire if we have valid item data from the server
        if itemInfo and itemInfo.itemId then
            ItemCollectionController._OnItemCollected(itemInfo)
        end
    end)
    
    print("✅ Item Collection Controller initialized")
end

function ItemCollectionController.Start()
    print("🌱 Starting Item Collection Controller...")
    
    task.spawn(function()
        ItemCollectionController._ProximityLoop()
    end)
    
    print("✅ Item Collection Controller started")
end

-- ============================
-- CHARACTER SETUP
-- ============================

function ItemCollectionController._SetupCharacter()
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
-- ITEM TRACKING
-- ============================

function ItemCollectionController._SetupItemTracking()
    -- Track existing items
    for _, item in ipairs(CollectionService:GetTagged(ITEM_TAG)) do
        ItemCollectionController._OnItemAdded(item)
    end
    
    -- Track new items
    CollectionService:GetInstanceAddedSignal(ITEM_TAG):Connect(function(item)
        ItemCollectionController._OnItemAdded(item)
    end)
    
    -- Track removed items
    CollectionService:GetInstanceRemovedSignal(ITEM_TAG):Connect(function(item)
        ItemCollectionController._OnItemRemoved(item)
    end)
end

function ItemCollectionController._OnItemAdded(item: Instance)
    nearbyItems[item] = true
end

function ItemCollectionController._OnItemRemoved(item: Instance)
    nearbyItems[item] = nil
    
    if highlightedItem == item then
        highlightedItem = nil
        currentItemData = nil
        ItemCollectionController._HidePrompt()
    end
end

-- ============================
-- CONFIG LOOKUP FUNCTIONS
-- ============================

-- ✅ FIX 2: Added function to get item config from Items.lua
function ItemCollectionController._GetItemConfig(itemId: string)
    if not itemId then return nil end
    return Items.GetItemById(itemId)
end

function ItemCollectionController._GetItemRarity(itemModel: Instance): string
    -- Try to get rarity from attribute (primary method)
    local rarity = itemModel:GetAttribute("rarity")
    if rarity and type(rarity) == "string" then
        return rarity:lower()
    end
    
    -- Fallback: try to find ItemData folder with rarity StringValue (legacy support)
    local itemData = itemModel:FindFirstChild("ItemData")
    if itemData then
        local rarityValue = itemData:FindFirstChild("rarity")
        if rarityValue and rarityValue:IsA("StringValue") then
            return rarityValue.Value:lower()
        end
    end
    
    -- Default to common if no rarity found
    return "common"
end

-- ============================
-- PROXIMITY DETECTION
-- ============================

function ItemCollectionController._ProximityLoop()
    while true do
        task.wait(PROXIMITY_CHECK_INTERVAL)
        
        if not humanoidRootPart then
            task.wait(1)
            continue
        end
        
        local currentNearby = {}
        local closestItem = nil
        local closestDistance = math.huge
        
        -- Find all nearby items
        for _, item in ipairs(CollectionService:GetTagged(ITEM_TAG)) do
            if item and item.Parent then
                local itemPart = item:FindFirstChild("ItemPart")
                
                if itemPart then
                    local distance = (humanoidRootPart.Position - itemPart.Position).Magnitude
                    
                    if distance <= HIGHLIGHT_RANGE then
                        currentNearby[item] = true
                        
                        if distance < closestDistance and distance <= COLLECTION_RANGE then
                            closestDistance = distance
                            closestItem = item
                        end
                    end
                end
            end
        end
        
        nearbyItems = currentNearby
        
        -- Update highlighted item
        if closestItem ~= highlightedItem then
            highlightedItem = closestItem
            
            if highlightedItem then
                -- ✅ Store current item data for quick access
                local itemId = highlightedItem:GetAttribute("itemId")
                currentItemData = ItemCollectionController._GetItemConfig(itemId)
                ItemCollectionController._ShowPrompt(highlightedItem)
            else
                currentItemData = nil
                ItemCollectionController._HidePrompt()
            end
        end
    end
end

-- ============================
-- UI MANAGEMENT
-- ============================

function ItemCollectionController._CreateUI()
    -- Create main screen GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ItemCollectionUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- ==================
    -- PROXIMITY PROMPT (UNIFIED NOTIFICATION)
    -- ==================
    local prompt = Instance.new("Frame")
    prompt.Name = "CollectionPrompt"
    prompt.Size = UDim2.new(0, 300, 0, 85)
    prompt.Position = UDim2.new(0.5, 0, 0.15, 0)
    prompt.AnchorPoint = Vector2.new(0.5, 0.5)
    prompt.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    prompt.BackgroundTransparency = 0.1
    prompt.BorderSizePixel = 0
    prompt.Visible = false
    prompt.Parent = screenGui
    
    -- Corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = prompt
    
    -- ✅ FIX 3: Rarity-based border that pulses
    local border = Instance.new("UIStroke")
    border.Name = "RarityBorder"
    border.Color = Color3.fromRGB(100, 200, 100) -- Default green
    border.Thickness = 3
    border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    border.Parent = prompt
    promptBorder = border
    
    -- Border pulse animation
    local function createBorderPulse()
        local pulseIn = TweenService:Create(
            border,
            TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            { Thickness = 5 }
        )
        pulseIn:Play()
    end
    createBorderPulse()
    
    -- ✅ FIX 2: Icon frame with rarity color background
    local iconFrame = Instance.new("Frame")
    iconFrame.Name = "IconFrame"
    iconFrame.Size = UDim2.new(0, 60, 0, 60)
    iconFrame.Position = UDim2.new(0, 10, 0.5, 0)
    iconFrame.AnchorPoint = Vector2.new(0, 0.5)
    iconFrame.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    iconFrame.BorderSizePixel = 0
    iconFrame.Parent = prompt
    
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 6)
    iconCorner.Parent = iconFrame
    
    -- ✅ FIX 2: ImageLabel for actual item icon
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0.85, 0, 0.85, 0)
    icon.Position = UDim2.new(0.5, 0, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = ""
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Parent = iconFrame
    
    -- Emoji fallback (only shown if no icon available)
    local emojiIcon = Instance.new("TextLabel")
    emojiIcon.Name = "EmojiIcon"
    emojiIcon.Size = UDim2.new(1, 0, 1, 0)
    emojiIcon.BackgroundTransparency = 1
    emojiIcon.Text = "📦"
    emojiIcon.TextSize = 36
    emojiIcon.Font = Enum.Font.SourceSansBold
    emojiIcon.Visible = false
    emojiIcon.Parent = iconFrame
    
    -- Title label (transforms between "Collect Item" and "✓ Item Collected!")
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -80, 0, 24)
    titleLabel.Position = UDim2.new(0, 75, 0, 12)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 20
    titleLabel.Text = "Collect Item"
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = prompt
    
    -- Detail label (shows item name)
    local detailLabel = Instance.new("TextLabel")
    detailLabel.Name = "Detail"
    detailLabel.Size = UDim2.new(1, -80, 0, 20)
    detailLabel.Position = UDim2.new(0, 75, 0, 38)
    detailLabel.BackgroundTransparency = 1
    detailLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    detailLabel.Font = Enum.Font.SourceSans
    detailLabel.TextSize = 16
    detailLabel.Text = "Item Name"
    detailLabel.TextXAlignment = Enum.TextXAlignment.Left
    detailLabel.TextTruncate = Enum.TextTruncate.AtEnd
    detailLabel.Parent = prompt
    
    -- Rarity label
    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Name = "Rarity"
    rarityLabel.Size = UDim2.new(1, -80, 0, 18)
    rarityLabel.Position = UDim2.new(0, 75, 0, 58)
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    rarityLabel.Font = Enum.Font.SourceSansBold
    rarityLabel.TextSize = 14
    rarityLabel.Text = "COMMON"
    rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
    rarityLabel.Parent = prompt
    
    itemPrompt = prompt
end

function ItemCollectionController._ShowPrompt(itemModel: Instance)
    if not itemPrompt or isTransitioning then return end
    
    -- Get item ID and look up config
    local itemId = itemModel:GetAttribute("itemId")
    local itemName = itemModel:GetAttribute("itemName") or itemModel.Name
    local rarity = ItemCollectionController._GetItemRarity(itemModel)
    local rarityLower = rarity:lower()
    
    -- Update UI elements
    local titleLabel = itemPrompt:FindFirstChild("Title")
    local detailLabel = itemPrompt:FindFirstChild("Detail")
    local rarityLabel = itemPrompt:FindFirstChild("Rarity")
    local iconFrame = itemPrompt:FindFirstChild("IconFrame")
    
    if titleLabel then
        titleLabel.Text = "Collect Item"
    end
    
    if detailLabel then
        -- Clean up the display name
        local displayName = itemName:gsub("_", " ")
        detailLabel.Text = displayName
    end
    
    if rarityLabel then
        rarityLabel.Text = rarity:upper()
        
        -- ✅ FIX 3: Set rarity color for label
        if RARITY_COLORS[rarityLower] then
            rarityLabel.TextColor3 = RARITY_COLORS[rarityLower]
        end
    end
    
    -- ✅ FIX 2 & 3: Update icon and colors based on item config
    if iconFrame then
        local icon = iconFrame:FindFirstChild("Icon")
        local emojiIcon = iconFrame:FindFirstChild("EmojiIcon")
        
        if icon and emojiIcon then
            -- Try to get icon from stored item data
            local iconId = nil
            if currentItemData and currentItemData.icon then
                iconId = currentItemData.icon
            end
            
            if iconId and iconId ~= "" then
                icon.Image = iconId
                icon.Visible = true
                emojiIcon.Visible = false
            else
                -- Fallback to emoji if no icon
                icon.Visible = false
                emojiIcon.Visible = true
                emojiIcon.Text = "📦"
            end
        end
        
        -- ✅ FIX 3: Icon frame background matches rarity
        if RARITY_COLORS[rarityLower] then
            iconFrame.BackgroundColor3 = RARITY_COLORS[rarityLower]
        end
    end
    
    -- ✅ FIX 3: Border color matches rarity
    if promptBorder and RARITY_COLORS[rarityLower] then
        promptBorder.Color = RARITY_COLORS[rarityLower]
    end
    
    -- ✅ FIX 4: Smooth fade-in animation
    if not isNotificationShowing then
        isNotificationShowing = true
        
        -- Start slightly above final position
        itemPrompt.Position = UDim2.new(0.5, 0, 0.12, 0)
        itemPrompt.BackgroundTransparency = 1
        
        local fadeIn = TweenService:Create(
            itemPrompt,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                BackgroundTransparency = 0.1,
                Position = UDim2.new(0.5, 0, 0.15, 0)
            }
        )
        fadeIn:Play()
    end
    
    itemPrompt.Visible = true
end

function ItemCollectionController._HidePrompt()
    if not itemPrompt or isTransitioning then return end
    
    isNotificationShowing = false
    
    -- Fade out
    local fadeOut = TweenService:Create(
        itemPrompt,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { BackgroundTransparency = 1 }
    )
    fadeOut:Play()
    
    fadeOut.Completed:Connect(function()
        if not isNotificationShowing then
            itemPrompt.Visible = false
        end
    end)
end

-- ✅ FIX 5: Transform notification from proximity to collected state
function ItemCollectionController._TransformToCollected(itemInfo: any)
    if not itemPrompt or isTransitioning then return end
    
    isTransitioning = true
    
    -- Scale up animation to draw attention
    local scaleUp = TweenService:Create(
        itemPrompt,
        TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Size = UDim2.new(0, 320, 0, 95) }
    )
    scaleUp:Play()
    
    scaleUp.Completed:Connect(function()
        -- Update text to "Collected"
        local titleLabel = itemPrompt:FindFirstChild("Title")
        if titleLabel then
            titleLabel.Text = "✓ Item Collected!"
        end
        
        -- Hold for 2 seconds
        task.wait(2)
        
        -- Fade out and reset
        local fadeOut = TweenService:Create(
            itemPrompt,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {
                BackgroundTransparency = 1,
                Position = UDim2.new(0.5, 0, 0.12, 0)
            }
        )
        fadeOut:Play()
        
        fadeOut.Completed:Connect(function()
            itemPrompt.Visible = false
            itemPrompt.Size = UDim2.new(0, 300, 0, 85) -- Reset size
            isNotificationShowing = false
            isTransitioning = false
        end)
    end)
end

-- ============================
-- INPUT HANDLING
-- ============================

function ItemCollectionController._SetupInput()
    -- Mouse click
    mouse.Button1Down:Connect(function()
        if highlightedItem and not isCollecting and not isTransitioning then
            ItemCollectionController._TryCollect(highlightedItem)
        end
    end)
    
    -- Touch input
    UserInputService.TouchTap:Connect(function(touchPositions, processed)
        if processed then return end
        if highlightedItem and not isCollecting and not isTransitioning then
            ItemCollectionController._TryCollect(highlightedItem)
        end
    end)
    
    -- Keyboard input (E key)
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        
        if input.KeyCode == Enum.KeyCode.E then
            if highlightedItem and not isCollecting and not isTransitioning then
                ItemCollectionController._TryCollect(highlightedItem)
            end
        end
    end)
end

-- ============================
-- COLLECTION
-- ============================

function ItemCollectionController._TryCollect(itemModel: Instance)
    if isCollecting or isTransitioning then return end
    if not itemModel or not itemModel.Parent then return end
    
    isCollecting = true
    
    ItemCollectionController._PlayCollectionEffect(itemModel)
    CollectItemEvent:FireServer(itemModel)
    
    task.wait(0.5)
    isCollecting = false
end

function ItemCollectionController._OnItemCollected(itemInfo: any)
    print("✅ Item collected on client:", itemInfo.itemName)
    
    -- ✅ FIX 5: Transform the proximity notification instead of creating a new one
    if isNotificationShowing and itemPrompt and itemPrompt.Visible then
        ItemCollectionController._TransformToCollected(itemInfo)
    else
        -- If proximity notification isn't showing (edge case), show traditional notification
        ItemCollectionController._ShowTraditionalNotification(itemInfo)
    end
end

-- Legacy notification for edge cases where proximity UI isn't active
function ItemCollectionController._ShowTraditionalNotification(itemInfo: any)
    -- Create temporary notification
    local notif = Instance.new("Frame")
    notif.Name = "CollectionNotification"
    notif.Size = UDim2.new(0, 300, 0, 80)
    notif.Position = UDim2.new(0.5, 0, 0.1, 0)
    notif.AnchorPoint = Vector2.new(0.5, 0.5)
    notif.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    notif.BackgroundTransparency = 1
    notif.BorderSizePixel = 0
    notif.Parent = playerGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notif
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -80, 0, 24)
    titleLabel.Position = UDim2.new(0, 70, 0, 15)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 20
    titleLabel.Text = "✓ Item Collected!"
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = notif
    
    local detailLabel = Instance.new("TextLabel")
    detailLabel.Name = "Detail"
    detailLabel.Size = UDim2.new(1, -80, 0, 20)
    detailLabel.Position = UDim2.new(0, 70, 0, 42)
    detailLabel.BackgroundTransparency = 1
    detailLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    detailLabel.Font = Enum.Font.SourceSans
    detailLabel.TextSize = 16
    detailLabel.Text = (itemInfo.itemName or "Item"):gsub("_", " ")
    detailLabel.TextXAlignment = Enum.TextXAlignment.Left
    detailLabel.Parent = notif
    
    -- Fade in
    local fadeIn = TweenService:Create(
        notif,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            BackgroundTransparency = 0.1,
            Position = UDim2.new(0.5, 0, 0.12, 0)
        }
    )
    fadeIn:Play()
    
    task.wait(2)
    
    -- Fade out
    local fadeOut = TweenService:Create(
        notif,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { BackgroundTransparency = 1 }
    )
    fadeOut:Play()
    
    fadeOut.Completed:Connect(function()
        notif:Destroy()
    end)
end

function ItemCollectionController._PlayCollectionEffect(itemModel: Instance)
    local itemPart = itemModel:FindFirstChild("ItemPart")
    if not itemPart then return end
    
    -- Animate item floating up and shrinking
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local goal = {
        Position = itemPart.Position + Vector3.new(0, 5, 0),
        Size = Vector3.new(0.1, 0.1, 0.1)
    }
    
    local tween = TweenService:Create(itemPart, tweenInfo, goal)
    tween:Play()
    
    -- Fade out highlight
    local highlight = itemModel:FindFirstChildWhichIsA("Highlight")
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

function ItemCollectionController.Cleanup()
    if itemPrompt then
        itemPrompt:Destroy()
        itemPrompt = nil
    end
    
    isNotificationShowing = false
    isTransitioning = false
    currentItemData = nil
end

return ItemCollectionController
