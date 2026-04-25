# Cookbook: Optimize a NeoForge Client Instance

A guided, end-to-end workflow for setting up or tuning a NeoForge Minecraft client instance on Windows for maximum FPS and stability.

---

## Phase 1 — Profile the System

Run this PowerShell block to gather hardware context before making recommendations:

```powershell
# Full system profile
$gpu = Get-CimInstance Win32_VideoController | Select-Object Name, @{N='VRAM_GB';E={[math]::Round($_.AdapterRAM/1GB,1)}}
$cpu = Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, @{N='MaxGHz';E={[math]::Round($_.MaxClockSpeed/1000,2)}}
$ramGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB,1)
$disks = Get-PhysicalDisk | Select-Object FriendlyName, MediaType

Write-Host "=== GPU ===" -ForegroundColor Cyan; $gpu | Format-List
Write-Host "=== CPU ===" -ForegroundColor Cyan; $cpu | Format-List
Write-Host "=== RAM ===" -ForegroundColor Cyan; Write-Host "Total: $ramGB GB"
Write-Host "=== Disks ===" -ForegroundColor Cyan; $disks | Format-Table
```

**Interpret results using [SYSTEM-PROFILING.md](../SYSTEM-PROFILING.md)** to determine:
- RAM budget for `-Xmx`
- Shader tier (Low / Mid / High)
- Whether SSD is available (affects chunk-gen strategy)

---

## Phase 2 — Interview (if hardware detection fails or is ambiguous)

Ask the user these questions in order:

1. **GPU model + VRAM** — e.g., "RTX 3070 8 GB"
2. **Total system RAM** — e.g., "16 GB"
3. **Modpack or mod count** — e.g., "Better MC, ~300 mods"
4. **Target FPS** — 30 stable / 60+ / 144+
5. **Shaders desired?** — Yes/No; if yes, which tier
6. **Current FPS and where lag occurs** — exploring, base, farms, etc.
7. **Java version currently configured** — check instance.cfg or PrismLauncher UI

---

## Phase 3 — Configure JVM Flags & Memory

### Step 3a — Choose Java Version

| Minecraft Version | Java Requirement |
|-------------------|-----------------|
| 1.21+ | Java 21 (use PrismLauncher auto-download) |
| 1.17–1.20.4 | Java 17 |
| 1.16.5 and below | Java 8 |

In PrismLauncher: **Edit Instance → Settings → Java installation → Override → Auto-detect or browse**.

### Step 3b — Set Memory

| System RAM | Recommended -Xmx |
|------------|------------------|
| 8 GB | 4096 MB |
| 16 GB | 6144–8192 MB |
| 32 GB | 8192–12288 MB |

Enable **Override memory** in instance settings. Set `MinMemAlloc` = `MaxMemAlloc`.

### Step 3c — Apply JVM Flags

Enable **Override Java arguments** and paste the appropriate flags:

**For Java 21 + NeoForge 1.21 (recommended)**:
```
-XX:+UseZGC -XX:+ZGenerational -XX:+AlwaysPreTouch -XX:+UseStringDeduplication -XX:+UnlockExperimentalVMOptions -XX:+AlwaysActAsServerClassMachine -XX:+DisableExplicitGC -XX:+UseNUMA -XX:ReservedCodeCacheSize=400M -XX:MetaspaceSize=512M
```

**For Java 17 + NeoForge 1.20.x (Aikar G1GC)**:
```
-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:ReservedCodeCacheSize=400M -XX:MetaspaceSize=512M
```

> Reference: User's BMC5 instance uses the ZGC flags above with 8192 MB and PermGen 1024. Use as a validated baseline.

---

## Phase 4 — Install Performance Mods

Add mods to `<instance>/minecraft/mods/`. Download from CurseForge or Modrinth.

### Minimum Stack (all modpacks)

| Mod | CurseForge |
|-----|-----------|
| Embeddium | https://www.curseforge.com/minecraft/mc-mods/embeddium |
| Embeddium Extra | (search CurseForge) |
| FerriteCore | https://www.curseforge.com/minecraft/mc-mods/ferritecore-fabric |
| ModernFix | https://www.curseforge.com/minecraft/mc-mods/modernfix |
| Entity Culling | https://www.curseforge.com/minecraft/mc-mods/entityculling |
| ImmediatelyFast | https://www.curseforge.com/minecraft/mc-mods/immediatelyfast |
| Clumps | https://www.curseforge.com/minecraft/mc-mods/clumps |

