--[[
    ItemSpawnController.lua - REFACTORED FOR NEW ITEM SYSTEM
    Manages item spawning across all zones in the world
    
    ✅ CHANGES FROM SeedSpawnController:
    1. Works with new Items.lua config (Forms, Substances, Attributes)
    2. Spawns different item types based on zone configuration
    3. Updated visual system for different item types
    4. Maintains all existing collection mechanics
    
    Features:
    - Zone-based spawning with configurable rates
    - Rarity-weighted item selection
    - Maximum items per zone
    - Respawn system
    - Collection handling with anti-exploit
    - Zone discovery system
]]

local ItemSpawnController = {}

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
    Items = require(Shared.Config.Items),
}

-- Managers
local DataManager = require(ServerScriptService.Data.DataManager)
local InventoryManager = require(ServerScriptService.Systems.InventorySystem.InventoryManager)

-- Constants
local ITEM_TAG = "ItemSpawn"
local ZONE_TAG = "ItemZone"
local SPAWN_CHECK_INTERVAL = 5
local ITEM_LIFETIME = 300
local COLLECTION_COOLDOWN = 0.5
local COLLECTION_RANGE = 20

-- State
local ActiveItems = {} -- {itemInstance = {data}}
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

local CollectItemEvent = RemoteEvents:FindFirstChild("CollectItem")
if not CollectItemEvent then
    CollectItemEvent = Instance.new("RemoteEvent")
    CollectItemEvent.Name = "CollectItem"
    CollectItemEvent.Parent = RemoteEvents
end

local ItemCollectedEvent = RemoteEvents:FindFirstChild("ItemCollected")
if not ItemCollectedEvent then
    ItemCollectedEvent = Instance.new("RemoteEvent")
    ItemCollectedEvent.Name = "ItemCollected"
    ItemCollectedEvent.Parent = RemoteEvents
end

-- ============================
-- INITIALIZATION
-- ============================

