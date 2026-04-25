# NeoForge Performance Mods

Reference for NeoForge 1.21.1 (primary) and 1.20.x (secondary). All mods are client-compatible unless noted.

## Recommended Starter Stack

For any NeoForge 1.21.1 modpack — zero compatibility risk, maximum return:

### Client + Server (must-have)
| Mod | Purpose |
|-----|---------|
| **Embeddium** | Sodium for NeoForge — rewrites terrain renderer, 2–3× FPS |
| **Embeddium Extra** | Adds OptiFine-style video options on top of Embeddium |
| **FerriteCore** | Deduplicates block state objects — frees 200–500 MB in large packs |
| **ModernFix** | Fixes memory leaks, speeds class loading, ~20% RAM reduction |
| **Entity Culling** | Async ray tracing — skips rendering hidden entities/tile entities |
| **ImmediatelyFast** | Batches GUI/text/HUD draw calls — zero-config FPS boost |
| **Clumps** | Merges XP orbs — essential for mob grinders |

### Add for heavier modpacks
| Mod | Purpose |
|-----|---------|
| **FastSuite** | Caches all JSON recipe lookups |
| **FastWorkbench** | Optimizes crafting table recipe resolution |
| **FastFurnace** | Caches furnace recipe checks |
| **Radium Reforged** | NeoForge Lithium port — AI, collision, tick optimization |
| **Alternate Current** | Deterministic redstone — prevents cascade lag |
| **Ksyxis** | Removes always-loaded spawn chunks — faster world load |

---

## Full Mod List by Category

### Rendering / FPS (Client-Side)

| Mod | What It Does | Notes |
|-----|-------------|-------|
| **Embeddium** | NeoForge port of Sodium. Rewrites the chunk renderer and GPU data paths. | **Prefer over Rubidium.** Use NeOculus for shaders |
| **Embeddium (Rubidium) Extra** | Adds zoom, particle control, weather toggle on top of Embeddium | Requires Embeddium |
| **Rubidium** | Older Sodium fork, mostly superseded | Use only if Embeddium unavailable |
| **ImmediatelyFast** | Batches immediate-mode OpenGL calls (GUIs, signs, maps, armor stands) | NeoForge 1.20.1+ |
| **Cull Less Leaves** | Culls interior leaf geometry — reduces leaf overdraw | Cosmetic tradeoff |
| **Vanillin** | Instanced rendering for repeated block-entity models (chests, furnaces in bulk) | NeoForge 1.21.1 |
| **Dynamic FPS** | Cuts framerate when Minecraft is unfocused / in background | Must-have for multi-tasking |
| **Fix GPU Memory Leak** | Patches vanilla GPU memory leak that degrades FPS over long sessions | — |

### Entity & Block-Entity Culling (Client)

| Mod | What It Does | Notes |
|-----|-------------|-------|
| **Entity Culling** | Async ray tracer — skips entities/tile entities hidden by blocks | Huge gains in farms, factories |
| **More Culling** | Complementary background culling | Pair with Entity Culling |
| **Better Beds** | Removes bed block entity renderer — treats beds as normal blocks | — |

### Memory Optimization (Both Sides)

| Mod | What It Does | Notes |
|-----|-------------|-------|
| **FerriteCore** | Deduplicates immutable block state / model structures | **Essential for modpacks** |
| **ModernFix** | Reflection reduction, class load optimization, memory leak fixes | Use alongside FerriteCore |
| **Saturn** | Reorganizes buffer allocation and vertex caching | — |
| **AllTheLeaks** | Detects and patches circular-reference memory leaks at runtime | NeoForge 1.21.1 |
| **LazyDFU** | Defers DataFixerUpper until first use — saves ~200 MB RAM | **Only for < 1.20**; vanilla fixed this in 1.20+ |

### Startup Speed

| Mod | What It Does | Notes |
|-----|-------------|-------|
| **ModernFix** | Also reduces "Joining World" pipeline time | (listed above) |
| **Smooth Boot Reloaded** | Rebalances thread priorities at startup to prevent CPU spikes | NeoForge 1.20.x |
| **ThreadTweak Reforged** | Rebalances JVM thread priorities at runtime | NeoForge 1.21.5→1.19 |
| **Fastload** | Optimizes world-joining pipeline — shorter "Loading terrain" screen | NeoForge 1.20.1→1.18.2 |
| **Ksyxis** | Removes always-loaded spawn chunks from memory | NeoForge 1.21→1.8 |

