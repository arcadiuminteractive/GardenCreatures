--[[
    Server.server.lua - REFACTORED FOR PROPER INITIALIZATION
    Main server initialization script
    
    ✅ BEST PRACTICES IMPLEMENTED:
    1. Initialize shared configs on server first
    2. Load dependencies in correct order
    3. Single initialization point
    4. Clear startup logging
    5. Proper error handling
]]

-- ============================
-- SERVICES
-- ============================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

-- ============================
-- STARTUP
-- ============================
print("🌱 Garden Creatures - Server Starting...")

-- ============================
-- SHARED CONFIGURATION INITIALIZATION
-- ============================
-- Initialize Items config ONCE on server startup
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemsConfig = require(Shared.Config.Items)

-- This is the ONLY place Items.Initialize() should be called
ItemsConfig.Initialize()

-- ============================
-- LOAD MANAGERS & SYSTEMS
-- ============================

-- Data Management
local DataManager = require(ServerScriptService.Data.DataManager)
print("✅ DataManager loaded successfully!")
print("✅ Inventory is managed separately by InventoryManager")

-- Admin Commands
local AdminCommands = require(ServerScriptService.AdminCommands)
print("✅ Admin Commands loaded")

-- ============================
-- REMOTE EVENTS SETUP
-- ============================
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not RemoteEvents then
    RemoteEvents = Instance.new("Folder")
    RemoteEvents.Name = "RemoteEvents"
    RemoteEvents.Parent = ReplicatedStorage
    print("📡 Created RemoteEvents folder")
end

-- Define all remote events (one-way communication)
local remoteEventNames = {
    -- Inventory
    "UpdateInventory",
    -- NOTE: RequestInventory is a RemoteFunction (created separately below)
    -- Item Collection
    "CollectItem",
    "ItemCollected",
    -- Creature Plots
    "PlacePlotItem",
    "RemovePlotItem",
    "ConfirmCreature",
    "CreaturePlotUpdated",
    -- Gardening
    "PlantSeed",
    "HarvestPlant",
    "WaterPlant",
    -- Crafting
    "CraftRecipe",
    -- Trading
    "SendTradeRequest",
    "AcceptTrade",
}

print("📡 Creating RemoteEvents...")
for _, eventName in ipairs(remoteEventNames) do
    if not RemoteEvents:FindFirstChild(eventName) then
        local remoteEvent = Instance.new("RemoteEvent")
        remoteEvent.Name = eventName
        remoteEvent.Parent = RemoteEvents
    end
end

-- Create RemoteFunctions separately (don't include in RemoteEvents list above)
local RequestInventoryFunc = RemoteEvents:FindFirstChild("RequestInventory")
if not RequestInventoryFunc or not RequestInventoryFunc:IsA("RemoteFunction") then
    -- Remove old RemoteEvent if it exists
    if RequestInventoryFunc then
        RequestInventoryFunc:Destroy()
    end
    RequestInventoryFunc = Instance.new("RemoteFunction")
    RequestInventoryFunc.Name = "RequestInventory"
    RequestInventoryFunc.Parent = RemoteEvents
end

print("✅ RemoteEvents initialized with " .. #remoteEventNames .. " events")
print("✅ RemoteFunctions initialized (RequestInventory)")

-- ============================
-- LOAD GAME SYSTEMS
-- ============================
print("✅ DataManager loaded")

-- Load game systems
local systems = {}
local systemModules = {
    InventoryManager = ServerScriptService.Systems.InventorySystem.InventoryManager,
    CreaturePlotManager = ServerScriptService.Systems.CreaturePlotSystem.CreaturePlotManager,
    ItemSpawnController = ServerScriptService.Systems.ItemSpawnSystem.ItemSpawnController,
    -- Add more systems here as they're created
    -- GardeningSystem = ServerScriptService.Systems.GardeningSystem.GardeningManager,
    -- CraftingSystem = ServerScriptService.Systems.CraftingSystem.CraftingManager,
}

-- Load all systems
for name, module in pairs(systemModules) do
    local success, system = pcall(require, module)
    if success then
        systems[name] = system
        print("✅ Loaded system:", name)
    else
        warn("❌ Failed to load system:", name, system)
    end
end

-- Initialize systems in dependency order
for name, system in pairs(systems) do
    if system.Init then
        local success, err = pcall(system.Init)
        if not success then
            warn("❌ Failed to initialize system:", name, err)
        end
    end
end

-- Start systems
for name, system in pairs(systems) do
    if system.Start then
        local success, err = pcall(system.Start)
        if not success then
            warn("❌ Failed to start system:", name, err)
        end
    end
end

-- ============================
-- PLAYER MANAGEMENT
-- ============================

Players.PlayerAdded:Connect(function(player)
    print("👤 Player joined:", player.Name)
    
    -- Admin check
    AdminCommands.OnPlayerJoined(player)
    
    -- Wait for character
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    
    -- Load player data
    DataManager.LoadPlayerData(player)
    
    -- Setup inventory
    if systems.InventoryManager and systems.InventoryManager.SetupPlayer then
        systems.InventoryManager.SetupPlayer(player)
    end
    
    -- Setup creature plots
    if systems.CreaturePlotManager then
        systems.CreaturePlotManager.SetupPlayerPlots(player)
    end
    
    -- Welcome message
    task.wait(2)
    print("🌱 Welcome to Garden Creatures, " .. player.Name .. "!")
end)

Players.PlayerRemoving:Connect(function(player)
    print("👋 Player leaving:", player.Name)
    
    -- Cleanup inventory (with safety check)
    if systems.InventoryManager then
        local cleanup = systems.InventoryManager.CleanupPlayer or systems.InventoryManager.CleanupInventory
        if cleanup then
            cleanup(player)
        end
    end
    
    -- Cleanup creature plots (with safety check)
    if systems.CreaturePlotManager and systems.CreaturePlotManager.CleanupPlayerPlots then
        systems.CreaturePlotManager.CleanupPlayerPlots(player)
    end
    
    -- Save and release player data
    DataManager.UnloadPlayerData(player)
end)

-- ============================
-- SHUTDOWN HANDLING
-- ============================

game:BindToClose(function()
    print("🛑 Server shutting down...")
    
    -- Save all data
    DataManager.SaveAllData()
    
    -- Cleanup all systems
    if systems.InventoryManager and systems.InventoryManager.SaveAllInventories then
        systems.InventoryManager.SaveAllInventories()
    end
    
    -- Wait for saves to complete
    task.wait(3)
    print("💾 All data saved. Goodbye!")
end)

-- ============================
-- SERVER READY
-- ============================

-- Count loaded systems
local systemCount = 0
for _ in pairs(systems) do
    systemCount = systemCount + 1
end

print("✅ Garden Creatures - Server Started Successfully!")
print("🌱 Version: 0.1.0 Alpha")
print("📊 Systems Loaded:", systemCount)
print("🎮 Ready for players!")
