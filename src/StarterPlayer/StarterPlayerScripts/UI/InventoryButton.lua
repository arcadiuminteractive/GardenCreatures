--[[
    InventoryButton.lua
    Creates the inventory toggle button in the top-left corner
    
    Features:
    - Roblox-style UI design
    - Responsive hover effects
    - Icon display
    - In-line with base UI
]]

local InventoryButton = {}

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Constants
local BUTTON_SIZE = UDim2.new(0, 50, 0, 50)
local BUTTON_POSITION = UDim2.new(0, 10, 0, 10) -- Top-left corner
local ICON_ID = "rbxassetid://3926305904" -- Backpack icon (you can change this)

-- Tween info for animations
local HOVER_TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local CLICK_TWEEN_INFO = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

--[[
    Creates the inventory button UI
    @return ScreenGui - The created button UI
]]
function InventoryButton.Create()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Check if button already exists
    local existingButton = playerGui:FindFirstChild("InventoryButton")
    if existingButton then
        return existingButton
    end
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "InventoryButton"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 10 -- Above most UI
    
    -- Create main button frame
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Name = "Button"
    buttonFrame.Size = BUTTON_SIZE
    buttonFrame.Position = BUTTON_POSITION
    buttonFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    buttonFrame.BorderSizePixel = 0
    buttonFrame.Parent = screenGui
    
    -- UICorner for rounded corners (Roblox style)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = buttonFrame
    
    -- UIStroke for border
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 60, 60)
    stroke.Thickness = 2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = buttonFrame
    
    -- Icon
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0.7, 0, 0.7, 0)
    icon.Position = UDim2.new(0.15, 0, 0.15, 0)
    icon.BackgroundTransparency = 1
    icon.Image = ICON_ID
    icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Parent = buttonFrame
    
    -- TextButton for interaction
    local button = Instance.new("TextButton")
    button.Name = "Clickable"
    button.Size = UDim2.new(1, 0, 1, 0)
    button.Position = UDim2.new(0, 0, 0, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = buttonFrame
    
    -- Hover effect
    button.MouseEnter:Connect(function()
        local hoverTween = TweenService:Create(
            buttonFrame,
            HOVER_TWEEN_INFO,
            {
                BackgroundColor3 = Color3.fromRGB(35, 35, 35),
                Size = BUTTON_SIZE + UDim2.new(0, 4, 0, 4)
            }
        )
        hoverTween:Play()
        
        local strokeTween = TweenService:Create(
            stroke,
            HOVER_TWEEN_INFO,
            { Color = Color3.fromRGB(100, 100, 100) }
        )
        strokeTween:Play()
    end)
    
    button.MouseLeave:Connect(function()
        local leaveTween = TweenService:Create(
            buttonFrame,
            HOVER_TWEEN_INFO,
            {
                BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                Size = BUTTON_SIZE
            }
        )
        leaveTween:Play()
        
        local strokeTween = TweenService:Create(
            stroke,
            HOVER_TWEEN_INFO,
            { Color = Color3.fromRGB(60, 60, 60) }
        )
        strokeTween:Play()
    end)
    
    -- Click effect
    button.MouseButton1Down:Connect(function()
        local clickTween = TweenService:Create(
            buttonFrame,
            CLICK_TWEEN_INFO,
            { Size = BUTTON_SIZE - UDim2.new(0, 4, 0, 4) }
        )
        clickTween:Play()
    end)
    
    button.MouseButton1Up:Connect(function()
        local releaseTween = TweenService:Create(
            buttonFrame,
            CLICK_TWEEN_INFO,
            { Size = BUTTON_SIZE + UDim2.new(0, 4, 0, 4) }
        )
        releaseTween:Play()
    end)
    
    -- Parent to PlayerGui
    screenGui.Parent = playerGui
    
    print("✅ Inventory button created")
    return screenGui
end

return InventoryButton
