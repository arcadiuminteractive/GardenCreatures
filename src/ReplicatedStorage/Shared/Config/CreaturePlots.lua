--[[
    CreaturePlots.lua
    Configuration and logic for creature plot system
    
    System Overview:
    - Players have creature plots (similar to garden plots)
    - Each plot has 4 slots: Form, Substance, Primary Attribute, Secondary Attribute
    - Players place items into these slots
    - After a growth period, a unique creature is generated
    - Creature stats/appearance determined by combined items
]]

local CreaturePlots = {
    -- Plot configuration
    defaultMaxPlots = 5,
    plotUnlockCost = 100, -- Coins per additional plot
    
    -- Growth timing
    growthTime = {
        common = 120,      -- 2 minutes
        uncommon = 180,    -- 3 minutes
        rare = 300,        -- 5 minutes
        legendary = 600,   -- 10 minutes
    },
    
    -- Plot types (can be expanded later)
    plotTypes = {
        {
            id = "basic_plot",
            name = "Basic Creature Plot",
            description = "A standard plot for growing creatures",
            growthMultiplier = 1.0,
            coinPrice = 0, -- First plot is free
            gemPrice = 0,
        },
        {
            id = "premium_plot",
            name = "Premium Creature Plot",
            description = "Grows creatures 25% faster",
            growthMultiplier = 0.75, -- 25% faster
            coinPrice = nil,
            gemPrice = 100,
        },
        {
            id = "mega_plot",
            name = "Mega Creature Plot",
            description = "Grows creatures 50% faster with bonus stats",
            growthMultiplier = 0.5, -- 50% faster
            statBonus = 1.1, -- 10% stat boost
            coinPrice = nil,
            gemPrice = 250,
        },
    },
    
    -- Slot definitions
    slotTypes = {
        Form = {
            name = "Form",
            description = "Determines the creature's body type",
            icon = "rbxassetid://TODO_FORM_ICON",
            required = true,
        },
        Substance = {
            name = "Substance",
            description = "Determines the creature's material and appearance",
            icon = "rbxassetid://TODO_SUBSTANCE_ICON",
            required = true,
        },
        PrimaryAttribute = {
            name = "Primary Attribute",
            description = "Determines the creature's main ability",
            icon = "rbxassetid://TODO_PRIMARY_ICON",
            required = false,
        },
        SecondaryAttribute = {
            name = "Secondary Attribute",
            description = "Determines the creature's secondary ability",
            icon = "rbxassetid://TODO_SECONDARY_ICON",
            required = false,
        },
    },
    
    -- Naming rules
    namingRules = {
        pattern = "{Substance} {Form}",
        -- Example: "Mud Wolf", "Iron Gorilla", "Beetle Hawk"
    },
}

-- ================================
-- CREATURE GENERATION LOGIC
-- ================================

--[[
    Generate a creature from a plot's items
    @param plotData - Table containing:
        - formItemId: string
        - substanceItemId: string
        - primaryAttributeItemId: string (optional)
        - secondaryAttributeItemId: string (optional)
    @return creatureData - Generated creature configuration
]]
function CreaturePlots.GenerateCreature(plotData: {[string]: string})
    local Items = require(game.ReplicatedStorage.Shared.Config.Items)
    
    -- Get item configs
    local formItem = Items.GetItemById(plotData.formItemId)
    local substanceItem = Items.GetItemById(plotData.substanceItemId)
    local primaryItem = plotData.primaryAttributeItemId and Items.GetItemById(plotData.primaryAttributeItemId)
    local secondaryItem = plotData.secondaryAttributeItemId and Items.GetItemById(plotData.secondaryAttributeItemId)
    
    if not formItem or not substanceItem then
        warn("❌ Cannot generate creature: missing required items")
        return nil
    end
    
    -- Calculate combined rarity
    local itemIds = {plotData.formItemId, plotData.substanceItemId}
    if plotData.primaryAttributeItemId then
        table.insert(itemIds, plotData.primaryAttributeItemId)
    end
    if plotData.secondaryAttributeItemId then
        table.insert(itemIds, plotData.secondaryAttributeItemId)
    end
    
    local rarity = Items.CalculateAverageRarity(itemIds)
    
    -- Generate creature name
    local creatureName = CreaturePlots.GenerateCreatureName(formItem, substanceItem)
    
    -- Calculate stats
    local stats = CreaturePlots.CalculateStats(formItem, substanceItem, primaryItem, secondaryItem)
    
    -- Calculate appearance
    local appearance = CreaturePlots.CalculateAppearance(formItem, substanceItem, rarity)
    
    -- Compile creature data
    local creatureData = {
        -- Identity
        name = creatureName,
        displayName = creatureName,
        rarity = rarity,
        
        -- Components (for tracking/debugging)
        formId = plotData.formItemId,
        substanceId = plotData.substanceItemId,
        primaryAttributeId = plotData.primaryAttributeItemId,
        secondaryAttributeId = plotData.secondaryAttributeItemId,
        
        -- Stats
        stats = stats,
        
        -- Appearance
        appearance = appearance,
        
        -- Metadata
        createdTimestamp = os.time(),
        instanceId = CreaturePlots.GenerateInstanceId(),
    }
    
    return creatureData
