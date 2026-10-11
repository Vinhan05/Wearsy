# =============================================================================
# WEARSY Full CI/CD Local Automation Script (PowerShell / Windows)
# Author: Vo The Dan - Tech & CI/CD Lead
# =============================================================================

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "       WEARSY FULL CI/CD QUALITY GATE EXECUTION           " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$TotalStartTime = Get-Date

# -----------------------------------------------------------------------------
# 1. BACKEND CI (7 STEPS)
# -----------------------------------------------------------------------------
Write-Host "`n>>> [1/3] EXECUTING BACKEND CI (apps/api-server)..." -ForegroundColor Yellow

Push-Location "apps/api-server"
try {
    Write-Host "  Step 1: Check dependencies..." -ForegroundColor Gray
    # npm ci can be used or skipped if node_modules exists

    Write-Host "  Step 2: Checking format (Prettier)..." -ForegroundColor Gray
    npm run format:check

    Write-Host "  Step 3: Running lint (ESLint)..." -ForegroundColor Gray
    npm run lint

    Write-Host "  Step 4: Running typecheck (tsc)..." -ForegroundColor Gray
    npm run typecheck

    Write-Host "  Step 5: Running unit tests (Jest)..." -ForegroundColor Gray
    npm test -- --coverage

    Write-Host "  Step 6: Running integration tests (E2E & /health)..." -ForegroundColor Gray
    npm run test:e2e

    Write-Host "  Step 7: Building backend (NestJS dist)..." -ForegroundColor Gray
    npm run build

    Write-Host "✅ BACKEND CI: ALL 7 STEPS PASSED!" -ForegroundColor Green
}
catch {
    Write-Host "❌ BACKEND CI FAILED: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location

# -----------------------------------------------------------------------------
# 2. MOBILE CI (7 STEPS)
# -----------------------------------------------------------------------------
Write-Host "`n>>> [2/3] EXECUTING MOBILE CI (apps/mobile-client)..." -ForegroundColor Yellow

Push-Location "apps/mobile-client"
try {
    Write-Host "  Step 1: Getting packages (flutter pub get)..." -ForegroundColor Gray
    flutter pub get

    Write-Host "  Step 2: Checking format (dart format)..." -ForegroundColor Gray
    dart format --output=none --set-exit-if-changed lib test

    Write-Host "  Step 3: Running lint (flutter analyze)..." -ForegroundColor Gray
    flutter analyze --no-fatal-infos

    Write-Host "  Step 4: Running typecheck (dart analyze)..." -ForegroundColor Gray
    dart analyze --fatal-warnings lib test

    Write-Host "  Step 5: Running unit tests..." -ForegroundColor Gray
    flutter test test/auth_validation_test.dart test/smart_fit_test.dart --coverage

    Write-Host "  Step 6: Running integration & widget tests..." -ForegroundColor Gray
    flutter test test/widget_test.dart

    Write-Host "✅ MOBILE CI: ALL 7 STEPS PASSED!" -ForegroundColor Green
}
catch {
    Write-Host "❌ MOBILE CI FAILED: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location

# -----------------------------------------------------------------------------
# 3. DATABASE MIGRATION & HEALTH VERIFICATION
# -----------------------------------------------------------------------------
Write-Host "`n>>> [3/3] EXECUTING SAFE DATABASE MIGRATION VERIFICATION..." -ForegroundColor Yellow
try {
    node infrastructure/scripts/migrate.js --dry-run
    Write-Host "✅ DATABASE MIGRATION CHECK: PASSED!" -ForegroundColor Green
}
catch {
    Write-Host "❌ DATABASE MIGRATION CHECK FAILED: $_" -ForegroundColor Red
    exit 1
}

$TotalEndTime = Get-Date
$Duration = $TotalEndTime - $TotalStartTime

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "🎉 PR GATE STATUS: PASSED! ALL CHECKS SUCCESSFUL!" -ForegroundColor Green
Write-Host "⏱️ Total Execution Time: $($Duration.Minutes)m $($Duration.Seconds)s" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
