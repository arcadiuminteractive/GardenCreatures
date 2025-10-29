# Garden Creatures - Development Guide

## 🚀 Getting Started

### Prerequisites
1. **Roblox Studio** - Latest version
2. **Visual Studio Code** - For coding
3. **Rojo VS Code Extension** - For syncing
4. **Luau LSP Extension** - For autocomplete and type checking
5. **Git & GitHub Desktop** - Version control

### First-Time Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/arcadiuminteractive/GardenCreatures.git
   cd GardenCreatures
   ```

2. **Open in VS Code:**
   ```bash
   code .
   ```

3. **Install VS Code extensions:**
   - Rojo (evaera.vscode-rojo)
   - Luau Language Server (johnnymorganz.luau-lsp)

4. **Start Rojo:**
   - Open Command Palette (Ctrl+Shift+P / Cmd+Shift+P)
   - Type "Rojo: Start Server"
   - Or run in terminal: `rojo serve`

5. **Connect Roblox Studio:**
   - Open Roblox Studio
   - Install Rojo plugin from [https://rojo.space/](https://rojo.space/)
   - Click "Connect" in Rojo plugin
   - Click "Sync In" to load the project

## 📂 Project Structure

```
GardenCreatures/
├── src/                          # Source code (synced to Roblox)
│   ├── ServerScriptService/
│   │   ├── Systems/             # Server-side game systems
│   │   ├── Data/                # Data management
│   │   └── Server.server.lua    # Main server entry point
│   ├── ReplicatedStorage/
│   │   ├── Shared/
│   │   │   ├── Config/          # All game configuration
│   │   │   ├── Modules/         # Shared utility modules
│   │   │   └── Types.lua        # Type definitions
│   │   └── Assets/              # Models, effects, etc.
│   ├── StarterPlayer/
│   │   └── StarterPlayerScripts/
│   │       ├── Controllers/     # Client-side controllers
│   │       ├── UI/              # UI handlers
│   │       └── Client.client.lua # Main client entry point
│   └── StarterGui/              # UI instances
├── default.project.json          # Rojo configuration
├── .gitignore                    # Git ignore rules
└── README.md                     # Project documentation
```

## 🎯 Development Workflow

### Making Changes

1. **Edit code in VS Code**
   - Rojo automatically syncs changes to Studio
   - See changes reflected immediately in Studio

2. **Test in Studio**
   - Play test your changes
   - Use output window for debugging

3. **Commit to Git**
   ```bash
   git add .
   git commit -m "Description of changes"
   git push
   ```

### Creating New Systems

1. Create module file in appropriate folder
2. Add require statement in Server.lua or Client.lua
3. Follow existing system patterns

### Adding Configuration

1. Edit config files in `src/ReplicatedStorage/Shared/Config/`
2. No code changes needed - configurations are data-driven
3. Reload game to see changes

## 🔧 Next Steps

### Immediate Priorities

1. **Install ProfileService**
   - Download from: https://github.com/MadStudioRoblox/ProfileService
   - Place in ServerScriptService or ReplicatedStorage
   - Update DataManager.lua to use it

2. **Create System Modules**
   - InventoryManager
   - PlantManager
   - CreatureManager
   - etc.

3. **Build UI**
   - Create UI instances in StarterGui
   - Connect to controllers

4. **Add Models**
   - Create/import seed models
   - Create/import plant models
   - Create/import creature models

### Development Order (Recommended)

**Phase 1: Foundation (Week 1-2)**
- [ ] Install ProfileService
- [ ] Implement DataManager fully
- [ ] Create InventoryManager
- [ ] Create basic UI framework
- [ ] Test data persistence

**Phase 2: Core Gameplay (Week 3-4)**
- [ ] Implement GardeningSystem
- [ ] Create garden plots in world
- [ ] Plant growth mechanics
- [ ] Harvest system
- [ ] Basic UI for gardening

**Phase 3: Creatures (Week 5-6)**
- [ ] Implement CraftingSystem
- [ ] Create RecipeManager
- [ ] Creature spawning
- [ ] Following mechanics
- [ ] Basic abilities

**Phase 4: Advanced Features (Week 7-8)**
- [ ] Creature leveling system
- [ ] Wild spawn system
- [ ] Trading system
- [ ] Home base instances

**Phase 5: Economy & Polish (Week 9-10)**
- [ ] Shop system
- [ ] Gamepass integration
- [ ] UI polish
- [ ] Balancing
- [ ] Bug fixes

## 🐛 Debugging

### Common Issues

**Rojo won't connect:**
- Ensure `rojo serve` is running
- Check Rojo plugin is installed in Studio
- Try restarting both VS Code and Studio

**Changes not syncing:**
- Check Rojo server output for errors
- Verify file is in correct location
- Try manual "Sync In" from Rojo plugin

**Script errors:**
- Check Output window in Studio
- Use print() statements for debugging
- Access _G.GardenCreatures for system inspection

### Debug Commands

Add these to Command Bar in Studio:

```lua
-- View loaded systems
print(_G.GardenCreatures.Systems)

-- View config
print(_G.GardenCreatures.Config.Seeds)

-- Get player data (replace USERNAME)
local player = game.Players.USERNAME
local data = _G.GardenCreatures.Systems.DataManager.GetData(player)
print(data)

-- Add currency
_G.GardenCreatures.Systems.DataManager.AddCurrency(player, "Coins", 1000)
```

## 📚 Resources

### Roblox Development
- [Roblox Creator Documentation](https://create.roblox.com/docs)
- [Luau Language Reference](https://luau-lang.org/)
- [ProfileService Docs](https://madstudioroblox.github.io/ProfileService/)

### Our Architecture
- See README.md for game design
- Check config files for all game data
- Review Types.lua for data structures

### Community
- Roblox DevForum: https://devforum.roblox.com/
- Rojo Discord: https://discord.gg/wH5ncNS

## 🎨 Asset Guidelines

### Models
- Optimize poly count (mobile-friendly)
- Use PBR textures when possible
- Keep file sizes reasonable

### Scripts
- Follow Luau best practices
- Use type annotations (see Types.lua)
- Comment complex logic
- Keep functions small and focused

### UI
- Design for multiple screen sizes
- Use UIConstraints and UIAspectRatios
- Test on mobile devices
- Keep consistent visual style

## 🔐 Security Notes

- Never commit Roblox API keys or secrets
- Keep gamepass IDs in config files
- Validate all client input on server
- Use RemoteEvents/Functions properly
- Data should be server-authoritative

## 📝 Code Style

```lua
-- Use descriptive variable names
local playerInventory = {}  -- Good
local pi = {}               -- Bad

-- Type annotations
function GetCreature(creatureId: string): Creature?
    -- Implementation
end

-- Comments for complex logic
-- Calculate growth time with all modifiers applied
local finalGrowthTime = baseTime * vipMultiplier * boosterMultiplier

-- Consistent formatting
if condition then
    -- Do something
elseif otherCondition then
    -- Do something else
else
    -- Default case
end
```

## 🚢 Deployment

When ready to publish:

1. **Test thoroughly**
   - All systems working
   - No console errors
   - Tested on multiple devices

2. **Build in Studio**
   - Sync latest code via Rojo
   - Test in Studio one final time
   - Publish to Roblox

3. **Update game metadata**
   - Description
   - Thumbnails
   - Tags

4. **Tag release in Git**
   ```bash
   git tag v0.1.0
   git push --tags
   ```

---

**Happy coding! 🌱**

For questions, contact the development team.
