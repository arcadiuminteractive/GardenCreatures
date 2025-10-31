--[[
    Items.lua - REFACTORED FOR SERVER-AUTHORITATIVE ARCHITECTURE
    Central configuration for all collectible items in Garden Creatures
    
    ✅ BEST PRACTICES IMPLEMENTED:
    1. Lazy initialization - only when explicitly called
    2. Server-side only generation - client receives via RemoteEvents
    3. Single source of truth on server
    4. Efficient caching system
    5. Proper module pattern with guards
    
    Features:
    - Template-based item generation
    - Rarity system (Common, Uncommon, Rare, Legendary)
    - Zone-based spawning configuration
    - Support for Forms, Substances, and Attributes
]]

local Items = {}

-- ================================
-- INITIALIZATION STATE
-- ================================
local _initialized = false
local _allItemsCache = nil
local _generatedForms = {}
local _generatedSubstances = {}

-- ================================
-- RARITY CONFIGURATION
-- ================================
Items.rarities = {
    Common = {
        color = Color3.fromRGB(100, 200, 100),
        weight = 50,
        multiplier = 1.0,
    },
    Uncommon = {
        color = Color3.fromRGB(100, 150, 255),
        weight = 30,
        multiplier = 1.5,
    },
    Rare = {
        color = Color3.fromRGB(128, 33, 117),
        weight = 15,
        multiplier = 2.0,
    },
    Legendary = {
        color = Color3.fromRGB(224, 26, 26),
        weight = 1,
        multiplier = 5.0,
    }
}

-- ================================
-- FORM TEMPLATES
-- ================================
Items.formTemplates = {
    {
    id = "wolf_form",
    name = "Wolf Jaw",
    description = "An old jawbone from a wild wolf long passed",
    itemType = "Form",
    formType = "Wolf",
    baseModel = "rbxassetid://1234567890", -- Creature model ID
    baseSize = Vector3.new(2, 2, 2),
    baseStats = {speed = 1.0, power = 1.0},
    baseStackSize = 1,
    basePrice = 50,
    spawnZones = {"meadow"},
    variants = {
        Common = {
            icon = "rbxassetid://96590138728105",
            glowEffect = false,
            particleEffect = nil,
            specialProperty = nil,
        },
        UnCommon = {
        icon = "rbxassetid://92170516959446",
        glowEffect = true,
        particleEffect = "rbxassetid://wolf_sparkle",
        specialProperty = "Lunar Howl",
        },
        Rare = {
            icon = "rbxassetid://104730292067575",
            glowEffect = true,
            particleEffect = "rbxassetid://wolf_sparkle",
            specialProperty = "Lunar Howl",
        },
        Legendary = {
            icon = "rbxassetid://139767131625010",
            glowEffect = true,
            particleEffect = "rbxassetid://legendary_aura",
            specialProperty = "Alpha Resonance",
        },
        },

    }
}
-- ================================
-- SUBSTANCE TEMPLATES
-- ================================
Items.substanceTemplates = {
    {
    id = "clay_chunk",
    name = "Clay Chunk",
    description = "A heavy chunk of clay",
    itemType = "Substance",
    substanceType = "Clay",
    material = Enum.Material.Glass,
    baseColor = Color3.fromRGB(150, 200, 255),
    texture = "rbxassetid://crystal_texture",
    baseStatModifiers = {durability = 1.5, magic = 2.0},
    baseStackSize = 10,
    basePrice = 80,
    spawnZones = {"meadow"},
    variants = {
        Common = {
            icon = "rbxassetid://87706048713897",
            glowEffect = false,
            baseColor = Color3.fromRGB(180, 220, 255),
        },
        Rare = {
            icon = "rbxassetid://icon_rare_crystal",
            glowEffect = true,
            particleEffect = "rbxassetid://crystal_sparkle",
            baseColor = Color3.fromRGB(200, 240, 255),
        },
        Legendary = {
            icon = "rbxassetid://icon_legendary_crystal",
            glowEffect = true,
            particleEffect = "rbxassetid://legendary_crystal_aura",
            baseColor = Color3.fromRGB(255, 255, 255),
            specialProperty = "Radiant Core",
        },
    }
}

}

-- ================================
-- SPAWN ZONE CONFIGURATION
-- ================================
Items.spawnZones = {}

-- ================================
-- INITIALIZATION FUNCTION
-- ================================

