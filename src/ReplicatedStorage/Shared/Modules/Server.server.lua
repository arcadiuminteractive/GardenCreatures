--[[
    Server.server.lua
    Main server entry point for Garden Creatures
    
    Initializes all server systems and manages game state
]]

print("🌱 Garden Creatures - Server Starting...")

-- Get services
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get system folders
local Systems = ServerScriptService.Systems
local Shared = ReplicatedStorage.Shared

-- Load configuration
local Config = {
    Seeds = require(Shared.Config.Seeds),
    Plants = require(Shared.Config.Plants),
    Recipes = require(Shared.Config.Recipes),
    Creatures = require(Shared.Config.Creatures),
    Economy = require(Shared.Config.Economy),
    WildSpawns = require(Shared.Config.WildSpawns),
}

-- Initialize systems (order matters!)
local SystemsToLoad = {
    -- Core systems first
    "Data/DataManager",
    "EconomySystem/CurrencyManager",
    
    -- Gameplay systems
    "InventorySystem/InventoryManager",
    "GardeningSystem/PlantManager",
    "CraftingSystem/RecipeManager",
    "CreatureSystem/CreatureManager",
    "TradingSystem/TradeManager",
    "HomeBaseSystem/HomeBaseManager",
    
    -- Secondary systems
    "CreatureSystem/WildSpawnController",
}

local LoadedSystems = {}

for _, systemPath in ipairs(SystemsToLoad) do
    local success, system = pcall(function()
        local modulePath = Systems:FindFirstChild(systemPath:match("^(.+)/"), true)
        if modulePath then
            local moduleName = systemPath:match("/(.+)$")
            local module = modulePath:FindFirstChild(moduleName)
            if module then
                return require(module)
            end
        end
        return nil
    end)
    
    if success and system then
        local systemName = systemPath:match("/(.+)$")
        LoadedSystems[systemName] = system
        print("✅ Loaded system:", systemName)
    else
        warn("❌ Failed to load system:", systemPath)
    end
end

-- Player management
Players.PlayerAdded:Connect(function(player)
    print("👤 Player joined:", player.Name)
    
    -- Initialize player data
    if LoadedSystems.DataManager then
        LoadedSystems.DataManager.InitializePlayer(player)
    end
    
    -- Setup player systems
    if LoadedSystems.InventoryManager then
        LoadedSystems.InventoryManager.SetupPlayer(player)
    end
    
    if LoadedSystems.CreatureManager then
        LoadedSystems.CreatureManager.SetupPlayer(player)
    end
    
    -- Welcome message
    task.wait(2)
    -- TODO: Show welcome GUI
    print("🌱 Welcome to Garden Creatures,", player.Name .. "!")
end)

Players.PlayerRemoving:Connect(function(player)
    print("👋 Player leaving:", player.Name)
    
    -- Save player data
    if LoadedSystems.DataManager then
        LoadedSystems.DataManager.SavePlayer(player)
    end
    
    -- Cleanup wild creatures associated with this player
    if LoadedSystems.WildSpawnController then
        LoadedSystems.WildSpawnController.CleanupPlayerCreatures(player)
    end
end)

-- Game shutdown
game:BindToClose(function()
    print("🛑 Server shutting down...")
    
    -- Save all player data
    if LoadedSystems.DataManager then
        for _, player in ipairs(Players:GetPlayers()) do
            LoadedSystems.DataManager.SavePlayer(player)
        end
    end
    
    print("💾 All data saved. Goodbye!")
end)

-- Start wild spawn system
if LoadedSystems.WildSpawnController then
    task.spawn(function()
        LoadedSystems.WildSpawnController.Start()
    end)
end

print("✅ Garden Creatures - Server Started Successfully!")
print("🌱 Version: 0.1.0 Alpha")
print("📊 Systems Loaded:", #SystemsToLoad)

-- Make systems accessible globally for debugging
_G.GardenCreatures = {
    Systems = LoadedSystems,
    Config = Config,
    Version = "0.1.0",
}
