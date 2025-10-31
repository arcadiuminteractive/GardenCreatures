--[[
    Creatures.lua
    Configuration for all creature types, abilities, and leveling system
]]

local Creatures = {
    -- Leveling system configuration
    levelingSystem = {
        maxLevel = 10,
        
        -- XP required for each level
        xpPerLevel = {
            [1] = 0,      -- Level 1 (starting)
            [2] = 100,
            [3] = 250,
            [4] = 500,
            [5] = 850,
            [6] = 1300,
            [7] = 1900,
            [8] = 2600,
            [9] = 3500,
            [10] = 4600,
        },
        
        -- Ways to gain XP
        xpSources = {
            timeFollowing = 1,        -- XP per minute while following
            seedCollected = 5,
            plantHarvested = 10,
            creatureCrafted = 25,
            tradeCompleted = 15,
            wildCreatureTamed = 30,
        },
        
        -- How abilities scale with level
        abilityScaling = {
            tier1Base = 0.05,         -- 5% at level 1
            tier1PerLevel = 0.015,    -- +1.5% per level
            tier2Base = 0.10,         -- 10% at level 1
            tier2PerLevel = 0.02,     -- +2% per level
            tier3Base = 0.20,         -- 20% at level 1
            tier3PerLevel = 0.025,    -- +2.5% per level
        },
    },
    
    -- Storage and following limits
    storageLimits = {
        free = 5,                     -- Free storage slots
        maxStorage = 50,              -- Hard cap
        slotPrice = 50,               -- Gems per additional slot
    },
    
    followLimits = {
        free = 1,                     -- 1 creature following
        dualFollowGamepass = 299,     -- Robux for 2 creatures
    },
    
    -- Creature definitions
    creatures = {
        -- COMMON CREATURES
        {
            id = "sunflower_sprite",
            name = "Sunflower Sprite",
            description = "A cheerful spirit born from sunflowers.",
            rarity = "Common",
            element = "nature",
            model = "rbxassetid://0",
            icon = "rbxassetid://0",
            
            abilities = {
                {
                    id = "growth_accelerator_1",
                    name = "Growth Accelerator",
                    description = "Plants grow faster",
                    tier = 1,
                    category = "Gardening",
                    effectType = "growth_speed",
                },
            },
            
            baseStats = {
                speed = 16,
                size = 1.0,
                followDistance = 5,
            },
        },
        
        {
            id = "grass_wisp",
            name = "Grass Wisp",
            description = "A tiny elemental made of living grass.",
            rarity = "Common",
            element = "nature",
            model = "rbxassetid://0",
            icon = "rbxassetid://0",
            
            abilities = {
                {
                    id = "seed_sense_1",
                    name = "Seed Sense",
                    description = "Highlights nearby seed spawns",
                    tier = 1,
                    category = "Gathering",
                    effectType = "seed_highlight",
                },
            },
            
            baseStats = {
                speed = 18,
                size = 0.8,
                followDistance = 4,
            },
        },
        
        -- UNCOMMON CREATURES
        {
            id = "rose_guardian",
            name = "Rose Guardian",
            description = "A thorny protector with a soft heart.",
            rarity = "Uncommon",
            element = "nature",
            model = "rbxassetid://0",
            icon = "rbxassetid://0",
            
            abilities = {
                {
                    id = "pest_guard_1",
                    name = "Pest Guard",
                    description = "Prevents plant diseases",
                    tier = 1,
                    category = "Gardening",
                    effectType = "disease_immunity",
                },
                {
                    id = "bountiful_harvest_1",
                    name = "Bountiful Harvest",
                    description = "Chance for double drops",
                    tier = 1,
                    category = "Gathering",
                    effectType = "double_drop_chance",
                },
            },
            
            baseStats = {
                speed = 15,
                size = 1.2,
                followDistance = 6,
            },
        },
        
        -- RARE CREATURES
        {
            id = "flame_fox",
            name = "Flame Fox",
            description = "A mystical fox wreathed in gentle flames.",
            rarity = "Rare",
            element = "fire",
            model = "rbxassetid://0",
            icon = "rbxassetid://0",
            
            abilities = {
                {
                    id = "rare_seed_magnet_2",
                    name = "Rare Seed Magnet",
                    description = "Increased rare seed drop chance",
                    tier = 2,
                    category = "Gathering",
                    effectType = "rare_drop_boost",
                },
                {
                    id = "speed_boost_2",
                    name = "Swift Movement",
                    description = "Increased player movement speed",
                    tier = 2,
                    category = "Exploration",
                    effectType = "player_speed",
                },
            },
            
            baseStats = {
                speed = 20,
                size = 1.3,
                followDistance = 7,
            },
            
            particleEffect = "fire",
            glowEffect = true,
        },
        
        {
            id = "water_spirit",
            name = "Water Spirit",
            description = "A serene being of pure water and life.",
            rarity = "Rare",
            element = "water",
            model = "rbxassetid://0",
            icon = "rbxassetid://0",
            
            abilities = {
                {
                    id = "auto_water_2",
                    name = "Auto-Water",
                    description = "Plants don't need watering",
                    tier = 2,
                    category = "Gardening",
                    effectType = "auto_water",
                },
                {
                    id = "mega_yield_2",
                    name = "Mega Yield",
                    description = "Plants produce more materials",
                    tier = 2,
                    category = "Gardening",
                    effectType = "harvest_multiplier",
                },
            },
            
            baseStats = {
                speed = 14,
                size = 1.1,
                followDistance = 5,
            },
            
            particleEffect = "water",
            glowEffect = true,
        },
        
        -- EPIC CREATURES
        {
            id = "crystal_drake",
            name = "Crystal Drake",
            description = "A small dragon made of living crystal.",
            rarity = "Epic",
            element = "crystal",
            model = "rbxassetid://0",
            icon = "rbxassetid://0",
            
            abilities = {
                {
                    id = "mutation_master_2",
                    name = "Mutation Master",
                    description = "Better creature mutations when crafting",
                    tier = 2,
                    category = "Crafting",
                    effectType = "mutation_boost",
                },
                {
                    id = "coin_multiplier_2",
                    name = "Coin Multiplier",
                    description = "Earn more coins from activities",
                    tier = 2,
                    category = "Economy",
                    effectType = "coin_bonus",
                },
                {
                    id = "treasure_hunter_2",
                    name = "Treasure Hunter",
                    description = "Marks rare spawn locations",
                    tier = 2,
                    category = "Exploration",
                    effectType = "treasure_sense",
                },
            },
            
            baseStats = {
                speed = 17,
                size = 1.5,
                followDistance = 8,
            },
            
            particleEffect = "sparkle",
            glowEffect = true,
            auraEffect = true,
        },
        
        {
            id = "shadow_panther",
            name = "Shadow Panther",
            description = "A sleek predator that moves through darkness.",
            rarity = "Epic",
            element = "shadow",
            model = "rbxassetid://0",
            icon = "rbxassetid://0",
            
            abilities = {
                {
                    id = "night_vision_2",
                    name = "Night Vision",
                    description = "Better visibility at night",
                    tier = 2,
                    category = "Exploration",
                    effectType = "night_sight",
                },
                {
                    id = "quick_craft_2",
                    name = "Quick Craft",
                    description = "Reduced crafting time",
                    tier = 2,
                    category = "Crafting",
                    effectType = "craft_speed",
                },
                {
                    id = "resource_saver_2",
                    name = "Resource Saver",
                    description = "Chance to refund materials",
                    tier = 2,
                    category = "Crafting",
                    effectType = "material_refund",
                },
            },
            
            baseStats = {
                speed = 22,
                size = 1.4,
                followDistance = 7,
            },
            
            particleEffect = "shadow",
            glowEffect = true,
        },
        
        -- LEGENDARY CREATURES
        {
            id = "ancient_tree_dragon",
            name = "Ancient Tree Dragon",
            description = "A massive dragon born from the oldest trees.",
            rarity = "Legendary",
            element = "nature",
            model = "rbxassetid://0",
            icon = "rbxassetid://0",
            
            abilities = {
                {
                    id = "rare_seed_magnet_3",
                    name = "Legendary Seed Magnet",
                    description = "Greatly increased rare seed drops",
                    tier = 3,
                    category = "Gathering",
                    effectType = "rare_drop_boost",
                },
                {
                    id = "mutation_master_3",
                    name = "Master Mutator",
                    description = "Exceptional mutation chances",
                    tier = 3,
                    category = "Crafting",
                    effectType = "mutation_boost",
                },
                {
                    id = "prestige_boost_3",
                    name = "Ancient Wisdom",
                    description = "Earn XP much faster",
                    tier = 3,
                    category = "Social",
                    effectType = "xp_multiplier",
                },
            },
            
            baseStats = {
                speed = 16,
                size = 2.5,
                followDistance = 10,
            },
            
            particleEffect = "leaves",
            glowEffect = true,
            auraEffect = true,
            uniqueAnimation = "fly",
        },
        
        {
            id = "celestial_phoenix",
            name = "Celestial Phoenix",
            description = "A cosmic bird that never truly dies.",
            rarity = "Legendary",
            element = "celestial",
            model = "rbxassetid://0",
            icon = "rbxassetid://0",
            
            abilities = {
                {
                    id = "lucky_find_3",
                    name = "Cosmic Luck",
                    description = "High chance for legendary items",
                    tier = 3,
                    category = "Gathering",
                    effectType = "legendary_drop_boost",
                },
                {
                    id = "gem_finder_3",
                    name = "Gem Vision",
                    description = "Find gems while exploring",
                    tier = 3,
                    category = "Economy",
                    effectType = "gem_drops",
                },
                {
                    id = "teleport_home",
                    name = "Celestial Portal",
                    description = "Teleport to home base anywhere",
                    tier = 3,
                    category = "Exploration",
                    effectType = "teleport_ability",
                },
            },
            
            baseStats = {
                speed = 24,
                size = 2.0,
                followDistance = 12,
            },
            
            particleEffect = "stars",
            glowEffect = true,
            auraEffect = true,
            uniqueAnimation = "fly",
            trailEffect = true,
        },
    },
}

-- Helper function to calculate ability strength at a given level
function Creatures.GetAbilityStrength(abilityTier, creatureLevel)
    local scaling = Creatures.levelingSystem.abilityScaling
    local base, perLevel
    
    if abilityTier == 1 then
        base = scaling.tier1Base
        perLevel = scaling.tier1PerLevel
    elseif abilityTier == 2 then
        base = scaling.tier2Base
        perLevel = scaling.tier2PerLevel
    elseif abilityTier == 3 then
        base = scaling.tier3Base
        perLevel = scaling.tier3PerLevel
    end
    
    return base + (perLevel * (creatureLevel - 1))
end

return Creatures
