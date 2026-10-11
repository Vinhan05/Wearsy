# CRITICAL RULE FOR ALL AI CODING AGENTS: APK VERSIONING STANDARD

Whenever performing changes or building an APK for `apps/mobile-client`:
1. Current base version: `beta 1.0.0` (Build 1).
2. Every subsequent release MUST strictly increment the patch version (+0.0.1) and build number (+1):
   - Example sequence: `1.0.0` -> `1.0.1` -> `1.0.2` -> `1.0.3`...
3. Always update:
   - `apps/mobile-client/pubspec.yaml` -> `version: 1.0.x+N`
   - `apps/mobile-client/lib/core/constants/app_version.dart` -> `versionName = 'beta 1.0.x'`, `buildNumber = N`.
4. Refer to [VERSIONING_GUIDE.md](../../VERSIONING_GUIDE.md) for full instructions and changelog.
