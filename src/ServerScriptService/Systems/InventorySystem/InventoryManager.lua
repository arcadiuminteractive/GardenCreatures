--[[
    InventoryManager.lua - REFACTORED VERSION
    Server-side inventory management system with its own persistence
    
    ✅ REFACTORED:
    1. Independent from DataManager - has its own data storage
    2. Uses ProfileStore for persistence (shares same profile but different key)
    3. Slot-based system (10 slots) with stacking
    4. Clean separation from progression data
    
    Features:
    - 10 slot inventory system
    - Item stacking (max 10 per slot, 100 total capacity)
    - Add/remove items with automatic stacking
    - Real-time client synchronization
    - Data persistence via ProfileStore
    
    Place in: ServerScriptService/Systems/InventorySystem/
]]

local InventoryManager = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- ProfileStore
local ProfileStoreModule = require(ServerScriptService:WaitForChild("ProfileStore"))

-- Constants
local INVENTORY_SLOTS = 10
local MAX_STACK_SIZE = 10
local MAX_TOTAL_CAPACITY = 100
local PROFILE_STORE_NAME = "PlayerInventory_v1" -- Separate store for inventory

-- Data
local InventoryProfiles = {} -- Separate inventory profiles

-- Remote Events
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdateInventoryEvent = nil
local RequestInventoryFunction = nil

-- ============================
-- DATA TEMPLATE
-- ============================

local function CreateEmptyInventory()
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

local function GetDefaultInventoryData()
    return {
        slots = CreateEmptyInventory(),
        lastUpdated = os.time(),
    }
end

-- Initialize ProfileStore for inventory
local InventoryStore = ProfileStoreModule.New(
    PlayerInventory_v1,
    GetDefaultInventoryData()
)

-- ============================
-- INITIALIZATION
-- ============================

function InventoryManager.Init()
    print("🎒 Initializing Inventory Manager...")
    
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
    print("🎒 Setting up inventory for", player.Name)
    
    -- Load inventory profile
    local profile = InventoryStore:StartSessionAsync(
        "Inventory_" .. player.UserId,
        {
            Cancel = function()
                return player.Parent ~= Players
            end
        }
    )
    
    if profile ~= nil then
        profile:AddUserId(player.UserId)
        profile:Reconcile()
        
        profile.OnSessionEnd:Connect(function()
            InventoryProfiles[player] = nil
            print("📦 Inventory session ended for", player.Name)
        end)
        
        if player:IsDescendantOf(Players) then
            InventoryProfiles[player] = profile
            
            -- Ensure slots exist
            if not profile.Data.slots then
                profile.Data.slots = CreateEmptyInventory()
            end
            
            profile.Data.lastUpdated = os.time()
            
            -- Send initial inventory to client
            if UpdateInventoryEvent then
                UpdateInventoryEvent:FireClient(player, profile.Data.slots)
            end
            
            print("✅ Inventory loaded for", player.Name)
            return true
        else
            profile:EndSession()
            return false
        end
    else
        warn("❌ Failed to load inventory for:", player.Name)
        return false
    end
end

function InventoryManager.CleanupPlayer(player: Player)
    local profile = InventoryProfiles[player]
    if profile then
        profile.Data.lastUpdated = os.time()
        profile:EndSession()
        InventoryProfiles[player] = nil
        print("💾 Saved and released inventory for:", player.Name)
    end
end

-- Backwards compatibility with legacy naming
InventoryManager.SetupInventory = InventoryManager.SetupPlayer
InventoryManager.CleanupInventory = InventoryManager.CleanupPlayer

-- ============================
-- INVENTORY OPERATIONS
-- ============================

function InventoryManager.GetInventory(player: Player)
    local profile = InventoryProfiles[player]
    if profile and profile.Data.slots then
        return profile.Data.slots
    end
    return CreateEmptyInventory()
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
    local profile = InventoryProfiles[player]
    if not profile then 
        return false, "Inventory not loaded"
    end
    
    local inventory = profile.Data.slots
    
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
]]
function InventoryManager.RemoveItem(player: Player, itemId: string, quantity: number): (boolean, string?)
    local profile = InventoryProfiles[player]
    if not profile then
        return false, "Inventory not loaded"
    end
    
    local inventory = profile.Data.slots
    
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
]]
function InventoryManager.HasSpace(player: Player, quantity: number): boolean
    local inventory = InventoryManager.GetInventory(player)
    local currentTotal = InventoryManager._GetTotalItems(inventory)
    return (currentTotal + quantity) <= MAX_TOTAL_CAPACITY
end

--[[
    Gets total item count in inventory
]]
function InventoryManager.GetTotalItemCount(player: Player): number
    local inventory = InventoryManager.GetInventory(player)
    return InventoryManager._GetTotalItems(inventory)
end

--[[
    Clears the entire inventory
]]
function InventoryManager.ClearInventory(player: Player): boolean
    local profile = InventoryProfiles[player]
    if not profile then
        return false
    end
    
    profile.Data.slots = CreateEmptyInventory()
    profile.Data.lastUpdated = os.time()
    
    InventoryManager._UpdateClient(player, profile.Data.slots)
    
    print("🧹 Cleared inventory for", player.Name)
    return true
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
    local profile = InventoryProfiles[player]
    if profile then
        profile.Data.slots = inventory
        profile.Data.lastUpdated = os.time()
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
    InventoryManager.CleanupPlayer(player)
end)

-- ============================
-- AUTO-SAVE
-- ============================

task.spawn(function()
    while true do
        task.wait(300) -- Save every 5 minutes
        
        for player, profile in pairs(InventoryProfiles) do
            if player:IsDescendantOf(Players) and profile then
                profile.Data.lastUpdated = os.time()
                profile:Save()
            end
        end
        
        print("💾 Inventory auto-save completed")
    end
end)

-- ============================
-- SHUTDOWN HANDLER
-- ============================

game:BindToClose(function()
    print("🛑 Saving all inventories...")
    
    for player, profile in pairs(InventoryProfiles) do
        if profile then
            profile.Data.lastUpdated = os.time()
        end
    end
    
    task.wait(2)
end)

print("✅ InventoryManager loaded (Separate persistence system)")

return InventoryManager
