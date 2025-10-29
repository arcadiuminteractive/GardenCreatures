--[[
    DataManager.lua
    Manages all player data persistence using ProfileStore
    
    Responsibilities:
    - Load/save player data
    - Provide safe data access
    - Handle player joins/leaves
    - Manage currency operations
    - Inventory management helpers
    - Data validation
]]

local DataManager = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- ProfileStore (Install from: https://github.com/MadStudioRoblox/ProfileStore)
-- Place ProfileStore module in ServerScriptService or ReplicatedStorage
local ProfileStoreModule = require(ServerScriptService:WaitForChild("ProfileStore"))

-- Configuration
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = {
    Economy = require(Shared.Config.Economy),
    Seeds = require(Shared.Config.Seeds),
    Plants = require(Shared.Config.Plants),
    Creatures = require(Shared.Config.Creatures),
}

-- Constants
local PROFILE_STORE_NAME = "PlayerData_v1" -- Change version number to reset all data
local AUTO_SAVE_INTERVAL = 300 -- Save every 5 minutes

-- Active profiles
local Profiles = {}

-- ============================
-- DATA TEMPLATE
-- ============================

-- Data template
function DataManager.GetDefaultData()
    return {
        -- Currency
        coins = Config.Economy.currencies.coins.startingAmount or 100,
        gems = Config.Economy.currencies.gems.startingAmount or 0,
        
        -- XP & Level
        xp = 0,
        level = 1,
        
        -- Inventory
        inventory = {
            seeds = {},    -- {seedId = count}
            plants = {},   -- {plantId = count}
            potions = {},  -- {potionId = count}
            foods = {},    -- {foodId = count}
            tools = {},    -- {toolId = count}
        },
        
        -- Creatures
        creatures = {},        -- Array of owned creature instances
        activeCreatures = {},  -- Array of instance IDs currently following
        maxFollowSlots = 3,    -- How many creatures can follow at once
        
        -- Garden
        gardenPlots = {},      -- Array of plot data
        maxPlots = 6,          -- Starting plot count
        
        -- Progression
        unlockedRecipes = {},  -- Array of recipe IDs
        unlockedAreas = {},    -- Array of area IDs
        
        -- Settings
        settings = {
            musicVolume = 0.5,
            sfxVolume = 0.7,
            showTutorial = true,
        },
        
        -- Stats/Analytics
        stats = {
            playtime = 0,
            seedsCollected = 0,
            plantsHarvested = 0,
            creaturesDiscovered = 0,
            recipesCooked = 0,
            coinsEarned = 0,
            gemsSpent = 0,
        },
        
        -- Timestamps
        firstJoin = os.time(),
        lastLogin = os.time(),
        lastSave = os.time(),
        
        -- Gamepasses
        ownedGamepasses = {}, -- Array of gamepass IDs
        
        -- Active effects
        activeEffects = {}, -- {effectId = expiryTime}
        
        -- Achievements
        achievements = {}, -- Array of achievement IDs
        
        -- Daily rewards
        dailyRewardStreak = 0,
        lastDailyReward = 0,
    }
end

-- Profile store (initialized AFTER GetDefaultData is defined)
local ProfileStore = ProfileStoreModule.GetProfileStore(
    PROFILE_STORE_NAME,
    DataManager.GetDefaultData()
)

-- ============================
-- CORE PROFILE MANAGEMENT
-- ============================

--[[
    Initialize a player's profile when they join
]]
function DataManager.InitializePlayer(player: Player)
    local profile = ProfileStore:StartSessionAsync(
        "Player_" .. player.UserId,
        {
            Cancel = function()
                return player.Parent ~= Players
            end
        }
    )
    
    if profile ~= nil then
        profile:AddUserId(player.UserId) -- GDPR compliance
        profile:Reconcile() -- Fill in missing data with defaults
        
        profile:ListenToRelease(function()
            Profiles[player] = nil
            player:Kick("Profile released - please rejoin")
        end)
        
        if player:IsDescendantOf(Players) then
            Profiles[player] = profile
            
            -- Update last login
            profile.Data.lastLogin = os.time()
            
            -- Check for daily reward
            DataManager._CheckDailyReward(player)
            
            -- Load gamepasses
            DataManager._LoadGamepasses(player)
            
            -- Clean up expired effects
            DataManager._CleanExpiredEffects(player)
            
            print("✅ Loaded profile for:", player.Name)
            
            -- Fire data loaded event
            DataManager._OnDataLoaded(player)
            
            return true
        else
            -- Player left before profile loaded
            profile:EndSession()
            return false
        end
    else
        -- Failed to load profile
        warn("❌ Failed to load profile for:", player.Name)
        player:Kick("Failed to load your data. Please rejoin!")
        return false
    end
end

--[[
    Safely access a player's data (read-only)
]]
function DataManager.GetData(player: Player)
    local profile = Profiles[player]
    if profile then
        return profile.Data
    end
    return nil
end

--[[
    Get a player's profile (for direct manipulation)
    Use sparingly - prefer specific methods
]]
function DataManager.GetProfile(player: Player)
    return Profiles[player]
end

--[[
    Save a player's profile
]]
function DataManager.SavePlayer(player: Player): boolean
    local profile = Profiles[player]
    if profile then
        profile.Data.lastSave = os.time()
        profile:Save()
        return true
    end
    return false
end

--[[
    Handle player leaving - save and release profile
]]
function DataManager.PlayerRemoving(player: Player)
    local profile = Profiles[player]
    if profile then
        profile.Data.lastSave = os.time()
        profile:EndSession()
        Profiles[player] = nil
        print("💾 Saved and released profile for:", player.Name)
    end
end

-- ============================
-- CURRENCY METHODS
-- ============================

function DataManager.GetCurrency(player: Player, currencyType: string): number?
    local data = DataManager.GetData(player)
    if data then
        return data[currencyType:lower()]
    end
    return nil
end

function DataManager.AddCurrency(player: Player, currencyType: string, amount: number): boolean
    local profile = Profiles[player]
    if not profile then return false end
    
    local currency = currencyType:lower()
    if profile.Data[currency] then
        profile.Data[currency] = profile.Data[currency] + amount
        
        -- Update stats
        if currency == "coins" then
            profile.Data.stats.coinsEarned = profile.Data.stats.coinsEarned + amount
        end
        
        return true
    end
    return false
end

function DataManager.RemoveCurrency(player: Player, currencyType: string, amount: number): boolean
    local profile = Profiles[player]
    if not profile then return false end
    
    local currency = currencyType:lower()
    if profile.Data[currency] and profile.Data[currency] >= amount then
        profile.Data[currency] = profile.Data[currency] - amount
        
        -- Update stats
        if currency == "gems" then
            profile.Data.stats.gemsSpent = profile.Data.stats.gemsSpent + amount
        end
        
        return true
    end
    return false
end

function DataManager.SetCurrency(player: Player, currencyType: string, amount: number): boolean
    local profile = Profiles[player]
    if not profile then return false end
    
    local currency = currencyType:lower()
    if profile.Data[currency] ~= nil then
        profile.Data[currency] = math.max(0, amount)
        return true
    end
    return false
end

-- ============================
-- INVENTORY METHODS
-- ============================

function DataManager.AddItem(player: Player, itemType: string, itemId: string, amount: number): boolean
    local profile = Profiles[player]
    if not profile then return false end
    
    local inventory = profile.Data.inventory[itemType]
    if not inventory then return false end
    
    inventory[itemId] = (inventory[itemId] or 0) + amount
    return true
end

function DataManager.RemoveItem(player: Player, itemType: string, itemId: string, amount: number): boolean
    local profile = Profiles[player]
    if not profile then return false end
    
    local inventory = profile.Data.inventory[itemType]
    if not inventory or not inventory[itemId] or inventory[itemId] < amount then
        return false
    end
    
    inventory[itemId] = inventory[itemId] - amount
    
    -- Remove entry if 0
    if inventory[itemId] <= 0 then
        inventory[itemId] = nil
    end
    
    return true
end

function DataManager.GetItemCount(player: Player, itemType: string, itemId: string): number
    local data = DataManager.GetData(player)
    if data and data.inventory[itemType] then
        return data.inventory[itemType][itemId] or 0
    end
    return 0
end

function DataManager.HasItem(player: Player, itemType: string, itemId: string, amount: number): boolean
    return DataManager.GetItemCount(player, itemType, itemId) >= amount
end

-- ============================
-- CREATURE METHODS
-- ============================

function DataManager.AddCreature(player: Player, creatureData: any): boolean
    local profile = Profiles[player]
    if not profile then return false end
    
    table.insert(profile.Data.creatures, creatureData)
    
    -- Update stats
    profile.Data.stats.creaturesDiscovered = profile.Data.stats.creaturesDiscovered + 1
    
    return true
end

function DataManager.GetCreature(player: Player, instanceId: string): any?
    local data = DataManager.GetData(player)
    if not data then return nil end
    
    for _, creature in ipairs(data.creatures) do
        if creature.instanceId == instanceId then
            return creature
        end
    end
    
    return nil
end

function DataManager.UpdateCreature(player: Player, instanceId: string, updates: any): boolean
    local profile = Profiles[player]
    if not profile then return false end
    
    for _, creature in ipairs(profile.Data.creatures) do
        if creature.instanceId == instanceId then
            for key, value in pairs(updates) do
                creature[key] = value
            end
            return true
        end
    end
    
    return false
end

function DataManager.SetActiveCreatures(player: Player, instanceIds: {string}): boolean
    local profile = Profiles[player]
    if not profile then return false end
    
    -- Validate count
    if #instanceIds > profile.Data.maxFollowSlots then
        return false
    end
    
    -- Validate all creatures exist
    for _, instanceId in ipairs(instanceIds) do
        if not DataManager.GetCreature(player, instanceId) then
            return false
        end
    end
    
    profile.Data.activeCreatures = instanceIds
    return true
end

-- ============================
-- GARDEN METHODS
-- ============================

function DataManager.AddGardenPlot(player: Player, plotData: any): boolean
    local profile = Profiles[player]
    if not profile then return false end
    
    -- Check plot limit
    if #profile.Data.gardenPlots >= profile.Data.maxPlots then
        return false
    end
    
    table.insert(profile.Data.gardenPlots, plotData)
    return true
end

function DataManager.UpdateGardenPlot(player: Player, plotId: string, updates: any): boolean
    local profile = Profiles[player]
    if not profile then return false end
    
    for _, plot in ipairs(profile.Data.gardenPlots) do
        if plot.plotId == plotId then
            for key, value in pairs(updates) do
                plot[key] = value
            end
            return true
        end
    end
    
    return false
end

function DataManager.GetGardenPlot(player: Player, plotId: string): any?
    local data = DataManager.GetData(player)
    if not data then return nil end
    
    for _, plot in ipairs(data.gardenPlots) do
        if plot.plotId == plotId then
            return plot
        end
    end
    
    return nil
end

-- ============================
-- PROGRESSION METHODS
-- ============================

function DataManager.AddXP(player: Player, amount: number): boolean
    local profile = Profiles[player]
    if not profile then return false end
    
    profile.Data.xp = profile.Data.xp + amount
    
    -- Check for level up
    -- TODO: Implement level-up logic based on XP thresholds
    
    return true
end

function DataManager.UnlockRecipe(player: Player, recipeId: string): boolean
    local profile = Profiles[player]
    if not profile then return false end
    
    if not table.find(profile.Data.unlockedRecipes, recipeId) then
        table.insert(profile.Data.unlockedRecipes, recipeId)
        return true
    end
    
    return false
end

function DataManager.HasRecipe(player: Player, recipeId: string): boolean
    local data = DataManager.GetData(player)
    if not data then return false end
    
    return table.find(data.unlockedRecipes, recipeId) ~= nil
end

-- ============================
-- STATS METHODS
-- ============================

function DataManager.IncrementStat(player: Player, statName: string, amount: number): boolean
    local profile = Profiles[player]
    if not profile or not profile.Data.stats[statName] then return false end
    
    profile.Data.stats[statName] = profile.Data.stats[statName] + amount
    return true
end

function DataManager.GetStat(player: Player, statName: string): number?
    local data = DataManager.GetData(player)
    if data and data.stats then
        return data.stats[statName]
    end
    return nil
end

-- ============================
-- GAMEPASS METHODS
-- ============================

function DataManager.GrantGamepass(player: Player, gamepassId: number): boolean
    local profile = Profiles[player]
    if not profile then return false end
    
    if not table.find(profile.Data.ownedGamepasses, gamepassId) then
        table.insert(profile.Data.ownedGamepasses, gamepassId)
        
        -- Apply gamepass benefits
        DataManager._ApplyGamepassBenefits(player, gamepassId)
        
        return true
    end
    
    return false
end

function DataManager.HasGamepass(player: Player, gamepassId: number): boolean
    local data = DataManager.GetData(player)
    if not data then return false end
    
    return table.find(data.ownedGamepasses, gamepassId) ~= nil
end

-- ============================
-- EFFECTS METHODS
-- ============================

function DataManager.AddEffect(player: Player, effectId: string, duration: number): boolean
    local profile = Profiles[player]
    if not profile then return false end
    
    local expiryTime = os.time() + duration
    profile.Data.activeEffects[effectId] = expiryTime
    
    return true
end

function DataManager.HasEffect(player: Player, effectId: string): boolean
    local data = DataManager.GetData(player)
    if not data or not data.activeEffects[effectId] then return false end
    
    return data.activeEffects[effectId] > os.time()
end

function DataManager.RemoveEffect(player: Player, effectId: string): boolean
    local profile = Profiles[player]
    if not profile then return false end
    
    profile.Data.activeEffects[effectId] = nil
    return true
end

-- ============================
-- SETTINGS METHODS
-- ============================

function DataManager.UpdateSetting(player: Player, settingName: string, value: any): boolean
    local profile = Profiles[player]
    if not profile or profile.Data.settings[settingName] == nil then return false end
    
    profile.Data.settings[settingName] = value
    return true
end

function DataManager.GetSetting(player: Player, settingName: string): any?
    local data = DataManager.GetData(player)
    if not data then return nil end
    
    return data.settings[settingName]
end

-- ============================
-- INTERNAL HELPER METHODS
-- ============================

function DataManager._CheckDailyReward(player: Player)
    local profile = Profiles[player]
    if not profile then return end
    
    local lastReward = profile.Data.lastDailyReward
    local currentTime = os.time()
    
    -- Check if 24 hours have passed
    if currentTime - lastReward >= 86400 then
        -- Eligible for daily reward
        -- TODO: Implement daily reward logic
    end
end

function DataManager._LoadGamepasses(player: Player)
    local profile = Profiles[player]
    if not profile then return end
    
    -- Check which gamepasses the player owns
    -- TODO: Implement gamepass checking via MarketplaceService
end

function DataManager._ApplyGamepassBenefits(player: Player, gamepassId: number)
    -- TODO: Apply benefits based on gamepass ID
    print("🎫 Applied benefits for gamepass:", gamepassId, "to", player.Name)
end

function DataManager._CleanExpiredEffects(player: Player)
    local profile = Profiles[player]
    if not profile then return end
    
    local currentTime = os.time()
    local toRemove = {}
    
    for effectId, expiryTime in pairs(profile.Data.activeEffects) do
        if expiryTime <= currentTime then
            table.insert(toRemove, effectId)
        end
    end
    
    for _, effectId in ipairs(toRemove) do
        profile.Data.activeEffects[effectId] = nil
    end
end

function DataManager._OnDataLoaded(player: Player)
    -- Fire event for other systems
    -- TODO: Create a RemoteEvent or BindableEvent for this
    print("📊 Data loaded for:", player.Name)
end

-- ============================
-- AUTO-SAVE SYSTEM
-- ============================

task.spawn(function()
    while true do
        task.wait(AUTO_SAVE_INTERVAL)
        
        for player, profile in pairs(Profiles) do
            if player:IsDescendantOf(Players) then
                DataManager.SavePlayer(player)
            end
        end
        
        print("💾 Auto-save completed")
    end
end)

-- ============================
-- PLAYER EVENTS
-- ============================

Players.PlayerRemoving:Connect(function(player)
    DataManager.PlayerRemoving(player)
end)

-- ============================
-- SHUTDOWN HANDLER
-- ============================

game:BindToClose(function()
    print("🛑 Server shutting down - saving all data...")
    
    for player, profile in pairs(Profiles) do
        if profile then
            profile.Data.lastSave = os.time()
        end
    end
    
    -- Wait for ProfileStore to finish saving
    task.wait(3)
end)

print("✅ DataManager loaded successfully!")

return DataManager