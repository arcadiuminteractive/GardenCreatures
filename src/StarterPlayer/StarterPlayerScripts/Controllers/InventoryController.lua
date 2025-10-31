--[[
    InventoryController.lua
    Client-side controller for player inventory management
    
    Features:
    - Open/close inventory UI
    - Display inventory slots (10 slots: 5 columns x 2 rows)
    - Item stacking (max 10 per slot, 100 total capacity)
    - Item selection and interaction
    - Real-time inventory updates from server
]]

local InventoryController = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local ItemsConfig = require(Config:WaitForChild("Items"))

-- Constants
local INVENTORY_SLOTS = 10
local MAX_STACK_SIZE = 10
local TOGGLE_KEY = Enum.KeyCode.B -- 'B' key to toggle inventory

-- State
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local inventoryData = {} -- Local cache of inventory data
local isInventoryOpen = false
local inventoryUI = nil
local inventoryButton = nil

-- RemoteEvents
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RequestInventory = nil
local UpdateInventoryEvent = nil

-- ============================
-- INITIALIZATION
-- ============================

function InventoryController.Init()
    print("🎒 Initializing Inventory Controller...")
    
    -- Setup RemoteEvents
    InventoryController._SetupRemotes()
    
    -- Initialize inventory data
    InventoryController._InitializeInventoryData()
    
    -- Setup input handling
    InventoryController._SetupInput()
    
    print("✅ Inventory Controller initialized")
end

function InventoryController.Start()
    print("🎒 Starting Inventory Controller...")
    
    -- Load and initialize UI modules
    local UI = script.Parent.Parent.UI
    
    -- Load InventoryButton module
    local InventoryButton = UI:FindFirstChild("InventoryButton")
    if InventoryButton then
        local buttonModule = require(InventoryButton)
        inventoryButton = buttonModule.Create()
        
        -- Connect button click
        local button = inventoryButton:FindFirstChild("Button")
        if button then
            local clickable = button:FindFirstChild("Clickable")
            if clickable then
                clickable.Activated:Connect(function()
                    InventoryController.ToggleInventory()
                end)
            end
        end
        print("✅ Inventory button created")
    else
        warn("⚠️  InventoryButton module not found in UI folder")
    end
    
    -- Load InventoryUI module
    local InventoryUIModule = UI:FindFirstChild("InventoryUI")
    if InventoryUIModule then
        local uiModule = require(InventoryUIModule)
        inventoryUI = uiModule.Create()
        
        -- Setup close button
        local mainFrame = inventoryUI:FindFirstChild("MainFrame")
        if mainFrame then
            local titleBar = mainFrame:FindFirstChild("TitleBar")
            if titleBar then
                local closeButton = titleBar:FindFirstChild("CloseButton")
                if closeButton then
                    closeButton.Activated:Connect(function()
                        InventoryController.CloseInventory()
                    end)
                end
            end
        end
        print("✅ Inventory UI created")
    else
        warn("⚠️  InventoryUI module not found in UI folder")
    end
    
    -- Request initial inventory data from server
    if RequestInventory then
        local success, result = pcall(function()
            return RequestInventory:InvokeServer()
        end)
        
        if success and result then
            InventoryController._OnInventoryUpdate(result)
        end
    end
    
    print("✅ Inventory Controller started")
end

-- ============================
-- SETUP
-- ============================

function InventoryController._SetupRemotes()
    -- Create RemoteEvents folder if it doesn't exist
    if not ReplicatedStorage:FindFirstChild("RemoteEvents") then
        local remoteFolder = Instance.new("Folder")
        remoteFolder.Name = "RemoteEvents"
        remoteFolder.Parent = ReplicatedStorage
    end
    
    -- Get or create RemoteFunction for inventory requests
    RequestInventory = RemoteEvents:FindFirstChild("RequestInventory")
    if not RequestInventory then
        warn("⚠️  RequestInventory RemoteFunction not found - inventory may not sync properly")
    end
    
    -- Get or create RemoteEvent for inventory updates
    UpdateInventoryEvent = RemoteEvents:FindFirstChild("UpdateInventory")
    if not UpdateInventoryEvent then
        warn("⚠️  UpdateInventory RemoteEvent not found - inventory may not update")
    else
        -- Listen for inventory updates from server
        UpdateInventoryEvent.OnClientEvent:Connect(function(newInventoryData)
            InventoryController._OnInventoryUpdate(newInventoryData)
        end)
    end
