--[[
    Types.lua
    Type definitions for Garden Creatures (Luau type annotations)
    
    ✅ UPDATED FOR NEW ITEMS SYSTEM
    - Changed from Seed types to Item types
    - Added Form and Substance types
    - Removed "Epic" rarity (only 4 rarities now)
    - Added template types
    - Updated to match Items.lua structure
    
    This file provides type safety and better IDE autocomplete
]]

-- ================================
-- CORE TYPES
-- ================================

export type Rarity = "common" | "uncommon" | "rare" | "legendary"

export type Element = "nature" | "fire" | "water" | "shadow" | "crystal" | "celestial"

export type ItemType = "Form" | "Substance"

-- ================================
-- ITEM TYPES (NEW SYSTEM)
-- ================================

-- Base item properties (shared by all items)
export type BaseItem = {
    id: string,
    templateId: string,
    name: string,
    description: string,
    itemType: ItemType,
    rarity: Rarity,
    icon: string,
    stackSize: number,
    sellPrice: number,
    glowEffect: boolean?,
    particleEffect: string?,
    specialProperty: string?,
}

-- Form item (defines creature body type)
export type FormItem = BaseItem & {
    formType: string,
    baseModel: string,
    baseSize: Vector3,
    baseStats: {
        [string]: number,
    },
}

-- Substance item (defines material/appearance)
export type SubstanceItem = BaseItem & {
    substanceType: string,
    material: Enum.Material,
    baseColor: Color3,
    texture: string,
    statModifiers: {
        [string]: number,
    },
}

-- Union type for any item
export type Item = FormItem | SubstanceItem

-- ================================
-- TEMPLATE TYPES (FOR CONFIG)
-- ================================

export type ItemVariant = {
    icon: string,
    specialProperty: string?,
    glowEffect: boolean?,
    particleEffect: string?,
    description: string?,
    baseColor: Color3?,
}

export type FormTemplate = {
    id: string,
    name: string,
    description: string,
    itemType: "Form",
    formType: string,
    baseModel: string,
    baseSize: Vector3,
    baseStats: {
        [string]: number,
    },
    baseStackSize: number,
    basePrice: number,
    variants: {
        common: ItemVariant,
        uncommon: ItemVariant,
        rare: ItemVariant,
        legendary: ItemVariant,
    },
    spawnZones: {string},
}

export type SubstanceTemplate = {
    id: string,
    name: string,
    description: string,
    itemType: "Substance",
    substanceType: string,
    material: Enum.Material,
    baseColor: Color3,
    texture: string,
    particleEffect: string?,
    baseStatModifiers: {
        [string]: number,
    },
    baseStackSize: number,
    basePrice: number,
    variants: {
        common: ItemVariant,
        uncommon: ItemVariant,
        rare: ItemVariant,
        legendary: ItemVariant,
    },
    spawnZones: {string},
}

-- ================================
-- PLANT TYPES
-- ================================

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
    itemId: string,  -- Changed from seedId
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

-- ================================
-- CREATURE TYPES
-- ================================

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
    [string]: number,  -- Allow any stat
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

-- ================================
-- CREATURE PLOT TYPES (NEW)
-- ================================

export type PlotSlotType = "Form" | "Substance" | "PrimaryAttribute" | "SecondaryAttribute"

export type PlotSlotConfig = {
    name: string,
    description: string,
    icon: string,
    required: boolean,
}

export type CreaturePlotData = {
    plotId: string,
    formItemId: string?,
    substanceItemId: string?,
    primaryAttributeItemId: string?,
    secondaryAttributeItemId: string?,
    isGrowing: boolean,
    growthStartTime: number?,
    growthDuration: number,
    ownerId: number,
}

-- ================================
-- RECIPE TYPES
-- ================================

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

-- ================================
-- INVENTORY TYPES
-- ================================

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

-- ================================
-- PLAYER DATA TYPES
-- ================================

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
    
    -- Creature Plots (NEW)
    creaturePlots: {CreaturePlotData},
    maxCreaturePlots: number,
    
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
    plantedItem: string?,  -- Changed from plantedSeed
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

-- ================================
-- TRADING TYPES
-- ================================

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

-- ================================
-- ECONOMY TYPES
-- ================================

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

-- ================================
-- SPAWN TYPES
-- ================================

export type SpawnZone = {
    name: string,
    position: Vector3,
    radius: number,
    spawnRate: number,
    allowedItems: {string},  -- Changed from allowedCreatureTypes
    rareSpawnBonus: number?,
    requiresLevel: number?,
}

export type ItemSpawn = {
    instanceId: string,
    itemId: string,
    position: Vector3,
    spawnZone: string,
    spawnedTimestamp: number,
    model: Model,
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

-- ================================
-- UI TYPES
-- ================================

export type NotificationData = {
    title: string,
    message: string,
    duration: number?,
    icon: string?,
    rarity: Rarity?,
}

export type DialogData = {
    title: string,
    message: string,
    buttons: {
        {
            text: string,
            callback: () -> (),
        }
    },
}

-- Export empty table (types are just for annotations)
return {}
