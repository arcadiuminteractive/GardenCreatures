--[[
    Client.client.lua - REFACTORED FOR CLIENT-SIDE BEST PRACTICES
    Main client initialization script
    
    ✅ BEST PRACTICES IMPLEMENTED:
    1. Client does NOT initialize Items config
    2. Client receives item data from server via RemoteEvents
    3. Only loads UI controllers and visual systems
    4. Waits for server data before proceeding
    5. Clean separation of concerns
]]

-- ============================
-- SERVICES
-- ============================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- ============================
-- REFERENCES
-- ============================
local LocalPlayer = Players.LocalPlayer

-- ============================
-- STARTUP
-- ============================
print("🌱 Garden Creatures - Client Starting...")

-- ============================
-- WAIT FOR SERVER
-- ============================
-- Wait for RemoteEvents to be created by server
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
if not RemoteEvents then
    warn("❌ Failed to connect to server - RemoteEvents not found!")
    return
end

-- Wait for essential RemoteEvents
local UpdateInventory = RemoteEvents:WaitForChild("UpdateInventory", 10)
local RequestInventory = RemoteEvents:WaitForChild("RequestInventory", 10)

if not UpdateInventory or not RequestInventory then
    warn("❌ Failed to connect to server - Essential RemoteEvents not found!")
    return
end

-- ============================
-- SHARED CONFIGURATION
-- ============================
-- Items config is available for reading (templates, rarities, etc.)
-- but we do NOT call Initialize() on client
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemsConfig = require(Shared.Config.Items)

-- NOTE: We do NOT call ItemsConfig.Initialize() here!
-- The server has already initialized it and will send us the data we need

-- ============================
-- LOAD CONTROLLERS
-- ============================
local controllers = {}
local controllerModules = {
    ItemCollectionController = script.Parent.Controllers.ItemCollectionController,
    InventoryController = script.Parent.Controllers.InventoryController,
    -- Add more controllers here as they're created
    -- GardeningController = script.Parent.Controllers.GardeningController,
    -- CreatureController = script.Parent.Controllers.CreatureController,
}

-- Load all controllers
for name, module in pairs(controllerModules) do
    local success, controller = pcall(require, module)
    if success then
        controllers[name] = controller
        print("✅ Loaded controller:", name)
    else
        warn("❌ Failed to load controller:", name, controller)
    end
end

-- Initialize controllers
for name, controller in pairs(controllers) do
    if controller.Init then
        local success, err = pcall(controller.Init)
        if not success then
            warn("❌ Failed to initialize controller:", name, err)
        end
    end
end

-- ============================
-- WAIT FOR CHARACTER
-- ============================
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- ============================
-- START CONTROLLERS
-- ============================
-- Start controllers after character is loaded
for name, controller in pairs(controllers) do
    if controller.Start then
        local success, err = pcall(controller.Start)
        if not success then
            warn("❌ Failed to start controller:", name, err)
        end
    end
end

-- ============================
-- CLIENT READY
-- ============================
-- Wait a moment for initial data sync
task.wait(0.5)

print("✅ Garden Creatures - Client Started Successfully!")
print("👤 Welcome, " .. LocalPlayer.Name .. "!")

-- Signal to server that client is ready (optional)
task.wait(1)
print("🌱 Client ready!")