function ItemSpawnController.Init()
    print("🌱 Initializing Item Spawn System...")
    
    ItemSpawnController._DiscoverZones()
    ItemSpawnController._SetupCollectionHandling()
    
    CollectionService:GetInstanceAddedSignal(ZONE_TAG):Connect(function(zone)
        ItemSpawnController._RegisterZone(zone)
    end)
    
    CollectionService:GetInstanceRemovedSignal(ZONE_TAG):Connect(function(zone)
        ItemSpawnController._UnregisterZone(zone)
    end)
    
    print("✅ Item Spawn System initialized with", #SpawnZones, "zones")
end

function ItemSpawnController.Start()
    if IsRunning then return end
    IsRunning = true
    
    print("🌱 Starting Item Spawn System...")
    
    for zonePart, zoneData in pairs(SpawnZones) do
        ItemSpawnController._SpawnInitialItems(zonePart, zoneData)
    end
    
    task.spawn(function()
        ItemSpawnController._SpawnLoop()
    end)
    
    task.spawn(function()
        ItemSpawnController._CleanupLoop()
    end)
    
    print("✅ Item Spawn System started!")
end

-- ============================
-- ZONE MANAGEMENT
-- ============================

function ItemSpawnController._DiscoverZones()
    local zones = CollectionService:GetTagged(ZONE_TAG)
    
    for _, zone in ipairs(zones) do
        ItemSpawnController._RegisterZone(zone)
    end
end

function ItemSpawnController._RegisterZone(zonePart: Part)
    if not zonePart:IsA("BasePart") then
        warn("⚠️ Item zone must be a BasePart:", zonePart:GetFullName())
        return
    end
    
    local zoneData = {
        name = zonePart:GetAttribute("ZoneName") or zonePart.Name,
        spawnRate = zonePart:GetAttribute("SpawnRate") or 1.0,
        maxItems = zonePart:GetAttribute("MaxItems") or 10,
        respawnTime = zonePart:GetAttribute("RespawnTime") or 30,
        allowedItems = ItemSpawnController._GetAllowedItems(zonePart),
        activeItems = {},
        lastSpawnTime = 0,
    }
    
    SpawnZones[zonePart] = zoneData
    
    print("📍 Registered spawn zone:", zoneData.name, "| Max items:", zoneData.maxItems)
end

function ItemSpawnController._UnregisterZone(zonePart: Part)
    local zoneData = SpawnZones[zonePart]
    if not zoneData then return end
    
    for itemInstance, _ in pairs(zoneData.activeItems) do
        ItemSpawnController._DespawnItem(itemInstance)
    end
    
    SpawnZones[zonePart] = nil
    print("📍 Unregistered spawn zone:", zoneData.name)
end

function ItemSpawnController._GetAllowedItems(zonePart: Part): {string}
    local zoneType = zonePart:GetAttribute("ZoneType") or "meadow"
    
    local allowedItems = {}
    local zoneConfig = Config.Items.spawnZones[zoneType:lower()]
    
    if not zoneConfig then
        warn("⚠️ Unknown zone type:", zoneType, "- using meadow defaults")
        zoneConfig = Config.Items.spawnZones.meadow
    end
    
    -- Collect all items from zone config
    for rarity, items in pairs(zoneConfig) do
        if type(items) == "table" then
            for _, itemId in ipairs(items) do
                table.insert(allowedItems, itemId)
            end
        end
    end
    
    return allowedItems
end

-- ============================
-- SPAWNING LOGIC
-- ============================

function ItemSpawnController._SpawnInitialItems(zonePart: Part, zoneData: any)
    local initialCount = math.floor(zoneData.maxItems * 0.5)
    
    for i = 1, initialCount do
        ItemSpawnController._SpawnItem(zonePart, zoneData)
        task.wait(0.1)
    end
end

function ItemSpawnController._SpawnLoop()
    while IsRunning do
        task.wait(SPAWN_CHECK_INTERVAL)
        
        for zonePart, zoneData in pairs(SpawnZones) do
            local activeCount = 0
            for _, _ in pairs(zoneData.activeItems) do
                activeCount = activeCount + 1
            end
            
            if activeCount < zoneData.maxItems then
                local timeSinceLastSpawn = tick() - zoneData.lastSpawnTime
                
                if timeSinceLastSpawn >= zoneData.respawnTime then
                    ItemSpawnController._SpawnItem(zonePart, zoneData)
                    zoneData.lastSpawnTime = tick()
                end
            end
        end
    end
end

function ItemSpawnController._SpawnItem(zonePart: Part, zoneData: any): Instance?
    local itemId = ItemSpawnController._SelectRandomItem(zoneData.allowedItems)
    if not itemId then return nil end
    
    local itemConfig = Config.Items.GetItemById(itemId)
    if not itemConfig then return nil end
    
    local position = ItemSpawnController._GetRandomPositionInZone(zonePart)
    
    local itemInstance = ItemSpawnController._CreateItemInstance(itemConfig, position)
    if not itemInstance then return nil end
    
    local itemData = {
        itemId = itemId,
        config = itemConfig,
        spawnTime = tick(),
        zonePart = zonePart,
        spawnPosition = position,
    }
    
    ActiveItems[itemInstance] = itemData
    zoneData.activeItems[itemInstance] = true
    
    return itemInstance
end

function ItemSpawnController._SelectRandomItem(allowedItems: {string}): string?
    if #allowedItems == 0 then return nil end
    
    local totalWeight = 0
    local itemWeights = {}
    
    for _, itemId in ipairs(allowedItems) do
        local itemConfig = Config.Items.GetItemById(itemId)
        if itemConfig then
            local weight = itemConfig.rarity == "common" and 100
                or itemConfig.rarity == "uncommon" and 50
                or itemConfig.rarity == "rare" and 25
                or itemConfig.rarity == "legendary" and 1
                or 50
            
            table.insert(itemWeights, {
                itemId = itemId,
                weight = weight
            })
            totalWeight = totalWeight + weight
        end
    end
    
    local roll = math.random() * totalWeight
    local currentWeight = 0
    
    for _, itemWeight in ipairs(itemWeights) do
        currentWeight = currentWeight + itemWeight.weight
        if roll <= currentWeight then
            return itemWeight.itemId
        end
    end
    
    return allowedItems[1]
end

function ItemSpawnController._GetRandomPositionInZone(zonePart: Part): Vector3
    local size = zonePart.Size
    local cframe = zonePart.CFrame
    
    local randomX = (math.random() - 0.5) * size.X * 0.9
    local randomZ = (math.random() - 0.5) * size.Z * 0.9
    
    local worldPosition = cframe * Vector3.new(randomX, size.Y / 2 + 2, randomZ)
    
    return worldPosition
end

function ItemSpawnController._CreateItemInstance(itemConfig: any, position: Vector3): Instance?
    local itemModel = Instance.new("Model")
    itemModel.Name = itemConfig.id
    
    local itemPart = Instance.new("Part")
    itemPart.Name = "ItemPart"
    itemPart.Size = Vector3.new(1, 1, 1)
    itemPart.Position = position
    itemPart.Anchored = true
    itemPart.CanCollide = false
    itemPart.Material = Enum.Material.SmoothPlastic
    
    -- Color based on rarity
    if itemConfig.rarity == "common" then
        itemPart.Color = Color3.fromRGB(100, 200, 100)
    elseif itemConfig.rarity == "uncommon" then
        itemPart.Color = Color3.fromRGB(100, 100, 255)
    elseif itemConfig.rarity == "rare" then
        itemPart.Color = Color3.fromRGB(200, 100, 255)
    elseif itemConfig.rarity == "legendary" then
        itemPart.Color = Color3.fromRGB(255, 50, 50)
    end
    
    itemPart.Parent = itemModel
    
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = COLLECTION_RANGE
    clickDetector.Parent = itemPart
    
    local highlight = Instance.new("Highlight")
    highlight.FillColor = itemPart.Color
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = itemModel
    
    CollectionService:AddTag(itemModel, ITEM_TAG)
    
    itemModel.Parent = workspace:FindFirstChild("Items") or workspace
    
    ItemSpawnController._AddFloatingAnimation(itemPart)
    
    return itemModel
end

function ItemSpawnController._AddFloatingAnimation(part: Part)
    local initialY = part.Position.Y
    
    task.spawn(function()
        local time = 0
        while part and part.Parent do
            time = time + 0.05
            
            local offset = math.sin(time * 2) * 0.3
            local newPosition = part.Position
            newPosition = Vector3.new(
                newPosition.X,
                initialY + offset,
                newPosition.Z
            )
            part.Position = newPosition
            
            part.CFrame = part.CFrame * CFrame.Angles(0, math.rad(2), 0)
            
            task.wait(0.05)
        end
    end)
end

-- ============================
-- COLLECTION HANDLING
-- ============================

function ItemSpawnController._SetupCollectionHandling()
    CollectItemEvent.OnServerEvent:Connect(function(player, itemModel)
        ItemSpawnController.CollectItem(player, itemModel)
    end)
    
    local function setupClickDetector(itemModel)
        local clickDetector = itemModel:FindFirstChildWhichIsA("ClickDetector", true)
        if clickDetector then
            clickDetector.MouseClick:Connect(function(clickingPlayer)
                ItemSpawnController.CollectItem(clickingPlayer, itemModel)
            end)
        end
    end
    
    for itemModel, _ in pairs(ActiveItems) do
        setupClickDetector(itemModel)
    end
    
    CollectionService:GetInstanceAddedSignal(ITEM_TAG):Connect(function(instance)
        setupClickDetector(instance)
    end)
end

function ItemSpawnController.CollectItem(player: Player, itemModel: Instance): boolean
    if not player or not player.Parent then 
        warn("⚠️ Invalid player attempted collection")
        return false 
    end
    
    if not itemModel or not itemModel.Parent then 
        warn("⚠️ Invalid item model")
        return false 
    end
    
    local lastCollection = PlayerCooldowns[player] or 0
    if tick() - lastCollection < COLLECTION_COOLDOWN then
        return false
    end
    
    local itemData = ActiveItems[itemModel]
    if not itemData then 
        warn("⚠️ Item not found in tracking:", itemModel.Name)
        return false 
    end
    
    local character = player.Character
    if not character then 
        warn("⚠️ Player has no character")
        return false 
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then 
        warn("⚠️ Player has no HumanoidRootPart")
        return false 
    end
    
    local distance = (humanoidRootPart.Position - itemData.spawnPosition).Magnitude
    if distance > COLLECTION_RANGE then
        warn("⚠️ Player too far from item:", player.Name, "Distance:", math.floor(distance), "Max:", COLLECTION_RANGE)
        return false
    end
    
    local itemName = itemData.config.name or itemData.itemId
    local success, errorMsg = InventoryManager.AddItem(player, itemData.itemId, itemName, 1)
    
    if not success then
        warn("❌ Failed to add item to inventory:", player.Name, itemData.itemId, errorMsg or "Unknown error")
        return false
    end
    
    DataManager.IncrementStat(player, "itemsCollected", 1) -- TODO: Rename this stat
    DataManager.AddCurrency(player, "coins", 2)
    
    PlayerCooldowns[player] = tick()
    
    ItemSpawnController._DespawnItem(itemModel)
    
    if ItemCollectedEvent then
        ItemCollectedEvent:FireClient(player, {
            itemId = itemData.itemId,
            itemName = itemName,
            rarity = itemData.config.rarity,
            icon = itemData.config.icon,
        })
    end
    
    print("✅ Collected item:", itemData.itemId, "by", player.Name, "| Distance:", math.floor(distance))
    
    return true
end

-- ============================
-- CLEANUP
-- ============================

function ItemSpawnController._CleanupLoop()
    while IsRunning do
        task.wait(30)
        
        local currentTime = tick()
        local itemsToRemove = {}
        
        for itemModel, itemData in pairs(ActiveItems) do
            if currentTime - itemData.spawnTime > ITEM_LIFETIME then
                table.insert(itemsToRemove, itemModel)
            end
            
            if not itemModel.Parent then
                table.insert(itemsToRemove, itemModel)
            end
        end
        
        for _, itemModel in ipairs(itemsToRemove) do
            ItemSpawnController._DespawnItem(itemModel)
        end
        
        if #itemsToRemove > 0 then
            print("🧹 Cleaned up", #itemsToRemove, "items")
        end
    end
end

function ItemSpawnController._DespawnItem(itemModel: Instance)
    local itemData = ActiveItems[itemModel]
    
    if itemData then
        local zoneData = SpawnZones[itemData.zonePart]
        if zoneData then
            zoneData.activeItems[itemModel] = nil
        end
        
        ActiveItems[itemModel] = nil
    end
    
    if itemModel and itemModel.Parent then
        itemModel:Destroy()
    end
end

function ItemSpawnController.Stop()
    IsRunning = false
    
    for itemModel, _ in pairs(ActiveItems) do
        ItemSpawnController._DespawnItem(itemModel)
    end
    
    print("🛑 Item Spawn System stopped")
end

-- ============================
-- DEBUG/ADMIN FUNCTIONS
-- ============================

function ItemSpawnController.GetActiveItems()
    local count = 0
    for _ in pairs(ActiveItems) do
        count = count + 1
    end
    return count
end

function ItemSpawnController.ForceSpawn(zoneName: string)
    for zonePart, zoneData in pairs(SpawnZones) do
        if zoneData.name == zoneName then
            return ItemSpawnController._SpawnItem(zonePart, zoneData)
        end
    end
    return nil
end

return ItemSpawnController
