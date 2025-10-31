--[[
    CreaturePlotManager.lua
    Server-side system for managing creature plots
    
    Responsibilities:
    - Create/manage player creature plots
    - Handle item placement in plot slots
    - Manage growth timing
    - Generate creatures when growth completes
    - Synchronize with client UI
    
    Place in: ServerScriptService/Systems/CreaturePlotSystem/
]]

local CreaturePlotManager = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

-- Configuration
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = {
    Items = require(Shared.Config.Items),
    CreaturePlots = require(Shared.Config.CreaturePlots),
}

-- Other systems
local DataManager = require(ServerScriptService.Data.DataManager)
local InventoryManager = require(ServerScriptService.Systems.InventorySystem.InventoryManager)

-- Constants
local PLOT_TAG = "CreaturePlot"

-- State
local PlayerPlots = {} -- {[player] = {plots}}
local ActiveGrowth = {} -- {[plotId] = {data}}

-- Remote Events
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local PlotRemotes = {}

-- ============================
-- INITIALIZATION
-- ============================

function CreaturePlotManager.Init()
    print("🌱 Initializing Creature Plot Manager...")
    
    CreaturePlotManager._SetupRemotes()
    
    print("✅ Creature Plot Manager initialized")
end

function CreaturePlotManager._SetupRemotes()
    -- Create RemoteEvent for plot actions
    local createPlotEvent = Instance.new("RemoteEvent")
    createPlotEvent.Name = "CreateCreaturePlot"
    createPlotEvent.Parent = RemoteEvents
    PlotRemotes.CreatePlot = createPlotEvent
    
    local placeItemEvent = Instance.new("RemoteEvent")
    placeItemEvent.Name = "PlaceItemInPlot"
    placeItemEvent.Parent = RemoteEvents
    PlotRemotes.PlaceItem = placeItemEvent
    
    local removeItemEvent = Instance.new("RemoteEvent")
    removeItemEvent.Name = "RemoveItemFromPlot"
    removeItemEvent.Parent = RemoteEvents
    PlotRemotes.RemoveItem = removeItemEvent
    
    local startGrowthEvent = Instance.new("RemoteEvent")
    startGrowthEvent.Name = "StartPlotGrowth"
    startGrowthEvent.Parent = RemoteEvents
    PlotRemotes.StartGrowth = startGrowthEvent
    
    local harvestCreatureEvent = Instance.new("RemoteEvent")
    harvestCreatureEvent.Name = "HarvestCreature"
    harvestCreatureEvent.Parent = RemoteEvents
    PlotRemotes.HarvestCreature = harvestCreatureEvent
    
    -- Function to request plot data
    local requestPlotsFunc = Instance.new("RemoteFunction")
    requestPlotsFunc.Name = "RequestPlayerPlots"
    requestPlotsFunc.Parent = RemoteEvents
    PlotRemotes.RequestPlots = requestPlotsFunc
    
    -- Connect events
    PlotRemotes.CreatePlot.OnServerEvent:Connect(function(player, plotType)
        CreaturePlotManager.CreatePlot(player, plotType)
    end)
    
    PlotRemotes.PlaceItem.OnServerEvent:Connect(function(player, plotId, slotType, itemId)
        CreaturePlotManager.PlaceItem(player, plotId, slotType, itemId)
    end)
    
    PlotRemotes.RemoveItem.OnServerEvent:Connect(function(player, plotId, slotType)
        CreaturePlotManager.RemoveItem(player, plotId, slotType)
    end)
    
    PlotRemotes.StartGrowth.OnServerEvent:Connect(function(player, plotId)
        CreaturePlotManager.StartGrowth(player, plotId)
    end)
    
    PlotRemotes.HarvestCreature.OnServerEvent:Connect(function(player, plotId)
        CreaturePlotManager.HarvestCreature(player, plotId)
    end)
    
    PlotRemotes.RequestPlots.OnServerInvoke = function(player)
        return CreaturePlotManager.GetPlayerPlots(player)
    end
    
    print("✅ Created creature plot RemoteEvents")
end

-- ============================
-- PLAYER SETUP
-- ============================

