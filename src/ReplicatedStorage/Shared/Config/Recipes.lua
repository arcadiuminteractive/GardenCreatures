--[[
    Recipes.lua
    Crafting recipes for creating creatures from plant materials
]]

local Recipes = {
    -- Crafting system settings
    craftingTime = {
        Common = 30,      -- seconds
        Uncommon = 60,
        Rare = 120,
        Epic = 300,
        Legendary = 600,
    },
    
    -- Mutation chances (base, before creature abilities)
    mutationChance = {
        Common = 0.01,       -- 1%
        Uncommon = 0.03,     -- 3%
        Rare = 0.05,         -- 5%
        Epic = 0.10,         -- 10%
        Legendary = 0.15,    -- 15%
    },
    
    -- Crafting recipes
    recipes = {
        -- COMMON CREATURES
        {
            id = "sunflower_sprite_recipe",
            name = "Sunflower Sprite Recipe",
            description = "Craft a cheerful Sunflower Sprite",
            resultCreature = "sunflower_sprite",
            rarity = "Common",
            
            materials = {
                { item = "sunflower_petals", amount = 10 },
                { item = "plant_fiber", amount = 5 },
            },
            
            unlocked = true, -- Available from start
            craftingXP = 25,
        },
        
        {
            id = "grass_wisp_recipe",
            name = "Grass Wisp Recipe",
            description = "Create a tiny Grass Wisp",
            resultCreature = "grass_wisp",
            rarity = "Common",
            
            materials = {
                { item = "grass_clippings", amount = 15 },
                { item = "daisy_petals", amount = 5 },
            },
            
            unlocked = true,
            craftingXP = 25,
        },
        
        -- UNCOMMON CREATURES
        {
            id = "rose_guardian_recipe",
            name = "Rose Guardian Recipe",
            description = "Summon a protective Rose Guardian",
            resultCreature = "rose_guardian",
            rarity = "Uncommon",
            
            materials = {
                { item = "rose_petals", amount = 15 },
                { item = "thorny_stems", amount = 10 },
                { item = "plant_fiber", amount = 8 },
            },
            
            unlockCost = 100, -- Coins to unlock recipe
            unlocked = false,
            craftingXP = 50,
        },
        
        -- RARE CREATURES
        {
            id = "flame_fox_recipe",
            name = "Flame Fox Recipe",
            description = "Forge a mystical Flame Fox",
            resultCreature = "flame_fox",
            rarity = "Rare",
            
            materials = {
                { item = "flame_petals", amount = 20 },
                { item = "fire_essence", amount = 8 },
                { item = "magical_ash", amount = 5 },
                { item = "rose_petals", amount = 10 },
            },
            
            unlockCost = 500, -- Coins
            unlocked = false,
            craftingXP = 150,
            requiresDiscovery = true, -- Must find recipe in world
        },
        
        {
            id = "water_spirit_recipe",
            name = "Water Spirit Recipe",
            description = "Channel a serene Water Spirit",
            resultCreature = "water_spirit",
            rarity = "Rare",
            
            materials = {
                { item = "lotus_petals", amount = 20 },
                { item = "water_essence", amount = 8 },
                { item = "pure_water", amount = 12 },
                { item = "daisy_petals", amount = 10 },
            },
            
            unlockCost = 500,
            unlocked = false,
            craftingXP = 150,
            requiresDiscovery = true,
        },
        
        -- EPIC CREATURES
        {
            id = "crystal_drake_recipe",
            name = "Crystal Drake Recipe",
            description = "Crystallize a powerful drake",
            resultCreature = "crystal_drake",
            rarity = "Epic",
            
            materials = {
                { item = "crystal_shards", amount = 30 },
                { item = "light_essence", amount = 15 },
                { item = "prismatic_dust", amount = 10 },
                { item = "flame_petals", amount = 15 },
                { item = "water_essence", amount = 10 },
            },
            
            unlockCost = 2000, -- Coins or 100 gems
            gemUnlockCost = 100,
            unlocked = false,
            craftingXP = 400,
            requiresDiscovery = true,
            mutationVariants = {
                "crystal_drake_fire",    -- Red crystal variant
                "crystal_drake_ice",     -- Blue crystal variant
                "crystal_drake_shadow",  -- Dark crystal variant
            },
        },
        
        {
            id = "shadow_panther_recipe",
            name = "Shadow Panther Recipe",
            description = "Summon a creature of darkness",
            resultCreature = "shadow_panther",
            rarity = "Epic",
            
            materials = {
                { item = "shadow_essence", amount = 25 },
                { item = "void_fragments", amount = 12 },
                { item = "thorny_stems", amount = 20 },
                { item = "magical_ash", amount = 15 },
            },
            
            unlockCost = 2000,
            gemUnlockCost = 100,
            unlocked = false,
            craftingXP = 400,
            requiresDiscovery = true,
        },
        
        -- LEGENDARY CREATURES
        {
            id = "ancient_tree_dragon_recipe",
            name = "Ancient Tree Dragon Recipe",
            description = "Awaken the legendary tree dragon",
            resultCreature = "ancient_tree_dragon",
            rarity = "Legendary",
            
            materials = {
                { item = "ancient_wood", amount = 50 },
                { item = "mystic_bark", amount = 40 },
                { item = "life_essence", amount = 25 },
                { item = "ancient_sap", amount = 20 },
                { item = "flame_petals", amount = 30 },
                { item = "lotus_petals", amount = 30 },
            },
            
            unlockCost = 10000, -- Coins or 500 gems
            gemUnlockCost = 500,
            unlocked = false,
            craftingXP = 1000,
            requiresDiscovery = true,
            requiresSpecialStation = true, -- Needs legendary crafting altar
            mutationVariants = {
                "ancient_tree_dragon_elder",     -- Even bigger, gold leaves
                "ancient_tree_dragon_corrupted", -- Dark, purple variant
            },
        },
        
        {
            id = "celestial_phoenix_recipe",
            name = "Celestial Phoenix Recipe",
            description = "Birth a cosmic phoenix",
            resultCreature = "celestial_phoenix",
            rarity = "Legendary",
            
            materials = {
                { item = "starlight_petals", amount = 50 },
                { item = "cosmic_dust", amount = 40 },
                { item = "celestial_essence", amount = 25 },
                { item = "void_fragments", amount = 20 },
                { item = "fire_essence", amount = 30 },
            },
            
            unlockCost = 10000,
            gemUnlockCost = 500,
            unlocked = false,
            craftingXP = 1000,
            requiresDiscovery = true,
            requiresSpecialStation = true,
            mutationVariants = {
                "celestial_phoenix_solar",   -- Golden, sun-themed
                "celestial_phoenix_lunar",   -- Silver, moon-themed
                "celestial_phoenix_nebula",  -- Multi-colored, galaxy-themed
            },
        },
    },
    
    -- Hidden recipes (must be discovered)
    hiddenRecipes = {
        {
            id = "rainbow_sprite_recipe",
            name = "Rainbow Sprite Recipe",
            description = "A secret creature of all colors",
            resultCreature = "rainbow_sprite",
            rarity = "Epic",
            
            materials = {
                { item = "sunflower_petals", amount = 10 },
                { item = "rose_petals", amount = 10 },
                { item = "flame_petals", amount = 10 },
                { item = "lotus_petals", amount = 10 },
                { item = "crystal_shards", amount = 15 },
                { item = "prismatic_dust", amount = 10 },
            },
            
            discoveryHint = "Combine materials from all elemental types...",
            unlocked = false,
            craftingXP = 500,
        },
    },
}

return Recipes
