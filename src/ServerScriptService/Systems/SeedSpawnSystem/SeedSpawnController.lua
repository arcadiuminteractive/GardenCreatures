--[[
    SeedSpawnController.lua
    Manages seed spawning across all zones in the world
    
    Features:
    - Zone-based spawning with configurable rates
    - Rarity-weighted seed selection
    - Maximum seeds per zone
    - Respawn system
    - Collection handling
    - Zone discovery system
]]

local SeedSpawnController = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

-- Configuration
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = {
    Seeds = require(Shared.Config.Seeds),
}

-- Constants
local SEED_TAG = "SeedSpawn"
local ZONE_TAG = "SeedZone"
local SPAWN_CHECK_INTERVAL = 5 -- Check for respawns every 5 seconds
local SEED_LIFETIME = 300 -- Seeds despawn after 5 minutes if not collected
local COLLECTION_COOLDOWN = 0.5 -- Prevent spam collection

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
    
    -- Track seed
    local seedData = {
        seedId = seedId,
        config = seedConfig,
        spawnTime = tick(),
        zonePart = zonePart,
    }
    
    ActiveSeeds[seedInstance] = seedData
    zoneData.activeSeeds[seedInstance] = true
    
    return seedInstance
end

function SeedSpawnController._SelectRandomSeed(allowedSeeds: {string}): string?
    if #allowedSeeds == 0 then return nil end
    
    -- Build weighted list based on rarity
    local weightedList = {}
    local totalWeight = 0
    
    for _, seedId in ipairs(allowedSeeds) do
        local seedConfig = SeedSpawnController._GetSeedConfig(seedId)
        if seedConfig then
            local weight = Config.Seeds.rarityWeights[seedConfig.rarity] or 1
            
            table.insert(weightedList, {
                seedId = seedId,
                weight = weight,
            })
            
            totalWeight = totalWeight + weight
        end
    end
    
    if totalWeight == 0 then return nil end
    
    -- Select random seed based on weights
    local roll = math.random() * totalWeight
    local accumulated = 0
    
    for _, entry in ipairs(weightedList) do
        accumulated = accumulated + entry.weight
        if roll <= accumulated then
            return entry.seedId
        end
    end
    
    -- Fallback
    return weightedList[1].seedId
end

function SeedSpawnController._GetSeedConfig(seedId: string): any?
    for _, seedConfig in ipairs(Config.Seeds.seeds) do
        if seedConfig.id == seedId then
            return seedConfig
        end
    end
    return nil
end

function SeedSpawnController._GetRandomPositionInZone(zonePart: Part): Vector3
    local size = zonePart.Size
    local cf = zonePart.CFrame
    
    -- Random position within the part
    local randomX = (math.random() - 0.5) * size.X
    local randomZ = (math.random() - 0.5) * size.Z
    
    -- Spawn slightly above the zone to let it fall
    local position = cf * Vector3.new(randomX, size.Y/2 + 2, randomZ)
    
    -- Raycast down to find ground
    local rayResult = workspace:Raycast(
        position,
        Vector3.new(0, -50, 0),
        RaycastParams.new()
    )
    
    if rayResult then
        return rayResult.Position + Vector3.new(0, 1, 0) -- Slightly above ground
    end
    
    return position
end

