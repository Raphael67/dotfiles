---
name: minecraft-client-expert
description: Expert knowledge for Minecraft Java Edition client optimization on Windows — FPS settings, NeoForge performance mods, shader configuration (Iris/Oculus), JVM flags, and PrismLauncher instance management. Auto-loads when discussing Minecraft performance, mods, shaders, or configuration.
triggers:
  - minecraft
  - neoforge
  - minecraft fps
  - minecraft mods
  - optifine
  - iris shaders
  - oculus mod
  - embeddium
  - prism launcher
  - prismlauncher
  - shader pack
  - jvm flags minecraft
  - minecraft optimization
  - java edition minecraft
invocable: true
---

# Minecraft Client Expert

Comprehensive reference for Minecraft Java Edition client optimization on Windows.
Scope: **client-side FPS, NeoForge modded performance, shaders (Iris/Oculus), JVM tuning, PrismLauncher management.**

## Quick Reference

| Topic | File | Use When |
|-------|------|----------|
| Vanilla FPS & Windows settings | [FPS-OPTIMIZATION.md](FPS-OPTIMIZATION.md) | Low FPS without mods, in-game settings |
| Shader installation & config | [SHADERS.md](SHADERS.md) | Iris/Oculus setup, per-tier shader tuning |
| NeoForge performance mods | [NEOFORGE-MODS.md](NEOFORGE-MODS.md) | Building a performance mod stack |
| JVM flags & Java selection | [JVM-FLAGS.md](JVM-FLAGS.md) | Memory allocation, GC flags, Java version |
| PrismLauncher config | [PRISM-LAUNCHER.md](PRISM-LAUNCHER.md) | Per-instance settings, override system |
| Hardware profiling (PowerShell) | [SYSTEM-PROFILING.md](SYSTEM-PROFILING.md) | Detecting GPU/CPU/RAM on Windows |
| Full optimization workflow | [cookbook/optimize-instance.md](cookbook/optimize-instance.md) | New instance setup, end-to-end tuning |

## Scope

- **Edition**: Java Edition only
- **Loader**: NeoForge (primary), Forge (secondary)
- **Platform**: Windows only (PowerShell for system commands)
- **Launcher**: PrismLauncher
- **Focus**: Client FPS, shaders, modded performance

## Core Principles

1. **Embeddium > OptiFine** for NeoForge. OptiFine is unmaintained for modern modded play.
2. **Iris/NeOculus > OptiFine shaders** — better FPS, mod compatibility, faster updates.
3. **ZGC Generational > G1GC** for Java 21+ clients. Lower pause times, better frame consistency.
4. **FerriteCore + ModernFix** are non-negotiable in any modpack for RAM reduction.
5. **Always profile first** — run hardware detection before recommending settings.

## Known Configurations

**User's BMC5 instance (NeoForge 1.21.1)** is a validated reference baseline:
- JVM: `-XX:+UseZGC -XX:+ZGenerational -XX:+AlwaysPreTouch -XX:+UseStringDeduplication -XX:+UnlockExperimentalVMOptions -XX:+AlwaysActAsServerClassMachine -XX:+DisableExplicitGC -XX:+UseNUMA -XX:ReservedCodeCacheSize=400M`
- Memory: 8192 MB min/max, PermGen 1024
- Java: Microsoft JDK 21 (bundled by PrismLauncher)

## When to Read Reference Files

**Read FPS-OPTIMIZATION.md when:**
- User reports low FPS without a clear cause
- Asking for vanilla/base game settings to tweak
- Windows-level GPU and process optimizations needed

**Read SHADERS.md when:**
- Installing shaders for the first time
- Shader FPS is too low — need to tune settings
- Choosing between shader packs for a given GPU tier

**Read NEOFORGE-MODS.md when:**
- Building or auditing a performance mod stack
- Diagnosing mod compatibility (Moonrise vs C2ME, Embeddium vs Rubidium)
- Looking for the right mod for a specific bottleneck (RAM, entity lag, startup)

**Read JVM-FLAGS.md when:**
- Configuring memory allocation (Xmx/Xms)
- Choosing garbage collector (ZGC vs G1GC)
- Selecting Java version for a Minecraft version
- Crashes with OutOfMemoryError or severe GC pauses

**Read PRISM-LAUNCHER.md when:**
- Creating or importing an instance
- Configuring per-instance Java/memory overrides
- Understanding instance.cfg and mmc-pack.json schemas

**Read SYSTEM-PROFILING.md when:**
- Starting a new optimization session without hardware info
- Need PowerShell commands to detect GPU, VRAM, CPU cores, RAM
- Checking installed Java versions on Windows

**Read cookbook/optimize-instance.md when:**
- Setting up a new NeoForge instance from scratch
- Doing a full optimization pass on an existing instance
- User wants a guided, step-by-step workflow
