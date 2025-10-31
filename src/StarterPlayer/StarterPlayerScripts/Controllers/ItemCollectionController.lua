--[[
    ItemCollectionController.lua - REFACTORED FOR NEW ITEM SYSTEM
    Client-side controller for item collection mechanics
    
    âœ… CHANGES FROM SeedCollectionController:
    1. Works with new Items.lua config
    2. Updated naming (seeds -> items)
    3. Supports different item types (Form, Substance, Attribute)
    4. Maintains all existing visual feedback
    
    Features:
    - Click-to-collect interface
    - Collection visual feedback with item icons
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
local nearbyItems = {}
local highlightedItem = nil
local isCollecting = false

-- RemoteEvents
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local CollectItemEvent = RemoteEvents:WaitForChild("CollectItem")
local ItemCollectedEvent = RemoteEvents:WaitForChild("ItemCollected")

-- UI
local playerGui = player:WaitForChild("PlayerGui")
local itemPrompt = nil
local notificationGui = nil
local promptBorder = nil

-- ============================
-- INITIALIZATION
-- ============================

function ItemCollectionController.Init()
    print("ðŸŒ± Initializing Item Collection Controller...")
    
    ItemCollectionController._SetupCharacter()
    ItemCollectionController._SetupItemTracking()
    ItemCollectionController._CreateUI()
    ItemCollectionController._SetupInput()
    
    ItemCollectedEvent.OnClientEvent:Connect(function(itemInfo)
        ItemCollectionController._OnItemCollected(itemInfo)
    end)
    
    print("âœ… Item Collection Controller initialized")
end

function ItemCollectionController.Start()
    print("ðŸŒ± Starting Item Collection Controller...")
    
    task.spawn(function()
        ItemCollectionController._ProximityLoop()
    end)
    
    print("âœ… Item Collection Controller started")
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
    for _, item in ipairs(CollectionService:GetTagged(ITEM_TAG)) do
        ItemCollectionController._OnItemAdded(item)
    end
    
    CollectionService:GetInstanceAddedSignal(ITEM_TAG):Connect(function(item)
        ItemCollectionController._OnItemAdded(item)
    end)
    
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
        ItemCollectionController._HidePrompt()
    end
end

-- ============================
-- PROXIMITY DETECTION
-- ============================

function ItemCollectionController._ProximityLoop()
    while true do
        task.wait(0.1)
        
        if not humanoidRootPart then
            task.wait(1)
            continue
        end
        
        local currentNearby = {}
        local closestItem = nil
        local closestDistance = math.huge
        
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
        
        if closestItem ~= highlightedItem then
            highlightedItem = closestItem
            
            if highlightedItem then
                ItemCollectionController._ShowPrompt(highlightedItem)
            else
                ItemCollectionController._HidePrompt()
            end
        end
    end
end

-- ============================
-- UI MANAGEMENT
-- ============================

function ItemCollectionController._CreateUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ItemCollectionUI"
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
    
    local border = Instance.new("UIStroke")
    border.Name = "RarityBorder"
    border.Thickness = 3
    border.Color = Color3.fromRGB(100, 255, 100)
    border.Transparency = 0
    border.Parent = prompt
    promptBorder = border
    
    task.spawn(function()
        while true do
            if prompt.Visible then
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
    icon.Text = "ðŸ“¦"
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
    
    itemPrompt = prompt
    
    ItemCollectionController._CreateNotificationUI(screenGui)
end

function ItemCollectionController._CreateNotificationUI(screenGui: ScreenGui)
    local notifFrame = Instance.new("Frame")
    notifFrame.Name = "NotificationFrame"
    notifFrame.Size = UDim2.new(0, 300, 0, 80)
    notifFrame.Position = UDim2.new(0.5, 0, 0.1, 0)
    notifFrame.AnchorPoint = Vector2.new(0.5, 0)
    notifFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    notifFrame.BackgroundTransparency = 1
    notifFrame.BorderSizePixel = 0
    notifFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = notifFrame
    
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
    
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0.8, 0, 0.8, 0)
    icon.Position = UDim2.new(0.5, 0, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = ""
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Parent = iconFrame
    
    local emojiIcon = Instance.new("TextLabel")
    emojiIcon.Name = "EmojiIcon"
    emojiIcon.Size = UDim2.new(1, 0, 1, 0)
    emojiIcon.BackgroundTransparency = 1
    emojiIcon.Text = "âœ…"
    emojiIcon.TextScaled = true
    emojiIcon.Visible = false
    emojiIcon.Parent = iconFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -80, 0, 25)
    titleLabel.Position = UDim2.new(0, 70, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 20
    titleLabel.Text = "Item Collected!"
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
    detailLabel.Text = "Common Item"
    detailLabel.TextXAlignment = Enum.TextXAlignment.Left
    detailLabel.Parent = notifFrame
    
    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Name = "Rarity"
    rarityLabel.Size = UDim2.new(1, -80, 0, 18)
    rarityLabel.Position = UDim2.new(0, 70, 0, 55)
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    rarityLabel.Font = Enum.Font.SourceSansBold
    rarityLabel.TextSize = 14
    rarityLabel.Text = "COMMON"
    rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
    rarityLabel.Parent = notifFrame
    
    notificationGui = notifFrame
end

function ItemCollectionController._ShowPrompt(itemModel: Instance)
    if not itemPrompt then return end
    
    -- Get item name from attribute or fall back to model name
    local itemName = itemModel:GetAttribute("itemName") or itemModel.Name
    
    local label = itemPrompt:FindFirstChild("Label")
    if label then
        -- Clean up the display name
        local displayName = itemName:gsub("_", " ")
        label.Text = "Collect " .. displayName
    end
    
    -- Get rarity and update border color
    local rarity = ItemCollectionController._GetItemRarity(itemModel)
    if promptBorder and RARITY_COLORS[rarity] then
        promptBorder.Color = RARITY_COLORS[rarity]
    end
    
    itemPrompt.Visible = true
end

function ItemCollectionController._HidePrompt()
    if itemPrompt then
        itemPrompt.Visible = false
    end
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

function ItemCollectionController._ShowNotification(itemInfo: any)
    if not notificationGui then return end
    
    local titleLabel = notificationGui:FindFirstChild("Title")
    local detailLabel = notificationGui:FindFirstChild("Detail")
    local rarityLabel = notificationGui:FindFirstChild("Rarity")
    local iconFrame = notificationGui:FindFirstChild("IconFrame")
    
    if titleLabel then
        titleLabel.Text = "Item Collected!"
    end
    
    local itemName = itemInfo.itemName or "Item"
    local rarity = itemInfo.rarity or "common"
    local rarityLower = rarity:lower()
    
    if detailLabel then
        detailLabel.Text = itemName:gsub("_", " ")
        detailLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
    
    if rarityLabel then
        rarityLabel.Text = rarity:upper()
        
        if RARITY_COLORS[rarityLower] then
            rarityLabel.TextColor3 = RARITY_COLORS[rarityLower]
        else
            rarityLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        end
    end
    
    if iconFrame then
        local icon = iconFrame:FindFirstChild("Icon")
        local emojiIcon = iconFrame:FindFirstChild("EmojiIcon")
        
        if icon and emojiIcon then
            local iconId = itemInfo.icon or itemInfo.iconId
            
            if iconId and iconId ~= "" then
                icon.Image = iconId
                icon.Visible = true
                emojiIcon.Visible = false
            else
                icon.Visible = false
                emojiIcon.Visible = true
                emojiIcon.Text = "ðŸ“¦"
            end
        end
        
        if RARITY_COLORS[rarityLower] then
            iconFrame.BackgroundColor3 = RARITY_COLORS[rarityLower]
        end
    end
    
    notificationGui.BackgroundTransparency = 1
    notificationGui.Position = UDim2.new(0.5, 0, 0, 0)
    
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local tween1 = TweenService:Create(notificationGui, tweenInfo, {
        BackgroundTransparency = 0.1,
        Position = UDim2.new(0.5, 0, 0.1, 0)
    })
    tween1:Play()
    
    task.wait(2)
    
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

function ItemCollectionController._SetupInput()
    mouse.Button1Down:Connect(function()
        if highlightedItem and not isCollecting then
            ItemCollectionController._TryCollect(highlightedItem)
        end
    end)
    
    UserInputService.TouchTap:Connect(function(touchPositions, processed)
        if processed then return end
        if highlightedItem and not isCollecting then
            ItemCollectionController._TryCollect(highlightedItem)
        end
    end)
    
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        
        if input.KeyCode == Enum.KeyCode.E then
            if highlightedItem and not isCollecting then
                ItemCollectionController._TryCollect(highlightedItem)
            end
        end
    end)
end

-- ============================
-- COLLECTION
-- ============================

function ItemCollectionController._TryCollect(itemModel: Instance)
    if isCollecting then return end
    if not itemModel or not itemModel.Parent then return end
    
    isCollecting = true
    
    ItemCollectionController._PlayCollectionEffect(itemModel)
    CollectItemEvent:FireServer(itemModel)
    
    task.wait(0.5)
    isCollecting = false
end

function ItemCollectionController._OnItemCollected(itemInfo: any)
    print("âœ… Item collected on client:", itemInfo.itemName)
    ItemCollectionController._ShowNotification(itemInfo)
end

function ItemCollectionController._PlayCollectionEffect(itemModel: Instance)
    local itemPart = itemModel:FindFirstChild("ItemPart")
    if not itemPart then return end
    
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local goal = {
        Position = itemPart.Position + Vector3.new(0, 5, 0),
        Size = Vector3.new(0.1, 0.1, 0.1)
    }
    
    local tween = TweenService:Create(itemPart, tweenInfo, goal)
    tween:Play()
    
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
    end
    
    if notificationGui then
        notificationGui:Destroy()
    end
end

return ItemCollectionController
