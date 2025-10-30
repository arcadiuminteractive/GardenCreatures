--[[
    AdminCommands.lua
    Provides admin commands for managing player data
    
    Commands:
    - /reset [UserId] - Reset all player data
    - /resetinv [UserId] - Reset only inventory
    - /resetme - Reset your own data
    - /give [UserId] [itemId] [amount] - Give item to player
    - /coins [UserId] [amount] - Set player coins
    - /gems [UserId] [amount] - Set player gems
    
    Setup:
    1. Place this file in ServerScriptService
    2. Add your UserId to the ADMINS table
    3. Require and Init() in Server.server.lua
]]

local AdminCommands = {}

-- Services
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Module references
local DataManager = require(ServerScriptService.Data.DataManager)

-- ============================
-- CONFIGURATION
-- ============================

-- 👑 Add your UserId here to grant admin access
local ADMINS = {
    9753182321,
    -- Add admin UserIds here:
    -- 123456789,  -- Your UserId
    -- 987654321,  -- Friend's UserId
}

-- Admin notification event
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
local AdminNotification = nil

if RemoteEvents then
    AdminNotification = RemoteEvents:FindFirstChild("AdminNotification")
    if not AdminNotification then
        AdminNotification = Instance.new("RemoteEvent")
        AdminNotification.Name = "AdminNotification"
        AdminNotification.Parent = RemoteEvents
    end
end

-- ============================
-- HELPER FUNCTIONS
-- ============================

local function isAdmin(player: Player): boolean
    return table.find(ADMINS, player.UserId) ~= nil
end

local function notifyAdmin(player: Player, message: string, success: boolean)
    print((success and "✅" or "❌"), message)
    
    if AdminNotification then
        AdminNotification:FireClient(player, {
            message = message,
            success = success
        })
    end
end

local function findPlayerByUserId(userId: number): Player?
    return Players:GetPlayerByUserId(userId)
end

-- ============================
-- ADMIN COMMANDS
-- ============================

--[[
    Reset all player data to defaults
]]
function AdminCommands.ResetPlayer(adminPlayer: Player, targetUserId: number)
    if not isAdmin(adminPlayer) then
        warn("⛔ Unauthorized reset attempt by:", adminPlayer.Name)
        return false, "Not authorized"
    end
    
    local targetPlayer = findPlayerByUserId(targetUserId)
    if not targetPlayer then
        notifyAdmin(adminPlayer, "Player not in game (UserId: " .. targetUserId .. ")", false)
        return false, "Player not in game"
    end
    
    local profile = DataManager.GetProfile(targetPlayer)
    if not profile then
        notifyAdmin(adminPlayer, "Profile not loaded for " .. targetPlayer.Name, false)
        return false, "Profile not loaded"
    end
    
    -- Reset to default data
    local defaultData = DataManager.GetDefaultData()
    for key, value in pairs(defaultData) do
        if type(value) == "table" then
            profile.Data[key] = {}
            for k, v in pairs(value) do
                profile.Data[key][k] = v
            end
        else
            profile.Data[key] = value
        end
    end
    
    -- Save immediately
    DataManager.SavePlayer(targetPlayer)
    
    -- Kick player to reload with fresh data
    targetPlayer:Kick("Your data has been reset by an admin. Please rejoin!")
    
    local message = "Reset all data for " .. targetPlayer.Name .. " (UserId: " .. targetUserId .. ")"
    notifyAdmin(adminPlayer, message, true)
    return true, message
end

--[[
    Reset only player inventory
]]
function AdminCommands.ResetInventory(adminPlayer: Player, targetUserId: number)
    if not isAdmin(adminPlayer) then
        warn("⛔ Unauthorized inventory reset attempt by:", adminPlayer.Name)
        return false, "Not authorized"
    end
    
    local targetPlayer = findPlayerByUserId(targetUserId)
    if not targetPlayer then
        notifyAdmin(adminPlayer, "Player not in game (UserId: " .. targetUserId .. ")", false)
        return false, "Player not in game"
    end
    
    local profile = DataManager.GetProfile(targetPlayer)
    if not profile then
        notifyAdmin(adminPlayer, "Profile not loaded for " .. targetPlayer.Name, false)
        return false, "Profile not loaded"
    end
    
    -- Reset only inventory
    profile.Data.inventory = {
        seeds = {},
        plants = {},
        materials = {},
    }
    
    DataManager.SavePlayer(targetPlayer)
    
    local message = "Reset inventory for " .. targetPlayer.Name
    notifyAdmin(adminPlayer, message, true)
    return true, message
