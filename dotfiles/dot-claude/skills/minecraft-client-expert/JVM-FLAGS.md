# JVM Flags & Java Configuration

## Java Version Selection

| Minecraft Version | Required Java | Recommended |
|-------------------|--------------|-------------|
| 1.21+ | Java 21+ | Microsoft JDK 21 or Eclipse Temurin 21 |
| 1.20.5 – 1.20.6 | Java 21+ | Eclipse Temurin 21 |
| 1.17 – 1.20.4 | Java 17+ | Eclipse Temurin 17 |
| 1.16.5 and older | Java 8 | Eclipse Temurin 8 |

**On Windows**, download as `.msi` installer, architecture x64.
- Eclipse Temurin: https://adoptium.net
- Microsoft JDK: bundled automatically by PrismLauncher via `AutomaticJavaDownload=true`

**Avoid**:
- Oracle JDK (licensing restrictions)
- OpenJ9 (incompatible with many mods)
- GraalVM Native Image (not supported for Minecraft runtime)
- Headless JRE builds (no GUI — Minecraft will not start)

---

## Memory Allocation

### Recommended Xmx by total system RAM

| System RAM | Vanilla / Lightly Modded | Heavy Modpack (100+ mods) |
|------------|--------------------------|---------------------------|
| 8 GB | 3–4 GB | 4 GB (max safe) |
| 16 GB | 4–6 GB | 6–8 GB |
| 32 GB | 6–8 GB | 8–12 GB |

**Rules**:
- Set `-Xms` = `-Xmx` (prevents GC pressure from heap resizing)
- Leave at least 4 GB free for Windows + other apps
- More RAM ≠ more FPS above the heap demand ceiling; over-allocation wastes ZGC bandwidth
- PermGen / MetaSpace (`-XX:MetaspaceSize`) should be 256–512 MB for vanilla, 512–1024 MB for heavy modpacks

---

## Recommended JVM Flags

### Modern ZGC Flags (Java 21+) — Recommended for NeoForge 1.21

These are validated by the user's BMC5 instance (NeoForge 1.21.1, 8 GB RAM):

```
-Xms8G -Xmx8G
-XX:+UseZGC
-XX:+ZGenerational
-XX:+AlwaysPreTouch
-XX:+UseStringDeduplication
-XX:+UnlockExperimentalVMOptions
-XX:+AlwaysActAsServerClassMachine
-XX:+DisableExplicitGC
-XX:+UseNUMA
-XX:ReservedCodeCacheSize=400M
-XX:MetaspaceSize=512M
```

**Flag explanations**:
- `UseZGC` — Z Garbage Collector: ultra-low pause times (<1 ms), better frame consistency than G1GC
- `ZGenerational` — Generational ZGC (Java 21+): further reduces GC overhead by separating short-lived and long-lived objects
- `AlwaysPreTouch` — Commits all heap pages at startup; avoids OS page-fault stalls mid-game
- `UseStringDeduplication` — Deduplicates identical String objects in the heap; saves 5–15% RAM in modpacks
- `AlwaysActAsServerClassMachine` — Enables server-class JVM optimizations (JIT tiers, thread priorities)
- `DisableExplicitGC` — Prevents mods from triggering `System.gc()` which causes GC pauses
- `UseNUMA` — Improves memory locality on multi-socket or multi-CCX CPUs
- `ReservedCodeCacheSize=400M` — JIT compiled code cache; prevents JIT deoptimization on large modpacks

### Aikar's G1GC Flags (Java 17 / legacy fallback)

For Minecraft 1.17–1.20.4 or when ZGC is unavailable:

```
-Xms6G -Xmx6G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1
```

Source: https://docs.papermc.io/paper/aikars-flags

---

### brucethemoose Benchmarked Client Flags (G1GC, Java 17+)

Benchmarked for client-side — lower `MaxGCPauseMillis`, different region sizing vs. Aikar's server-oriented flags.