function CreaturePlotManager.SetupPlayer(player: Player)
    print("🌱 Setting up creature plots for", player.Name)
    
    -- Load plots from DataManager
    local data = DataManager.GetData(player)
    if not data then
        warn("❌ No data found for", player.Name)
        return false
    end
    
    -- Initialize plots if not exists
    if not data.creaturePlots then
        data.creaturePlots = {}
        
        -- Give player their first free plot
        local firstPlot = CreaturePlotManager._CreatePlotData("basic_plot")
        table.insert(data.creaturePlots, firstPlot)
        
        print("✅ Created first creature plot for", player.Name)
    end
    
    PlayerPlots[player] = data.creaturePlots
    
    -- Resume any interrupted growth
    CreaturePlotManager._ResumeGrowth(player)
    
    return true
end

function CreaturePlotManager.CleanupPlayer(player: Player)
    -- Stop any active growth
    for plotId, growthData in pairs(ActiveGrowth) do
        if growthData.player == player then
            ActiveGrowth[plotId] = nil
        end
    end
    
    PlayerPlots[player] = nil
    print("✅ Cleaned up creature plots for", player.Name)
end

-- ============================
-- PLOT MANAGEMENT
-- ============================

function CreaturePlotManager.CreatePlot(player: Player, plotType: string): (boolean, string?)
    local data = DataManager.GetData(player)
    if not data then
        return false, "Data not loaded"
    end
    
    -- Check plot limit
    local currentPlots = #data.creaturePlots
    local maxPlots = data.maxCreaturePlots or Config.CreaturePlots.defaultMaxPlots
    
    if currentPlots >= maxPlots then
        return false, "Max plots reached"
    end
    
    -- Get plot type config
    local plotConfig = Config.CreaturePlots.GetPlotType(plotType)
    if not plotConfig then
        return false, "Invalid plot type"
    end
    
    -- Check cost
    if plotConfig.coinPrice and plotConfig.coinPrice > 0 then
        local coins = DataManager.GetCurrency(player, "coins")
        if coins < plotConfig.coinPrice then
            return false, "Not enough coins"
        end
        DataManager.RemoveCurrency(player, "coins", plotConfig.coinPrice)
    end
    
    if plotConfig.gemPrice and plotConfig.gemPrice > 0 then
        local gems = DataManager.GetCurrency(player, "gems")
        if gems < plotConfig.gemPrice then
            return false, "Not enough gems"
        end
        DataManager.RemoveCurrency(player, "gems", plotConfig.gemPrice)
    end
    
    -- Create plot
    local newPlot = CreaturePlotManager._CreatePlotData(plotType)
    table.insert(data.creaturePlots, newPlot)
    
    PlayerPlots[player] = data.creaturePlots
    
    -- Update client
    CreaturePlotManager._UpdateClient(player)
    
    print("✅", player.Name, "created plot:", plotType)
    return true
end

function CreaturePlotManager._CreatePlotData(plotType: string)
    return {
        plotId = "plot_" .. tostring(tick()) .. "_" .. tostring(math.random(1000, 9999)),
        plotType = plotType,
        
        -- Slots
        formItemId = nil,
        substanceItemId = nil,
        primaryAttributeItemId = nil,
        secondaryAttributeItemId = nil,
        
        -- State
        state = "empty", -- empty, filled, growing, ready
        startedGrowthTime = nil,
        growthDuration = nil,
        readyCreatureData = nil,
        
        createdTimestamp = os.time(),
    }
end

function CreaturePlotManager.GetPlayerPlots(player: Player)
    return PlayerPlots[player] or {}
end

function CreaturePlotManager.GetPlot(player: Player, plotId: string)
    local plots = PlayerPlots[player]
    if not plots then return nil end
    
    for _, plot in ipairs(plots) do
        if plot.plotId == plotId then
            return plot
        end
    end
    
    return nil
end

-- ============================
-- ITEM PLACEMENT
-- ============================

