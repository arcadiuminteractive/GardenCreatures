--[[
    Economy.lua
    All economy settings, shop items, and monetization configuration
]]

local Economy = {
    -- Currency settings
    currencies = {
        coins = {
            name = "Coins",
            icon = "rbxassetid://0",
            startingAmount = 100,
        },
        gems = {
            name = "Gems",
            icon = "rbxassetid://0",
            startingAmount = 0,
            premium = true, -- Purchased with Robux
        },
    },
    
    -- Gem packages (Developer Products)
    gemPackages = {
        {
            id = "gems_100",
            name = "Small Gem Pack",
            gems = 100,
            price = 99,          -- Robux
            productId = 0,       -- Replace with actual product ID
            bonus = 0,           -- No bonus gems
        },
        {
            id = "gems_500",
            name = "Medium Gem Pack",
            gems = 500,
            price = 449,
            productId = 0,
            bonus = 50,          -- +50 bonus gems
        },
        {
            id = "gems_1000",
            name = "Large Gem Pack",
            gems = 1000,
            price = 849,
            productId = 0,
            bonus = 150,         -- +150 bonus gems
        },
        {
            id = "gems_5000",
            name = "Mega Gem Pack",
            gems = 5000,
            price = 3999,
            productId = 0,
            bonus = 1000,        -- +1000 bonus gems
            bestValue = true,
        },
    },
    
    -- Gamepasses
    gamepasses = {
        {
            id = "dual_creature_follow",
            name = "Dual Creature Follow",
            description = "Have 2 creatures following you at once!",
            price = 299,
            gamepassId = 0,      -- Replace with actual gamepass ID
            benefits = {
                "Follow with 2 creatures simultaneously",
                "Stack creature abilities",
                "Strategic gameplay advantage",
            },
        },
        {
            id = "portable_creature_pod",
            name = "Portable Creature Pod",
            description = "Swap creatures anywhere, anytime!",
            price = 199,
            gamepassId = 0,
            benefits = {
                "Swap creatures anywhere in the world",
                "No need to return to home base",
                "Adapt to any situation instantly",
            },
        },
        {
            id = "infinite_garden_plots",
            name = "Infinite Garden Plots",
            description = "Unlimited garden expansion!",
            price = 499,
            gamepassId = 0,
            benefits = {
                "Unlimited garden plots",
                "Massive farming potential",
                "Never run out of space",
            },
        },
        {
            id = "auto_harvest",
            name = "Auto-Harvest",
            description = "Automatically harvest mature plants!",
            price = 399,
            gamepassId = 0,
            benefits = {
                "Plants auto-harvest when mature",
                "Never miss a harvest",
                "Efficient farming",
            },
        },
        {
            id = "vip",
            name = "VIP Bundle",
            description = "The ultimate Garden Creatures experience!",
            price = 799,
            gamepassId = 0,
            benefits = {
                "+3 creature storage slots",
                "+1 creature follow slot",
                "2x XP gain for creatures",
                "1.5x plant growth speed",
                "Exclusive VIP badge",
                "Access to VIP garden area",
                "Reduced trading tax (4% instead of 8%)",
                "Monthly gem bonus (100 gems)",
            },
            recommended = true,
        },
    },
    
    -- Developer Products (consumables)
    developerProducts = {
        {
            id = "xp_boost_1h",
            name = "XP Boost (1 Hour)",
            description = "2x XP gain for 1 hour",
            price = 49,          -- Robux
            productId = 0,
            duration = 3600,     -- seconds
        },
        {
            id = "growth_boost_1h",
            name = "Growth Boost (1 Hour)",
            description = "2x plant growth speed for 1 hour",
            price = 59,
            productId = 0,
            duration = 3600,
        },
        {
            id = "mutation_boost_1h",
            name = "Mutation Boost (1 Hour)",
            description = "+50% mutation chance for 1 hour",
            price = 79,
            productId = 0,
            duration = 3600,
        },
    },
    
    -- Shop items
    shop = {
        -- Garden Plots
        gardenPlots = {
            {
                id = "basic_plot",
                name = "Basic Plot",
                description = "A simple garden plot",
                coinPrice = 100,
                gemPrice = 25,
                maxPerPlayer = nil, -- Unlimited (unless infinite plots gamepass)
            },
            {
                id = "premium_plot",
                name = "Premium Plot",
                description = "1.25x growth speed",
                coinPrice = nil,     -- Gems only
                gemPrice = 100,
                maxPerPlayer = 10,
                growthMultiplier = 1.25,
            },
            {
                id = "mega_plot",
                name = "Mega Plot",
                description = "2x2 size, 1.5x growth speed",
                coinPrice = nil,
                gemPrice = 250,
                maxPerPlayer = 5,
                size = {2, 2},
                growthMultiplier = 1.5,
            },
        },
        
        -- Storage Expansions
        storage = {
            {
                id = "creature_slot",
                name = "Creature Storage Slot",
                description = "Store one more creature",
                coinPrice = nil,     -- Gems only
                gemPrice = 50,
                maxPurchases = 45,   -- Can buy up to max storage (50 total - 5 free)
            },
            {
                id = "inventory_expansion_25",
                name = "Inventory Expansion (25 slots)",
                description = "Add 25 item slots to your inventory",
                coinPrice = 1000,
                gemPrice = 100,
            },
        },
        
        -- Boosters
        boosters = {
            {
                id = "fertilizer",
                name = "Fertilizer",
                description = "1.25x growth speed for one plant",
                coinPrice = 50,
                gemPrice = 10,
                consumable = true,
                stackSize = 99,
            },
            {
                id = "rare_seed_charm",
                name = "Rare Seed Charm",
                description = "+10% rare seed drop for 30 minutes",
                coinPrice = 200,
                gemPrice = 25,
                consumable = true,
                duration = 1800,     -- 30 minutes
            },
            {
                id = "instant_harvest",
                name = "Instant Harvest",
                description = "Instantly mature one plant",
                coinPrice = nil,     -- Gems only
                gemPrice = 50,
                consumable = true,
                stackSize = 10,
            },
        },
        
        -- Cosmetics
        cosmetics = {
            {
                id = "garden_fountain",
                name = "Garden Fountain",
                description = "Decorative fountain for your garden",
                coinPrice = 5000,
                gemPrice = 500,
                category = "decoration",
            },
            {
                id = "glowing_lantern",
                name = "Glowing Lantern",
                description = "Magical light for your garden",
                coinPrice = 1000,
                gemPrice = 100,
                category = "decoration",
            },
            {
                id = "pet_hat_wizard",
                name = "Wizard Hat",
                description = "Dress your creature as a wizard!",
                coinPrice = nil,
                gemPrice = 150,
                category = "creature_cosmetic",
            },
        },
        
        -- Recipe Unlocks
        recipeUnlocks = {
            -- Prices defined in Recipes.lua
            -- This section for quick access shop items
        },
    },
    
    -- Trading settings
    trading = {
        taxRate = 0.08,          -- 8% tax on trades
        vipTaxRate = 0.04,       -- 4% tax for VIP
        tradeCooldown = 60,      -- 60 seconds between trades
        
        -- What can be traded
        tradeable = {
            coins = true,
            gems = false,        -- Cannot trade gems (Roblox TOS)
            creatures = true,
            items = true,
            plantMatter = true,
            craftingMaterials = true,
            cosmetics = false,   -- Cosmetics cannot be traded
        },
        
        -- Trade value limits (anti-scam)
        warningThreshold = 1000, -- Warn if trade imbalance > 1000 coins value
        maxTradeValue = 50000,   -- Max total value per trade
    },
    
    -- Earning rates
    earningRates = {
        seedCollect = 2,         -- Coins per seed collected
        plantHarvest = {
            Common = 5,
            Uncommon = 15,
            Rare = 50,
            Epic = 150,
            Legendary = 500,
        },
        creatureCraft = {
            Common = 10,
            Uncommon = 25,
            Rare = 75,
            Epic = 200,
            Legendary = 1000,
        },
        wildCreatureTame = 50,   -- Coins for taming wild creature
        tradeCompletion = 10,    -- Coins for completing trade
        dailyLogin = 100,        -- Free coins for daily login
        vipDailyBonus = 100,     -- Extra gems for VIP daily login
    },
    
    -- Coin sinks (ways to spend coins)
    coinSinks = {
        recipeUnlocks = true,
        gardenPlots = true,
        tradingTax = true,
        shopItems = true,
    },
}

return Economy