end

function InventoryController._InitializeInventoryData()
    -- Initialize empty inventory slots
    inventoryData = {}
    for i = 1, INVENTORY_SLOTS do
        inventoryData[i] = {
            itemId = nil,
            itemName = nil,
            quantity = 0,
        }
    end
end

function InventoryController._SetupInput()
    -- Toggle inventory with 'B' key
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        
        if input.KeyCode == TOGGLE_KEY then
            InventoryController.ToggleInventory()
        end
    end)
end

function InventoryController._GetItemConfig(itemId: string): any?
    for _, item in ipairs(ItemsConfig.items) do
        if item.id == itemId then
            return item
        end
    end
    return nil
end

-- ============================
-- INVENTORY MANAGEMENT
-- ============================

function InventoryController.ToggleInventory()
    if isInventoryOpen then
        InventoryController.CloseInventory()
    else
        InventoryController.OpenInventory()
    end
end

function InventoryController.OpenInventory()
    if not inventoryUI then
        warn("⚠️  Cannot open inventory - UI not found")
        return
    end
    
    isInventoryOpen = true
    inventoryUI.Enabled = true
    
    -- Refresh inventory display
    InventoryController._RefreshInventoryDisplay()
    
    print("🎒 Inventory opened")
end

function InventoryController.CloseInventory()
    if not inventoryUI then return end
    
    isInventoryOpen = false
    inventoryUI.Enabled = false
    
    print("🎒 Inventory closed")
end

function InventoryController._OnInventoryUpdate(newInventoryData)
    -- Update local inventory cache
    inventoryData = newInventoryData or inventoryData
    
    -- Refresh display if inventory is open
    if isInventoryOpen then
        InventoryController._RefreshInventoryDisplay()
    end
    
    print("🎒 Inventory updated from server")
end

function InventoryController._RefreshInventoryDisplay()
    if not inventoryUI then return end
    
    -- Find inventory slots container (it's inside MainFrame)
    local mainFrame = inventoryUI:FindFirstChild("MainFrame")
    if not mainFrame then
        warn("⚠️  MainFrame not found in InventoryUI")
        return
    end
    
    local slotsContainer = mainFrame:FindFirstChild("SlotsContainer")
    if not slotsContainer then
        warn("⚠️  SlotsContainer not found in MainFrame")
        return
    end
    
    -- Update each slot
    for slotIndex = 1, INVENTORY_SLOTS do
        local slotFrame = slotsContainer:FindFirstChild("Slot" .. slotIndex)
        if slotFrame then
            local itemData = inventoryData[slotIndex]
            
            -- Update slot display
            local itemIcon = slotFrame:FindFirstChild("ItemIcon")
            local quantityLabel = slotFrame:FindFirstChild("QuantityLabel")
            
            if itemData and itemData.quantity > 0 then
    -- Show item
    if itemIcon then
        itemIcon.Visible = true
        
        -- ✅ Look up seed config and set icon
        local itemConfig = InventoryController._GetItemConfig(itemData.itemId)
        if itemConfig and itemConfig.icon then
            itemIcon.Image = itemConfig.icon
        else
            itemIcon.Visible = false
            warn("⚠️  No icon found for item:", itemData.itemId)
        end
    end
    
    if quantityLabel then
        quantityLabel.Visible = true
        quantityLabel.Text = tostring(itemData.quantity)
    end
                
                if quantityLabel then
                    quantityLabel.Visible = true
                    quantityLabel.Text = tostring(itemData.quantity)
                end
            else
                -- Empty slot
                if itemIcon then
                    itemIcon.Visible = false
                end
                
                if quantityLabel then
                    quantityLabel.Visible = false
                end
            end
        end
    end
end

-- ============================
-- PUBLIC API
-- ============================

function InventoryController.GetInventoryData()
    return inventoryData
end

function InventoryController.IsInventoryOpen(): boolean
    return isInventoryOpen
end

function InventoryController.GetTotalItemCount(): number
    local total = 0
    for _, slot in ipairs(inventoryData) do
        total = total + slot.quantity
    end
    return total
end

function InventoryController.GetSlotCount(): number
    return INVENTORY_SLOTS
end

function InventoryController.GetMaxStackSize(): number
    return MAX_STACK_SIZE
end

print("✅ InventoryController loaded")

return InventoryController