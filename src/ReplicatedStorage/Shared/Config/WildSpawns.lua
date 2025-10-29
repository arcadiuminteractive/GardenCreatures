--[[
    WildSpawns.lua
    Configuration for wild creature spawning system
]]

local WildSpawns = {
    -- Player-associated spawns (common versions of player creatures)
    playerAssociated = {
        enabled = true,
        spawnInterval = 60,              -- Check every 60 seconds
        spawnChance = 0.3,               -- 30% chance per interval
        maxPerServer = 15,               -- Maximum wild creatures from players
        rarityOverride = "Common",       -- Always spawn common version
        
        -- Spawn locations
        spawnZones = {
            "Meadow",
            "Forest",
            "Lakeside",
            "Mountain",
            "Cave",
        },
        
        -- Despawn rules
        despawnOnOwnerLeave = true,      -- Despawn when creature's owner leaves
        despawnDistance = 200,           -- Despawn if no players within 200 studs
        maxLifetime = 600,               -- Despawn after 10 minutes if not tamed
    },
    
    -- Rare world spawns (not from player inventories)
    rareWorldSpawns = {
        enabled = true,
        spawnInterval = 300,             -- Check every 5 minutes
        spawnChance = 0.001,             -- 0.1% chance per interval
        maxPerServer = 3,                -- Maximum rare world spawns
        
        -- Possible rare spawn creatures
        possibleCreatures = {
            {
                id = "mystic_seedling",
                name = "Mystic Seedling",
                rarity = "Epic",
                spawnWeight = 60,        -- More common rare spawn
                spawnZones = {"Forest", "Mystical Grove"},
            },
            {
                id = "void_shadow",
                name = "Void Shadow",
                rarity = "Epic",
                spawnWeight = 30,
                spawnZones = {"Cave", "Shadow Realm"},
            },
            {
                id = "prism_fairy",
                name = "Prism Fairy",
                rarity = "Epic",
                spawnWeight = 40,
                spawnZones = {"Crystal Cavern", "Mountain"},
            },
            {
                id = "elder_wisp",
                name = "Elder Wisp",
                rarity = "Legendary",
                spawnWeight = 5,         -- Very rare
                spawnZones = {"Ancient Forest"},
                uniqueMutation = true,   -- Has special trait
            },
            {
                id = "star_guardian",
                name = "Star Guardian",
                rarity = "Legendary",
                spawnWeight = 3,
                spawnZones = {"Celestial Peak"},
                uniqueMutation = true,
                onlySpawnsAtNight = true,
            },
        },
        
        -- Despawn rules
        despawnOnLeave = false,          -- Persist even if players leave
        persistUntilTamed = true,        -- Stay until someone tames them
        announceSpawn = true,            -- Notify server when rare spawn appears
    },
    
    -- Spawn mechanics
    spawnMechanics = {
        -- Rarity conversion for player creatures
        rarityConversion = {
            Common = "Common",
            Uncommon = "Common",
            Rare = "Common",
            Epic = "Common",
            Legendary = "Common",
        },
        
        -- Spawn positioning
        spawnRadius = 20,                -- Radius around spawn point
        minPlayerDistance = 50,          -- Don't spawn within 50 studs of players
        maxSpawnHeight = 10,             -- Max Y offset for spawn
        
        -- Taming mechanics
        tamingDifficulty = {
            Common = 0.8,                -- 80% tame chance
            Uncommon = 0.7,              -- 70% tame chance
            Rare = 0.5,                  -- 50% tame chance
            Epic = 0.3,                  -- 30% tame chance
            Legendary = 0.1,             -- 10% tame chance
        },
        
        tamingCooldown = 5,              -- 5 seconds between tame attempts
        tamingXP = {
            Common = 20,
            Uncommon = 40,
            Rare = 80,
            Epic = 150,
            Legendary = 300,
        },
    },
    
    -- Spawn zones configuration
    zones = {
        {
            name = "Meadow",
            position = Vector3.new(0, 0, 0),     -- Replace with actual position
            radius = 100,
            spawnRate = 1.0,                     -- Normal spawn rate
            allowedCreatureTypes = {"nature", "common"},
        },
        {
            name = "Forest",
            position = Vector3.new(200, 0, 0),
            radius = 150,
            spawnRate = 1.2,                     -- 20% more spawns
            allowedCreatureTypes = {"nature", "shadow"},
        },
        {
            name = "Volcanic",
            position = Vector3.new(400, 0, 0),
            radius = 80,
            spawnRate = 0.8,                     -- 20% fewer spawns
            allowedCreatureTypes = {"fire"},
            requiresGamepass = false,
        },
        {
            name = "Crystal Cavern",
            position = Vector3.new(0, 0, 200),
            radius = 100,
            spawnRate = 0.5,                     -- Rare spawns
            allowedCreatureTypes = {"crystal"},
            rareSpawnBonus = 2.0,                -- 2x rare spawn chance here
        },
        {
            name = "Celestial Peak",
            position = Vector3.new(0, 100, 0),
            radius = 60,
            spawnRate = 0.3,                     -- Very rare
            allowedCreatureTypes = {"celestial"},
            rareSpawnBonus = 5.0,                -- 5x rare spawn chance
            requiresLevel = 25,                  -- Must be level 25 to access
        },
    },
    
    -- Visual effects for spawns
    spawnEffects = {
        playerAssociated = {
            particle = "sparkle",
            sound = "rbxassetid://0",            -- Spawn sound
            duration = 2,                        -- Effect duration in seconds
        },
        rareWorld = {
            particle = "legendary_spawn",
            sound = "rbxassetid://0",            -- Epic spawn sound
            duration = 5,
            lightEffect = true,
            announceMessage = "%s has appeared in %s!", -- Creature name, zone name
        },
    },
    
    -- Seasonal events (can modify spawn rates/types)
    seasonalModifiers = {
        enabled = false,
        -- Add seasonal events here later
        -- Example: Halloween, Summer Festival, etc.
    },
}

return WildSpawns
