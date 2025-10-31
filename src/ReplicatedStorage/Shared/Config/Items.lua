--[[
    Items.lua - TEMPLATE-BASED ITEM CONFIGURATION SYSTEM
    Configuration for all collectible items in Garden Creatures
    
    ✅ REFACTORED TO USE TEMPLATES (Like Seeds.lua refactor)
    - Eliminates duplicate entries for each rarity
    - Single source of truth for each item
    - Automatic variant generation
    - Easy maintenance and scaling
    
    Item System Overview:
    - Items combine in Creature Plots to create unique creatures
    - 2 main item types: Forms and Substances
    - 4 slots: Form + Substance + Primary Attribute + Secondary Attribute
    
    Item Types:
    - Form: Defines creature body type (Wolf, Gorilla, Hawk, etc.)
      * Contains: formType, baseModel, baseStats, rarity, economy
    - Substance: Defines material/appearance (Dust, Mud, Iron, etc.)
      * Contains: material, texture, specialProperty (for attributes), rarity, economy
]]

local Items = {}

-- ================================
-- RARITY CONFIGURATION
-- ================================

-- Rarity distribution in world spawns
Items.rarityWeights = {
    common = 60,      -- 60%
    uncommon = 25,    -- 25%
    rare = 10,        -- 10%
    legendary = 5     -- 5%
}

-- Price multipliers per rarity
Items.rarityPriceMultipliers = {
    common = 1,
    uncommon = 2,
    rare = 5,
    legendary = 50
}

-- Stack size multipliers per rarity (higher rarity = more valuable = smaller stacks)
Items.rarityStackMultipliers = {
    common = 1.0,
    uncommon = 0.5,
    rare = 0.25,
    legendary = 0.1
}

-- Stat multipliers per rarity
Items.rarityStatMultipliers = {
    common = 1.0,
    uncommon = 1.1,
    rare = 1.25,
    legendary = 1.5
}

-- Visual scale factors (affects creature size)
Items.rarityScales = {
    common = 1.0,
    uncommon = 1.1,
    rare = 1.25,
    legendary = 1.5
}

-- ================================
-- FORM ITEM TEMPLATES
-- ================================

Items.formTemplates = {
    {
        id = "wolf_tooth",
        name = "Wolf Tooth",
        description = "The upper jaw bone of a wolf long passed",
        itemType = "Form",
        
        -- Form-specific data
        formType = "wolf",
        baseModel = "rbxassetid://TODO_WOLF_MODEL",
        baseSize = Vector3.new(3, 2, 4),
        
        -- Base stats (multiplied by rarity)
        baseStats = {
            speed = 20,
            health = 100,
        },
        
        -- Economy
        baseStackSize = 10,
        basePrice = 10,
        
        -- Rarity variants
        variants = {
            common = {
                icon = "rbxassetid://96590138728105",
                specialProperty = "Basic wolf essence",
            },
            uncommon = {
                icon = "rbxassetid://92170516959446",
                specialProperty = "Refined wolf essence",
            },
            rare = {
                icon = "rbxassetid://104730292067575",
                specialProperty = "Potent wolf essence",
                glowEffect = true,
            },
            legendary = {
                icon = "rbxassetid://139767131625010",
                specialProperty = "Ancient alpha essence",
                glowEffect = true,
                particleEffect = "wolf_aura",
                description = "The fang of an ancient alpha wolf" -- Override
            }
        },
        
        spawnZones = {"meadow", "forest"},
    },
    
    {
        id = "gorilla_hand",
        name = "Gorilla Hand",
        description = "The mighty hand of a silverback gorilla",
        itemType = "Form",
        
        formType = "gorilla",
        baseModel = "rbxassetid://TODO_GORILLA_MODEL",
        baseSize = Vector3.new(4, 3, 4),
        
        baseStats = {
            attack = 25,
            health = 150,
            defense = 15,
        },
        
        baseStackSize = 5,
        basePrice = 20,
        
        variants = {
            common = {
                icon = "rbxassetid://TODO_GORILLA_C",
                specialProperty = "Raw strength",
            },
            uncommon = {
                icon = "rbxassetid://TODO_GORILLA_U",
                specialProperty = "Controlled power",
            },
            rare = {
                icon = "rbxassetid://TODO_GORILLA_R",
                specialProperty = "Primal might",
                glowEffect = true,
            },
            legendary = {
                icon = "rbxassetid://TODO_GORILLA_L",
                specialProperty = "King Kong fury",
                glowEffect = true,
                particleEffect = "gorilla_roar",
                description = "The skull of a legendary mountain king"
            }
        },
        
        spawnZones = {"forest", "mountain"},
    },
    
    {
        id = "hawk_talon",
        name = "Hawk Talon",
        description = "A sharp talon from a predatory hawk",
        itemType = "Form",
        
        formType = "hawk",
        baseModel = "rbxassetid://TODO_HAWK_MODEL",
        baseSize = Vector3.new(2, 2, 3),
        
        baseStats = {
            speed = 30,
            agility = 25,
            sight = 20,
        },
        
        baseStackSize = 15,
        basePrice = 15,
        
        variants = {
            common = {
                icon = "rbxassetid://TODO_HAWK_C",
                specialProperty = "Swift hunter",
            },
            uncommon = {
                icon = "rbxassetid://TODO_HAWK_U",
                specialProperty = "Aerial predator",
            },
            rare = {
                icon = "rbxassetid://TODO_HAWK_R",
                specialProperty = "Sky master",
                glowEffect = true,
            },
            legendary = {
                icon = "rbxassetid://TODO_HAWK_L",
                specialProperty = "Celestial raptor",
                glowEffect = true,
                particleEffect = "feather_trail",
                description = "The talon of a mythical sky guardian"
            }
        },
        
        spawnZones = {"meadow", "mountain", "sky_island"},
    },
    
    -- TODO: Add more forms (Lizard, Bear, Snake, Tiger, etc.)
}

