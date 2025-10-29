# 🌱 Garden Creatures

A hybrid Roblox game combining exploration, gardening, crafting, and creature collection mechanics.

## 🎮 Game Concept

**Garden Creatures** blends the best mechanics from popular games:
- **Exploration & Collection** (like Pokémon) - Collect seeds from the world
- **Gardening** (like Grow a Garden) - Plant, grow, and harvest
- **Crafting** (like Minecraft) - Use plant matter to craft living creatures
- **Creature/Pet Dynamics** (like Adopt Me!) - Tame, level up, and utilize creature abilities

## 🏗️ Core Systems

### 1. Inventory System
- Manages seeds, plant matter, and creatures
- Storage capacity with expandable slots
- Item stacking and organization

### 2. Gardening System
- Plant seeds in garden plots
- Growth stages with time progression
- Harvest plant matter for crafting
- Plot ownership and upgrades

### 3. Crafting System
- Recipe-based creature creation
- Mutation system for rare variants
- Requires specific plant matter combinations
- Recipe discovery and unlocks

### 4. Creature System
- **Storage:** 5 creatures (expandable)
- **Following:** 1 active creature (2 with gamepass)
- **Leveling:** Creatures level 1-10 through use
- **Abilities:** Passive bonuses while following
- **Swapping:** Only at Home Base (portable swap with gamepass)

### 5. Wild Spawn System
- **Player-Associated Spawns:** Common versions of player-owned creatures
- **Rare World Spawns:** Unique creatures not from player inventories (very rare)
- Despawn rules based on player presence

### 6. Economy System
- **Coins:** Soft currency (earned in-game)
- **Gems:** Premium currency (Robux purchase)
- Shop for items, upgrades, and boosts
- Monetization through gamepasses and developer products

### 7. Trading System
- Player-to-player trading
- Trade seeds, plants, creatures, and coins
- 8% coin tax on trades (4% for VIP)
- No gem trading (Roblox TOS compliance)

### 8. Home Base System
- Personal instanced garden area
- Creature swap station
- Crafting station
- Storage and shop access

## ⚡ Creature Abilities

Creatures provide passive bonuses while following:

### Gathering Bonuses
- Rare Seed Magnet - Increased rare seed drops
- Seed Sense - Highlights nearby seeds
- Bountiful Harvest - Double seed drop chance
- Lucky Find - Legendary seed chance

### Gardening Bonuses
- Growth Accelerator - Faster plant growth
- Auto-Water - No watering needed
- Mutation Boost - Higher plant mutation chance
- Mega Yield - More harvestable matter

### Crafting Bonuses
- Mutation Master - Better creature mutations
- Resource Saver - Material refund chance
- Recipe Revealer - Discover hidden recipes
- Quality Boost - Higher tier creatures

### Economy Bonuses
- Coin Multiplier - Increased coin earnings
- Shop Discount - Reduced purchase prices
- Gem Finder - Rare gem drops

### Exploration Bonuses
- Speed Boost - Increased movement
- Area Revealer - Shows unexplored zones
- Treasure Hunter - Marks rare spawns

## 📊 Creature Leveling

- **Max Level:** 10
- **XP Sources:**
  - Time following (1 XP/min)
  - Seeds collected (5 XP)
  - Plants harvested (10 XP)
  - Creatures crafted (25 XP)
  - Trades completed (15 XP)

**Ability Scaling:**
- Tier 1 (Common): 5% → 18.5% at max level
- Tier 2 (Rare): 10% → 28% at max level
- Tier 3 (Legendary): 20% → 42.5% at max level

## 💰 Monetization

### Gamepasses
- **Dual Creature Follow** - 299 Robux (2 creatures active)
- **Portable Creature Pod** - 199 Robux (swap anywhere)
- **Infinite Garden Plots** - 499 Robux
- **Auto-Harvest** - 399 Robux
- **VIP Bundle** - 799 Robux (+3 storage, +1 follow slot, 2x XP)

### In-Game Purchases
- Creature storage slots (50 gems)
- Garden plot expansions (100 coins or 25 gems)
- Growth boosters (10 gems = 2x speed/1hr)
- Recipe unlocks (varies by rarity)
- Cosmetics (skins, decorations)

### Developer Products
- Gem packs (100-5000 gems)
- XP boost (2x for 1 hour)
- Mutation chance boost

## 🗂️ Project Structure

```
GardenCreatures/
├── src/
│   ├── ServerScriptService/
│   │   ├── Systems/
│   │   │   ├── InventorySystem/
│   │   │   ├── GardeningSystem/
│   │   │   ├── CraftingSystem/
│   │   │   ├── CreatureSystem/
│   │   │   ├── EconomySystem/
│   │   │   ├── TradingSystem/
│   │   │   └── HomeBaseSystem/
│   │   └── Data/
│   ├── ReplicatedStorage/
│   │   └── Shared/
│   │       ├── Config/
│   │       └── Modules/
│   ├── StarterPlayer/
│   │   └── StarterPlayerScripts/
│   │       ├── Controllers/
│   │       └── UI/
│   └── StarterGui/
├── default.project.json
└── README.md
```

## 🛠️ Development Setup

### Prerequisites
- [Roblox Studio](https://www.roblox.com/create)
- [Rojo](https://rojo.space/) (for sync)
- [VS Code](https://code.visualstudio.com/) (recommended IDE)
- [Git](https://git-scm.com/)

### VS Code Extensions
- **Rojo** - Official Rojo extension
- **Luau LSP** - Language server for Luau
- **Selene** - Linter for Roblox Luau

### Getting Started
1. Clone the repository
2. Install Rojo: `cargo install rojo` or download from [rojo.space](https://rojo.space)
3. Run `rojo serve` in the project directory
4. Connect from Roblox Studio using the Rojo plugin

## 🎯 Development Priorities

### Phase 1: Foundation
1. Inventory System
2. Economy System (basic)
3. Data persistence (ProfileService)

### Phase 2: Core Loop
1. Gardening System
2. Crafting System
3. Basic creature creation

### Phase 3: Creature Features
1. Creature following
2. Ability system
3. Leveling system

### Phase 4: World Systems
1. Wild spawns (player-associated)
2. Wild spawns (rare)
3. Exploration zones

### Phase 5: Social & Economy
1. Trading system
2. Home Base system
3. Full monetization implementation

### Phase 6: Polish
1. UI/UX refinement
2. Balancing
3. Performance optimization
4. Beta testing

## 📝 Design Principles

- **Server Authority:** All important logic on server (anti-cheat)
- **Modular Design:** Systems are independent and communicate via APIs
- **Configuration-Driven:** Balance changes without code changes
- **F2P Friendly:** Full gameplay available to free players
- **Ethical Monetization:** Convenience and cosmetics, not pay-to-win

## 🤝 Contributing

This is a private development project. All contributors should follow:
- Luau style guide
- Modular architecture patterns
- Server-authoritative design
- Clear commenting and documentation

## 📄 License

Private project - All rights reserved

---

**Built with ❤️ by Arcadium Interactive**
