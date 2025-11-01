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

-- Data Management (with error handling)
local DataManager
local dataManagerSuccess, dataManagerError = pcall(function()
    DataManager = require(ServerScriptService.Data.DataManager)
end)

if dataManagerSuccess and DataManager then
    print("✅ DataManager loaded successfully!")
else
    warn("❌ Failed to load DataManager:", dataManagerError or "Unknown error")
    error("CRITICAL: Cannot start server without DataManager")
end

-- Admin Commands (with error handling)
local AdminCommands
local adminSuccess, adminError = pcall(function()
    AdminCommands = require(ServerScriptService.AdminCommands)
end)

if adminSuccess and AdminCommands then
    print("✅ Admin Commands loaded")
else
    warn("❌ Failed to load AdminCommands:", adminError or "Unknown error")
    -- Not critical, create stub
    AdminCommands = {
        OnPlayerJoined = function() end
    }
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
    InventoryManager = ServerScriptService.Systems.InventorySystem.InventoryManager,
    CreaturePlotManager = ServerScriptService.Systems.CreaturePlotSystem.CreaturePlotManager,
    ItemSpawnController = ServerScriptService.Systems.ItemSpawnSystem.ItemSpawnController,
    -- Add more systems here as they're created
    -- GardeningSystem = ServerScriptService.Systems.GardeningSystem.GardeningManager,
    -- CraftingSystem = ServerScriptService.Systems.CraftingSystem.CraftingManager,
}

-- Load all systems with detailed error reporting
for name, module in pairs(systemModules) do
    local success, system = pcall(require, module)
    if success then
        systems[name] = system
        print("✅ Loaded system:", name)
    else
        warn("❌ Failed to load system:", name, "Error:", system)
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

Players.PlayerAdded:Connect(function(player)
    print("👤 Player joined:", player.Name, "(UserId:", player.UserId .. ")")
    
    -- Admin check
    if AdminCommands and AdminCommands.OnPlayerJoined then
        local success, err = pcall(AdminCommands.OnPlayerJoined, player)
        if not success then
            warn("❌ Admin check failed for", player.Name, ":", err)
        end
    end
    
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
    
    -- ✅ Setup inventory with proper error handling and logging
    if systems.InventoryManager then
        if systems.InventoryManager.SetupPlayer then
            print("🎒 Setting up inventory for", player.Name)
            local invSuccess, invErr = pcall(systems.InventoryManager.SetupPlayer, player)
            if invSuccess then
                print("✅ Inventory setup completed for", player.Name)
                
                -- ✅ WAIT FOR INVENTORY TO BE READY (if function exists)
                if systems.InventoryManager.IsPlayerReady then
                    local maxWait = 30  -- 30 second timeout
                    local waited = 0
                    local startTime = tick()
                    
                    while not systems.InventoryManager.IsPlayerReady(player) and waited < maxWait do
                        task.wait(0.1)
                        waited = waited + 0.1
                    end
                    
                    if systems.InventoryManager.IsPlayerReady(player) then
                        print("✅ Inventory confirmed ready for", player.Name, "in", string.format("%.2f", tick() - startTime), "seconds")
                    else
                        warn("⚠️ Inventory load timeout for", player.Name, "- may experience issues")
                    end
                else
                    -- IsPlayerReady function doesn't exist yet
                    print("⚠️ IsPlayerReady function not found - assuming inventory is ready")
                end
            else
                warn("❌ Failed to setup inventory for", player.Name, ":", invErr)
            end
        else
            warn("⚠️ InventoryManager.SetupPlayer function not found!")
        end
    else
        warn("⚠️ InventoryManager system not loaded!")
    end
    
    -- Setup creature plots
    if systems.CreaturePlotManager then
        if systems.CreaturePlotManager.SetupPlayerPlots then
            local plotSuccess, plotErr = pcall(systems.CreaturePlotManager.SetupPlayerPlots, player)
            if not plotSuccess then
                warn("❌ Failed to setup creature plots for", player.Name, ":", plotErr)
            end
        end
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