-- ================================
-- SUBSTANCE ITEM TEMPLATES
-- ================================

Items.substanceTemplates = {
    {
        id = "dust_pebble",
        name = "Dust Pebble",
        description = "A dusty pebble of earth",
        itemType = "Substance",
        
        -- Substance-specific data
        substanceType = "dust",
        material = Enum.Material.Sand,
        baseColor = Color3.fromRGB(180, 150, 120),
        texture = "rbxassetid://TODO_DUST_TEXTURE",
        particleEffect = nil,
        
        -- Base stat modifiers (multiplied by rarity)
        baseStatModifiers = {
            defense = 1,
            weight = -5, -- Lighter = faster
        },
        
        -- Economy
        baseStackSize = 99,
        basePrice = 1,
        
        -- Rarity variants
        variants = {
            common = {
                icon = "rbxassetid://95697693509834",
                specialProperty = nil, -- No attribute for common
            },
            uncommon = {
                icon = "rbxassetid://TODO_DUST_U",
                specialProperty = "Wind Affinity", -- Primary attribute
            },
            rare = {
                icon = "rbxassetid://TODO_DUST_R",
                specialProperty = "Sandstorm", -- Primary attribute
                glowEffect = true,
            },
            legendary = {
                icon = "rbxassetid://TODO_DUST_L",
                specialProperty = "Desert King", -- Primary attribute
                glowEffect = true,
                particleEffect = "dust_swirl",
                description = "Ancient earth essence condensed into form"
            }
        },
        
        spawnZones = {"meadow", "desert"},
    },
    
    {
        id = "clay_chunk",
        name = "Clay Chunk",
        description = "A chunk of moldable clay",
        itemType = "Substance",
        
        substanceType = "clay",
        material = Enum.Material.Slate,
        baseColor = Color3.fromRGB(150, 120, 90),
        texture = "rbxassetid://TODO_CLAY_TEXTURE",
        particleEffect = nil,
        
        baseStatModifiers = {
            defense = 2,
            health = 10,
        },
        
        baseStackSize = 99,
        basePrice = 2,
        
        variants = {
            common = {
                icon = "rbxassetid://87706048713897",
                specialProperty = nil,
            },
            uncommon = {
                icon = "rbxassetid://TODO_CLAY_U",
                specialProperty = "Earth Shield",
            },
            rare = {
                icon = "rbxassetid://TODO_CLAY_R",
                specialProperty = "Stone Skin",
                glowEffect = true,
            },
            legendary = {
                icon = "rbxassetid://TODO_CLAY_L",
                specialProperty = "Golem Form",
                glowEffect = true,
                particleEffect = "clay_hardening",
                description = "Primordial clay from the world's first mountain"
            }
        },
        
        spawnZones = {"meadow", "swamp"},
    },
    
    {
        id = "iron_fragment",
        name = "Iron Fragment",
        description = "A jagged piece of raw iron ore",
        itemType = "Substance",
        
        substanceType = "iron",
        material = Enum.Material.Metal,
        baseColor = Color3.fromRGB(120, 120, 130),
        texture = "rbxassetid://TODO_IRON_TEXTURE",
        particleEffect = nil,
        
        baseStatModifiers = {
            defense = 15,
            attack = 5,
            weight = 10, -- Heavier = slower
        },
        
        baseStackSize = 50,
        basePrice = 5,
        
        variants = {
            common = {
                icon = "rbxassetid://TODO_IRON_C",
                specialProperty = nil,
            },
            uncommon = {
                icon = "rbxassetid://TODO_IRON_U",
                specialProperty = "Metal Plating",
            },
            rare = {
                icon = "rbxassetid://TODO_IRON_R",
                specialProperty = "Iron Will",
                glowEffect = true,
            },
            legendary = {
                icon = "rbxassetid://TODO_IRON_L",
                specialProperty = "Adamantine Body",
                glowEffect = true,
                particleEffect = "metal_shine",
                description = "Meteoric iron from beyond the stars"
            }
        },
        
        spawnZones = {"mountain", "cave"},
    },
    
    {
        id = "beetle_carapace",
        name = "Beetle Carapace",
        description = "A shiny beetle shell segment",
        itemType = "Substance",
        
        substanceType = "beetle",
        material = Enum.Material.Glass,
        baseColor = Color3.fromRGB(50, 100, 80),
        texture = "rbxassetid://TODO_BEETLE_TEXTURE",
        particleEffect = nil,
        
        baseStatModifiers = {
            defense = 8,
            speed = 3,
        },
        
        baseStackSize = 30,
        basePrice = 8,
        
        variants = {
            common = {
                icon = "rbxassetid://TODO_BEETLE_C",
                specialProperty = nil,
            },
            uncommon = {
                icon = "rbxassetid://TODO_BEETLE_U",
                specialProperty = "Chitin Armor",
            },
            rare = {
                icon = "rbxassetid://109057061984432",
                specialProperty = "Hardened Shell",
                glowEffect = true,
            },
            legendary = {
                icon = "rbxassetid://80832768025430",
                specialProperty = "Jewel Aspect",
                glowEffect = true,
                particleEffect = "rainbow_sparkle",
                description = "A stunning jewel-like beetle carapace",
                baseColor = Color3.fromRGB(100, 200, 255), -- Override color
            }
        },
        
        spawnZones = {"forest", "swamp"},
    },
    
    -- TODO: Add more substances (Stone, Crystal, Lava, Ice, Shadow, Light, etc.)
}