### Server Logic / TPS (Server / Single-Player World Perf)

| Mod | What It Does | Notes |
|-----|-------------|-------|
| **Radium Reforged** | NeoForge Lithium port — AI, physics, ticking, chunk management | 20–40% MSPT reduction |
| **Moonrise** | Rewrites chunk system, entity tracking, collision (Paper-derived) | **Not compatible with C2ME or Starlight** |
| **Lithium** | Gold-standard optimization — NeoForge port exists | Use Radium if unavailable |
| **Adaptive Performance Tweaks** | Dynamically adjusts spawn rates / view distance when TPS drops | NeoForge 1.21→1.16 |
| **C2ME** | Concurrent chunk generation across multiple threads | Alpha for 1.21. **Not compatible with Moonrise** |
| **Alternate Current** | Deterministic redstone propagation — prevents cascade lag | NeoForge 1.21, 1.20.2 |
| **ScalableLux** | Parallel light propagation (successor to Starlight for 1.21+) | Beta for 1.21.x |
| **Starlight** | Full light engine rewrite — superseded by vanilla in 1.20+, use ScalableLux for 1.21 | — |
| **AI Improvements** | Better pathfinding — limits nodes, caches objectives | — |
| **Chunky** | Pre-generates chunks offline to eliminate in-session gen lag | Essential for servers |

### Recipe & Item Caching (Server)

| Mod | What It Does | Notes |
|-----|-------------|-------|
| **FastSuite** | Extends recipe caching to all JSON recipe types | NeoForge 1.21, 1.20.1 |
| **FastWorkbench** | Eliminates costly crafting table recipe pathfinding | NeoForge 1.21→1.20 |
| **FastFurnace** | Caches furnace recipes to skip per-tick verification | NeoForge 1.21→1.20 |

### Entity Count Reduction

| Mod | What It Does | Notes |
|-----|-------------|-------|
| **Clumps** | Merges nearby XP orbs into single large orbs | Essential for mob grinders |
| **Get It Together, Drops!** | Auto-merges ground item drops of the same type | NeoForge 1.21→1.15 |
| **Let Me Despawn** | Fixes vanilla mob despawn bug causing entity buildup | NeoForge 1.20.x |

### Shaders (Client)

| Mod | What It Does | Notes |
|-----|-------------|-------|
| **Iris** | Shader loader — native NeoForge support since 1.21.1 | Best option for 1.21.1+ |
| **NeOculus** | Iris fork maintained for NeoForge 1.21+ | Use if Iris NeoForge unavailable |
| **Oculus** | Iris fork for Forge/older NeoForge (1.20.x and below) | — |

---

## Compatibility Matrix

| Conflict | Resolution |
|----------|-----------|
| Embeddium vs Rubidium | Use Embeddium — Rubidium is deprecated |
| Moonrise vs C2ME | Install one only — both touch the chunk system |
| Moonrise vs Starlight/Lithium | Moonrise auto-disables overlapping features — no manual action needed |
| ScalableLux vs Starlight | Use ScalableLux for 1.21+; Starlight irrelevant above 1.20 |
| LazyDFU on 1.20.2+ | Remove it — vanilla addressed DFU in 1.20.2 |
| Iris vs Oculus | Iris for 1.21.1+; Oculus/NeOculus for older NeoForge |

---

## Downloads

- CurseForge NeoForge filter: https://www.curseforge.com/minecraft/mc-mods?gameVersion=1.21.1&modLoaders=neoforge
- Modrinth NeoForge filter: https://modrinth.com/mods?g=neoforge
- Curated performance collection (Modrinth): https://modrinth.com/collection/OKLUsu4U
- Embeddium: https://www.curseforge.com/minecraft/mc-mods/embeddium
- FerriteCore: https://www.curseforge.com/minecraft/mc-mods/ferritecore-fabric
- ModernFix: https://www.curseforge.com/minecraft/mc-mods/modernfix
- Entity Culling: https://www.curseforge.com/minecraft/mc-mods/entityculling
- Clumps: https://www.curseforge.com/minecraft/mc-mods/clumps