function CreaturePlotManager.PlaceItem(player: Player, plotId: string, slotType: string, itemId: string): (boolean, string?)
    local plot = CreaturePlotManager.GetPlot(player, plotId)
    if not plot then
        return false, "Plot not found"
    end
    
    -- Check plot state
    if plot.state ~= "empty" and plot.state ~= "filled" then
        return false, "Plot is " .. plot.state
    end
    
    -- Verify slot type is valid
    local validSlots = {"Form", "Substance", "PrimaryAttribute", "SecondaryAttribute"}
    if not table.find(validSlots, slotType) then
        return false, "Invalid slot type"
    end
    
    -- Get item config
    local item = Config.Items.GetItemById(itemId)
    if not item then
        return false, "Invalid item"
    end
    
    -- Verify item type matches slot
    local slotKey = slotType == "Form" and "formItemId"
        or slotType == "Substance" and "substanceItemId"
        or slotType == "PrimaryAttribute" and "primaryAttributeItemId"
        or "secondaryAttributeItemId"
    
    -- Check if item type is correct
    if slotType == "Form" and item.itemType ~= "Form" then
        return false, "Item must be a Form item"
    elseif slotType == "Substance" and item.itemType ~= "Substance" then
        return false, "Item must be a Substance item"
    elseif (slotType == "PrimaryAttribute" or slotType == "SecondaryAttribute") and item.itemType ~= "Attribute" then
        return false, "Item must be an Attribute item"
    end
    
    -- Check if player has item in inventory
    local itemCount = InventoryManager.GetItemCount(player, itemId)
    if itemCount < 1 then
        return false, "You don't have this item"
    end
    
    -- Remove item from inventory
    local success, errorMsg = InventoryManager.RemoveItem(player, itemId, 1)
    if not success then
        return false, errorMsg
    end
    
    -- If slot was occupied, return old item to inventory
    if plot[slotKey] then
        InventoryManager.AddItem(player, plot[slotKey], "Item", 1)
    end
    
    -- Place item in slot
    plot[slotKey] = itemId
    
    -- Update plot state
    if plot.formItemId and plot.substanceItemId then
        plot.state = "filled"
    end
    
    -- Update client
    CreaturePlotManager._UpdateClient(player)
    
    print("✅", player.Name, "placed", itemId, "in", slotType, "slot of plot", plotId)
    return true
end

function CreaturePlotManager.RemoveItem(player: Player, plotId: string, slotType: string): (boolean, string?)
    local plot = CreaturePlotManager.GetPlot(player, plotId)
    if not plot then
        return false, "Plot not found"
    end
    
    -- Check plot state
    if plot.state ~= "empty" and plot.state ~= "filled" then
        return false, "Plot is " .. plot.state
    end
    
    local slotKey = slotType == "Form" and "formItemId"
        or slotType == "Substance" and "substanceItemId"
        or slotType == "PrimaryAttribute" and "primaryAttributeItemId"
        or "secondaryAttributeItemId"
    
    local itemId = plot[slotKey]
    if not itemId then
        return false, "Slot is empty"
    end
    
    -- Return item to inventory
    local item = Config.Items.GetItemById(itemId)
    if item then
        InventoryManager.AddItem(player, itemId, item.name, 1)
    end
    
    -- Remove from slot
    plot[slotKey] = nil
    
    -- Update plot state
    if not plot.formItemId or not plot.substanceItemId then
        plot.state = "empty"
    end
    
    -- Update client
    CreaturePlotManager._UpdateClient(player)
    
    print("✅", player.Name, "removed item from", slotType, "slot of plot", plotId)
    return true
end

-- ============================
-- GROWTH SYSTEM
-- ============================

function CreaturePlotManager.StartGrowth(player: Player, plotId: string): (boolean, string?)
    local plot = CreaturePlotManager.GetPlot(player, plotId)
    if not plot then
        return false, "Plot not found"
    end
    
    -- Check plot state
    if plot.state ~= "filled" then
        return false, "Plot must be filled with items"
    end
    
    -- Validate plot data
    local valid, errorMsg = Config.CreaturePlots.ValidatePlotData(plot)
    if not valid then
        return false, errorMsg
    end
    
    -- Calculate growth time
    local itemIds = {plot.formItemId, plot.substanceItemId}
    if plot.primaryAttributeItemId then
        table.insert(itemIds, plot.primaryAttributeItemId)
    end
    if plot.secondaryAttributeItemId then
        table.insert(itemIds, plot.secondaryAttributeItemId)
    end
    
    local rarity = Config.Items.CalculateAverageRarity(itemIds)
    local growthDuration = Config.CreaturePlots.CalculateGrowthTime(rarity, plot.plotType)
    
    -- Update plot
    plot.state = "growing"
    plot.startedGrowthTime = os.time()
    plot.growthDuration = growthDuration
    
    -- Add to active growth tracking
    ActiveGrowth[plotId] = {
        player = player,
        plotId = plotId,
        startTime = os.time(),
        duration = growthDuration,
    }
    
    -- Update client
    CreaturePlotManager._UpdateClient(player)
    
    print("✅", player.Name, "started growing creature in plot", plotId, "| Duration:", growthDuration .. "s")
    
    -- Schedule completion
    task.delay(growthDuration, function()
        CreaturePlotManager._CompleteGrowth(player, plotId)
    end)
    
    return true