-- ================================
-- SPAWN ZONE CONFIGURATION
-- ================================

Items.spawnZones = {
    meadow = {
        -- Templates automatically add all variants
        -- Just list the template IDs
    },
    forest = {
        -- Templates handle variant spawning
    },
    mountain = {
        -- No need to list all rarities
    },
    desert = {},
    swamp = {},
    cave = {},
    sky_island = {},
}

-- ================================
-- INTERNAL: GENERATED ITEMS CACHE
-- ================================

-- This will store the fully generated items (all variants)
Items._generatedForms = nil
Items._generatedSubstances = nil
Items._allItemsCache = nil

-- ================================
-- TEMPLATE PROCESSING FUNCTIONS
-- ================================

--[[
    Generate all item variants from templates
    Creates individual item entries for each rarity
]]
local function GenerateItemsFromTemplates(templates, itemType)
    local generatedItems = {}
    
    for _, template in ipairs(templates) do
        -- Generate an item for each rarity variant
        for rarity, variantData in pairs(template.variants) do
            local item = {
                -- Base data from template
                id = template.id .. "_" .. rarity, -- e.g., "wolf_tooth_common"
                templateId = template.id,
                name = template.name,
                description = variantData.description or template.description,
                itemType = template.itemType,
                rarity = rarity,
                
                -- Icon from variant
                icon = variantData.icon,
                
                -- Economy (with rarity multipliers)
                stackSize = math.floor(template.baseStackSize * (Items.rarityStackMultipliers[rarity] or 1)),
                sellPrice = math.floor(template.basePrice * (Items.rarityPriceMultipliers[rarity] or 1)),
                
                -- Visual effects
                glowEffect = variantData.glowEffect or false,
                particleEffect = variantData.particleEffect or nil,
                
                -- Special property (for attributes)
                specialProperty = variantData.specialProperty or nil,
            }
            
            -- Add type-specific data
            if itemType == "Form" then
                item.formType = template.formType
                item.baseModel = template.baseModel
                item.baseSize = template.baseSize
                
                -- Scale stats by rarity
                item.baseStats = {}
                for stat, value in pairs(template.baseStats) do
                    item.baseStats[stat] = math.floor(value * (Items.rarityStatMultipliers[rarity] or 1))
                end
                
            elseif itemType == "Substance" then
                item.substanceType = template.substanceType
                item.material = template.material
                item.baseColor = variantData.baseColor or template.baseColor
                item.texture = template.texture
                
                -- Scale stat modifiers by rarity
                item.statModifiers = {}
                for stat, value in pairs(template.baseStatModifiers or {}) do
                    item.statModifiers[stat] = math.floor(value * (Items.rarityStatMultipliers[rarity] or 1))
                end
            end
            
            table.insert(generatedItems, item)
        end
    end
    
    return generatedItems
