# CRITICAL RULE FOR ALL AI CODING AGENTS: APK VERSIONING & ARCHIVAL STANDARD

Whenever performing changes or building an APK for `apps/mobile-client`:
1. Current base version: `beta 1.0.0` (Build 1).
2. Every subsequent release MUST strictly increment the patch version (+0.0.1) and build number (+1):
   - Example sequence: `1.0.0` -> `1.0.1` -> `1.0.2` -> `1.0.3`...
3. Always update:
   - `apps/mobile-client/pubspec.yaml` -> `version: 1.0.x+N`
   - `apps/mobile-client/lib/core/constants/app_version.dart` -> `versionName = 'beta 1.0.x'`, `buildNumber = N`.
4. **ROLLBACK SAFETY & ARCHIVE RULE**:
   - Always archive builds into `releases/apk/wearsy-beta-X.Y.Z.apk` and update `releases/apk/wearsy-latest.apk`.
   - **NEVER delete or overwrite older APK versions** in `releases/apk/`. Older versions (e.g. `wearsy-beta-1.0.0.apk`) must remain intact as backups for instant emergency rollback.
   - Use `build_and_archive_apk.bat` or `build_and_archive_apk.ps1` to automate this build and archival safely.
5. Refer to [VERSIONING_GUIDE.md](../../VERSIONING_GUIDE.md) for full instructions and changelog.
