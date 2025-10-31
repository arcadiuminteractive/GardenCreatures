--[[
    Types.lua
    Type definitions for Garden Creatures (Luau type annotations)
    
    This file provides type safety and better IDE autocomplete
]]

export type Rarity = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary"

export type Element = "nature" | "fire" | "water" | "shadow" | "crystal" | "celestial"

-- Seed types
export type Seed = {
    id: string,
    name: string,
    description: string,
    rarity: Rarity,
    plantType: string,
    icon: string,
    stackSize: number,
    sellPrice: number,
    specialProperty: string?,
    growthMultiplier: number?,
    glowEffect: boolean?,
}

-- Plant types
export type PlantStage = {
    name: string,
    duration: number,  -- seconds
    model: string,
}

export type HarvestYield = {
    item: string,
    amount: {
        min: number,
        max: number,
    },
}

export type Plant = {
    name: string,
    rarity: Rarity,
    seedId: string,
    element: Element?,
    growthStages: {PlantStage},
    harvestYield: {HarvestYield},
    harvestXP: number,
    canReharvest: boolean,
    reharvestTime: number?,
    requiresWater: boolean?,
    requiresSpecialPlot: boolean?,
    glowEffect: boolean?,
    particleEffect: string?,
    onlyGrowsAtNight: boolean?,
    mutationChance: number?,
}

-- Creature types
export type Ability = {
    id: string,
    name: string,
    description: string,
    tier: number,  -- 1, 2, or 3
    category: string,
    effectType: string,
}

export type CreatureStats = {
    speed: number,
    size: number,
    followDistance: number,
}

export type Creature = {
    id: string,
    name: string,
    description: string,
    rarity: Rarity,
    element: Element,
    model: string,
    icon: string,
    abilities: {Ability},
    baseStats: CreatureStats,
    particleEffect: string?,
    glowEffect: boolean?,
    auraEffect: boolean?,
    uniqueAnimation: string?,
    trailEffect: boolean?,
}

-- Instance of a creature (with level, XP, etc.)
export type CreatureInstance = {
    instanceId: string,           -- Unique ID for this creature
    creatureId: string,           -- Reference to Creature definition
    level: number,
    xp: number,
    displayName: string?,         -- Custom name given by player
    isFavorite: boolean,
    obtainedTimestamp: number,
    mutation: string?,            -- Mutation variant if any
}

-- Recipe types
export type RecipeMaterial = {
    item: string,
    amount: number,
}

export type Recipe = {
    id: string,
    name: string,
    description: string,
    resultCreature: string,
    rarity: Rarity,
    materials: {RecipeMaterial},
    unlockCost: number?,
    gemUnlockCost: number?,
    unlocked: boolean,
    craftingXP: number,
    requiresDiscovery: boolean?,
    requiresSpecialStation: boolean?,
    mutationVariants: {string}?,
}

-- Inventory types
export type InventoryItem = {
    itemId: string,
    amount: number,
    metadata: {[string]: any}?,
}

export type Inventory = {
    items: {[string]: number},
    materials: {[string]: number},
    creatures: {CreatureInstance},
    maxSlots: number,
    usedSlots: number,
}

-- Player data types
export type PlayerData = {
    -- Currency
    coins: number,
    gems: number,
    
    -- Inventory
    inventory: Inventory,
    
    -- Creatures
    activeCreatures: {string},     -- Instance IDs of following creatures
    maxFollowSlots: number,
    creatureStorage: {CreatureInstance},
    maxStorageSlots: number,
    
    -- Garden
    gardenPlots: {PlotData},
    maxPlots: number,
    
    -- Progression
    level: number,
    xp: number,
    unlockedRecipes: {string},
    discoveredCreatures: {string},
    
    -- Settings
    settings: PlayerSettings,
    
    -- Stats
    stats: PlayerStats,
    
    -- Timestamps
    lastLogin: number,
    creationDate: number,
}

export type PlotData = {
    plotId: string,
    plotType: string,
    plantedSeed: string?,
    plantStage: number,
    plantedTimestamp: number?,
    harvestReady: boolean,
    position: Vector3?,
}

export type PlayerSettings = {
    musicVolume: number,
    sfxVolume: number,
    showTutorial: boolean,
    chatEnabled: boolean,
}

export type PlayerStats = {
    itemsCollected: number,
    plantsHarvested: number,
    creaturesCreated: number,
    creaturesTamed: number,
    tradesCompleted: number,
    coinsEarned: number,
    gemsSpent: number,
    timePlayed: number,
}

-- Trading types
export type TradeOffer = {
    coins: number,
    items: {[string]: number},
    materials: {[string]: number},
    creatures: {string},  -- Instance IDs
}

export type TradeSession = {
    tradeId: string,
    player1: Player,
    player2: Player,
    player1Offer: TradeOffer,
    player2Offer: TradeOffer,
    player1Accepted: boolean,
    player2Accepted: boolean,
    status: string,  -- "pending", "accepted", "cancelled", "completed"
    createdTimestamp: number,
}

-- Economy types
export type ShopItem = {
    id: string,
    name: string,
    description: string,
    coinPrice: number?,
    gemPrice: number?,
    category: string,
    maxPurchases: number?,
    metadata: {[string]: any}?,
}

export type Gamepass = {
    id: string,
    name: string,
    description: string,
    price: number,
    gamepassId: number,
    benefits: {string},
}

-- Spawn types
export type SpawnZone = {
    name: string,
    position: Vector3,
    radius: number,
    spawnRate: number,
    allowedCreatureTypes: {string},
    rareSpawnBonus: number?,
    requiresLevel: number?,
}

export type WildCreature = {
    instanceId: string,
    creatureId: string,
    position: Vector3,
    spawnZone: string,
    spawnType: string,  -- "player_associated" or "rare_world"
    sourcePlayerId: number?,  -- If player-associated
    spawnedTimestamp: number,
    model: Model,
}

return {}
