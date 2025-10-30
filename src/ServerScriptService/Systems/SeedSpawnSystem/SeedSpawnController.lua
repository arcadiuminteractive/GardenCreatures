--[[
    SeedSpawnController.lua - INVENTORY MANAGER INTEGRATION
    Manages seed spawning across all zones in the world
    
    ✅ FIXES APPLIED:
    1. Distance check uses initial spawn position
    2. Uses InventoryManager.AddItem() instead of DataManager.AddItem()
    3. Proper inventory integration with slot-based system
    4. Client notification on successful collection
    
    Features:
    - Zone-based spawning with configurable rates
    - Rarity-weighted seed selection
    - Maximum seeds per zone
    - Respawn system
    - Collection handling with anti-exploit
    - Zone discovery system
]]

local SeedSpawnController = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

-- Configuration
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = {
    Seeds = require(Shared.Config.Seeds),
}

-- ✅ FIX: Import BOTH managers
local DataManager = require(ServerScriptService.Data.DataManager)
local InventoryManager = require(ServerScriptService.Systems.InventorySystem.InventoryManager)

-- Constants
local SEED_TAG = "SeedSpawn"
local ZONE_TAG = "SeedZone"
local SPAWN_CHECK_INTERVAL = 5 -- Check for respawns every 5 seconds
local SEED_LIFETIME = 300 -- Seeds despawn after 5 minutes if not collected
local COLLECTION_COOLDOWN = 0.5 -- Prevent spam collection
local COLLECTION_RANGE = 20 -- Maximum distance to collect seed

-- State
local ActiveSeeds = {} -- {seedInstance = {data}}
local SpawnZones = {} -- {zonePart = {config}}
local PlayerCooldowns = {} -- {player = lastCollectionTime}
local IsRunning = false

-- RemoteEvents
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not RemoteEvents then
    RemoteEvents = Instance.new("Folder")
    RemoteEvents.Name = "RemoteEvents"
    RemoteEvents.Parent = ReplicatedStorage
end

local CollectSeedEvent = RemoteEvents:FindFirstChild("CollectSeed")
if not CollectSeedEvent then
    CollectSeedEvent = Instance.new("RemoteEvent")
    CollectSeedEvent.Name = "CollectSeed"
    CollectSeedEvent.Parent = RemoteEvents
end

-- Notification event for client feedback
local SeedCollectedEvent = RemoteEvents:FindFirstChild("SeedCollected")
if not SeedCollectedEvent then
    SeedCollectedEvent = Instance.new("RemoteEvent")
    SeedCollectedEvent.Name = "SeedCollected"
    SeedCollectedEvent.Parent = RemoteEvents
end

-- ============================
-- INITIALIZATION
-- ============================

