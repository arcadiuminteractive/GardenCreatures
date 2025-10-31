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

local RunService = game:GetService("RunService")

local Items = {}

-- ================================
-- INITIALIZATION STATE
-- ================================
local _initialized = false
local _allItemsCache = nil
local _generatedForms = {}
local _generatedSubstances = {}
local _itemsById = {}

local function resetCaches()
    _generatedForms = {}
    _generatedSubstances = {}
    _itemsById = {}
    _allItemsCache = nil
    Items.spawnZones = {}
end

-- ================================
-- RARITY CONFIGURATION
-- ================================
Items.rarities = {
    common = {
        color = Color3.fromRGB(100, 200, 100),
        weight = 50,
        multiplier = 1.0,
        displayName = "Common",
    },
    uncommon = {
        color = Color3.fromRGB(100, 150, 255),
        weight = 30,
        multiplier = 1.5,
        displayName = "Uncommon",
    },
    rare = {
        color = Color3.fromRGB(128, 33, 117),
        weight = 15,
        multiplier = 2.0,
        displayName = "Rare",
    },
    legendary = {
        color = Color3.fromRGB(224, 26, 26),
        weight = 1,
        multiplier = 5.0,
        displayName = "Legendary",
    }
}

local RARITY_ALIASES = {
    Common = "common",
    common = "common",
    Uncommon = "uncommon",
    UNCOMMON = "uncommon",
    uncommon = "uncommon",
    UnCommon = "uncommon",
    Rare = "rare",
    rare = "rare",
    Legendary = "legendary",
    legendary = "legendary",
}

local function normalizeRarity(rarity)
    if type(rarity) ~= "string" then
        return nil
    end

    return RARITY_ALIASES[rarity] or RARITY_ALIASES[string.lower(rarity)] or nil
end

local function cloneTable(tbl)
    local copy = {}
    if tbl then
        for key, value in pairs(tbl) do
            copy[key] = value
        end
    end
    return copy
end

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
        baseStats = { speed = 1.0, power = 1.0 },
        baseStackSize = 1,
        basePrice = 50,
        spawnZones = { "meadow" },
        variants = {
            Common = {
                icon = "rbxassetid://96590138728105",
                glowEffect = false,
                particleEffect = nil,
                specialProperty = nil,
            },
            Uncommon = {
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
    },
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
        baseStatModifiers = { durability = 1.5, magic = 2.0 },
        baseStackSize = 10,
        basePrice = 80,
        spawnZones = { "meadow" },
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
        },
    },
}

-- ================================
-- SPAWN ZONE CONFIGURATION
-- ================================
Items.spawnZones = {}

-- ================================
-- INITIALIZATION FUNCTION
-- ================================

--[[
    Initialize the Items system.
    The server should call this during startup so shared caches are warm,
    but clients can safely call the public API which lazily builds data
    on demand if initialization hasn't happened yet.
]]
local function generateItemsFromTemplates(templates, category)
    local generated = {}

    for _, template in ipairs(templates) do
        local baseStackSize = template.baseStackSize or 1

        for rarityKey, variantData in pairs(template.variants or {}) do
            local rarity = normalizeRarity(rarityKey)

            if rarity then
                local rarityConfig = Items.rarities[rarity]

                if rarityConfig then
                    local displayRarity = rarityConfig.displayName or rarity
                    local displayName = string.format("%s %s", displayRarity, template.name)
                    local icon = variantData.icon or template.icon or ""
                    local itemId = template.id .. "_" .. rarity

                    local item = {
                        id = itemId,
                        baseId = template.id,
                        baseName = template.name,
                        name = displayName,
                        description = template.description,
                        category = category,
                        rarity = rarity,
                        rarityDisplayName = displayRarity,
                        rarityWeight = rarityConfig.weight,
                        rarityMultiplier = rarityConfig.multiplier,
                        color = rarityConfig.color,
                        icon = icon,
                        template = template,
                        variant = cloneTable(variantData),
                        stackable = baseStackSize > 1,
                        maxStack = baseStackSize,
                        baseStackSize = baseStackSize,
                        basePrice = template.basePrice,
                        formType = template.formType,
                        substanceType = template.substanceType,
                        baseModel = template.baseModel,
                    }

                    table.insert(generated, item)
                    _itemsById[itemId] = item
                else
                    warn("⚠️ Missing rarity configuration for", rarityKey, "in template", template.id)
                end
            else
                warn("⚠️ Unknown rarity variant", rarityKey, "for template", template.id)
            end
        end
    end

    return generated
end

local function buildSpawnZones()
    local zoneSets = {}

    local function registerTemplate(template)
        if not template.spawnZones then
            return
        end

        for _, zoneName in ipairs(template.spawnZones) do
            local normalizedZone = string.lower(zoneName)
            zoneSets[normalizedZone] = zoneSets[normalizedZone] or {}

            for rarityKey in pairs(template.variants or {}) do
                local rarity = normalizeRarity(rarityKey)
                if rarity then
                    local itemId = template.id .. "_" .. rarity
                    if _itemsById[itemId] then
                        zoneSets[normalizedZone][itemId] = true
                    else
                        warn("⚠️ Spawn zone references missing item variant", itemId)
                    end
                end
            end
        end
    end

    for _, template in ipairs(Items.formTemplates) do
        registerTemplate(template)
    end

    for _, template in ipairs(Items.substanceTemplates) do
        registerTemplate(template)
    end

    Items.spawnZones = {}
    for zoneName, itemSet in pairs(zoneSets) do
        local zoneItems = {}
        for itemId in pairs(itemSet) do
            table.insert(zoneItems, itemId)
        end
        table.sort(zoneItems)
        Items.spawnZones[zoneName] = zoneItems
    end
end

local function ensureInitialized()
    if _initialized then
        return
    end

    resetCaches()

    _generatedForms = generateItemsFromTemplates(Items.formTemplates, "Form")
    _generatedSubstances = generateItemsFromTemplates(Items.substanceTemplates, "Substance")

    buildSpawnZones()

    _initialized = true

    if RunService:IsServer() then
        print(string.format("✅ Generated %d form variants from %d templates", #_generatedForms, #Items.formTemplates))
        print(string.format("✅ Generated %d substance variants from %d templates", #_generatedSubstances, #Items.substanceTemplates))
        print("✅ Items configuration initialized")
    end
end

function Items.Initialize()
    if _initialized then
        return
    end

    ensureInitialized()
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

-- ================================
-- PUBLIC API FUNCTIONS
-- ================================

--[[
    Get all items as a flat list
    Client-safe: Returns cached data
]]
function Items.GetAllItems()
    ensureInitialized()

    if not _allItemsCache then
        _allItemsCache = {}

        for _, item in ipairs(_generatedForms) do
            table.insert(_allItemsCache, item)
        end

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
    ensureInitialized()

    if not itemId then
        return nil
    end

    return _itemsById[itemId]
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
    ensureInitialized()

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
]]
function Items.GetSpawnZones()
    ensureInitialized()

    return Items.spawnZones
end

function Items.GetRarityInfo(rarity: string)
    local normalized = normalizeRarity(rarity)
    if not normalized then
        return nil
    end

    return Items.rarities[normalized]
end

--[[
    Get items for a specific zone
]]
function Items.GetZoneItems(zoneName: string)
    ensureInitialized()

    if type(zoneName) ~= "string" then
        return {}
    end

    return Items.spawnZones[zoneName:lower()] or {}
end

print("✅ Items module loaded (not initialized - call Items.Initialize() on server)")

return Items
