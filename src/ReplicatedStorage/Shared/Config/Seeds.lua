--[[
    Seeds.lua
    Configuration for all seed types in Garden Creatures
    
    Each seed defines:
    - Name and description
    - Rarity tier
    - Plant it grows into
    - Drop locations
    - Special properties
]]

local Seeds = {
    -- Rarity distribution in world spawns
    rarityWeights = {
        Common = 60,      -- 60%
        Uncommon = 25,    -- 25%
        Rare = 10,        -- 10%
        Epic = 4,         -- 4%
        Legendary = 1     -- 1%
    },
    
    -- Seed definitions
    seeds = {
        -- COMMON SEEDS
        {
            id = "sunflower_seed",
            name = "Sunflower Seed",
            description = "A bright, cheerful seed that grows into a sunflower.",
            rarity = "Common",
            plantType = "sunflower",
            icon = "rbxassetid://0", -- Replace with actual asset ID
            stackSize = 99,
            sellPrice = 5, -- coins
        },
        
        {
            id = "daisy_seed",
            name = "Daisy Seed",
            description = "A simple white flower seed.",
            rarity = "Common",
            plantType = "daisy",
            icon = "rbxassetid://0",
            stackSize = 99,
            sellPrice = 5,
        },
        
        {
            id = "grass_seed",
            name = "Grass Seed",
            description = "Basic grass that grows quickly.",
            rarity = "Common",
            plantType = "grass",
            icon = "rbxassetid://0",
            stackSize = 99,
            sellPrice = 3,
        },
        
        -- UNCOMMON SEEDS
        {
            id = "rose_seed",
            name = "Rose Seed",
            description = "A thorny but beautiful flower.",
            rarity = "Uncommon",
            plantType = "rose",
            icon = "rbxassetid://0",
            stackSize = 99,
            sellPrice = 15,
        },
        
        {
            id = "tulip_seed",
            name = "Tulip Seed",
            description = "A colorful spring flower.",
            rarity = "Uncommon",
            plantType = "tulip",
            icon = "rbxassetid://0",
            stackSize = 99,
            sellPrice = 15,
        },
        
        -- RARE SEEDS
        {
            id = "fire_lily_seed",
            name = "Fire Lily Seed",
            description = "A magical flower that glows with inner warmth.",
            rarity = "Rare",
            plantType = "fire_lily",
            icon = "rbxassetid://0",
            stackSize = 50,
            sellPrice = 50,
            specialProperty = "fire_element",
        },
        
        {
            id = "water_lotus_seed",
            name = "Water Lotus Seed",
            description = "A mystical aquatic plant.",
            rarity = "Rare",
            plantType = "water_lotus",
            icon = "rbxassetid://0",
            stackSize = 50,
            sellPrice = 50,
            specialProperty = "water_element",
        },
        
        -- EPIC SEEDS
        {
            id = "crystal_bloom_seed",
            name = "Crystal Bloom Seed",
            description = "A rare seed that grows crystalline flowers.",
            rarity = "Epic",
            plantType = "crystal_bloom",
            icon = "rbxassetid://0",
            stackSize = 25,
            sellPrice = 150,
            specialProperty = "crystal_growth",
        },
        
        {
            id = "shadow_vine_seed",
            name = "Shadow Vine Seed",
            description = "A mysterious dark plant with purple glow.",
            rarity = "Epic",
            plantType = "shadow_vine",
            icon = "rbxassetid://0",
            stackSize = 25,
            sellPrice = 150,
            specialProperty = "shadow_element",
        },
        
        -- LEGENDARY SEEDS
        {
            id = "ancient_tree_seed",
            name = "Ancient Tree Seed",
            description = "The seed of a legendary tree said to live for millennia.",
            rarity = "Legendary",
            plantType = "ancient_tree",
            icon = "rbxassetid://0",
            stackSize = 10,
            sellPrice = 500,
            specialProperty = "ancient_power",
            growthMultiplier = 2.0, -- Takes longer to grow
        },
        
        {
            id = "starlight_seed",
            name = "Starlight Seed",
            description = "A cosmic seed that fell from the heavens.",
            rarity = "Legendary",
            plantType = "starlight_flower",
            icon = "rbxassetid://0",
            stackSize = 10,
            sellPrice = 500,
            specialProperty = "celestial_power",
            glowEffect = true,
        },
    },
    
    -- Spawn locations for different seed types
    spawnZones = {
        meadow = { "sunflower_seed", "daisy_seed", "grass_seed", "tulip_seed" },
        forest = { "grass_seed", "rose_seed", "shadow_vine_seed" },
        volcanic = { "fire_lily_seed", "crystal_bloom_seed" },
        aquatic = { "water_lotus_seed", "tulip_seed" },
        mystical = { "ancient_tree_seed", "starlight_seed", "crystal_bloom_seed" },
    }
}

return Seeds
