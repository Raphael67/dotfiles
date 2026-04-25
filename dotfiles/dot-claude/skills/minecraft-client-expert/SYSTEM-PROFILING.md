# System Profiling — Windows / PowerShell

Run these PowerShell commands to gather hardware info before making optimization recommendations.
All commands use built-in Windows APIs — no extra tools needed.

## Full Profile (run all at once)

```powershell
# GPU
Get-CimInstance Win32_VideoController |
  Select-Object Name,
    @{N='VRAM_GB';E={[math]::Round($_.AdapterRAM/1GB,1)}},
    DriverVersion,
    VideoModeDescription |
  Format-List

# CPU
Get-CimInstance Win32_Processor |
  Select-Object Name, NumberOfCores, NumberOfLogicalProcessors,
    @{N='MaxGHz';E={[math]::Round($_.MaxClockSpeed/1000,2)}} |
  Format-List

# RAM
$ram = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory
"Total RAM: {0:N1} GB" -f ($ram/1GB)

# Disk type (SSD vs HDD)
Get-PhysicalDisk | Select-Object FriendlyName, MediaType, Size | Format-Table

# Windows version
(Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ProductName
[System.Environment]::OSVersion.Version
```

## Java Detection

```powershell
# All java.exe / javaw.exe on PATH
Get-Command java -ErrorAction SilentlyContinue | Select-Object Source
Get-Command javaw -ErrorAction SilentlyContinue | Select-Object Source

# Java version
& java -version 2>&1

# PrismLauncher bundled JRE
$prismJava = "$env:APPDATA\PrismLauncher\java"
if (Test-Path $prismJava) {
    Get-ChildItem $prismJava -Directory | ForEach-Object {
        $ver = & "$($_.FullName)\bin\java.exe" -version 2>&1 | Select-Object -First 1
        [PSCustomObject]@{ Runtime = $_.Name; Version = $ver }
    }
}
```

## PrismLauncher Instance Discovery

```powershell
$instances = "$env:APPDATA\PrismLauncher\instances"
Get-ChildItem $instances -Directory | Where-Object { $_.Name -ne '.tmp' } |
  ForEach-Object {
    $cfg = Get-Content "$($_.FullName)\instance.cfg" -ErrorAction SilentlyContinue
    $ram = ($cfg | Select-String 'MaxMemAlloc=(.+)').Matches.Groups[1].Value
    $jvm = ($cfg | Select-String 'JvmArgs=(.+)').Matches.Groups[1].Value
    [PSCustomObject]@{
      Instance   = $_.Name
      MaxRAM_MB  = $ram
      HasCustomJVM = ($jvm -and $jvm.Length -gt 0)
    }
  } | Format-Table
```

## Performance Baseline

```powershell
# CPU single-core indicator (useful to judge simulation headroom)
$cpu = Get-CimInstance Win32_Processor
"CPU: $($cpu.Name)"
"Cores/Threads: $($cpu.NumberOfCores) / $($cpu.NumberOfLogicalProcessors)"
"Max Clock: $([math]::Round($cpu.MaxClockSpeed/1000,2)) GHz"

# GPU driver date (old drivers = common FPS issue)
Get-CimInstance Win32_VideoController |
  Select-Object Name, DriverDate, DriverVersion | Format-List
```

## Interpreting Results

| Hardware | Recommendation |
|----------|----------------|
| VRAM < 4 GB | Avoid high-res texture packs; shader quality Low/Potato |
| VRAM 4–6 GB | Shader quality Low–Medium; shadow distance ≤ 80 |
| VRAM 8+ GB | Shader quality High; shadow distance 100–120 |
| RAM ≤ 8 GB total | Allocate max 4 GB to Minecraft (-Xmx4G) |
| RAM 16 GB | Allocate 6–8 GB (-Xmx6G to -Xmx8G) |
| RAM 32 GB | Allocate 8–12 GB (-Xmx8G to -Xmx12G) |
| CPU < 3.5 GHz single-core | Low simulation-distance, fewer entity mods |
| HDD (not SSD) | Pre-generate chunks; enable Smooth Chunk Save mod |

## Interview Questions (if hardware detection fails)

Ask the user:
1. GPU model and VRAM
2. Total system RAM
3. How many mods / which modpack
4. Target FPS (30 stable vs 60+ vs 144+)
5. Whether shaders are desired
6. Current FPS and where lag occurs (exploring, farms, base)
7. Java version currently used
8. Any recent changes (new mods, driver update, Windows update)