end

--[[
    Generate creature name from form and substance
]]
function CreaturePlots.GenerateCreatureName(formItem, substanceItem): string
    -- Pattern: "{Substance} {Form}"
    local substanceName = substanceItem.substanceType or "Unknown"
    local formName = formItem.formType or "Creature"
    
    -- Capitalize first letter
    substanceName = substanceName:sub(1,1):upper() .. substanceName:sub(2)
    formName = formName:sub(1,1):upper() .. formName:sub(2)
    
    return substanceName .. " " .. formName
end

--[[
    Calculate creature stats from all items
]]
function CreaturePlots.CalculateStats(formItem, substanceItem, primaryItem, secondaryItem)
    local stats = {
        -- Base stats from form
        speed = formItem.baseStats.speed or 16,
        health = formItem.baseStats.health or 100,
        
        -- Secondary stats
        defense = 0,
        attack = 0,
        regeneration = 0,
        sight = 0,
        stealth = 0,
        detection = 0,
        luck = 0,
        weight = 0,
    }
    
    -- Apply substance modifiers
    if substanceItem.statModifiers then
        for stat, value in pairs(substanceItem.statModifiers) do
            stats[stat] = (stats[stat] or 0) + value
        end
    end
    
    -- Apply primary attribute modifiers
    if primaryItem and primaryItem.statModifiers then
        for stat, value in pairs(primaryItem.statModifiers) do
            stats[stat] = (stats[stat] or 0) + value
        end
    end
    
    -- Apply secondary attribute modifiers
    if secondaryItem and secondaryItem.statModifiers then
        for stat, value in pairs(secondaryItem.statModifiers) do
            stats[stat] = (stats[stat] or 0) + value
        end
    end
    
    -- Apply weight to speed (negative weight = faster, positive = slower)
    if stats.weight ~= 0 then
        stats.speed = stats.speed - (stats.weight * 0.5)
        stats.speed = math.max(stats.speed, 5) -- Minimum speed
    end
    
    -- Ensure all stats are positive
    for stat, value in pairs(stats) do
        if type(value) == "number" then
            stats[stat] = math.max(value, 0)
        end
    end
    
    return stats
end

--[[
    Calculate creature appearance from form, substance, and rarity
]]
function CreaturePlots.CalculateAppearance(formItem, substanceItem, rarity)
    local Items = require(game.ReplicatedStorage.Shared.Config.Items)
    
    local appearance = {
        -- Model
        modelId = formItem.baseModel,
        baseSize = formItem.baseSize,
        
        -- Material & Color
        material = substanceItem.material,
        baseColor = substanceItem.baseColor,
        texture = substanceItem.texture,
        
        -- Effects
        particleEffect = substanceItem.particleEffect,
        glowEffect = false,
        auraEffect = false,
        
        -- Rarity scaling
        sizeMultiplier = Items.rarityScales[rarity] or 1.0,
    }
    
    -- Apply rarity-based effects
    if rarity == "rare" then
        appearance.glowEffect = true
    elseif rarity == "legendary" then
        appearance.glowEffect = true
        appearance.auraEffect = true
    end
    
    return appearance
end

--[[
    Generate a unique instance ID for a creature
]]
function CreaturePlots.GenerateInstanceId(): string
    return "creature_" .. tostring(tick()) .. "_" .. tostring(math.random(1000, 9999))
end

--[[
    Calculate growth time based on rarity and plot type
]]
function CreaturePlots.CalculateGrowthTime(rarity: string, plotType: string): number
    local baseTime = CreaturePlots.growthTime[rarity] or 120
    
    -- Apply plot multiplier if available
    for _, plotConfig in ipairs(CreaturePlots.plotTypes) do
        if plotConfig.id == plotType then
            return baseTime * (plotConfig.growthMultiplier or 1.0)
        end
    end
    
    return baseTime
end

--[[
    Validate plot data (check if all required slots are filled)
]]
function CreaturePlots.ValidatePlotData(plotData): (boolean, string?)
    if not plotData.formItemId then
        return false, "Form slot is required"
    end
    
    if not plotData.substanceItemId then
        return false, "Substance slot is required"
    end
    
    -- Verify items exist
    local Items = require(game.ReplicatedStorage.Shared.Config.Items)
    
    if not Items.GetItemById(plotData.formItemId) then
        return false, "Invalid form item"
    end
    
    if not Items.GetItemById(plotData.substanceItemId) then
        return false, "Invalid substance item"
    end
    
    -- Optional attributes don't need validation
    
    return true
end

--[[
    Get plot type configuration
]]
function CreaturePlots.GetPlotType(plotTypeId: string)
    for _, plotType in ipairs(CreaturePlots.plotTypes) do
        if plotType.id == plotTypeId then
            return plotType
        end
    end
    return nil
end

return CreaturePlots
