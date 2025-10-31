--[[
    Items.lua
    Configuration for all collectible items in Garden Creatures
    
    Item System Overview:
    - Items replace the old "seed" system
    - Each item has a Type: Form, Substance, Attribute
    - Items combine in Creature Plots to create unique creatures
    - 4 slots: Form + Substance + Primary Attribute + Secondary Attribute
    
    Item Types:
    - Form: Defines creature body type (Wolf, Gorilla, Hawk, etc.)
    - Substance: Defines material/appearance (Dust, Mud, Iron, etc.)
    - Attribute: Defines stats/abilities (Speed, Armor, Sight, etc.)
]]

local Items = {
    -- Rarity distribution in world spawns
    rarityWeights = {
        common = 60,      -- 60%
        uncommon = 25,    -- 25%
        rare = 10,        -- 10%
        legendary = 1     -- 1%
    },
    
    -- Rarity scale factors (affects creature size, glow, particles)
    rarityScales = {
        common = 1.0,
        uncommon = 1.1,
        rare = 1.25,
        legendary = 1.5,
    },
    
    -- ================================
    -- FORM ITEMS (Define creature body)
    -- ================================
    forms = {
        {
            id = "wolf_tooth_c",
            name = "Wolf Tooth",
            description = "The upper jaw bone of a wolf long passed",
            itemType = "Form",
            rarity = "common",
            
            -- Form-specific data
            formType = "wolf",
            baseModel = "rbxassetid://TODO_WOLF_MODEL",
            baseSize = Vector3.new(3, 2, 4),
            baseStats = {
                speed = 20,
                health = 100,
            },
            
            -- Visual
            icon = "rbxassetid://96590138728105",
            stackSize = 10,
            sellPrice = 10,
        },
        
        {
            id = "wolf_tooth_u",
            name = "Wolf Tooth",
            description = "The upper jaw bone of a wolf long passed",
            itemType = "Form",
            rarity = "uncommon",
            
            formType = "wolf",
            baseModel = "rbxassetid://TODO_WOLF_MODEL",
            baseSize = Vector3.new(3, 2, 4),
            baseStats = {
                speed = 22,
                health = 110,
            },
            
            icon = "rbxassetid://92170516959446",
            stackSize = 10,
            sellPrice = 20,
        },
        
        {
            id = "wolf_tooth_r",
            name = "Wolf Tooth",
            description = "The upper jaw bone of a wolf long passed",
            itemType = "Form",
            rarity = "rare",
            
            formType = "wolf",
            baseModel = "rbxassetid://TODO_WOLF_MODEL",
            baseSize = Vector3.new(3, 2, 4),
            baseStats = {
                speed = 25,
                health = 125,
            },
            
            icon = "rbxassetid://104730292067575",
            stackSize = 5,
            sellPrice = 50,
        },
        
        {
            id = "wolf_tooth_l",
            name = "Wolf Tooth",
            description = "The upper jaw bone of a wolf long passed",
            itemType = "Form",
            rarity = "legendary",
            
            formType = "wolf",
            baseModel = "rbxassetid://TODO_WOLF_MODEL",
            baseSize = Vector3.new(3, 2, 4),
            baseStats = {
                speed = 30,
                health = 150,
            },
            
            icon = "rbxassetid://139767131625010",
            stackSize = 1,
            sellPrice = 500,
            glowEffect = true,
        },
        
        -- TODO: Add more form types (Gorilla, Hawk, Lizard, Bear, etc.)
    },
    
    -- ================================
    -- SUBSTANCE ITEMS (Define material/appearance)
    -- ================================
    substances = {
        {
            id = "dust_pebble",
            name = "Dust Pebble",
            description = "A dusty pebble of earth",
            itemType = "Substance",
            rarity = "common",
            
            -- Substance-specific data
            substanceType = "dust",
            material = Enum.Material.Sand,
            baseColor = Color3.fromRGB(180, 150, 120),
            texture = "rbxassetid://TODO_DUST_TEXTURE",
            particleEffect = nil,
            
            -- Stats granted by this substance
            statModifiers = {
                defense = 1,
                weight = -5, -- Lighter = faster
            },
            
            icon = "rbxassetid://95697693509834",
            stackSize = 99,
            sellPrice = 1,
        },
        
        {
            id = "clay_chunk",
            name = "Clay Chunk",
            description = "A chunk of moldable clay",
            itemType = "Substance",
            rarity = "common",
            
            substanceType = "clay",
            material = Enum.Material.Slate,
            baseColor = Color3.fromRGB(150, 120, 90),
            texture = "rbxassetid://TODO_CLAY_TEXTURE",
            particleEffect = nil,
            
            statModifiers = {
                defense = 2,
                health = 10,
            },
            
            icon = "rbxassetid://87706048713897",
            stackSize = 99,
            sellPrice = 1,
        },
        
        {
            id = "mud_heart",
            name = "Mud Heart",
            description = "A mysterious mud heart from unknown origin",
            itemType = "Substance",
            rarity = "uncommon",
            
            substanceType = "mud",
            material = Enum.Material.Mud,
            baseColor = Color3.fromRGB(100, 80, 60),
            texture = "rbxassetid://TODO_MUD_TEXTURE",
            particleEffect = "drip",
            
            statModifiers = {
                defense = 3,
                health = 20,
                regeneration = 1,
            },
            
            icon = "rbxassetid://75209915738251",
            stackSize = 50,
            sellPrice = 5,
        },
        
        {
            id = "iron_shard",
            name = "Iron Shard",
            description = "A fragment of pure iron",
            itemType = "Substance",
            rarity = "uncommon",
            
            substanceType = "iron",
            material = Enum.Material.Metal,
            baseColor = Color3.fromRGB(120, 120, 130),
            texture = "rbxassetid://TODO_IRON_TEXTURE",
            particleEffect = "sparkle",
            
            statModifiers = {
                defense = 8,
                health = 30,
                weight = 10, -- Heavier = slower
            },
            
            icon = "rbxassetid://110604248442404",
            stackSize = 50,
            sellPrice = 5,
            glowEffect = true,
        },
        
        {
            id = "earth_worm",
            name = "Earth Worm",
            description = "An earthy grub with an odd look to it",
            itemType = "Substance",
            rarity = "rare",
            
            substanceType = "worm",
            material = Enum.Material.Fabric,
            baseColor = Color3.fromRGB(140, 100, 80),
            texture = "rbxassetid://TODO_WORM_TEXTURE",
            particleEffect = "wiggle",
            
            statModifiers = {
                defense = -2,
                health = 15,
                regeneration = 3,
                speed = 5,
            },
            
            icon = "rbxassetid://109057061984432",
            stackSize = 20,
            sellPrice = 10,
            glowEffect = true,
        },
        
        {
            id = "jewel_beetle",
            name = "Jewel Beetle",
            description = "A stunning jewel-like beetle carapace",
            itemType = "Substance",
            rarity = "legendary",
            
            substanceType = "beetle",
            material = Enum.Material.Glass,
            baseColor = Color3.fromRGB(100, 200, 255),
            texture = "rbxassetid://TODO_BEETLE_TEXTURE",
            particleEffect = "rainbow_sparkle",
            
            statModifiers = {
                defense = 15,
                health = 50,
                speed = 8,
                luck = 5,
            },
            
            icon = "rbxassetid://80832768025430",
            stackSize = 1,
            sellPrice = 100,
            glowEffect = true,
        },
        
        -- TODO: Add more substances (Stone, Crystal, Lava, Ice, etc.)
    },
    
    -- ================================
    -- ATTRIBUTE ITEMS (Define abilities/stats)
    -- ================================
    attributes = {
        -- PRIMARY ATTRIBUTES (Major stats)
        {
            id = "speed_essence",
            name = "Speed Essence",
            description = "Pure speed energy",
            itemType = "Attribute",
            attributeTier = "primary",
            rarity = "common",
            
            -- Attribute-specific data
            statModifiers = {
                speed = 10,
            },
            
            icon = "rbxassetid://TODO_SPEED_ICON",
            stackSize = 20,
            sellPrice = 5,
        },
        
        {
            id = "armor_fragment",
            name = "Armor Fragment",
            description = "A piece of hardened armor",
            itemType = "Attribute",
            attributeTier = "primary",
            rarity = "common",
            
            statModifiers = {
                defense = 10,
            },
            
            icon = "rbxassetid://TODO_ARMOR_ICON",
            stackSize = 20,
            sellPrice = 5,
        },
        
        {
            id = "strength_core",
            name = "Strength Core",
            description = "Concentrated physical power",
            itemType = "Attribute",
            attributeTier = "primary",
            rarity = "uncommon",
            
            statModifiers = {
                attack = 15,
                health = 20,
            },
            
            icon = "rbxassetid://TODO_STRENGTH_ICON",
            stackSize = 15,
            sellPrice = 10,
        },
        
        -- SECONDARY ATTRIBUTES (Minor stats/utility)
        {
            id = "sight_lens",
            name = "Sight Lens",
            description = "Enhances perception",
            itemType = "Attribute",
            attributeTier = "secondary",
            rarity = "common",
            
            statModifiers = {
                sight = 5,
                detection = 10,
            },
            
            abilityGrant = "highlight_enemies",
            
            icon = "rbxassetid://TODO_SIGHT_ICON",
            stackSize = 20,
            sellPrice = 3,
        },
        
        {
            id = "regen_shard",
            name = "Regeneration Shard",
            description = "Grants healing over time",
            itemType = "Attribute",
            attributeTier = "secondary",
            rarity = "uncommon",
            
            statModifiers = {
                regeneration = 3,
                health = 10,
            },
            
            abilityGrant = "passive_heal",
            
            icon = "rbxassetid://TODO_REGEN_ICON",
            stackSize = 15,
            sellPrice = 8,
        },
        
        {
            id = "stealth_shadow",
            name = "Stealth Shadow",
            description = "Grants stealth abilities",
            itemType = "Attribute",
            attributeTier = "secondary",
            rarity = "rare",
            
            statModifiers = {
                stealth = 20,
                speed = 5,
            },
            
            abilityGrant = "invisibility",
            
            icon = "rbxassetid://TODO_STEALTH_ICON",
            stackSize = 10,
            sellPrice = 15,
            glowEffect = true,
        },
        
        -- TODO: Add more attributes (Fire, Ice, Poison, Electric, etc.)
    },
    
    -- Spawn zones configuration
    spawnZones = {
        meadow = {
            -- Common items spawn frequently
            common = {
                "dust_pebble",
                "clay_chunk",
                "speed_essence",
                "armor_fragment",
                "sight_lens",
            },
            -- Uncommon items spawn occasionally
            uncommon = {
                "mud_heart",
                "iron_shard",
                "strength_core",
                "regen_shard",
            },
            -- Rare items spawn rarely
            rare = {
                "earth_worm",
                "stealth_shadow",
            },
            -- Legendary items spawn very rarely
            legendary = {
                "jewel_beetle",
            },
            -- Form items (can be any rarity)
            forms = {
                "wolf_tooth_c",
                "wolf_tooth_u",
                "wolf_tooth_r",
                "wolf_tooth_l",
            },
        },
        
        -- TODO: Add more zones (forest, volcanic, aquatic, etc.)
    },
}

