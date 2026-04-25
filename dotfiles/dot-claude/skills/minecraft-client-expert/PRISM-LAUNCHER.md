# PrismLauncher — Instance Management & Configuration

## Directory Structure

```
C:\Users\<user>\AppData\Roaming\PrismLauncher\
├── prismlauncher.cfg          ← global launcher settings
├── accounts.json              ← Microsoft accounts
├── java/                      ← bundled JREs (auto-downloaded)
│   └── java-runtime-delta/
├── libraries/                 ← Maven dependency cache
├── assets/                    ← Minecraft asset cache
├── instances/
│   ├── instgroups.json        ← instance folder grouping
│   ├── <InstanceName>/
│   │   ├── instance.cfg       ← per-instance settings
│   │   ├── mmc-pack.json      ← component manifest (Minecraft + loader)
│   │   ├── modlist.html       ← generated mod list (read-only reference)
│   │   ├── minecraft/         ← actual game directory
│   │   │   ├── mods/
│   │   │   ├── config/
│   │   │   ├── shaderpacks/
│   │   │   ├── resourcepacks/
│   │   │   └── saves/
│   │   └── flame/             ← CurseForge modpack metadata
└── logs/
```

---

## instance.cfg Reference

INI format. All JVM and memory overrides live here.

```ini
[General]
# Identity
name=My Instance
InstanceType=OneSix
iconKey=default

# Memory (only applied when OverrideMemory=true)
OverrideMemory=true
MaxMemAlloc=8192       ← heap max in MB
MinMemAlloc=8192       ← set equal to Max to prevent GC resize pressure
PermGen=1024           ← MetaSpace / PermGen in MB

# JVM Flags (only applied when OverrideJavaArgs=true)
OverrideJavaArgs=true
JvmArgs=-XX:+UseZGC -XX:+ZGenerational -XX:+AlwaysPreTouch -XX:+UseStringDeduplication -XX:+UnlockExperimentalVMOptions -XX:+AlwaysActAsServerClassMachine -XX:+DisableExplicitGC -XX:+UseNUMA -XX:ReservedCodeCacheSize=400M -XX:MetaspaceSize=512M

# Java path (only applied when OverrideJavaLocation=true)
OverrideJavaLocation=true
JavaPath=C:/Users/<user>/AppData/Roaming/PrismLauncher/java/java-runtime-delta/bin/javaw.exe
JavaVersion=21.0.7
JavaVendor=Microsoft

# Window
LaunchMaximized=false
MinecraftWinWidth=1280
MinecraftWinHeight=720
CloseAfterLaunch=false
ShowConsole=false
```

### Override Logic

If an `Override*=false`, the global value from `prismlauncher.cfg` is used.
If an `Override*=true`, the instance-specific value takes precedence.

| Override Flag | Controls |
|--------------|---------|
| `OverrideMemory` | `MaxMemAlloc`, `MinMemAlloc`, `PermGen` |
| `OverrideJavaArgs` | `JvmArgs` |
| `OverrideJavaLocation` | `JavaPath`, `JavaVersion`, `JavaVendor` |
| `OverrideCommands` | Pre/post-launch commands |
| `OverrideEnv` | Environment variables |

---

## mmc-pack.json Reference

Auto-generated component manifest — do not edit manually.

```json
{
  "formatVersion": 1,
  "components": [
    {
      "uid": "org.lwjgl3",
      "version": "3.3.3",
      "cachedName": "LWJGL 3",
      "dependencyOnly": true
    },
    {
      "uid": "net.minecraft",
      "version": "1.21.1",
      "cachedName": "Minecraft",
      "important": true
    },
    {
      "uid": "net.neoforged",
      "version": "21.1.228",
      "cachedName": "NeoForge"
    }
  ]
}
```

**Component UIDs**:
- `net.minecraft` — Minecraft version
- `net.neoforged` — NeoForge loader
- `net.minecraftforge` — Forge loader
- `org.lwjgl3` — LWJGL 3 (graphics/audio backend)
- `com.mumfrey.liteloader` — LiteLoader (legacy)