--[[
    Initialize the Items system - MUST be called by server on startup
    This function should ONLY be called once by the server
]]
function Items.Initialize()
    -- Guard against double initialization
    if _initialized then
        warn("⚠️ Items.Initialize() called multiple times - ignoring")
        return
    end
    
    local RunService = game:GetService("RunService")
    if not RunService:IsServer() then
        error("❌ Items.Initialize() can only be called on the server!")
        return
    end
    
    print("📦 Initializing Items configuration...")
    
    -- Generate all variants
    _generatedForms = GenerateItemsFromTemplates(Items.formTemplates, "Form")
    print("✅ Generated " .. #_generatedForms .. " form variants from " .. #Items.formTemplates .. " templates")
    
    _generatedSubstances = GenerateItemsFromTemplates(Items.substanceTemplates, "Substance")
    print("✅ Generated " .. #_generatedSubstances .. " substance variants from " .. #Items.substanceTemplates .. " templates")
    
    -- Build spawn zones
    BuildSpawnZones()
    
    _initialized = true
    print("✅ Items configuration initialized")
end

--[[
    Check if Items system is initialized
]]
function Items.IsInitialized()
    return _initialized
end

-- ================================
-- GENERATION FUNCTIONS (PRIVATE)
-- ================================

--[[
    Generate all item variants from templates
]]
function GenerateItemsFromTemplates(templates, category)
    local generated = {}
    
    for _, template in ipairs(templates) do
        for rarity, variantData in pairs(template.variants) do
            local rarityConfig = Items.rarities[rarity]
            if rarityConfig then
                local item = {
                    id = template.id .. "_" .. rarity,
                    baseId = template.id,
                    name = rarity .. " " .. template.name,
                    description = template.description,
                    category = category,
                    rarity = rarity,
                    rarityWeight = rarityConfig.weight,
                    rarityMultiplier = rarityConfig.multiplier,
                    color = rarityConfig.color,
                    model = template.model,
                    icon = template.icon,
                    stats = variantData,
                    stackable = true,
                    maxStack = 99,
                }
                
                table.insert(generated, item)
            end
        end
    end
    
    return generated
end

--[[
    Build spawn zones by adding all variants from templates
]]
function BuildSpawnZones()
    -- Clear existing zones
    Items.spawnZones = {}
    
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
    
    -- Debug: Print what was built
    print("📍 Built spawn zones:")
    for zoneName, itemIds in pairs(Items.spawnZones) do
        print("  -", zoneName, ":", #itemIds, "items")
    end
end

-- ================================
-- PUBLIC API FUNCTIONS
-- ================================

--[[
    Get all items as a flat list
    Client-safe: Returns cached data
]]
function Items.GetAllItems()
    if not _initialized then
        warn("⚠️ Items.GetAllItems() called before initialization")
        return {}
    end
    
    if not _allItemsCache then
        _allItemsCache = {}
        
        -- Add all generated forms
        for _, item in ipairs(_generatedForms) do
            table.insert(_allItemsCache, item)
        end
        
        -- Add all generated substances
        for _, item in ipairs(_generatedSubstances) do
            table.insert(_allItemsCache, item)
        end
    end
    
    return _allItemsCache
end

--[[
    Get item configuration by ID
    Client-safe: Returns cached data
]]
function Items.GetItemById(itemId: string)
    if not _initialized then
        warn("⚠️ Items.GetItemById() called before initialization")
        return nil
    end
    
    if not itemId then return nil end
    
    -- Search forms
    for _, item in ipairs(_generatedForms) do
        if item.id == itemId then
            return item
        end
    end
    
    -- Search substances
    for _, item in ipairs(_generatedSubstances) do
        if item.id == itemId then
            return item
        end
    end
    
    return nil
end

--[[
    Get item template by ID (without rarity suffix)
    Client-safe: Returns template data
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
    Client-safe: Returns generated variants
]]
function Items.GetTemplateVariants(templateId: string)
    if not _initialized then
        warn("⚠️ Items.GetTemplateVariants() called before initialization")
        return {}
    end
    
    local variants = {}
    
    -- Search in generated forms
    for _, item in ipairs(_generatedForms) do
        if item.baseId == templateId then
            table.insert(variants, item)
        end
    end
    
    -- Search in generated substances
    for _, item in ipairs(_generatedSubstances) do
        if item.baseId == templateId then
            table.insert(variants, item)
        end
    end
    
    return variants
end

--[[
    Get spawn zones configuration
    Server-only: Used for spawning logic
]]
function Items.GetSpawnZones()
    if not _initialized then
        warn("⚠️ Items.GetSpawnZones() called before initialization")
        return {}
    end
    
    return Items.spawnZones
end

--[[
    Get items for a specific zone
    Server-only: Used for spawning logic
]]
function Items.GetZoneItems(zoneName: string)
    if not _initialized then
        warn("⚠️ Items.GetZoneItems() called before initialization")
        return {}
    end
    
    return Items.spawnZones[zoneName:lower()] or {}
end

print("✅ Items module loaded (not initialized - call Items.Initialize() on server)")

return Items
