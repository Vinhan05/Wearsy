#!/usr/bin/env bash
# =============================================================================
# WEARSY Full CI/CD Local Automation Script (Bash / Linux / macOS)
# Author: Vo The Dan - Tech & CI/CD Lead
# =============================================================================

set -e

echo "=========================================================="
echo "       WEARSY FULL CI/CD QUALITY GATE EXECUTION           "
echo "=========================================================="

START_TIME=$(date +%s)

# 1. BACKEND CI (7 STEPS)
echo -e "\n>>> [1/3] EXECUTING BACKEND CI (apps/api-server)..."
cd apps/api-server
npm run format:check
npm run lint
npm run typecheck
npm test -- --coverage
npm run test:e2e
npm run build
cd ../..
echo "✅ BACKEND CI: ALL 7 STEPS PASSED!"

# 2. MOBILE CI (7 STEPS)
echo -e "\n>>> [2/3] EXECUTING MOBILE CI (apps/mobile-client)..."
cd apps/mobile-client
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-fatal-infos
dart analyze --fatal-warnings lib test
flutter test test/auth_validation_test.dart test/smart_fit_test.dart --coverage
flutter test test/widget_test.dart
cd ../..
echo "✅ MOBILE CI: ALL 7 STEPS PASSED!"

# 3. DATABASE MIGRATION CHECK
echo -e "\n>>> [3/3] EXECUTING SAFE DATABASE MIGRATION VERIFICATION..."
node infrastructure/scripts/migrate.js --dry-run
echo "✅ DATABASE MIGRATION CHECK: PASSED!"

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo "=========================================================="
echo "🎉 PR GATE STATUS: PASSED! ALL CHECKS SUCCESSFUL!"
echo "⏱️ Total Execution Time: ${DURATION}s"
echo "=========================================================="
