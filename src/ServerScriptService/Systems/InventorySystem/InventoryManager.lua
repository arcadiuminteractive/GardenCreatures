--[[
    InventoryManager.lua
    Server-side inventory management system
    
    Features:
    - Manages player inventories (10 slots)
    - Item stacking (max 10 per slot, 100 total capacity)
    - Add/remove items
    - Inventory validation
    - Data persistence integration
    
    Place in: ServerScriptService/Systems/InventorySystem/
]]

local InventoryManager = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Constants
local INVENTORY_SLOTS = 10
local MAX_STACK_SIZE = 10
local MAX_TOTAL_CAPACITY = 100

-- Data
local playerInventories = {} -- Cache of player inventories

-- Remote Events
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdateInventoryEvent = nil
local RequestInventoryFunction = nil

-- Get DataManager reference
local ServerScriptService = game:GetService("ServerScriptService")
local DataManager = require(ServerScriptService.Data.DataManager)

-- ============================
-- INITIALIZATION
-- ============================

function InventoryManager.Init()
    print("🎒 Initializing Inventory Manager...")
    
    -- Create RemoteEvents if they don't exist
    InventoryManager._SetupRemotes()
    
    print("✅ Inventory Manager initialized")
end

function InventoryManager._SetupRemotes()
    -- Create UpdateInventory RemoteEvent
    UpdateInventoryEvent = RemoteEvents:FindFirstChild("UpdateInventory")
    if not UpdateInventoryEvent then
        UpdateInventoryEvent = Instance.new("RemoteEvent")
        UpdateInventoryEvent.Name = "UpdateInventory"
        UpdateInventoryEvent.Parent = RemoteEvents
        print("✅ Created UpdateInventory RemoteEvent")
    end
    
    -- Create RequestInventory RemoteFunction
    RequestInventoryFunction = RemoteEvents:FindFirstChild("RequestInventory")
    if not RequestInventoryFunction then
        RequestInventoryFunction = Instance.new("RemoteFunction")
        RequestInventoryFunction.Name = "RequestInventory"
        RequestInventoryFunction.Parent = RemoteEvents
        print("✅ Created RequestInventory RemoteFunction")
    end
    
    -- Handle inventory requests
    RequestInventoryFunction.OnServerInvoke = function(player)
        return InventoryManager.GetInventory(player)
    end
end

-- ============================
-- PLAYER SETUP
-- ============================

function InventoryManager.SetupPlayer(player: Player)
    -- Initialize player inventory cache
    local playerData = DataManager.GetData(player)
    
    if playerData then
        -- Initialize inventory if it doesn't exist
        if not playerData.Inventory then
            playerData.Inventory = InventoryManager._CreateEmptyInventory()
            print("✅ Created new inventory for", player.Name)
        end
        
        -- Cache inventory
        playerInventories[player.UserId] = playerData.Inventory
        
        -- Send initial inventory to client
        if UpdateInventoryEvent then
            UpdateInventoryEvent:FireClient(player, playerData.Inventory)
        end
    else
        warn("⚠️  Could not get player data for", player.Name)
    end
end

function InventoryManager._CreateEmptyInventory()
    local inventory = {}
    for i = 1, INVENTORY_SLOTS do
        inventory[i] = {
            itemId = nil,
            itemName = nil,
            quantity = 0,
        }
    end
    return inventory
end

-- ============================
-- INVENTORY OPERATIONS
-- ============================

--[[
    Gets a player's inventory
    @param player - The player
    @return table - The player's inventory
]]
function InventoryManager.GetInventory(player: Player)
    return playerInventories[player.UserId] or InventoryManager._CreateEmptyInventory()
end

