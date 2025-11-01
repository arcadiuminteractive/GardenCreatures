--[[
    Server.server.lua - REFACTORED FOR PROPER INITIALIZATION
    Main server initialization script
    
    ✅ BEST PRACTICES IMPLEMENTED:
    1. Initialize shared configs on server first
    2. Load dependencies in correct order
    3. Single initialization point
    4. Clear startup logging
    5. Proper error handling
    
    ✅ FIXED ISSUES:
    1. Print statements appearing before modules are loaded (lines 42-43, 111)
    2. Missing error handling for DataManager and AdminCommands loading
    3. No verification that InventoryManager loaded successfully
]]

-- ============================
-- SERVICES
-- ============================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

-- ============================
-- 🔍 DIAGNOSTIC: ProfileStore Loading
-- ============================
print("🔍 Attempting to load ProfileStore...")

local ProfileStoreModule = ServerScriptService:WaitForChild("ProfileStore", 10)
if not ProfileStoreModule then
    error("❌ ProfileStore not found after waiting 10 seconds")
end
print("✅ Found ProfileStore")

print("📋 ProfileStore ClassName:", ProfileStoreModule.ClassName)
if not ProfileStoreModule:IsA("ModuleScript") then
    error("❌ ProfileStore is not a ModuleScript!")
end
print("✅ ProfileStore is a ModuleScript")

print("📦 Attempting to require ProfileStore...")
local success, result = pcall(require, ProfileStoreModule)

if success then
    print("✅ ProfileStore loaded successfully!")
    print("📦 Module type:", type(result))
    if type(result) == "table" then
        print("📋 Module contents:")
        for key, value in pairs(result) do
            print("  -", key, ":", type(value))
        end
    end
else
    error("❌ Failed to require ProfileStore: " .. tostring(result))
end

local ProfileStore = result

-- ============================
-- Continue with rest of your server code...
-- ============================

-- ============================
-- STARTUP
-- ============================
print("🌱 Garden Creatures - Server Starting...")

-- ============================
-- SHARED CONFIGURATION INITIALIZATION
-- ============================
-- Initialize Items config ONCE on server startup
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigFolder = Shared:WaitForChild("Config")
local ItemsConfig = require(ConfigFolder:WaitForChild("Items"))

-- This is the ONLY place Items.Initialize() should be called
ItemsConfig.Initialize()

-- ============================
-- LOAD MANAGERS & SYSTEMS
-- ============================

-- Data Management (with error handling)
local DataManager
local dataManagerSuccess, dataManagerError = pcall(function()
    local DataFolder = ServerScriptService:WaitForChild("Data")
    DataManager = require(DataFolder:WaitForChild("DataManager"))
end)

if dataManagerSuccess and DataManager then
    print("✅ DataManager loaded successfully!")
else
    warn("❌ Failed to load DataManager:", dataManagerError or "Unknown error")
    error("CRITICAL: Cannot start server without DataManager")
end

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
print("📦 Loading game systems...")

-- Load game systems
local systems = {}
local systemModules = {
    InventoryManager = {
        path = {"Systems", "InventorySystem", "InventoryManager"},
        parent = ServerScriptService
    },
    CreaturePlotManager = {
        path = {"Systems", "CreaturePlotSystem", "CreaturePlotManager"},
        parent = ServerScriptService
    },
    ItemSpawnController = {
        path = {"Systems", "ItemSpawnSystem", "ItemSpawnController"},
        parent = ServerScriptService
    },
    -- Add more systems here as they're created
    -- GardeningSystem = {
    --     path = {"Systems", "GardeningSystem", "GardeningManager"},
    --     parent = ServerScriptService
    -- },
    -- CraftingSystem = {
    --     path = {"Systems", "CraftingSystem", "CraftingManager"},
    --     parent = ServerScriptService
    -- },
}

-- Load all systems with detailed error reporting
for name, config in pairs(systemModules) do
    local success, result = pcall(function()
        local current = config.parent
        for _, childName in ipairs(config.path) do
            current = current:WaitForChild(childName, 5)
            if not current then
                error("Failed to find child: " .. childName)
            end
        end
        return require(current)
    end)
    
    if success then
        systems[name] = result
        print("✅ Loaded system:", name)
    else
        warn("❌ Failed to load system:", name, "Error:", result)
    end
end

-- ✅ VERIFY CRITICAL SYSTEMS LOADED
if not systems.InventoryManager then
    warn("⚠️ InventoryManager failed to load - inventory functionality will not work!")
end

-- Initialize systems in dependency order
print("🔧 Initializing systems...")
for name, system in pairs(systems) do
    if system.Init then
        local success, err = pcall(system.Init)
        if success then
            print("✅ Initialized:", name)
        else
            warn("❌ Failed to initialize system:", name, "Error:", err)
        end
    end
end

-- Start systems
print("▶️ Starting systems...")
for name, system in pairs(systems) do
    if system.Start then
        local success, err = pcall(system.Start)
        if success then
            print("✅ Started:", name)
        else
            warn("❌ Failed to start system:", name, "Error:", err)
        end
    end
end

-- ============================
-- PLAYER MANAGEMENT
-- ============================