```
-Xms8G -Xmx8G -XX:+UnlockExperimentalVMOptions -XX:+UnlockDiagnosticVMOptions -XX:+AlwaysActAsServerClassMachine -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+UseNUMA -XX:NmethodSweepActivity=1 -XX:ReservedCodeCacheSize=400M -XX:NonNMethodCodeHeapSize=12M -XX:ProfiledCodeHeapSize=194M -XX:NonProfiledCodeHeapSize=194M -XX:-DontCompileHugeMethods -XX:MaxNodeLimit=240000 -XX:NodeLimitFudgeFactor=8000 -XX:+UseVectorCmov -XX:+PerfDisableSharedMem -XX:+UseFastUnorderedTimeStamps -XX:+UseCriticalJavaThreadPriority -XX:ThreadPriorityPolicy=1 -XX:AllocatePrefetchStyle=3 -XX:+UseG1GC -XX:MaxGCPauseMillis=37 -XX:G1HeapRegionSize=16M -XX:G1NewSizePercent=23 -XX:G1ReservePercent=20 -XX:SurvivorRatio=32 -XX:G1MixedGCCountTarget=3 -XX:G1HeapWastePercent=20 -XX:InitiatingHeapOccupancyPercent=10 -XX:G1RSetUpdatingPauseTimePercent=0 -XX:MaxTenuringThreshold=1 -XX:G1SATBBufferEnqueueingThresholdPercent=30 -XX:G1ConcMarkStepDurationMillis=5.0 -XX:G1ConcRSHotCardLimit=16 -XX:G1ConcRefinementServiceIntervalMillis=150 -XX:GCTimeRatio=99
```

Source: https://github.com/brucethemoose/Minecraft-Performance-Flags-Benchmarks

---

### Obydux Minimal ZGC Flags (Java 21+)

Minimal, clean ZGC flags (no experimental noise):

```
-Xms8G -Xmx8G -XX:+UseZGC -XX:+ZGenerational -XX:+AlwaysPreTouch -XX:+UseStringDeduplication -XX:TrimNativeHeapInterval=5000
```

Source: https://github.com/Obydux/Minecraft-startup-flags

---

## PrismLauncher Configuration

### Per-Instance (Edit Instance → Settings → Java)

Enable **Override Java arguments** and **Override memory** to apply per-instance settings.

**Fields in instance.cfg**:
```ini
OverrideMemory=true
MaxMemAlloc=8192
MinMemAlloc=8192
PermGen=1024
OverrideJavaArgs=true
JvmArgs=-XX:+UseZGC -XX:+ZGenerational -XX:+AlwaysPreTouch -XX:+UseStringDeduplication -XX:+UnlockExperimentalVMOptions -XX:+AlwaysActAsServerClassMachine -XX:+DisableExplicitGC -XX:+UseNUMA -XX:ReservedCodeCacheSize=400M -XX:MetaspaceSize=512M
```

### Java Auto-Detection

PrismLauncher's global config (`prismlauncher.cfg`):
```ini
AutomaticJavaDownload=true
AutomaticJavaSwitch=true
```
With these enabled, PrismLauncher downloads and selects the correct JRE per Minecraft version automatically.

---

## Garbage Collector Comparison

| GC | Best For | Pause Times | RAM Overhead |
|----|----------|-------------|--------------|
| ZGC + Generational | Java 21+, NeoForge 1.21 | < 1 ms | Low |
| G1GC (Aikar) | Java 17, 1.17–1.20.4 | 10–200 ms | Moderate |
| Shenandoah | Alternative low-pause | < 10 ms | Low |
| Serial GC | Never for Minecraft | Very high | Lowest |

**Recommendation**: Always use ZGC Generational on Java 21. Do not use G1GC on 1.21+ instances.

---

## Common JVM Issues

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `OutOfMemoryError: Java heap space` | Xmx too low for modpack | Increase `-Xmx` |
| `OutOfMemoryError: Metaspace` | MetaspaceSize too low | Add `-XX:MetaspaceSize=512M` or higher |
| Stutters every few seconds | G1GC pauses | Switch to ZGC Generational |
| Long startup time | No LazyDFU (< 1.20) or MetaspaceSize too small | Add LazyDFU mod or increase MetaspaceSize |
| JVM crashes with ZGC | Java < 21 | ZGenerational requires Java 21+ |
| Massive GC pauses after hours of play | `System.gc()` calls from mods | Ensure `DisableExplicitGC` is set |