function SeedSpawnController.Init()
    print("🌱 Initializing Seed Spawn System...")
    
    -- Discover all spawn zones
    SeedSpawnController._DiscoverZones()
    
    -- Setup collection handling
    SeedSpawnController._SetupCollectionHandling()
    
    -- Listen for new zones
    CollectionService:GetInstanceAddedSignal(ZONE_TAG):Connect(function(zone)
        SeedSpawnController._RegisterZone(zone)
    end)
    
    CollectionService:GetInstanceRemovedSignal(ZONE_TAG):Connect(function(zone)
        SeedSpawnController._UnregisterZone(zone)
    end)
    
    print("✅ Seed Spawn System initialized with", #SpawnZones, "zones")
end

function SeedSpawnController.Start()
    if IsRunning then return end
    IsRunning = true
    
    print("🌱 Starting Seed Spawn System...")
    
    -- Initial spawn for all zones
    for zonePart, zoneData in pairs(SpawnZones) do
        SeedSpawnController._SpawnInitialSeeds(zonePart, zoneData)
    end
    
    -- Start spawn loop
    task.spawn(function()
        SeedSpawnController._SpawnLoop()
    end)
    
    -- Start cleanup loop
    task.spawn(function()
        SeedSpawnController._CleanupLoop()
    end)
    
    print("✅ Seed Spawn System started!")
end

-- ============================
-- ZONE MANAGEMENT
-- ============================

function SeedSpawnController._DiscoverZones()
    local zones = CollectionService:GetTagged(ZONE_TAG)
    
    for _, zone in ipairs(zones) do
        SeedSpawnController._RegisterZone(zone)
    end
end

function SeedSpawnController._RegisterZone(zonePart: Part)
    if not zonePart:IsA("BasePart") then
        warn("⚠️  Seed zone must be a BasePart:", zonePart:GetFullName())
        return
    end
    
    -- Get zone configuration from attributes
    local zoneData = {
        name = zonePart:GetAttribute("ZoneName") or zonePart.Name,
        spawnRate = zonePart:GetAttribute("SpawnRate") or 1.0,
        maxSeeds = zonePart:GetAttribute("MaxSeeds") or 10,
        respawnTime = zonePart:GetAttribute("RespawnTime") or 30,
        allowedSeeds = SeedSpawnController._GetAllowedSeeds(zonePart),
        activeSeeds = {},
        lastSpawnTime = 0,
    }
    
    SpawnZones[zonePart] = zoneData
    
    print("📍 Registered spawn zone:", zoneData.name, "| Max seeds:", zoneData.maxSeeds)
end

function SeedSpawnController._UnregisterZone(zonePart: Part)
    local zoneData = SpawnZones[zonePart]
    if not zoneData then return end
    
    -- Cleanup all seeds in this zone
    for seedInstance, _ in pairs(zoneData.activeSeeds) do
        SeedSpawnController._DespawnSeed(seedInstance)
    end
    
    SpawnZones[zonePart] = nil
    print("📍 Unregistered spawn zone:", zoneData.name)
end

function SeedSpawnController._GetAllowedSeeds(zonePart: Part): {string}
    local zoneType = zonePart:GetAttribute("ZoneType") or "meadow"
    
    -- Get seeds for this zone from config
    local allowedSeeds = Config.Seeds.spawnZones[zoneType:lower()]
    
    if not allowedSeeds then
        warn("⚠️  Unknown zone type:", zoneType, "- using meadow defaults")
        allowedSeeds = Config.Seeds.spawnZones.meadow
    end
    
    return allowedSeeds
end

-- ============================
-- SPAWNING LOGIC
-- ============================

function SeedSpawnController._SpawnInitialSeeds(zonePart: Part, zoneData: any)
    -- Spawn 50% of max seeds initially
    local initialCount = math.floor(zoneData.maxSeeds * 0.5)
    
    for i = 1, initialCount do
        SeedSpawnController._SpawnSeed(zonePart, zoneData)
        task.wait(0.1) -- Spread out spawns
    end
end

function SeedSpawnController._SpawnLoop()
    while IsRunning do
        task.wait(SPAWN_CHECK_INTERVAL)
        
        for zonePart, zoneData in pairs(SpawnZones) do
            -- Count active seeds in this zone
            local activeCount = 0
            for _, _ in pairs(zoneData.activeSeeds) do
                activeCount = activeCount + 1
            end
            
            -- Check if we need to spawn more
            if activeCount < zoneData.maxSeeds then
                local timeSinceLastSpawn = tick() - zoneData.lastSpawnTime
                
                -- Respect respawn time
                if timeSinceLastSpawn >= zoneData.respawnTime then
                    SeedSpawnController._SpawnSeed(zonePart, zoneData)
                    zoneData.lastSpawnTime = tick()
                end
            end
        end
    end
end

function SeedSpawnController._SpawnSeed(zonePart: Part, zoneData: any): Instance?
    -- Select a seed based on rarity weights
    local seedId = SeedSpawnController._SelectRandomSeed(zoneData.allowedSeeds)
    if not seedId then return nil end
    
    -- Get seed config
    local seedConfig = SeedSpawnController._GetSeedConfig(seedId)
    if not seedConfig then return nil end
    
    -- Calculate spawn position
    local position = SeedSpawnController._GetRandomPositionInZone(zonePart)
    
    -- Create seed instance
    local seedInstance = SeedSpawnController._CreateSeedInstance(seedConfig, position)
    if not seedInstance then return nil end
    
    -- Track seed with INITIAL POSITION for distance checking
    local seedData = {
        seedId = seedId,
        config = seedConfig,
        spawnTime = tick(),
        zonePart = zonePart,
        spawnPosition = position, -- ✅ Store original position for distance checks
    }
    
    ActiveSeeds[seedInstance] = seedData
    zoneData.activeSeeds[seedInstance] = true
    
    return seedInstance
end

function SeedSpawnController._SelectRandomSeed(allowedSeeds: {string}): string?
    if #allowedSeeds == 0 then return nil end
    
    -- Calculate total weight
    local totalWeight = 0
    local seedWeights = {}
    
    for _, seedId in ipairs(allowedSeeds) do
        local seedConfig = SeedSpawnController._GetSeedConfig(seedId)
        if seedConfig then
            local weight = seedConfig.rarity == "common" and 100
                or seedConfig.rarity == "uncommon" and 50
                or seedConfig.rarity == "rare" and 25
                or seedConfig.rarity == "epic" and 10
                or seedConfig.rarity == "legendary" and 5
                or 50
            
            table.insert(seedWeights, {
                seedId = seedId,
                weight = weight
            })
            totalWeight = totalWeight + weight
        end
    end
    
    -- Random selection
    local roll = math.random() * totalWeight
    local currentWeight = 0
    
    for _, seedWeight in ipairs(seedWeights) do
        currentWeight = currentWeight + seedWeight.weight
        if roll <= currentWeight then
            return seedWeight.seedId
        end
    end
    
    return allowedSeeds[1] -- Fallback
end

function SeedSpawnController._GetSeedConfig(seedId: string): any?
    for _, seed in ipairs(Config.Seeds.seeds) do
        if seed.id == seedId then
            return seed
        end
    end
    return nil
end

function SeedSpawnController._GetRandomPositionInZone(zonePart: Part): Vector3
    local size = zonePart.Size
    local cframe = zonePart.CFrame
    
    -- Random position within zone bounds
    local randomX = (math.random() - 0.5) * size.X * 0.9
    local randomZ = (math.random() - 0.5) * size.Z * 0.9
    
    local worldPosition = cframe * Vector3.new(randomX, size.Y / 2 + 2, randomZ)
    
    return worldPosition
end

function SeedSpawnController._CreateSeedInstance(seedConfig: any, position: Vector3): Instance?
    -- Create seed model
    local seedModel = Instance.new("Model")
    seedModel.Name = seedConfig.id
    
    -- Create seed part
    local seedPart = Instance.new("Part")
    seedPart.Name = "SeedPart"
    seedPart.Size = Vector3.new(1, 1, 1)
    seedPart.Position = position
    seedPart.Anchored = true
    seedPart.CanCollide = false
    seedPart.Material = Enum.Material.SmoothPlastic
    
    -- Color based on rarity
    if seedConfig.rarity == "common" then
        seedPart.Color = Color3.fromRGB(200, 200, 200)
    elseif seedConfig.rarity == "uncommon" then
        seedPart.Color = Color3.fromRGB(100, 200, 100)
    elseif seedConfig.rarity == "rare" then
        seedPart.Color = Color3.fromRGB(100, 100, 255)
    elseif seedConfig.rarity == "epic" then
        seedPart.Color = Color3.fromRGB(180, 100, 255)
    elseif seedConfig.rarity == "legendary" then
        seedPart.Color = Color3.fromRGB(255, 200, 50)
    end
    
    seedPart.Parent = seedModel
    
    -- Add click detector
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = COLLECTION_RANGE
    clickDetector.Parent = seedPart
    
    -- Add highlight
    local highlight = Instance.new("Highlight")
    highlight.FillColor = seedPart.Color
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = seedModel
    
    -- Tag for collection service
    CollectionService:AddTag(seedModel, SEED_TAG)
    
    -- Parent to workspace
    seedModel.Parent = workspace:FindFirstChild("Seeds") or workspace
    
    -- Add floating animation
    SeedSpawnController._AddFloatingAnimation(seedPart)
    
    return seedModel
end

function SeedSpawnController._AddFloatingAnimation(part: Part)
    local initialY = part.Position.Y
    
    task.spawn(function()
        local time = 0
        while part and part.Parent do
            time = time + 0.05
            
            -- Float up and down
            local offset = math.sin(time * 2) * 0.3
            local newPosition = part.Position
            newPosition = Vector3.new(
                newPosition.X,
                initialY + offset,
                newPosition.Z
            )
            part.Position = newPosition
            
            -- Rotate
            part.CFrame = part.CFrame * CFrame.Angles(0, math.rad(2), 0)
            
            task.wait(0.05)
        end
    end)
end

-- ============================
-- COLLECTION HANDLING
-- ============================

function SeedSpawnController._SetupCollectionHandling()
    CollectSeedEvent.OnServerEvent:Connect(function(player, seedModel)
        SeedSpawnController.CollectSeed(player, seedModel)
    end)
    
    -- Also handle ClickDetector clicks
    local function setupClickDetector(seedModel)
        local clickDetector = seedModel:FindFirstChildWhichIsA("ClickDetector", true)
        if clickDetector then
            clickDetector.MouseClick:Connect(function(clickingPlayer)
                SeedSpawnController.CollectSeed(clickingPlayer, seedModel)
            end)
        end
    end
    
    -- Setup for existing seeds
    for seedModel, _ in pairs(ActiveSeeds) do
        setupClickDetector(seedModel)
    end
    
    -- Setup for new seeds
    CollectionService:GetInstanceAddedSignal(SEED_TAG):Connect(function(instance)
        setupClickDetector(instance)
    end)
end

function SeedSpawnController.CollectSeed(player: Player, seedModel: Instance): boolean
    -- Validate player
    if not player or not player.Parent then 
        warn("⚠️  Invalid player attempted collection")
        return false 
    end
    
    -- Validate seed model
    if not seedModel or not seedModel.Parent then 
        warn("⚠️  Invalid seed model")
        return false 
    end
    
    -- Check cooldown
    local lastCollection = PlayerCooldowns[player] or 0
    if tick() - lastCollection < COLLECTION_COOLDOWN then
        return false
    end
    
    -- Check if seed exists in our tracking
    local seedData = ActiveSeeds[seedModel]
    if not seedData then 
        warn("⚠️  Seed not found in tracking:", seedModel.Name)
        return false 
    end
    
    -- ✅ FIX: Check distance using ORIGINAL spawn position
    local character = player.Character
    if not character then 
        warn("⚠️  Player has no character")
        return false 
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then 
        warn("⚠️  Player has no HumanoidRootPart")
        return false 
    end
    
    -- Use stored spawn position instead of current seed position
    local distance = (humanoidRootPart.Position - seedData.spawnPosition).Magnitude
    if distance > COLLECTION_RANGE then
        warn("⚠️  Player too far from seed:", player.Name, "Distance:", math.floor(distance), "Max:", COLLECTION_RANGE)
        return false
    end
    
    -- ✅ FIX: Use InventoryManager instead of DataManager for inventory
    local seedName = seedData.config.name or seedData.seedId
    local success, errorMsg = InventoryManager.AddItem(player, seedData.seedId, seedName, 1)
    
    if not success then
        warn("❌ Failed to add seed to inventory:", player.Name, seedData.seedId, errorMsg or "Unknown error")
        return false
    end
    
    -- Update stats (still using DataManager for stats/currency)
    DataManager.IncrementStat(player, "seedsCollected", 1)
    
    -- Award coins
    DataManager.AddCurrency(player, "coins", 2)
    
    -- Update cooldown
    PlayerCooldowns[player] = tick()
    
    -- Despawn seed
    SeedSpawnController._DespawnSeed(seedModel)
    
    -- Fire client notification
    if SeedCollectedEvent then
        SeedCollectedEvent:FireClient(player, {
            seedId = seedData.seedId,
            seedName = seedName,
            rarity = seedData.config.rarity
        })
    end
    
    -- Success feedback
    print("✅ Collected seed:", seedData.seedId, "by", player.Name, "| Distance:", math.floor(distance))
    
    return true
end

-- ============================
-- CLEANUP
-- ============================

function SeedSpawnController._CleanupLoop()
    while IsRunning do
        task.wait(30) -- Check every 30 seconds
        
        local currentTime = tick()
        local seedsToRemove = {}
        
        for seedModel, seedData in pairs(ActiveSeeds) do
            -- Check if seed expired
            if currentTime - seedData.spawnTime > SEED_LIFETIME then
                table.insert(seedsToRemove, seedModel)
            end
            
            -- Check if seed still exists
            if not seedModel.Parent then
                table.insert(seedsToRemove, seedModel)
            end
        end
        
        -- Remove expired/invalid seeds
        for _, seedModel in ipairs(seedsToRemove) do
            SeedSpawnController._DespawnSeed(seedModel)
        end
        
        if #seedsToRemove > 0 then
            print("🧹 Cleaned up", #seedsToRemove, "seeds")
        end
    end
end

function SeedSpawnController._DespawnSeed(seedModel: Instance)
    local seedData = ActiveSeeds[seedModel]
    
    if seedData then
        -- Remove from zone tracking
        local zoneData = SpawnZones[seedData.zonePart]
        if zoneData then
            zoneData.activeSeeds[seedModel] = nil
        end
        
        -- Remove from active seeds
        ActiveSeeds[seedModel] = nil
    end
    
    -- Destroy the model
    if seedModel and seedModel.Parent then
        seedModel:Destroy()
    end
end

function SeedSpawnController.Stop()
    IsRunning = false
    
    -- Cleanup all seeds
    for seedModel, _ in pairs(ActiveSeeds) do
        SeedSpawnController._DespawnSeed(seedModel)
    end
    
    print("🛑 Seed Spawn System stopped")
end

-- ============================
-- DEBUG/ADMIN FUNCTIONS
-- ============================

function SeedSpawnController.GetActiveSeeds()
    local count = 0
    for _ in pairs(ActiveSeeds) do
        count = count + 1
    end
    return count
end

function SeedSpawnController.ForceSpawn(zoneName: string)
    for zonePart, zoneData in pairs(SpawnZones) do
        if zoneData.name == zoneName then
            return SeedSpawnController._SpawnSeed(zonePart, zoneData)
        end
    end
    return nil
end

return SeedSpawnController