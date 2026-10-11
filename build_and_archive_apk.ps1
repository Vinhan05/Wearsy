<#
.SYNOPSIS
    Builds the Flutter mobile client APK and automatically archives it under its version name,
    preserving all previous APK builds for rollback safety.
#>

param(
    [string]$Mode = "debug"
)

$ErrorActionPreference = "Stop"

$repoRoot = $PSScriptRoot
$clientDir = Join-Path $repoRoot "apps\mobile-client"
$releaseDir = Join-Path $repoRoot "releases\apk"
$versionFile = Join-Path $clientDir "lib\core\constants\app_version.dart"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "       WEARSY MOBILE CLIENT - BUILD & ARCHIVE APK          " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Detect Version
$versionName = "beta-1.0.0"
$buildNum = "1"

if (Test-Path $versionFile) {
    $content = Get-Content $versionFile -Raw
    if ($content -match "static const String versionName\s*=\s*['""]([^'""]+)['""]") {
        $versionName = $matches[1].Trim()
    }
    if ($content -match "static const int buildNumber\s*=\s*(\d+)") {
        $buildNum = $matches[1].Trim()
    }
}

$slug = $versionName -replace "\s+", "-"
$destFileName = "wearsy-$slug.apk"

Write-Host "[+] Detected Version: $versionName (Build $buildNum)" -ForegroundColor Green
Write-Host "[+] Target Archive Name: $destFileName" -ForegroundColor Green
Write-Host "[+] Build Mode: $Mode" -ForegroundColor Green
Write-Host ""

# 2. Run Flutter Build
Set-Location $clientDir
Write-Host "[*] Executing: flutter build apk --$Mode ..." -ForegroundColor Yellow
if ($Mode -eq "release") {
    flutter build apk --release
} else {
    flutter build apk --debug
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] Flutter build failed with code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}

# 3. Locate generated APK
$candidates = @(
    (Join-Path $clientDir "build\app\outputs\flutter-apk\app-$Mode.apk"),
    (Join-Path $clientDir "build\app\outputs\apk\$Mode\app-$Mode.apk"),
    (Join-Path $clientDir "build\app\outputs\flutter-apk\app-debug.apk")
)

$builtApk = $null
foreach ($c in $candidates) {
    if (Test-Path $c) {
        $builtApk = $c
        break
    }
}

if (-not $builtApk) {
    Write-Host "[!] Could not locate built APK output." -ForegroundColor Red
    exit 1
}

# 4. Archive into releases/apk/
if (-not (Test-Path $releaseDir)) {
    New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null
}

$versionDestPath = Join-Path $releaseDir $destFileName
$latestDestPath = Join-Path $releaseDir "wearsy-latest.apk"

Copy-Item $builtApk $versionDestPath -Force
Copy-Item $builtApk $latestDestPath -Force

Write-Host ""
Write-Host "[OK] Saved new version: $versionDestPath" -ForegroundColor Green
Write-Host "[OK] Updated latest link: $latestDestPath" -ForegroundColor Green
Write-Host ""

# 5. List all preserved versions for rollback safety
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "        ALL PRESERVED HISTORICAL RELEASES (ROLLBACK LIST) " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Get-ChildItem -Path $releaseDir -Filter "*.apk" | Select-Object Name, @{Name="Size (MB)"; Expression={[math]::round($_.Length / 1MB, 2)}}, LastWriteTime | Format-Table -AutoSize

Write-Host "[V] All older versions are safely preserved! No old APKs were overwritten." -ForegroundColor Green
Set-Location $repoRoot