### Add for Large Modpacks (100+ mods)

| Mod | Purpose |
|-----|---------|
| FastSuite | Recipe cache |
| FastWorkbench | Crafting table optimization |
| FastFurnace | Furnace optimization |
| Radium Reforged | AI, physics, ticking |
| Dynamic FPS | Reduce FPS when unfocused |
| Alternate Current | Redstone cascade prevention |

See [NEOFORGE-MODS.md](../NEOFORGE-MODS.md) for full list.

---

## Phase 5 — Configure In-Game Video Settings

Launch the instance, enter a world, then apply these settings via Options → Video Settings:

| Setting | Value |
|---------|-------|
| Render Distance | 10 chunks (adjust after measuring FPS) |
| Simulation Distance | 8 chunks |
| Max Framerate | Unlimited |
| VSync | OFF |
| Graphics | Fast |
| Clouds | OFF |
| Particles | Minimal |
| Smooth Lighting | OFF (or let shader handle it) |
| Entity Shadows | OFF |
| Biome Blend | 3×3 |

Measure FPS with `F3`. Adjust Render Distance up if FPS > target; down if below.

---

## Phase 6 — Add Shaders (Optional)

If shaders are desired:

1. Install **Iris** (NeoForge 1.21.1+) from https://modrinth.com/mod/iris
2. Download a shader pack matching the GPU tier:
   - Low-end: YoFPS, MakeUp Ultra Fast
   - Mid: Complementary (Potato profile), BSL (Low preset)
   - High-end: Complementary Reimagined, BSL (Medium+)
3. Place `.zip` in `<instance>/minecraft/shaderpacks/`
4. In-game: Options → Video Settings → Shader Packs → select → Apply
5. Open shader settings and reduce:
   - Shadow Distance → 80–96
   - Shadow Resolution → 1024
   - Volumetric Light → OFF
   - Clouds → OFF
   - Water Reflections → OFF

See [SHADERS.md](../SHADERS.md) for per-shader-pack tuning guides.

---

## Phase 7 — Windows Optimizations

```powershell
# 1. Set High Performance power plan
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

# 2. Add Windows Defender exclusions (run as Admin)
Add-MpPreference -ExclusionPath "$env:APPDATA\PrismLauncher"
Add-MpPreference -ExclusionProcess "javaw.exe"
```

Also:
- Set NVIDIA/AMD GPU to "Prefer Maximum Performance" for `javaw.exe`
- Disable fullscreen optimizations on `javaw.exe` (Properties → Compatibility)
- Close Discord, browsers, and other heavy background apps before playing

---

## Phase 8 — Validate & Measure

1. Launch and enter a world
2. Press `F3` — note baseline FPS and memory usage
3. Explore for 2–3 minutes; note FPS in different scenarios (base, exploration, caves)
4. If FPS still below target:
   - Reduce Render Distance by 2
   - Lower shader shadow distance or switch to lower preset
   - Check `Memory` field in F3 — if >85%, increase `-Xmx`
   - Install Chunky and pre-generate chunks

### FPS Benchmarks by GPU Tier (no shaders, 12 chunks, NeoForge + optimization mods)

| GPU | Expected FPS |
|-----|-------------|
| GTX 1060 / RX 580 | 80–120 |
| RTX 2060 / RX 5700 | 120–200 |
| RTX 3070 / RX 6700 XT | 180–300+ |
| RTX 4080+ | 300+ (cap at monitor Hz) |

With shaders on Complementary Low: subtract ~50% from above values.

---

## Quick Checklist

- [ ] Java 21 configured (for NeoForge 1.21)
- [ ] Memory set (Min = Max, ≥ 50% of system RAM free for OS)
- [ ] ZGC Generational flags applied
- [ ] Embeddium installed
- [ ] FerriteCore + ModernFix installed
- [ ] Entity Culling installed
- [ ] ImmediatelyFast installed
- [ ] VSync OFF in-game
- [ ] Graphics set to Fast
- [ ] Power plan set to High Performance
- [ ] Windows Defender exclusions added
- [ ] (Optional) Iris + shader pack installed and tuned
