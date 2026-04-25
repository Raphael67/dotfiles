# FPS Optimization — Vanilla Settings & Windows

## In-Game Video Settings

### Critical Settings (highest FPS impact)

| Setting | Recommended | Notes |
|---------|-------------|-------|
| **Render Distance** | 8–12 chunks | Never exceed 12 with shaders; 6–8 for low-end |
| **Simulation Distance** | 6–8 chunks | Lower than render distance; affects ticking |
| **Max Framerate** | Unlimited (or monitor Hz) | Uncapped avoids VSync input lag |
| **VSync** | OFF | Causes FPS dips and input lag — disable |
| **Graphics** | Fast | "Fancy" enables leaf transparency, 3D leaves — costly |
| **Clouds** | OFF or Fast | "Fancy" clouds are expensive |
| **Particles** | Minimal | "All" doubles particle-related CPU load |
| **Smooth Lighting** | OFF or Minimum | Or let shaders handle it entirely |
| **Entity Shadows** | OFF | Small blobs under entities — non-trivial cost |
| **Biome Blend** | 3×3 or OFF | 15×15 (max) is very CPU-heavy |

### Secondary Settings

| Setting | Recommended | Notes |
|---------|-------------|-------|
| **Mipmap Levels** | 0 or 2 | High mipmap = texture blur at distance; minor cost |
| **Entity Distance** | 75–100% | Reduces entity render distance |
| **FOV** | 70–90 | Lower FOV = fewer entities rendered |
| **GUI Scale** | 2–3 | Has minor effect; higher scales slightly cheaper |
| **Fullscreen** | ON | Borderless windowed can reduce FPS on Windows |
| **Fullscreen Resolution** | Native | Avoid supersampling |

### OptiFine-Specific Settings (if applicable)

| Setting | Recommended |
|---------|-------------|
| Fast Render | **DISABLED** — incompatible with most shaders |
| Fast Math | ON — minor FPS gain, imperceptible visual change |
| Smooth FPS | OFF — caps framerate artificially |
| Dynamic FOV | OFF — reduces motion processing |
| Render Regions | ON — batches chunk rendering |
| Smart Animations | ON — pauses off-screen animations |

> **Note**: For NeoForge 1.21+, prefer Embeddium + Embeddium Extra over OptiFine. OptiFine is unmaintained for modern NeoForge and breaks many mods.

---

## Windows-Level Optimizations

### Power Plan

```powershell
# Set to High Performance (or Ultimate Performance if available)
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

# List all plans to find Ultimate Performance
powercfg /list
```

Or via Settings → Power & sleep → Additional power settings → High Performance.

### Process Priority

Set `javaw.exe` to High priority after launching Minecraft:

```powershell
# In PowerShell (run after Minecraft starts)
$proc = Get-Process javaw -ErrorAction SilentlyContinue
if ($proc) {
    $proc.PriorityClass = 'High'
    "Priority set to High for PID $($proc.Id)"
}
```

Or manually: Task Manager → Details → Right-click `javaw.exe` → Set priority → High.

### GPU Driver Settings (NVIDIA)

Via NVIDIA Control Panel → Manage 3D Settings → Program Settings → Add `javaw.exe`:

| Setting | Value |
|---------|-------|
| Power management mode | Prefer maximum performance |
| OpenGL rendering GPU | Your discrete GPU (not integrated) |
| Texture filtering – Quality | High performance |
| Vertical sync | Off |
| Threaded optimization | On |
| Shader cache size | Unlimited |

### GPU Driver Settings (AMD)

Via AMD Software → Gaming → Add `javaw.exe`:

| Setting | Value |
|---------|-------|
| Radeon Chill | Disabled |
| Wait for Vertical Refresh | Always Off |
| OpenGL Triple Buffering | Enabled |
| Texture Filtering Quality | Performance |

### Disable Fullscreen Optimizations (Windows)

Right-click `javaw.exe` (usually in `C:\Program Files\Eclipse Adoptium\...` or PrismLauncher's java folder) → Properties → Compatibility → ✓ **Disable fullscreen optimizations** + ✓ **Override high DPI scaling**.

### Close Background Apps

High-impact apps to close before playing:
- Discord (use web version or disable hardware acceleration)
- Browsers with many tabs
- OBS / recording software (if not streaming)
- Windows Update (check for active downloads in Task Manager)
- Antivirus real-time scanning — add Minecraft and Java dirs to exclusions

### Windows Defender Exclusions (PowerShell, Admin)

```powershell
# Add exclusions for common Minecraft paths
Add-MpPreference -ExclusionPath "$env:APPDATA\PrismLauncher"
Add-MpPreference -ExclusionPath "$env:APPDATA\.minecraft"
Add-MpPreference -ExclusionProcess "javaw.exe"
Add-MpPreference -ExclusionProcess "java.exe"
```

---

## Texture Packs & Resolution

| Resolution | FPS Impact | Use When |
|------------|-----------|----------|
| 16×16 (default) | Baseline | Always safe |
| 32×32 | −5 to −10 FPS | Minor quality bump |
| 64×64 | −10 to −20 FPS | Mid-range GPU required |
| 128×128+ | −20 to −40+ FPS | High VRAM (8+ GB) required |
| 8×8 | +5 to +10 FPS | Extreme performance recovery |

---

## Chunk Loading & Pregeneration

Pre-generating chunks eliminates in-session chunk-gen stutters (one of the most common FPS complaint sources in exploration):

```
# Install Chunky mod, then in-game or server console:
/chunky center <x> <z>
/chunky radius 2000
/chunky start
```

Monitor progress with `/chunky status`. For single-player worlds, this runs in the background.

---

## Diagnosing FPS Drops

Use `F3` debug screen in-game:

| F3 Field | What It Tells You |
|----------|------------------|
| `fps` | Current frames per second |
| `C:` | Chunks rendered vs total loaded |
| `E:` | Entities rendered vs total |
| `Chunk updates` | High = chunk-loading bottleneck |
| `Memory: X% Y/Z MB` | Heap usage — if >85%, increase Xmx |
| `Allocated: X MB` | Current committed heap |
| `ms/tick` | Server tick time — >50ms = TPS drop |

Use **Spark** (`/spark profiler start` / `stop`) for detailed CPU profiling.
