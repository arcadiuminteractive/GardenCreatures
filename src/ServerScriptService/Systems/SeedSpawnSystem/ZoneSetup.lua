--[[
    ZoneSetup.lua
    Helper module for setting up seed spawn zones
    
    Use this to easily configure spawn zones in your world
]]

local ZoneSetup = {}

-- ============================
-- ZONE CONFIGURATION HELPER
-- ============================

--[[
    Sets up a part as a seed spawn zone
    
    @param zonePart - The Part to convert into a spawn zone
    @param config - Configuration table:
        - zoneName: string (optional, defaults to part name)
        - zoneType: string (meadow, forest, volcanic, aquatic, mystical)
        - spawnRate: number (multiplier, default 1.0)
        - maxSeeds: number (max seeds in zone, default 10)
        - respawnTime: number (seconds between spawns, default 30)
]]
function ZoneSetup.SetupZone(zonePart: Part, config: {[string]: any})
    if not zonePart:IsA("BasePart") then
        warn("❌ Zone must be a BasePart")
        return false
    end
    
    -- Set attributes
    zonePart:SetAttribute("ZoneName", config.zoneName or zonePart.Name)
    zonePart:SetAttribute("ZoneType", config.zoneType or "meadow")
    zonePart:SetAttribute("SpawnRate", config.spawnRate or 1.0)
    zonePart:SetAttribute("MaxSeeds", config.maxSeeds or 10)
    zonePart:SetAttribute("RespawnTime", config.respawnTime or 30)
    
    -- Add tag
    local CollectionService = game:GetService("CollectionService")
    CollectionService:AddTag(zonePart, "SeedZone")
    
    -- Make transparent and non-collidable for better visuals
    zonePart.Transparency = 0.8
    zonePart.CanCollide = false
    zonePart.CanTouch = false
    zonePart.CanQuery = false
    
    -- Color code by zone type
    local zoneColors = {
        meadow = Color3.fromRGB(100, 200, 100),
        forest = Color3.fromRGB(50, 150, 50),
        volcanic = Color3.fromRGB(200, 50, 50),
        aquatic = Color3.fromRGB(50, 100, 200),
        mystical = Color3.fromRGB(150, 50, 200),
    }
    zonePart.Color = zoneColors[config.zoneType] or zoneColors.meadow
    
    print("✅ Setup spawn zone:", zonePart.Name, "| Type:", config.zoneType)
    
    return true
end

--[[
    Creates a new spawn zone from scratch
    
    @param position - Vector3 position
    @param size - Vector3 size
    @param config - Same as SetupZone config
    @param parent - Parent instance (defaults to workspace)
]]
function ZoneSetup.CreateZone(position: Vector3, size: Vector3, config: {[string]: any}, parent: Instance?): Part
    local zonePart = Instance.new("Part")
    zonePart.Name = config.zoneName or "SeedZone"
    zonePart.Size = size
    zonePart.Position = position
    zonePart.Anchored = true
    zonePart.Parent = parent or workspace
    
    ZoneSetup.SetupZone(zonePart, config)
    
    return zonePart
end

--[[
    Quick setup for common zone types
]]
function ZoneSetup.CreateMeadowZone(position: Vector3, size: Vector3): Part
    return ZoneSetup.CreateZone(position, size, {
        zoneName = "Meadow",
        zoneType = "meadow",
        maxSeeds = 15,
        respawnTime = 20,
    })
end

function ZoneSetup.CreateForestZone(position: Vector3, size: Vector3): Part
    return ZoneSetup.CreateZone(position, size, {
        zoneName = "Forest",
        zoneType = "forest",
        maxSeeds = 12,
        respawnTime = 25,
    })
end

function ZoneSetup.CreateVolcanicZone(position: Vector3, size: Vector3): Part
    return ZoneSetup.CreateZone(position, size, {
        zoneName = "Volcanic Area",
        zoneType = "volcanic",
        maxSeeds = 8,
        respawnTime = 40,
    })
end

function ZoneSetup.CreateAquaticZone(position: Vector3, size: Vector3): Part
    return ZoneSetup.CreateZone(position, size, {
        zoneName = "Lakeside",
        zoneType = "aquatic",
        maxSeeds = 10,
        respawnTime = 30,
    })
end

function ZoneSetup.CreateMysticalZone(position: Vector3, size: Vector3): Part
    return ZoneSetup.CreateZone(position, size, {
        zoneName = "Mystical Grove",
        zoneType = "mystical",
        maxSeeds = 5,
        respawnTime = 60, -- Rare spawns
        spawnRate = 0.5,
    })
end

--[[
    Visualize all spawn zones (for debugging)
]]
function ZoneSetup.VisualizeZones()
    local CollectionService = game:GetService("CollectionService")
    local zones = CollectionService:GetTagged("SeedZone")
    
    for _, zone in ipairs(zones) do
        if zone:IsA("BasePart") then
            zone.Transparency = 0.5
            
            -- Add label
            local billboard = zone:FindFirstChild("ZoneLabel") or Instance.new("BillboardGui")
            billboard.Name = "ZoneLabel"
            billboard.Size = UDim2.new(0, 200, 0, 50)
            billboard.StudsOffset = Vector3.new(0, zone.Size.Y/2 + 2, 0)
            billboard.AlwaysOnTop = true
            billboard.Parent = zone
            
            local label = billboard:FindFirstChild("TextLabel") or Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextScaled = true
            label.TextColor3 = Color3.new(1, 1, 1)
            label.Font = Enum.Font.SourceSansBold
            label.Text = string.format(
                "%s\nMax: %d | Respawn: %ds",
                zone:GetAttribute("ZoneName") or zone.Name,
                zone:GetAttribute("MaxSeeds") or 10,
                zone:GetAttribute("RespawnTime") or 30
            )
            label.Parent = billboard
        end
    end
    
    print("📍 Visualized", #zones, "spawn zones")
end

--[[
    Hide zone visualization
]]
function ZoneSetup.HideZones()
    local CollectionService = game:GetService("CollectionService")
    local zones = CollectionService:GetTagged("SeedZone")
    
    for _, zone in ipairs(zones) do
        if zone:IsA("BasePart") then
            zone.Transparency = 1
            
            local billboard = zone:FindFirstChild("ZoneLabel")
            if billboard then
                billboard:Destroy()
            end
        end
    end
    
    print("📍 Hid spawn zones")
end

--[[
    Get zone statistics
]]
function ZoneSetup.GetZoneStats()
    local CollectionService = game:GetService("CollectionService")
    local zones = CollectionService:GetTagged("SeedZone")
    
    local stats = {
        totalZones = #zones,
        byType = {},
        totalMaxSeeds = 0,
    }
    
    for _, zone in ipairs(zones) do
        if zone:IsA("BasePart") then
            local zoneType = zone:GetAttribute("ZoneType") or "meadow"
            stats.byType[zoneType] = (stats.byType[zoneType] or 0) + 1
            stats.totalMaxSeeds = stats.totalMaxSeeds + (zone:GetAttribute("MaxSeeds") or 10)
        end
    end
    
    return stats
end

print("✅ ZoneSetup loaded")

return ZoneSetup
