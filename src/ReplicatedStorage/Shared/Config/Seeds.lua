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
            id = "dust_pebble",
            name = "Dust Pebble",
            description = "A dusty pebble of earth",
            rarity = "common",
            materialType = "dust",
            specialProperty = "ass +1",
            icon = "rbxassetid://95697693509834",
            modelId = "rbxassetid://123456789",
            stackSize = 99,
            sellPrice = 1,
            glowEffect = false
        },

        {
            id = "clay_chunk",
            name = "Clay Chunk",
            description = "A chunk of clay",
            rarity = "common",
            materialType = "clay",
            specialProperty = "ass +1",
            icon = "rbxassetid://87706048713897",
            modelId = "rbxassetid://123456789",
            stackSize = 99,
            sellPrice = 1,
            glowEffect = false
        },

        -- UNCOMMON SEEDS

        {
            id = "mud_heart",
            name = "Mud Heart",
            description = "A mysterious mud heart from unknown origin",
            rarity = "uncommon",
            materialType = "mud",
            specialProperty = "ass +2",
            icon = "rbxassetid://75209915738251",
            modelId = "rbxassetid://123456789",
            stackSize = 50,
            sellPrice = 5,
            glowEffect = false
        },

        {
            id = "iron_shard",
            name = "Iron Shard",
            description = "An iron shard",
            rarity = "uncommon",
            materialType = "mud",
            specialProperty = "ass +2",
            icon = "rbxassetid://110604248442404",
            modelId = "rbxassetid://123456789",
            stackSize = 50,
            sellPrice = 5,
            glowEffect = true
        },

        -- RARE SEEDS

        {
            id = "earth_worm",
            name = "Earth Worm",
            description = "An earthy grub with an odd look to it",
            rarity = "rare",
            materialType = "worm",
            specialProperty = "ass +5",
            icon = "rbxassetid://109057061984432",
            modelId = "rbxassetid://123456789",
            stackSize = 20,
            sellPrice = 10,
            glowEffect = true
        },

        -- LEGENDARY SEEDS

        {
            id = "jewel_beetle",
            name = "Jewel Beetle",
            description = "A stunning Jewel like Beetle",
            rarity = "legendary",
            materialType = "beetle",
            specialProperty = "ass +20",
            icon = "rbxassetid://80832768025430",
            modelId = "rbxassetid://123456789",
            stackSize = 1,
            sellPrice = 100,
            glowEffect = true
        },

        
        
    },
    
    -- Spawn locations for different seed types
    spawnZones = {
        meadow = { "dust_pebble", "clay_chunk", "iron_shard", "earth_worm", "jewel_beetle" },
    }
}

return Seeds