--[[
    Adds an item to a player's inventory
    @param player - The player
    @param itemId - The item identifier
    @param itemName - The item display name
    @param quantity - Amount to add
    @return boolean - Success
    @return string - Error message if failed
]]
function InventoryManager.AddItem(player: Player, itemId: string, itemName: string, quantity: number): (boolean, string?)
    local inventory = InventoryManager.GetInventory(player)
    
    -- Validate quantity
    if quantity <= 0 then
        return false, "Invalid quantity"
    end
    
    -- Check total capacity
    local currentTotal = InventoryManager._GetTotalItems(inventory)
    if currentTotal + quantity > MAX_TOTAL_CAPACITY then
        return false, "Inventory full (max 100 items)"
    end
    
    local remainingToAdd = quantity
    
    -- First, try to stack in existing slots with same item
    for i = 1, INVENTORY_SLOTS do
        if remainingToAdd <= 0 then break end
        
        local slot = inventory[i]
        if slot.itemId == itemId and slot.quantity < MAX_STACK_SIZE then
            local spaceInSlot = MAX_STACK_SIZE - slot.quantity
            local amountToAdd = math.min(spaceInSlot, remainingToAdd)
            
            slot.quantity = slot.quantity + amountToAdd
            remainingToAdd = remainingToAdd - amountToAdd
        end
    end
    
    -- Then, fill empty slots
    for i = 1, INVENTORY_SLOTS do
        if remainingToAdd <= 0 then break end
        
        local slot = inventory[i]
        if slot.quantity == 0 then
            local amountToAdd = math.min(MAX_STACK_SIZE, remainingToAdd)
            
            slot.itemId = itemId
            slot.itemName = itemName
            slot.quantity = amountToAdd
            remainingToAdd = remainingToAdd - amountToAdd
        end
    end
    
    -- Check if we added everything
    if remainingToAdd > 0 then
        -- Rollback? Or partial success?
        -- For now, return partial success
        local addedAmount = quantity - remainingToAdd
        InventoryManager._SaveInventory(player, inventory)
        InventoryManager._UpdateClient(player, inventory)
        return true, "Partially added: " .. addedAmount .. "/" .. quantity .. " (inventory full)"
    end
    
    -- Success!
    InventoryManager._SaveInventory(player, inventory)
    InventoryManager._UpdateClient(player, inventory)
    
    print("✅", player.Name, "received", quantity, "x", itemName)
    return true
end

--[[
    Removes an item from a player's inventory
    @param player - The player
    @param itemId - The item identifier
    @param quantity - Amount to remove
    @return boolean - Success
    @return string - Error message if failed
]]
function InventoryManager.RemoveItem(player: Player, itemId: string, quantity: number): (boolean, string?)
    local inventory = InventoryManager.GetInventory(player)
    
    -- Check if player has enough of the item
    local totalAmount = InventoryManager.GetItemCount(player, itemId)
    if totalAmount < quantity then
        return false, "Not enough items (has " .. totalAmount .. ", needs " .. quantity .. ")"
    end
    
    local remainingToRemove = quantity
    
    -- Remove from slots
    for i = 1, INVENTORY_SLOTS do
        if remainingToRemove <= 0 then break end
        
        local slot = inventory[i]
        if slot.itemId == itemId then
            local amountToRemove = math.min(slot.quantity, remainingToRemove)
            slot.quantity = slot.quantity - amountToRemove
            remainingToRemove = remainingToRemove - amountToRemove
            
            -- Clear slot if empty
            if slot.quantity == 0 then
                slot.itemId = nil
                slot.itemName = nil
            end
        end
    end
    
    -- Save and update
    InventoryManager._SaveInventory(player, inventory)
    InventoryManager._UpdateClient(player, inventory)
    
    print("✅ Removed", quantity, "x", itemId, "from", player.Name)
    return true
end

--[[
    Gets the count of a specific item in inventory
    @param player - The player
    @param itemId - The item identifier
    @return number - Total count
]]
function InventoryManager.GetItemCount(player: Player, itemId: string): number
    local inventory = InventoryManager.GetInventory(player)
    local total = 0
    
    for i = 1, INVENTORY_SLOTS do
        local slot = inventory[i]
        if slot.itemId == itemId then
            total = total + slot.quantity
        end
    end
    
    return total
end

--[[
    Checks if inventory has space for items
    @param player - The player
    @param quantity - Amount to check
    @return boolean - Has space
]]
function InventoryManager.HasSpace(player: Player, quantity: number): boolean
    local inventory = InventoryManager.GetInventory(player)
    local currentTotal = InventoryManager._GetTotalItems(inventory)
    return (currentTotal + quantity) <= MAX_TOTAL_CAPACITY
end

--[[
    Gets total item count in inventory
    @param player - The player
    @return number - Total items
]]
function InventoryManager.GetTotalItemCount(player: Player): number
    local inventory = InventoryManager.GetInventory(player)
    return InventoryManager._GetTotalItems(inventory)
end

-- ============================
-- HELPER FUNCTIONS
-- ============================

function InventoryManager._GetTotalItems(inventory)
    local total = 0
    for i = 1, INVENTORY_SLOTS do
        total = total + inventory[i].quantity
    end
    return total
end

function InventoryManager._SaveInventory(player: Player, inventory)
    local playerData = DataManager.GetData(player)
    if playerData then
        playerData.Inventory = inventory
        playerInventories[player.UserId] = inventory
    end
end

function InventoryManager._UpdateClient(player: Player, inventory)
    if UpdateInventoryEvent then
        UpdateInventoryEvent:FireClient(player, inventory)
    end
end

-- ============================
-- PLAYER CLEANUP
-- ============================

Players.PlayerRemoving:Connect(function(player)
    -- Clear cache
    playerInventories[player.UserId] = nil
    print("🎒 Cleared inventory cache for", player.Name)
end)

-- ============================
-- PUBLIC API
-- ============================

print("✅ InventoryManager loaded")

return InventoryManager
