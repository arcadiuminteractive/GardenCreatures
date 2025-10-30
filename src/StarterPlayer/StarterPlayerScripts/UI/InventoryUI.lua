--[[
    InventoryUI.lua
    Creates the main inventory window UI
    
    Features:
    - 10 slot grid (5 columns x 2 rows)
    - Item icons and quantities
    - Stacking display
    - Clean Roblox-style design
    - Close button
    - Draggable window
]]

local InventoryUI = {}

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Constants
local INVENTORY_SLOTS = 10
local COLUMNS = 5
local ROWS = 2
local SLOT_SIZE = 70
local SLOT_PADDING = 10
local WINDOW_PADDING = 20

-- Calculate window size
local WINDOW_WIDTH = (SLOT_SIZE * COLUMNS) + (SLOT_PADDING * (COLUMNS + 1)) + (WINDOW_PADDING * 2)
local WINDOW_HEIGHT = (SLOT_SIZE * ROWS) + (SLOT_PADDING * (ROWS + 1)) + (WINDOW_PADDING * 2) + 50 -- +50 for title bar

--[[
    Creates the inventory UI window
    @return ScreenGui - The created inventory UI
]]
function InventoryUI.Create()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Check if UI already exists
    local existingUI = playerGui:FindFirstChild("InventoryUI")
    if existingUI then
        return existingUI
    end
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "InventoryUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 100 -- Above other UI
    screenGui.Enabled = false -- Start hidden
    
    -- Main window frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, WINDOW_WIDTH, 0, WINDOW_HEIGHT)
    mainFrame.Position = UDim2.new(0.5, -WINDOW_WIDTH/2, 0.5, -WINDOW_HEIGHT/2) -- Centered
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- UICorner for rounded corners
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame
    
    -- UIStroke for border
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(70, 70, 70)
    mainStroke.Thickness = 2
    mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    mainStroke.Parent = mainFrame
    
    -- DropShadow effect
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.7
    shadow.ZIndex = -1
    shadow.Parent = mainFrame
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    -- Title bar corner (only top corners)
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    -- Title bar bottom cover (to square off bottom)
    local titleCover = Instance.new("Frame")
    titleCover.Size = UDim2.new(1, 0, 0, 12)
    titleCover.Position = UDim2.new(0, 0, 1, -12)
    titleCover.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    titleCover.BorderSizePixel = 0
    titleCover.Parent = titleBar
    
    -- Title text
    local titleText = Instance.new("TextLabel")
    titleText.Name = "Title"
    titleText.Size = UDim2.new(1, -50, 1, 0)
    titleText.Position = UDim2.new(0, 15, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "Inventory (10 slots)"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextSize = 18
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 18
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    -- Close button hover effect
    closeButton.MouseEnter:Connect(function()
        local tween = TweenService:Create(
            closeButton,
            TweenInfo.new(0.15),
            { BackgroundColor3 = Color3.fromRGB(200, 50, 50) }
        )
        tween:Play()
    end)
    
    closeButton.MouseLeave:Connect(function()
        local tween = TweenService:Create(
            closeButton,
            TweenInfo.new(0.15),
            { BackgroundColor3 = Color3.fromRGB(50, 50, 50) }
        )
        tween:Play()
    end)
    
    -- Slots container
    local slotsContainer = Instance.new("Frame")
    slotsContainer.Name = "SlotsContainer"
    slotsContainer.Size = UDim2.new(1, -WINDOW_PADDING * 2, 1, -WINDOW_PADDING * 2 - 40) -- Account for title bar
    slotsContainer.Position = UDim2.new(0, WINDOW_PADDING, 0, 40 + WINDOW_PADDING)
    slotsContainer.BackgroundTransparency = 1
    slotsContainer.Parent = mainFrame
    
    -- Create inventory slots
    for row = 0, ROWS - 1 do
        for col = 0, COLUMNS - 1 do
            local slotIndex = (row * COLUMNS) + col + 1
            if slotIndex <= INVENTORY_SLOTS then
                InventoryUI._CreateSlot(slotsContainer, slotIndex, col, row)
            end
        end
    end
    
    -- Make window draggable
    InventoryUI._MakeDraggable(mainFrame, titleBar)
    
    -- Parent to PlayerGui
    screenGui.Parent = playerGui
    
    print("✅ Inventory UI created")
    return screenGui
end

--[[
    Creates a single inventory slot
]]
function InventoryUI._CreateSlot(parent: Frame, index: number, col: number, row: number)
    -- Calculate position
    local xPos = (col * (SLOT_SIZE + SLOT_PADDING)) + SLOT_PADDING
    local yPos = (row * (SLOT_SIZE + SLOT_PADDING)) + SLOT_PADDING
    
    -- Slot frame
    local slotFrame = Instance.new("Frame")
    slotFrame.Name = "Slot" .. index
    slotFrame.Size = UDim2.new(0, SLOT_SIZE, 0, SLOT_SIZE)
    slotFrame.Position = UDim2.new(0, xPos, 0, yPos)
    slotFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    slotFrame.BorderSizePixel = 0
    slotFrame.Parent = parent
    
    -- Slot corner
    local slotCorner = Instance.new("UICorner")
    slotCorner.CornerRadius = UDim.new(0, 8)
    slotCorner.Parent = slotFrame
    
    -- Slot stroke
    local slotStroke = Instance.new("UIStroke")
    slotStroke.Color = Color3.fromRGB(60, 60, 60)
    slotStroke.Thickness = 2
    slotStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    slotStroke.Parent = slotFrame
    
    -- Item icon (hidden by default)
    local itemIcon = Instance.new("ImageLabel")
    itemIcon.Name = "ItemIcon"
    itemIcon.Size = UDim2.new(0.8, 0, 0.8, 0)
    itemIcon.Position = UDim2.new(0.1, 0, 0.1, 0)
    itemIcon.BackgroundTransparency = 1
    itemIcon.Image = "" -- Will be set by controller
    itemIcon.ScaleType = Enum.ScaleType.Fit
    itemIcon.Visible = false
    itemIcon.Parent = slotFrame
    
    -- Quantity label
    local quantityLabel = Instance.new("TextLabel")
    quantityLabel.Name = "QuantityLabel"
    quantityLabel.Size = UDim2.new(0, 30, 0, 20)
    quantityLabel.Position = UDim2.new(1, -32, 1, -22)
    quantityLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    quantityLabel.BackgroundTransparency = 0.3
    quantityLabel.BorderSizePixel = 0
    quantityLabel.Text = "0"
    quantityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    quantityLabel.TextSize = 14
    quantityLabel.Font = Enum.Font.GothamBold
    quantityLabel.TextStrokeTransparency = 0.5
    quantityLabel.Visible = false
    quantityLabel.Parent = slotFrame
    
    local quantityCorner = Instance.new("UICorner")
    quantityCorner.CornerRadius = UDim.new(0, 4)
    quantityCorner.Parent = quantityLabel
    
    -- Slot button for interaction
    local slotButton = Instance.new("TextButton")
    slotButton.Name = "SlotButton"
    slotButton.Size = UDim2.new(1, 0, 1, 0)
    slotButton.BackgroundTransparency = 1
    slotButton.Text = ""
    slotButton.Parent = slotFrame
    
    -- Hover effect
    slotButton.MouseEnter:Connect(function()
        local tween = TweenService:Create(
            slotFrame,
            TweenInfo.new(0.15),
            { BackgroundColor3 = Color3.fromRGB(50, 50, 50) }
        )
        tween:Play()
    end)
    
    slotButton.MouseLeave:Connect(function()
        local tween = TweenService:Create(
            slotFrame,
            TweenInfo.new(0.15),
            { BackgroundColor3 = Color3.fromRGB(40, 40, 40) }
        )
        tween:Play()
    end)
end

--[[
    Makes a frame draggable
]]
function InventoryUI._MakeDraggable(frame: Frame, dragHandle: Frame)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    dragHandle.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

return InventoryUI
