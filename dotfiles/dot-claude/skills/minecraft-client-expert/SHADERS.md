# Shaders — Installation, Configuration, and Performance

## Shader Loader Options for NeoForge

| Loader | NeoForge Version | Status |
|--------|-----------------|--------|
| **Iris** (native) | 1.21.1+ | Recommended — official NeoForge support |
| **NeOculus** | 1.21+ | Use if Iris unavailable for your exact version |
| **Oculus** | 1.20.x and below | Iris fork for Forge/old NeoForge |
| OptiFine | None (Forge only) | Dead for modern NeoForge — avoid |

> OptiFine is effectively unmaintained for modded NeoForge. It conflicts with many mods and lags months behind each MC release. Iris + Embeddium gives better FPS and compatibility.

---

## Installation (Iris on NeoForge 1.21.1+)

1. Download Iris `.jar` from https://modrinth.com/mod/iris or https://www.curseforge.com/minecraft/mc-mods/irisshaders
2. Place in your instance's `mods/` folder
3. Ensure **Embeddium** is also installed (Iris on NeoForge requires it separately)
4. Place shader `.zip` files in `<instance>/minecraft/shaderpacks/`
5. In-game: **Options → Video Settings → Shader Packs** → select shader → Apply

**PrismLauncher path to shaderpacks**:
```
C:\Users\<user>\AppData\Roaming\PrismLauncher\instances\<InstanceName>\minecraft\shaderpacks\
```

---

## Shader Pack Tiers by GPU

### Low-End (Intel iGPU, GTX 750 Ti, GTX 1050, RX 560 or older)

| Shader | Why |
|--------|-----|
| **YoFPS** | Best FPS-per-visual ratio for weak hardware |
| **MakeUp – Ultra Fast** | Nearly every effect optional — surgical tuning |
| **Potato Shader** (RRe36) | Absolute minimum cost; subtle lighting only |
| **Sildur's Enhanced Default** | Near-vanilla look with minimal overhead |

Download: https://modrinth.com/shader/yofps · https://modrinth.com/shader/makeup-ultra-fast-shaders

### Mid-Range (GTX 1060–1660, RTX 2060, RX 580–6600)

| Shader | Settings |
|--------|---------|
| **Complementary Shaders** | Use Potato or Low profile; shadow distance 80 |
| **BSL Shaders** | Low preset; shadow quality 0.3×; clouds OFF |
| **Sildur's Vibrant Shaders** | Lite version |

Download: https://www.complementary.dev/shaders/ · https://modrinth.com/shader/bsl-shaders

### High-End (RTX 3060+, RX 6700+, RTX 4070+)

| Shader | Why |
|--------|-----|
| **Complementary Reimagined** | Cinematic quality, well-optimized, supports 1.8.9–1.21.x |
| **BSL Shaders** | Medium/High preset |
| **Rethinking Voxels** | Voxel-based GI, near RTX-quality |
| **Photon Shaders** | Modern PBR |

Download: https://modrinth.com/shader/complementary-reimagined · https://modrinth.com/shader/rethinking-voxels

---

## Settings That Impact FPS (Ranked by Cost)

### Critical — Disable/Reduce These First

| Setting | Recommended Value | FPS Recovered |
|---------|------------------|---------------|
| **Shadow Distance** | 80–96 blocks (default often 120) | Very high |
| **Shadow Resolution** | 1024 (default 2048) or OFF | Very high |
| **Volumetric Light / Light Shafts** | OFF | High (10–20 FPS) |
| **Volumetric Clouds** | OFF or Low | High |
| **Water Reflections** | OFF or Low | High |
| **Global Illumination / GI** | OFF | Very high (if present) |
| **Depth of Field** | OFF | Medium–High |

### Secondary — Adjust After Critical Settings

| Setting | Recommended | FPS Impact |
|---------|-------------|-----------|
| **Ambient Occlusion (SSAO)** | Medium or OFF | Medium |
| **Bloom** | OFF | Medium |
| **Motion Blur** | OFF | Low–Medium |
| **Render Quality / Resolution Scale** | Never above 1.0× | High if >1.0 |
| **Entity Shadows** | OFF or Low | Medium |
| **Reflections on transparent blocks** | OFF | Medium |

---

## Complementary Shaders — Performance Profile

1. Open Shader Pack Settings in-game
2. Select **Profile: Potato** or **Low**
3. Manual tweaks:
   - `Lighting → Shadow Distance`: 80 or 96
   - `Lighting → Shadow Resolution`: 1024
   - `Atmosphere → Volumetric Light`: OFF
   - `Atmosphere → Clouds`: OFF or Fast
   - `Water → Reflections`: OFF
   - `Post Processing → Bloom`: OFF
   - `Post Processing → Depth of Field`: OFF

