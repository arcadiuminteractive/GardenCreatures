--[[
    InventoryUIManager.lua
    Manages inventory UI initialization
    
    This script should be placed in StarterPlayer/StarterPlayerScripts/UI/
    and will be required by the InventoryController
]]

local InventoryUIManager = {}

-- Services
local Players = game:GetService("Players")

-- Module references
local InventoryButton = nil
local InventoryUI = nil

--[[
    Initializes all inventory UI components
]]
function InventoryUIManager.Init()
    print("🎨 Initializing Inventory UI Manager...")
    
    -- Get module references (these should be in the UI folder)
    local uiFolder = script.Parent
    
    -- Load InventoryButton module
    local buttonModule = uiFolder:FindFirstChild("InventoryButton")
    if buttonModule then
        InventoryButton = require(buttonModule)
    else
        warn("⚠️  InventoryButton module not found")
    end
    
    -- Load InventoryUI module
    local uiModule = uiFolder:FindFirstChild("InventoryUI")
    if uiModule then
        InventoryUI = require(uiModule)
    else
        warn("⚠️  InventoryUI module not found")
    end
    
    print("✅ Inventory UI Manager initialized")
end

--[[
    Creates all inventory UI components
]]
function InventoryUIManager.CreateUI()
    -- Create inventory button
    if InventoryButton then
        InventoryButton.Create()
    end
    
    -- Create inventory window
    if InventoryUI then
        InventoryUI.Create()
    end
    
    print("✅ Inventory UI components created")
end

return InventoryUIManager