function SeedSpawnController._CreateSeedInstance(seedConfig: any, position: Vector3): Instance?
    -- Create seed model
    local seedModel = Instance.new("Model")
    seedModel.Name = seedConfig.name
    
    -- Create seed part
    local seedPart = Instance.new("Part")
    seedPart.Name = "SeedPart"
    seedPart.Size = Vector3.new(1, 1, 1)
    seedPart.Position = position
    seedPart.Anchored = false
    seedPart.CanCollide = false
    seedPart.Shape = Enum.PartType.Ball
    seedPart.Material = Enum.Material.Neon
    
    -- Color based on rarity
    local rarityColors = {
        Common = Color3.fromRGB(200, 200, 200),
        Uncommon = Color3.fromRGB(100, 200, 100),
        Rare = Color3.fromRGB(100, 150, 255),
        Epic = Color3.fromRGB(200, 100, 255),
        Legendary = Color3.fromRGB(255, 200, 50),
    }
    seedPart.Color = rarityColors[seedConfig.rarity] or rarityColors.Common
    
    -- Add glow effect for rare seeds
    if seedConfig.rarity ~= "Common" then
        local light = Instance.new("PointLight")
        light.Brightness = 2
        light.Range = 10
        light.Color = seedPart.Color
        light.Parent = seedPart
    end
    
    seedPart.Parent = seedModel
    
    -- Create clickable detector
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 15
    clickDetector.Parent = seedPart
    
    -- Store seed data in attributes
    seedModel:SetAttribute("SeedId", seedConfig.id)
    seedModel:SetAttribute("Rarity", seedConfig.rarity)
    seedModel:SetAttribute("SpawnTime", tick())
    
    -- Add to workspace
    seedModel.Parent = workspace:FindFirstChild("Seeds") or workspace
    seedModel.PrimaryPart = seedPart
    
    -- Tag for easy identification
    CollectionService:AddTag(seedModel, SEED_TAG)
    
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
    -- Validate
    if not player or not player.Parent then return false end
    if not seedModel or not seedModel.Parent then return false end
    
    -- Check cooldown
    local lastCollection = PlayerCooldowns[player] or 0
    if tick() - lastCollection < COLLECTION_COOLDOWN then
        return false
    end
    
    -- Check if seed exists in our tracking
    local seedData = ActiveSeeds[seedModel]
    if not seedData then return false end
    
    -- Check distance (anti-exploit)
    local character = player.Character
    if not character then return false end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end
    
    local seedPart = seedModel:FindFirstChild("SeedPart")
    if not seedPart then return false end
    
    local distance = (humanoidRootPart.Position - seedPart.Position).Magnitude
    if distance > 20 then
        warn("⚠️  Player too far from seed:", player.Name, distance)
        return false
    end
    
    -- Add to inventory (using DataManager)
    local DataManager = require(game.ServerScriptService.Data.DataManager)
    local success = DataManager.AddItem(player, "seeds", seedData.seedId, 1)
    
    if not success then
        warn("❌ Failed to add seed to inventory:", player.Name, seedData.seedId)
        return false
    end
    
    -- Update stats
    DataManager.IncrementStat(player, "seedsCollected", 1)
    
    -- Award coins
    DataManager.AddCurrency(player, "coins", 2)
    
    -- Update cooldown
    PlayerCooldowns[player] = tick()
    
    -- Despawn seed
    SeedSpawnController._DespawnSeed(seedModel)
    
    -- Success feedback
    print("✅ Collected seed:", seedData.seedId, "by", player.Name)
    
    -- TODO: Fire RemoteEvent to show collection effect on client
    
    return true
end

-- ============================
-- CLEANUP
-- ============================

function SeedSpawnController._CleanupLoop()
    while IsRunning do
        task.wait(30) -- Check every 30 seconds
        
        local currentTime = tick()
        local toRemove = {}
        
        for seedModel, seedData in pairs(ActiveSeeds) do
            -- Check if seed expired
            if currentTime - seedData.spawnTime > SEED_LIFETIME then
                table.insert(toRemove, seedModel)
            end
            
            -- Check if seed model was destroyed
            if not seedModel.Parent then
                table.insert(toRemove, seedModel)
            end
        end
        
        -- Remove expired seeds
        for _, seedModel in ipairs(toRemove) do
            SeedSpawnController._DespawnSeed(seedModel)
        end
        
        if #toRemove > 0 then
            print("🧹 Cleaned up", #toRemove, "expired seeds")
        end
    end
end

function SeedSpawnController._DespawnSeed(seedModel: Instance)
    local seedData = ActiveSeeds[seedModel]
    if not seedData then return end
    
    -- Remove from zone tracking
    local zoneData = SpawnZones[seedData.zonePart]
    if zoneData then
        zoneData.activeSeeds[seedModel] = nil
    end
    
    -- Remove from active tracking
    ActiveSeeds[seedModel] = nil
    
    -- Destroy model
    if seedModel.Parent then
        seedModel:Destroy()
    end
end

-- ============================
-- DEBUG COMMANDS
-- ============================

function SeedSpawnController.GetActiveSeeds(): number
    local count = 0
    for _, _ in pairs(ActiveSeeds) do
        count = count + 1
    end
    return count
end

function SeedSpawnController.GetZoneCount(): number
    local count = 0
    for _, _ in pairs(SpawnZones) do
        count = count + 1
    end
    return count
end

function SeedSpawnController.ForceSpawn(zoneName: string?): boolean
    for zonePart, zoneData in pairs(SpawnZones) do
        if not zoneName or zoneData.name == zoneName then
            SeedSpawnController._SpawnSeed(zonePart, zoneData)
            return true
        end
    end
    return false
end

function SeedSpawnController.ClearAllSeeds()
    for seedModel, _ in pairs(ActiveSeeds) do
        SeedSpawnController._DespawnSeed(seedModel)
    end
    print("🧹 Cleared all seeds")
end

-- ============================
-- SHUTDOWN
-- ============================

function SeedSpawnController.Shutdown()
    IsRunning = false
    SeedSpawnController.ClearAllSeeds()
    print("🛑 Seed Spawn System shut down")
end

print("✅ SeedSpawnController loaded")

return SeedSpawnController
