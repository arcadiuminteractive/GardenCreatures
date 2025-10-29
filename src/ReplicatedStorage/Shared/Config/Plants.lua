--[[
    Plants.lua
    Configuration for all plant types and growth mechanics
    
    Defines:
    - Growth stages and timing
    - Harvest yields
    - Plant requirements
    - Special properties
]]

local Plants = {
    -- Global plant settings
    baseGrowthTime = 60, -- seconds per stage
    wateringInterval = 300, -- 5 minutes between watering needs
    
    -- Plant definitions
    plants = {
        -- COMMON PLANTS
        sunflower = {
            name = "Sunflower",
            rarity = "Common",
            seedId = "sunflower_seed",
            
            growthStages = {
                { name = "Sprout", duration = 30, model = "rbxassetid://0" },
                { name = "Growing", duration = 60, model = "rbxassetid://0" },
                { name = "Blooming", duration = 90, model = "rbxassetid://0" },
                { name = "Mature", duration = 0, model = "rbxassetid://0" } -- Final stage
            },
            
            harvestYield = {
                { item = "sunflower_petals", amount = {min = 3, max = 6} },
                { item = "plant_fiber", amount = {min = 2, max = 4} },
            },
            
            harvestXP = 10,
            canReharvest = false, -- Plant dies after harvest
        },
        
        daisy = {
            name = "Daisy",
            rarity = "Common",
            seedId = "daisy_seed",
            
            growthStages = {
                { name = "Sprout", duration = 25, model = "rbxassetid://0" },
                { name = "Growing", duration = 50, model = "rbxassetid://0" },
                { name = "Blooming", duration = 75, model = "rbxassetid://0" },
                { name = "Mature", duration = 0, model = "rbxassetid://0" }
            },
            
            harvestYield = {
                { item = "daisy_petals", amount = {min = 2, max = 5} },
                { item = "plant_fiber", amount = {min = 1, max = 3} },
            },
            
            harvestXP = 8,
            canReharvest = false,
        },
        
        grass = {
            name = "Grass",
            rarity = "Common",
            seedId = "grass_seed",
            
            growthStages = {
                { name = "Sprout", duration = 20, model = "rbxassetid://0" },
                { name = "Mature", duration = 0, model = "rbxassetid://0" }
            },
            
            harvestYield = {
                { item = "grass_clippings", amount = {min = 5, max = 10} },
            },
            
            harvestXP = 5,
            canReharvest = true, -- Grass regrows
            reharvestTime = 60,
        },
        
        -- UNCOMMON PLANTS
        rose = {
            name = "Rose",
            rarity = "Uncommon",
            seedId = "rose_seed",
            
            growthStages = {
                { name = "Sprout", duration = 45, model = "rbxassetid://0" },
                { name = "Growing", duration = 90, model = "rbxassetid://0" },
                { name = "Budding", duration = 120, model = "rbxassetid://0" },
                { name = "Blooming", duration = 150, model = "rbxassetid://0" },
                { name = "Mature", duration = 0, model = "rbxassetid://0" }
            },
            
            harvestYield = {
                { item = "rose_petals", amount = {min = 4, max = 8} },
                { item = "thorny_stems", amount = {min = 2, max = 5} },
                { item = "plant_fiber", amount = {min = 3, max = 6} },
            },
            
            harvestXP = 25,
            canReharvest = false,
        },
        
        -- RARE PLANTS
        fire_lily = {
            name = "Fire Lily",
            rarity = "Rare",
            seedId = "fire_lily_seed",
            element = "fire",
            
            growthStages = {
                { name = "Sprout", duration = 60, model = "rbxassetid://0" },
                { name = "Growing", duration = 120, model = "rbxassetid://0" },
                { name = "Heating", duration = 180, model = "rbxassetid://0" },
                { name = "Blazing", duration = 240, model = "rbxassetid://0" },
                { name = "Mature", duration = 0, model = "rbxassetid://0" }
            },
            
            harvestYield = {
                { item = "flame_petals", amount = {min = 5, max = 10} },
                { item = "fire_essence", amount = {min = 2, max = 4} },
                { item = "magical_ash", amount = {min = 1, max = 3} },
            },
            
            harvestXP = 75,
            canReharvest = false,
            glowEffect = true,
            particleEffect = "fire",
        },
        
        water_lotus = {
            name = "Water Lotus",
            rarity = "Rare",
            seedId = "water_lotus_seed",
            element = "water",
            requiresWater = true, -- Must be planted in water plot
            
            growthStages = {
                { name = "Floating Seed", duration = 60, model = "rbxassetid://0" },
                { name = "Sprouting", duration = 120, model = "rbxassetid://0" },
                { name = "Lily Pad", duration = 180, model = "rbxassetid://0" },
                { name = "Budding", duration = 240, model = "rbxassetid://0" },
                { name = "Blooming", duration = 0, model = "rbxassetid://0" }
            },
            
            harvestYield = {
                { item = "lotus_petals", amount = {min = 5, max = 10} },
                { item = "water_essence", amount = {min = 2, max = 4} },
                { item = "pure_water", amount = {min = 3, max = 6} },
            },
            
            harvestXP = 75,
            canReharvest = true,
            reharvestTime = 300,
        },
        
        -- EPIC PLANTS
        crystal_bloom = {
            name = "Crystal Bloom",
            rarity = "Epic",
            seedId = "crystal_bloom_seed",
            
            growthStages = {
                { name = "Crystal Seed", duration = 120, model = "rbxassetid://0" },
                { name = "Crystallizing", duration = 240, model = "rbxassetid://0" },
                { name = "Forming", duration = 360, model = "rbxassetid://0" },
                { name = "Shimmering", duration = 480, model = "rbxassetid://0" },
                { name = "Radiant", duration = 0, model = "rbxassetid://0" }
            },
            
            harvestYield = {
                { item = "crystal_shards", amount = {min = 8, max = 15} },
                { item = "light_essence", amount = {min = 4, max = 8} },
                { item = "prismatic_dust", amount = {min = 2, max = 5} },
            },
            
            harvestXP = 200,
            canReharvest = false,
            glowEffect = true,
            particleEffect = "sparkle",
            mutationChance = 0.15, -- 15% chance for mutation
        },
        
        -- LEGENDARY PLANTS
        ancient_tree = {
            name = "Ancient Tree",
            rarity = "Legendary",
            seedId = "ancient_tree_seed",
            requiresSpecialPlot = true, -- Needs large plot
            
            growthStages = {
                { name = "Seedling", duration = 300, model = "rbxassetid://0" },
                { name = "Sapling", duration = 600, model = "rbxassetid://0" },
                { name = "Young Tree", duration = 900, model = "rbxassetid://0" },
                { name = "Growing Tree", duration = 1200, model = "rbxassetid://0" },
                { name = "Mature Tree", duration = 1500, model = "rbxassetid://0" },
                { name = "Ancient Tree", duration = 0, model = "rbxassetid://0" }
            },
            
            harvestYield = {
                { item = "ancient_wood", amount = {min = 15, max = 25} },
                { item = "mystic_bark", amount = {min = 10, max = 18} },
                { item = "life_essence", amount = {min = 5, max = 10} },
                { item = "ancient_sap", amount = {min = 3, max = 7} },
            },
            
            harvestXP = 500,
            canReharvest = true,
            reharvestTime = 1800, -- 30 minutes
            glowEffect = true,
            auraEffect = true,
            mutationChance = 0.25,
        },
        
        starlight_flower = {
            name = "Starlight Flower",
            rarity = "Legendary",
            seedId = "starlight_seed",
            
            growthStages = {
                { name = "Cosmic Seed", duration = 300, model = "rbxassetid://0" },
                { name = "Stardust Sprout", duration = 600, model = "rbxassetid://0" },
                { name = "Moonlit Growth", duration = 900, model = "rbxassetid://0" },
                { name = "Stellar Bloom", duration = 1200, model = "rbxassetid://0" },
                { name = "Celestial Radiance", duration = 0, model = "rbxassetid://0" }
            },
            
            harvestYield = {
                { item = "starlight_petals", amount = {min = 12, max = 20} },
                { item = "cosmic_dust", amount = {min = 8, max = 15} },
                { item = "celestial_essence", amount = {min = 5, max = 10} },
                { item = "void_fragments", amount = {min = 2, max = 5} },
            },
            
            harvestXP = 500,
            canReharvest = false,
            glowEffect = true,
            particleEffect = "stars",
            onlyGrowsAtNight = true, -- Special condition
            mutationChance = 0.30,
        },
    },
    
    -- Growth boost modifiers
    boostModifiers = {
        vip = 1.5,           -- VIP players get 50% faster growth
        growthBooster = 2.0, -- Growth booster item doubles speed
        fertilizer = 1.25,   -- Fertilizer adds 25% speed
    },
}

return Plants