end

function CreaturePlotManager._CompleteGrowth(player: Player, plotId: string)
    local plot = CreaturePlotManager.GetPlot(player, plotId)
    if not plot then return end
    
    if plot.state ~= "growing" then return end
    
    -- Generate creature
    local creatureData = Config.CreaturePlots.GenerateCreature(plot)
    if not creatureData then
        warn("❌ Failed to generate creature for plot", plotId)
        return
    end
    
    -- Update plot
    plot.state = "ready"
    plot.readyCreatureData = creatureData
    
    -- Remove from active growth
    ActiveGrowth[plotId] = nil
    
    -- Update client
    CreaturePlotManager._UpdateClient(player)
    
    print("✅ Creature ready in plot", plotId, ":", creatureData.name)
end

function CreaturePlotManager._ResumeGrowth(player: Player)
    local plots = PlayerPlots[player]
    if not plots then return end
    
    for _, plot in ipairs(plots) do
        if plot.state == "growing" and plot.startedGrowthTime and plot.growthDuration then
            local elapsed = os.time() - plot.startedGrowthTime
            local remaining = plot.growthDuration - elapsed
            
            if remaining <= 0 then
                -- Growth should be complete
                CreaturePlotManager._CompleteGrowth(player, plot.plotId)
            else
                -- Resume growth
                ActiveGrowth[plot.plotId] = {
                    player = player,
                    plotId = plot.plotId,
                    startTime = plot.startedGrowthTime,
                    duration = plot.growthDuration,
                }
                
                task.delay(remaining, function()
                    CreaturePlotManager._CompleteGrowth(player, plot.plotId)
                end)
                
                print("🔄 Resumed growth for plot", plot.plotId, "| Remaining:", remaining .. "s")
            end
        end
    end
end

-- ============================
-- HARVESTING
-- ============================

function CreaturePlotManager.HarvestCreature(player: Player, plotId: string): (boolean, string?)
    local plot = CreaturePlotManager.GetPlot(player, plotId)
    if not plot then
        return false, "Plot not found"
    end
    
    if plot.state ~= "ready" then
        return false, "No creature ready to harvest"
    end
    
    if not plot.readyCreatureData then
        return false, "Creature data missing"
    end
    
    -- Add creature to player's collection
    local success = DataManager.AddCreature(player, plot.readyCreatureData)
    if not success then
        return false, "Failed to add creature"
    end
    
    -- Award XP and coins
    DataManager.AddXP(player, 50)
    DataManager.AddCurrency(player, "coins", 25)
    
    -- Reset plot
    plot.state = "empty"
    plot.formItemId = nil
    plot.substanceItemId = nil
    plot.primaryAttributeItemId = nil
    plot.secondaryAttributeItemId = nil
    plot.startedGrowthTime = nil
    plot.growthDuration = nil
    plot.readyCreatureData = nil
    
    -- Update client
    CreaturePlotManager._UpdateClient(player)
    
    print("✅", player.Name, "harvested creature:", plot.readyCreatureData.name)
    return true, plot.readyCreatureData
end

-- ============================
-- CLIENT SYNC
-- ============================

function CreaturePlotManager._UpdateClient(player: Player)
    local plots = PlayerPlots[player]
    if not plots then return end
    
    -- Fire update event to client
    local updateEvent = RemoteEvents:FindFirstChild("UpdateCreaturePlots")
    if not updateEvent then
        updateEvent = Instance.new("RemoteEvent")
        updateEvent.Name = "UpdateCreaturePlots"
        updateEvent.Parent = RemoteEvents
    end
    
    updateEvent:FireClient(player, plots)
end

-- ============================
-- CLEANUP
-- ============================

Players.PlayerRemoving:Connect(function(player)
    CreaturePlotManager.CleanupPlayer(player)
end)

print("✅ CreaturePlotManager loaded")

return CreaturePlotManager