Expected: +15–25 FPS vs default profile on same hardware.

---

## BSL Shaders — Low/Mid Performance Profile

1. In-game Shader Settings:
   - `Shadow → Shadow Distance`: 80
   - `Shadow → Shadow Resolution`: 1024 (or 512 for < GTX 1060)
   - `Shadow → Shadow Quality`: 0.3×
   - `Atmosphere → Clouds`: OFF
   - `Atmosphere → Weather`: OFF
   - `Water → Reflections`: OFF
   - `Post Processing → Bloom`: OFF
   - `Post Processing → Motion Blur`: OFF
   - `Lighting → Volumetric Light`: OFF

Expected on GTX 1060 at 1080p, 12 chunks: ~50–70 FPS.

---

## Disabling Clouds Properly (Two-Step)

**Vanilla `renderClouds:"false"` in `options.txt` is NOT enough when a shader is active.** Shader packs override Minecraft's cloud renderer with their own cloud system, so you must disable clouds in *both* places:

1. **Vanilla**: `options.txt` → `renderClouds:"false"` (kills the vanilla cloud layer in case the shader ever falls back).
2. **Shader settings**: open the shader's settings GUI (Options → Video Settings → Shader Pack Settings → Apply changes), or edit the shader's `.txt` config in `shaderpacks/`:
   - **Complementary Reimagined / Unbound**: `CLOUDS=Off` (or set `CLOUD_STYLE` to the Off value)
   - **EuphoriaPatches addon**: `CLOUD_QUALITY=0` to minimize, but the base Complementary `CLOUDS=Off` is the actual on/off toggle
   - **BSL Shaders**: `CLOUDS=false` and `CLOUDS_2D=false`
   - **Photon / Rethinking Voxels**: `CLOUDS=Off` in the shader settings GUI

If you change only the vanilla setting while a shader is loaded, clouds stay drawn by the shader and you save zero FPS.

The same dual-disable rule applies to other vanilla→shader-overridden effects: **fog, sky color, water visuals, weather effects** — disabling them in `options.txt` does nothing if the active shader replaces them.

---

## Minecraft Video Settings With Shaders Active

| Setting | Recommendation |
|---------|----------------|
| **Render Distance** | 10–12 chunks max with shaders |
| **Smooth Lighting** | Minimum or OFF (let shader handle it) |
| **Mipmap Levels** | 0 in modded (high cost, low visual gain with shaders) |
| **VSync** | OFF |
| **Smooth FPS** | OFF |
| **Fast Math (OptiFine/Embeddium Extra)** | ON |
| **Fast Render (OptiFine)** | **DISABLED** — breaks shaders |

---

## OptiFine vs Iris Comparison

| Factor | OptiFine | Iris + Embeddium |
|--------|---------|-----------------|
| FPS with same shader | Baseline | +20–40% faster |
| Mod compatibility | Frequently breaks | Designed to coexist |
| Update speed | Weeks–months per MC version | Days |
| NeoForge support | None | Native (1.21.1+) |
| Shader format | `.zip` | Same `.zip` — fully compatible |
| Architecture | Patches vanilla renderer | Builds on Embeddium/Sodium |

---

## Download Reference

| Resource | URL |
|----------|-----|
| Iris (official) | https://irisshaders.dev/ |
| Iris on Modrinth | https://modrinth.com/mod/iris |
| NeOculus (NeoForge 1.21+) | https://www.curseforge.com/minecraft/mc-mods/neoculus |
| Oculus (NeoForge 1.20.x) | https://www.curseforge.com/minecraft/mc-mods/oculus |
| Complementary Shaders | https://www.complementary.dev/shaders/ |
| Complementary Reimagined | https://modrinth.com/shader/complementary-reimagined |
| BSL Shaders | https://modrinth.com/shader/bsl-shaders |
| MakeUp Ultra Fast | https://modrinth.com/shader/makeup-ultra-fast-shaders |
| YoFPS | https://modrinth.com/shader/yofps |
| Potato Shader | https://modrinth.com/shader/potato |
| Sildur's Shaders | https://sildurs-shaders.github.io/ |
| shaderLABS Performance Guide | https://shaderlabs.org/wiki/Performance_Tips |
| Prism OptiFine Alternatives | https://prismlauncher.org/wiki/getting-started/install-of-alternatives/ |