local function HandlePlayerJoin(player)
    print("👤 Player joined:", player.Name, "(UserId:", player.UserId .. ")")
    
    -- Wait for character
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    
    -- Load player data
    local dataSuccess, dataErr = pcall(DataManager.LoadPlayerData, player)
    if not dataSuccess then
        warn("❌ Failed to load player data for", player.Name, ":", dataErr)
        player:Kick("Failed to load player data. Please rejoin.")
        return
    end
    
    -- ✅ Setup inventory
    if systems.InventoryManager and systems.InventoryManager.SetupPlayer then
        print("🎒 Setting up inventory for", player.Name)
        local invSuccess, invErr = pcall(systems.InventoryManager.SetupPlayer, player)
        if invSuccess then
            print("✅ Inventory setup completed for", player.Name)
        else
            warn("❌ Failed to setup inventory for", player.Name, ":", invErr)
        end
    else
        warn("⚠️ InventoryManager.SetupPlayer not available!")
    end
    
    -- Setup creature plots
    if systems.CreaturePlotManager and systems.CreaturePlotManager.SetupPlayerPlots then
        local plotSuccess, plotErr = pcall(systems.CreaturePlotManager.SetupPlayerPlots, player)
        if not plotSuccess then
            warn("❌ Failed to setup creature plots for", player.Name, ":", plotErr)
        end
    end
    
    -- Welcome message
    task.wait(2)
    print("🌱 Welcome to Garden Creatures!")
end

-- Connect for future players
Players.PlayerAdded:Connect(HandlePlayerJoin)

-- ✅ Handle players already in game (important for Studio testing)
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(HandlePlayerJoin, player)
end

-- ✅ SEPARATE PlayerRemoving handler (NOT inside PlayerAdded!)
Players.PlayerRemoving:Connect(function(player)
    if not player then
        warn("⚠️ PlayerRemoving called with nil player")
        return
    end
    
    print("👋 Player leaving:", player.Name)
    
    -- Cleanup inventory
    if systems.InventoryManager then
        local cleanup = systems.InventoryManager.CleanupPlayer or systems.InventoryManager.CleanupInventory
        if cleanup then
            local success, err = pcall(cleanup, player)
            if not success then
                warn("❌ Failed to cleanup inventory for", player.Name, ":", err)
            end
        end
    end
    
    -- Cleanup creature plots
    if systems.CreaturePlotManager and systems.CreaturePlotManager.CleanupPlayerPlots then
        local success, err = pcall(systems.CreaturePlotManager.CleanupPlayerPlots, player)
        if not success then
            warn("❌ Failed to cleanup creature plots for", player.Name, ":", err)
        else
            print("✅ Cleaned up creature plots for", player.Name)
        end
    end
    
    -- Save and release player data
    local success, err = pcall(DataManager.UnloadPlayerData, player)
    if not success then
        warn("❌ Failed to unload player data for", player.Name, ":", err)
    end
end)
    
    -- Welcome message
    task.wait(2)
    print("🌱 Welcome to Garden Creatures, " .. player.Name .. "!")

-- Connect for future players
Players.PlayerAdded:Connect(HandlePlayerJoin)

-- ✅ Handle players already in game (important for Studio testing)
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(HandlePlayerJoin, player)
end

Players.PlayerRemoving:Connect(function(player)
    print("👋 Player leaving:", player.Name)
    
    -- [rest of your PlayerRemoving code...]
end)
    
    -- Welcome message
    task.wait(2)
    print("🌱 Welcome to Garden Creatures, " .. player.Name .. "!")

Players.PlayerRemoving:Connect(function(player)
    print("👋 Player leaving:", player.Name)
    
    -- Cleanup inventory (with safety check)
    if systems.InventoryManager then
        local cleanup = systems.InventoryManager.CleanupPlayer or systems.InventoryManager.CleanupInventory
        if cleanup then
            local success, err = pcall(cleanup, player)
            if not success then
                warn("❌ Failed to cleanup inventory for", player.Name, ":", err)
            end
        end
    end
    
    -- Cleanup creature plots (with safety check)
    if systems.CreaturePlotManager and systems.CreaturePlotManager.CleanupPlayerPlots then
        local success, err = pcall(systems.CreaturePlotManager.CleanupPlayerPlots, player)
        if not success then
            warn("❌ Failed to cleanup creature plots for", player.Name, ":", err)
        end
    end
    
    -- Save and release player data
    local success, err = pcall(DataManager.UnloadPlayerData, player)
    if not success then
        warn("❌ Failed to unload player data for", player.Name, ":", err)
    end
end)

-- ============================
-- SHUTDOWN HANDLING
-- ============================

game:BindToClose(function()
    print("🛑 Server shutting down...")
    
    -- Save all data
    local success, err = pcall(DataManager.SaveAllData)
    if not success then
        warn("❌ Error saving all data during shutdown:", err)
    end
    
    -- Cleanup all systems
    if systems.InventoryManager and systems.InventoryManager.SaveAllInventories then
        local invSuccess, invErr = pcall(systems.InventoryManager.SaveAllInventories)
        if not invSuccess then
            warn("❌ Error saving inventories during shutdown:", invErr)
        end
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

print("\n" .. string.rep("=", 50))
print("✅ Garden Creatures - Server Started Successfully!")
print("🌱 Version: 0.1.0 Alpha")
print("📊 Systems Loaded:", systemCount)
print("🎮 Ready for players!")
print(string.rep("=", 50) .. "\n")

-- ============================
-- DIAGNOSTIC INFO
-- ============================
if systems.InventoryManager then
    print("✅ Inventory is managed separately by InventoryManager")
    if systems.InventoryManager.IsPlayerReady then
        print("✅ Inventory readiness checking available")
    else
        print("⚠️ Inventory readiness checking NOT available - consider implementing")
    end
else
    warn("❌ InventoryManager not loaded - inventory features will not work!")
end
