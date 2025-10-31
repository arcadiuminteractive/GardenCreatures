--[[
    Client.client.lua
    Main client entry point for Garden Creatures
    
    Initializes all client controllers and UI
]]

print("🌱 Garden Creatures - Client Starting...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage.Shared

-- Load configuration (read-only on client)
local Config = {
    Items = require(Shared.Config.Items),         -- ✨ RENAMED from Seeds
    CreaturePlots = require(Shared.Config.CreaturePlots),  -- ✨ NEW
    Plants = require(Shared.Config.Plants),
    Recipes = require(Shared.Config.Recipes),
    Creatures = require(Shared.Config.Creatures),
    Economy = require(Shared.Config.Economy),
}

-- Get controller folders
local Controllers = script.Parent.Controllers
local UI = script.Parent.UI

-- Controllers to load
local ControllersToLoad = {
    "ItemCollectionController",        -- ✨ RENAMED from SeedCollectionController
    "InventoryController",
    -- "CreaturePlotUIController",     -- 🚧 TODO: Create this
}

local LoadedControllers = {}

-- Load controllers
for _, controllerName in ipairs(ControllersToLoad) do
    local controller = Controllers:FindFirstChild(controllerName)
    if controller then
        local success, module = pcall(require, controller)
        if success then
            LoadedControllers[controllerName] = module
            print("✅ Loaded controller:", controllerName)
            
            -- Initialize if Init method exists
            if module.Init then
                module.Init()
            end
        else
            warn("❌ Failed to load controller:", controllerName, module)
        end
    else
        warn("❌ Controller not found:", controllerName)
    end
end

-- Start controllers
for name, controller in pairs(LoadedControllers) do
    if controller.Start then
        task.spawn(function()
            controller.Start()
        end)
    end
end

-- Wait for character
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

print("✅ Garden Creatures - Client Started Successfully!")
print("👤 Welcome,", player.Name .. "!")

-- Make controllers accessible globally for debugging
_G.GardenCreaturesClient = {
    Controllers = LoadedControllers,
    Config = Config,
    Player = player,
}

-- TODO: Show welcome UI after tutorial check
task.wait(1)
print("🌱 Client ready!")