end

--[[
    Give item to player
]]
function AdminCommands.GiveItem(adminPlayer: Player, targetUserId: number, itemType: string, itemId: string, amount: number)
    if not isAdmin(adminPlayer) then
        warn("⛔ Unauthorized give attempt by:", adminPlayer.Name)
        return false, "Not authorized"
    end
    
    local targetPlayer = findPlayerByUserId(targetUserId)
    if not targetPlayer then
        notifyAdmin(adminPlayer, "Player not in game (UserId: " .. targetUserId .. ")", false)
        return false, "Player not in game"
    end
    
    -- Validate amount
    amount = math.max(1, math.floor(amount or 1))
    
    -- Add item
    local success = DataManager.AddItem(targetPlayer, itemType, itemId, amount)
    
    if success then
        local message = string.format("Gave %d x %s (%s) to %s", amount, itemId, itemType, targetPlayer.Name)
        notifyAdmin(adminPlayer, message, true)
        return true, message
    else
        local message = "Failed to give item to " .. targetPlayer.Name
        notifyAdmin(adminPlayer, message, false)
        return false, message
    end
end

--[[
    Set player coins
]]
function AdminCommands.SetCoins(adminPlayer: Player, targetUserId: number, amount: number)
    if not isAdmin(adminPlayer) then
        warn("⛔ Unauthorized coin set attempt by:", adminPlayer.Name)
        return false, "Not authorized"
    end
    
    local targetPlayer = findPlayerByUserId(targetUserId)
    if not targetPlayer then
        notifyAdmin(adminPlayer, "Player not in game (UserId: " .. targetUserId .. ")", false)
        return false, "Player not in game"
    end
    
    amount = math.max(0, math.floor(amount or 0))
    
    local success = DataManager.SetCurrency(targetPlayer, "coins", amount)
    
    if success then
        local message = string.format("Set %s's coins to %d", targetPlayer.Name, amount)
        notifyAdmin(adminPlayer, message, true)
        return true, message
    else
        local message = "Failed to set coins for " .. targetPlayer.Name
        notifyAdmin(adminPlayer, message, false)
        return false, message
    end
end

--[[
    Set player gems
]]
function AdminCommands.SetGems(adminPlayer: Player, targetUserId: number, amount: number)
    if not isAdmin(adminPlayer) then
        warn("⛔ Unauthorized gem set attempt by:", adminPlayer.Name)
        return false, "Not authorized"
    end
    
    local targetPlayer = findPlayerByUserId(targetUserId)
    if not targetPlayer then
        notifyAdmin(adminPlayer, "Player not in game (UserId: " .. targetUserId .. ")", false)
        return false, "Player not in game"
    end
    
    amount = math.max(0, math.floor(amount or 0))
    
    local success = DataManager.SetCurrency(targetPlayer, "gems", amount)
    
    if success then
        local message = string.format("Set %s's gems to %d", targetPlayer.Name, amount)
        notifyAdmin(adminPlayer, message, true)
        return true, message
    else
        local message = "Failed to set gems for " .. targetPlayer.Name
        notifyAdmin(adminPlayer, message, false)
        return false, message
    end
end

--[[
    View player data
]]
function AdminCommands.ViewData(adminPlayer: Player, targetUserId: number)
    if not isAdmin(adminPlayer) then
        warn("⛔ Unauthorized data view attempt by:", adminPlayer.Name)
        return false, "Not authorized"
    end
    
    local targetPlayer = findPlayerByUserId(targetUserId)
    if not targetPlayer then
        notifyAdmin(adminPlayer, "Player not in game (UserId: " .. targetUserId .. ")", false)
        return false, "Player not in game"
    end
    
    local data = DataManager.GetData(targetPlayer)
    if not data then
        notifyAdmin(adminPlayer, "No data found for " .. targetPlayer.Name, false)
        return false, "No data found"
    end
    
    -- Print data summary to console
    print("=== DATA FOR", targetPlayer.Name, "===")
    print("Coins:", data.coins)
    print("Gems:", data.gems)
    print("Level:", data.level, "XP:", data.xp)
    
    -- Count inventory items
    local seedCount = 0
    for _, _ in pairs(data.inventory.seeds) do
        seedCount = seedCount + 1
    end
    print("Seeds:", seedCount, "types")
    
    local creatureCount = #data.creatures
    print("Creatures:", creatureCount)
    
    print("===========================")
    
    notifyAdmin(adminPlayer, "Check console for " .. targetPlayer.Name .. "'s data", true)
    return true, "Data printed to console"
