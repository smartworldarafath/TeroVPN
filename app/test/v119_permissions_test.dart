import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terovpn/core/android_core.dart';
import 'package:terovpn/core/app_preferences.dart';
import 'package:terovpn/core/app_update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
  });

  group('v1.1.9 Permissions & Version Tests', () {
    test('Version is bumped to 1.1.9 across AppUpdateService', () {
      expect(AppUpdateService.currentVersion, '1.1.9');
      expect(AppUpdateService.isNewerVersion('v1.2.0', '1.1.9'), true);
      expect(AppUpdateService.isNewerVersion('v1.1.9', '1.1.9'), false);
      expect(AppUpdateService.isNewerVersion('v1.1.8', '1.1.9'), false);
    });

    test('AppPreferences stores and retrieves permissionsOnboardingDone', () async {
      expect(AppPreferences.permissionsOnboardingDone, false);
      await AppPreferences.setPermissionsOnboardingDone(true);
      expect(AppPreferences.permissionsOnboardingDone, true);
    });

    test('AppPreferences stores and retrieves lastPermissionPromptTime', () async {
      expect(AppPreferences.lastPermissionPromptTime, 0);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await AppPreferences.setLastPermissionPromptTime(timestamp);
      expect(AppPreferences.lastPermissionPromptTime, timestamp);
    });

    test('AndroidCore checkPermissions fallback returns safe defaults in test environment', () async {
      final perms = await AndroidCore.checkPermissions();
      expect(perms.containsKey('vpn'), true);
      expect(perms.containsKey('network'), true);
      expect(perms.containsKey('notifications'), true);
      expect(perms.containsKey('nearby'), true);
      expect(perms.containsKey('usage_access'), true);
      expect(perms.containsKey('camera'), true);
      expect(perms['network'], true);
    });

    test('AndroidCore isVpnPermissionGranted returns boolean in test environment', () async {
      final vpn = await AndroidCore.isVpnPermissionGranted();
      expect(vpn, isA<bool>());
    });
  });
}