end

--[[
    Initialize the items system
    Generates all variants from templates
]]
function Items.Init()
    print("📦 Initializing Items configuration...")
    
    -- Generate all form variants
    Items._generatedForms = GenerateItemsFromTemplates(Items.formTemplates, "Form")
    print("✅ Generated " .. #Items._generatedForms .. " form variants from " .. #Items.formTemplates .. " templates")
    
    -- Generate all substance variants
    Items._generatedSubstances = GenerateItemsFromTemplates(Items.substanceTemplates, "Substance")
    print("✅ Generated " .. #Items._generatedSubstances .. " substance variants from " .. #Items.substanceTemplates .. " templates")
    
    -- Build spawn zones with all variants
    Items._BuildSpawnZones()
    
    print("✅ Items configuration initialized")
end

--[[
    Build spawn zones by adding all variants from templates
]]
function Items._BuildSpawnZones()
    -- Process form templates
    for _, template in ipairs(Items.formTemplates) do
        if template.spawnZones then
            for _, zoneName in ipairs(template.spawnZones) do
                if not Items.spawnZones[zoneName] then
                    Items.spawnZones[zoneName] = {}
                end
                
                -- Add all rarity variants of this form to the zone
                for rarity, _ in pairs(template.variants) do
                    table.insert(Items.spawnZones[zoneName], template.id .. "_" .. rarity)
                end
            end
        end
    end
    
    -- Process substance templates
    for _, template in ipairs(Items.substanceTemplates) do
        if template.spawnZones then
            for _, zoneName in ipairs(template.spawnZones) do
                if not Items.spawnZones[zoneName] then
                    Items.spawnZones[zoneName] = {}
                end
                
                -- Add all rarity variants of this substance to the zone
                for rarity, _ in pairs(template.variants) do
                    table.insert(Items.spawnZones[zoneName], template.id .. "_" .. rarity)
                end
            end
        end
    end
end

-- ================================
-- HELPER FUNCTIONS
-- ================================

--[[
    Get all items as a flat list
]]
function Items.GetAllItems()
    if not Items._allItemsCache then
        Items._allItemsCache = {}
        
        -- Add all generated forms
        for _, item in ipairs(Items._generatedForms or {}) do
            table.insert(Items._allItemsCache, item)
        end
        
        -- Add all generated substances
        for _, item in ipairs(Items._generatedSubstances or {}) do
            table.insert(Items._allItemsCache, item)
        end
    end
    
    return Items._allItemsCache
end

--[[
    Get item configuration by ID
]]
function Items.GetItemById(itemId: string)
    if not itemId then return nil end
    
    -- Search forms
    for _, item in ipairs(Items._generatedForms or {}) do
        if item.id == itemId then
            return item
        end
    end
    
    -- Search substances
    for _, item in ipairs(Items._generatedSubstances or {}) do
        if item.id == itemId then
            return item
        end
    end
    
    return nil
end

--[[
    Get item template by ID (without rarity suffix)
]]
function Items.GetTemplateById(templateId: string)
    if not templateId then return nil end
    
    -- Search form templates
    for _, template in ipairs(Items.formTemplates) do
        if template.id == templateId then
            return template
        end
    end
    
    -- Search substance templates
    for _, template in ipairs(Items.substanceTemplates) do
        if template.id == templateId then
            return template
        end
    end
    
    return nil
end

--[[
    Get all variants of a specific template
]]
function Items.GetTemplateVariants(templateId: string)
    local variants = {}
    
    for _, item in ipairs(Items.GetAllItems()) do
        if item.templateId == templateId then
            table.insert(variants, item)
        end
    end
    
    return variants
end

--[[
    Get items by type
]]
function Items.GetItemsByType(itemType: string)
    if itemType == "Form" then
        return Items._generatedForms or {}
    elseif itemType == "Substance" then
        return Items._generatedSubstances or {}
    end
    return {}
end

--[[
    Get items by rarity
]]
function Items.GetItemsByRarity(rarity: string)
    local results = {}
    
    for _, item in ipairs(Items.GetAllItems()) do
        if item.rarity == rarity then
            table.insert(results, item)
        end
    end
    
    return results
end

--[[
    Get items for a specific zone
]]
function Items.GetItemsForZone(zoneName: string)
    return Items.spawnZones[zoneName] or {}
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

-- ================================
-- AUTO-INITIALIZATION
-- ================================

-- Initialize on require
Items.Init()

return Items
