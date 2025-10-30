--[[
    Server.server.lua - FIXED VERSION
    Main server entry point for Garden Creatures
    
    ✅ FIXES APPLIED:
    1. Creates RemoteEvents folder BEFORE any systems load
    2. Pre-creates commonly used RemoteEvents to prevent race conditions
    3. Ensures clients can access RemoteEvents immediately
    
    Place this file in: ServerScriptService/Server.server.lua
    
    Initializes all server systems and manages game state
]]

print("🌱 Garden Creatures - Server Starting...")

-- Get services
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AdminCommands = require(ServerScriptService.AdminCommands)
   AdminCommands.Init()

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

-- ============================
-- ✅ FIX: CREATE REMOTE EVENTS FOLDER IMMEDIATELY
-- This prevents client race conditions where they try to access
-- RemoteEvents before the server creates it
-- ============================

local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not RemoteEvents then
    RemoteEvents = Instance.new("Folder")
    RemoteEvents.Name = "RemoteEvents"
    RemoteEvents.Parent = ReplicatedStorage
    print("📡 Created RemoteEvents folder")
end

-- Helper function to create RemoteEvents
local function CreateRemoteEvent(name: string): RemoteEvent
    local existing = RemoteEvents:FindFirstChild(name)
    if existing and existing:IsA("RemoteEvent") then
        return existing
    end
    
    local remoteEvent = Instance.new("RemoteEvent")
    remoteEvent.Name = name
    remoteEvent.Parent = RemoteEvents
    return remoteEvent
end

-- Helper function to create RemoteFunctions
local function CreateRemoteFunction(name: string): RemoteFunction
    local existing = RemoteEvents:FindFirstChild(name)
    if existing and existing:IsA("RemoteFunction") then
        return existing
    end
    
    local remoteFunction = Instance.new("RemoteFunction")
    remoteFunction.Name = name
    remoteFunction.Parent = RemoteEvents
    return remoteFunction
end

-- ✅ Pre-create commonly used RemoteEvents to prevent infinite yield warnings
print("📡 Creating RemoteEvents...")

-- Seed Collection System
CreateRemoteEvent("CollectSeed")

-- Plant System
CreateRemoteEvent("PlantSeed")
CreateRemoteEvent("HarvestPlant")
CreateRemoteEvent("WaterPlant")

-- Creature System
CreateRemoteEvent("CraftCreature")
CreateRemoteEvent("TameCreature")
CreateRemoteEvent("SetActiveCreatures")
CreateRemoteEvent("UseAbility")

-- Economy System
CreateRemoteEvent("PurchaseItem")
CreateRemoteEvent("SellItem")

-- Trading System
CreateRemoteEvent("SendTradeRequest")
CreateRemoteEvent("AcceptTrade")
CreateRemoteEvent("DeclineTrade")

-- UI Updates (Server -> Client)
CreateRemoteEvent("UpdateInventoryUI")
CreateRemoteEvent("UpdateCurrencyUI")
CreateRemoteEvent("ShowNotification")

print("✅ RemoteEvents initialized with", #RemoteEvents:GetChildren(), "events")

-- ============================
-- LOAD DATAMANAGER (CRITICAL!)
-- ============================

local DataManager = require(Data.DataManager)
print("✅ DataManager loaded")

-- Initialize other systems
local LoadedSystems = {
    DataManager = DataManager,
}

-- Systems to load (in order)
local SystemsToLoad = {
    { folder = "SeedSpawnSystem", module = "SeedSpawnController" },
    { folder = "InventorySystem", module = "InventoryManager" },
    
    -- Uncomment these as you implement them:
    -- { folder = "EconomySystem", module = "CurrencyManager" },
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
        -- local ShowNotification = RemoteEvents:FindFirstChild("ShowNotification")
        -- if ShowNotification then
        --     ShowNotification:FireClient(player, {
        --         title = "Welcome!",
        --         message = "Start collecting seeds to grow your garden!",
        --         duration = 5
        --     })
        -- end
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
    RemoteEvents = RemoteEvents,
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

_G.GC_AddSeed = function(player, seedId, amount)
    return DataManager.AddItem(player, "seeds", seedId, amount or 1)
end

-- ============================
-- STARTUP COMPLETE
-- ============================

print("✅ Garden Creatures - Server Started Successfully!")
print("🌱 Version: 0.1.0 Alpha")
print("📊 Systems Loaded:", #SystemsToLoad + 1) -- +1 for DataManager
print("🎮 Ready for players!")