end

-- ============================
-- CHAT COMMAND PARSER
-- ============================

local function parseCommand(player: Player, message: string)
    if not isAdmin(player) then return end
    
    -- Remove leading slash
    if not message:sub(1, 1) == "/" then return end
    message = message:sub(2)
    
    -- Split into parts
    local parts = {}
    for part in message:gmatch("%S+") do
        table.insert(parts, part)
    end
    
    if #parts == 0 then return end
    
    local command = parts[1]:lower()
    
    -- /reset [UserId]
    if command == "reset" and parts[2] then
        local userId = tonumber(parts[2])
        if userId then
            AdminCommands.ResetPlayer(player, userId)
        end
    
    -- /resetinv [UserId]
    elseif command == "resetinv" and parts[2] then
        local userId = tonumber(parts[2])
        if userId then
            AdminCommands.ResetInventory(player, userId)
        end
    
    -- /resetme
    elseif command == "resetme" then
        AdminCommands.ResetPlayer(player, player.UserId)
    
    -- /give [UserId] [itemType] [itemId] [amount]
    elseif command == "give" and parts[2] and parts[3] and parts[4] then
        local userId = tonumber(parts[2])
        local itemType = parts[3]
        local itemId = parts[4]
        local amount = tonumber(parts[5]) or 1
        
        if userId then
            AdminCommands.GiveItem(player, userId, itemType, itemId, amount)
        end
    
    -- /coins [UserId] [amount]
    elseif command == "coins" and parts[2] and parts[3] then
        local userId = tonumber(parts[2])
        local amount = tonumber(parts[3])
        
        if userId and amount then
            AdminCommands.SetCoins(player, userId, amount)
        end
    
    -- /gems [UserId] [amount]
    elseif command == "gems" and parts[2] and parts[3] then
        local userId = tonumber(parts[2])
        local amount = tonumber(parts[3])
        
        if userId and amount then
            AdminCommands.SetGems(player, userId, amount)
        end
    
    -- /view [UserId]
    elseif command == "view" and parts[2] then
        local userId = tonumber(parts[2])
        if userId then
            AdminCommands.ViewData(player, userId)
        end
    
    -- /help
    elseif command == "help" then
        print("=== ADMIN COMMANDS ===")
        print("/reset [UserId] - Reset all player data")
        print("/resetinv [UserId] - Reset inventory only")
        print("/resetme - Reset your own data")
        print("/give [UserId] [itemType] [itemId] [amount] - Give item")
        print("/coins [UserId] [amount] - Set coins")
        print("/gems [UserId] [amount] - Set gems")
        print("/view [UserId] - View player data")
        print("=====================")
        notifyAdmin(player, "Commands printed to console", true)
    end
end

-- ============================
-- INITIALIZATION
-- ============================

function AdminCommands.Init()
    print("👑 Initializing Admin Commands...")
    
    if #ADMINS == 0 then
        warn("⚠️  No admins configured! Add UserIds to ADMINS table in AdminCommands.lua")
    else
        print("👑 Admin UserIds:", table.concat(ADMINS, ", "))
    end
    
    Players.PlayerAdded:Connect(function(player)
        if isAdmin(player) then
            print("👑 Admin joined:", player.Name, "(UserId:", player.UserId .. ")")
            
            -- Send welcome message
            task.wait(2)
            if AdminNotification then
                AdminNotification:FireClient(player, {
                    message = "Admin commands active. Type /help for commands.",
                    success = true
                })
            end
        end
        
        -- Listen for chat commands
        player.Chatted:Connect(function(message)
            parseCommand(player, message)
        end)
    end)
    
    print("✅ Admin Commands initialized")
end

return AdminCommands