-- ================================
-- HELPER FUNCTIONS
-- ================================

--[[
    Get all items as a flat list
]]
function Items.GetAllItems()
    local allItems = {}
    
    -- Add forms
    for _, item in ipairs(Items.forms) do
        table.insert(allItems, item)
    end
    
    -- Add substances
    for _, item in ipairs(Items.substances) do
        table.insert(allItems, item)
    end
    
    -- Add attributes
    for _, item in ipairs(Items.attributes) do
        table.insert(allItems, item)
    end
    
    return allItems
end

--[[
    Get item configuration by ID
]]
function Items.GetItemById(itemId: string)
    -- Search forms
    for _, item in ipairs(Items.forms) do
        if item.id == itemId then
            return item
        end
    end
    
    -- Search substances
    for _, item in ipairs(Items.substances) do
        if item.id == itemId then
            return item
        end
    end
    
    -- Search attributes
    for _, item in ipairs(Items.attributes) do
        if item.id == itemId then
            return item
        end
    end
    
    return nil
end

--[[
    Get items by type
]]
function Items.GetItemsByType(itemType: string)
    if itemType == "Form" then
        return Items.forms
    elseif itemType == "Substance" then
        return Items.substances
    elseif itemType == "Attribute" then
        return Items.attributes
    end
    return {}
end

--[[
    Get items by rarity
]]
function Items.GetItemsByRarity(rarity: string)
    local results = {}
    local allItems = Items.GetAllItems()
    
    for _, item in ipairs(allItems) do
        if item.rarity == rarity then
            table.insert(results, item)
        end
    end
    
    return results
end

--[[
    Calculate average rarity from multiple items
    Returns: "common", "uncommon", "rare", or "legendary"
]]
function Items.CalculateAverageRarity(itemIds: {string}): string
    local rarityValues = {
        common = 1,
        uncommon = 2,
        rare = 3,
        legendary = 4,
    }
    
    local rarityNames = {"common", "uncommon", "rare", "legendary"}
    
    local total = 0
    local count = 0
    
    for _, itemId in ipairs(itemIds) do
        local item = Items.GetItemById(itemId)
        if item and item.rarity then
            total = total + (rarityValues[item.rarity] or 1)
            count = count + 1
        end
    end
    
    if count == 0 then return "common" end
    
    local average = math.floor((total / count) + 0.5) -- Round to nearest
    return rarityNames[math.clamp(average, 1, 4)]
end

return Items