---

## Global Config (prismlauncher.cfg)

```ini
[General]
JavaPath=                          ← empty = auto-detect
MaxMemAlloc=4096                   ← global default heap
MinMemAlloc=512                    ← global default min heap
JvmArgs=                           ← global JVM flags (empty = none)
PermGen=128
AutomaticJavaDownload=true         ← download JREs automatically
AutomaticJavaSwitch=true           ← switch JRE per MC version
Language=fr                        ← UI language
ApplicationTheme=dark
InstanceDir=instances
CentralModsDir=mods
```

---

## Per-Instance Java Setup (UI Steps)

1. Right-click instance → **Edit** → **Settings** tab
2. Enable **Java installation** checkbox → select or browse JRE
3. Enable **Java memory** checkbox → set Min/Max
4. Enable **Java arguments** checkbox → paste JVM flags
5. Click **Close** — settings saved to `instance.cfg`

---

## PrismLauncher PowerShell Helpers

```powershell
# List all instances and their RAM allocation
$base = "$env:APPDATA\PrismLauncher\instances"
Get-ChildItem $base -Directory |
  Where-Object { $_.Name -ne '.tmp' } |
  ForEach-Object {
    $cfg = Get-Content "$($_.FullName)\instance.cfg" -Raw
    $max = [regex]::Match($cfg, 'MaxMemAlloc=(\d+)').Groups[1].Value
    $jvmOverride = [regex]::Match($cfg, 'OverrideJavaArgs=(true|false)').Groups[1].Value
    [PSCustomObject]@{
      Instance     = $_.Name
      MaxRAM_MB    = $max
      CustomJVM    = $jvmOverride
    }
  } | Format-Table -AutoSize

# Read JVM flags for a specific instance
$inst = "Better MC [NEOFORGE] BMC5"
$cfg = Get-Content "$env:APPDATA\PrismLauncher\instances\$inst\instance.cfg" -Raw
[regex]::Match($cfg, 'JvmArgs=(.+)').Groups[1].Value

# Find installed mods in an instance
$inst = "Better MC [NEOFORGE] BMC5"
Get-ChildItem "$env:APPDATA\PrismLauncher\instances\$inst\minecraft\mods" |
  Select-Object Name | Sort-Object Name
```

---

## Known Good Configuration (User Reference)

**Better MC [NEOFORGE] BMC5** on this machine is a validated baseline:

```ini
MaxMemAlloc=8192
MinMemAlloc=8192
PermGen=1024
OverrideMemory=true
OverrideJavaArgs=true
JvmArgs=-XX:+UseZGC -XX:+ZGenerational -XX:+AlwaysPreTouch -XX:+UseStringDeduplication -XX:+UnlockExperimentalVMOptions -XX:+AlwaysActAsServerClassMachine -XX:+DisableExplicitGC -XX:+UseNUMA -XX:ReservedCodeCacheSize=400M
JavaPath=C:/Users/rapha/AppData/Roaming/PrismLauncher/java/java-runtime-delta/bin/javaw.exe
JavaVersion=21.0.7
JavaVendor=Microsoft
```

Use this as a starting template for new NeoForge 1.21.1 instances on this machine.

---

## Common Issues

| Problem | Cause | Fix |
|---------|-------|-----|
| Instance won't launch | Wrong Java version | Enable AutomaticJavaSwitch or select correct JRE |
| Game crashes immediately | JVM flag not supported by Java version | Remove `ZGenerational` if Java < 21 |
| Memory settings not applied | `OverrideMemory=false` | Enable override in instance settings |
| Instance uses wrong Java | `OverrideJavaLocation=false` | Enable override and set Java path |
| Modpack won't update | `ManagedPack=true` but no internet | Check CurseForge/Modrinth API connectivity |
| Long "Downloading libraries" | First launch or corrupted cache | Delete `libraries/` folder and relaunch |
