--[[
    Server.server.lua
    Main server entry point for Garden Creatures
    
    Place this file in: ServerScriptService/Server.server.lua
    
    Initializes all server systems and manages game state
]]

print("🌱 Garden Creatures - Server Starting...")

-- Get services
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for critical folders
local Systems = ServerScriptService:WaitForChild("Systems")
local Data = ServerScriptService:WaitForChild("Data")
local Shared = ReplicatedStorage:WaitForChild("Shared")

-- Load configuration
local Config = {
    Seeds = require(Shared.Config.Seeds),
    Plants = require(Shared.Config.Plants),
    Recipes = require(Shared.Config.Recipes),
    Creatures = require(Shared.Config.Creatures),
    Economy = require(Shared.Config.Economy),
    WildSpawns = require(Shared.Config.WildSpawns),
}

-- Load DataManager first (critical!)
local DataManager = require(Data.DataManager)
print("✅ DataManager loaded")

-- Initialize other systems
local LoadedSystems = {
    DataManager = DataManager,
}

-- Systems to load (in order)
local SystemsToLoad = {
    { folder = "SeedSpawnSystem", module = "SeedSpawnController" },
    -- { folder = "EconomySystem", module = "CurrencyManager" },
    -- { folder = "InventorySystem", module = "InventoryManager" },
    -- { folder = "GardeningSystem", module = "PlantManager" },
    -- { folder = "CraftingSystem", module = "RecipeManager" },
    -- { folder = "CreatureSystem", module = "CreatureManager" },
    -- { folder = "TradingSystem", module = "TradeManager" },
    -- { folder = "HomeBaseSystem", module = "HomeBaseManager" },
    -- { folder = "CreatureSystem", module = "WildSpawnController" },
}

-- Load systems
for _, systemInfo in ipairs(SystemsToLoad) do
    local success, result = pcall(function()
        local folder = Systems:FindFirstChild(systemInfo.folder)
        if folder then
            local module = folder:FindFirstChild(systemInfo.module)
            if module then
                return require(module)
            end
        end
        return nil
    end)
    
    if success and result then
        LoadedSystems[systemInfo.module] = result
        print("✅ Loaded system:", systemInfo.module)
        
        -- Initialize if Init method exists
        if result.Init then
            local initSuccess, initError = pcall(result.Init)
            if not initSuccess then
                warn("❌ Failed to initialize:", systemInfo.module, initError)
            end
        end
    else
        warn("⚠️  System not found or failed to load:", systemInfo.folder .. "/" .. systemInfo.module)
    end
end

-- ============================
-- PLAYER MANAGEMENT
-- ============================

Players.PlayerAdded:Connect(function(player)
    print("👤 Player joined:", player.Name)
    
    -- Initialize player data (critical!)
    local success = DataManager.InitializePlayer(player)
    
    if success then
        -- Setup other systems after data loads
        for systemName, system in pairs(LoadedSystems) do
            if system.SetupPlayer then
                local setupSuccess, setupError = pcall(function()
                    system.SetupPlayer(player)
                end)
                
                if not setupSuccess then
                    warn("❌ Failed to setup player for system:", systemName, setupError)
                end
            end
        end
        
        -- Welcome message
        task.wait(2)
        print("🌱 Welcome to Garden Creatures,", player.Name .. "!")
        
        -- TODO: Fire RemoteEvent to show welcome UI
    else
        warn("❌ Failed to initialize player data for:", player.Name)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    print("👋 Player leaving:", player.Name)
    
    -- Save player data
    DataManager.SavePlayer(player)
    
    -- Cleanup other systems
    for systemName, system in pairs(LoadedSystems) do
        if system.CleanupPlayer then
            pcall(function()
                system.CleanupPlayer(player)
            end)
        end
    end
end)

-- ============================
-- GAME SHUTDOWN
-- ============================

game:BindToClose(function()
    print("🛑 Server shutting down...")
    
    -- Save all player data
    for _, player in ipairs(Players:GetPlayers()) do
        DataManager.SavePlayer(player)
    end
    
    -- Wait for ProfileService to finish
    task.wait(3)
    
    print("💾 All data saved. Goodbye!")
end)

-- ============================
-- START BACKGROUND SYSTEMS
-- ============================

-- Start systems that run continuously
for systemName, system in pairs(LoadedSystems) do
    if system.Start then
        task.spawn(function()
            local success, err = pcall(system.Start)
            if not success then
                warn("❌ System start failed:", systemName, err)
            end
        end)
    end
end

-- ============================
-- DEBUGGING ACCESS
-- ============================

-- Make systems accessible globally for debugging
_G.GardenCreatures = {
    Systems = LoadedSystems,
    Config = Config,
    Version = "0.1.0",
}

-- Debug commands
_G.GC_AddCoins = function(player, amount)
    return DataManager.AddCurrency(player, "Coins", amount)
end

_G.GC_AddGems = function(player, amount)
    return DataManager.AddCurrency(player, "Gems", amount)
end

_G.GC_GetData = function(player)
    return DataManager.GetData(player)
end

-- ============================
-- STARTUP COMPLETE
-- ============================

print("✅ Garden Creatures - Server Started Successfully!")
print("🌱 Version: 0.1.0 Alpha")
print("📊 Systems Loaded:", #SystemsToLoad + 1) -- +1 for DataManager
print("🎮 Ready for players!")
