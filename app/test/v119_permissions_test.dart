import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terovpn/core/app_preferences.dart';
import 'package:terovpn/core/app_permissions_service.dart';
import 'package:terovpn/core/core_controller.dart';
import 'package:terovpn/core/core_api.dart';
import 'package:terovpn/core/models.dart';
import 'package:terovpn/ui/permissions/permissions_setup_screen.dart';
import 'package:terovpn/ui/settings/permissions_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
    await AppPermissionsService.instance.init();
  });

  group('v1.1.9 Permissions Architecture & Core Enforcement Tests', () {
    test('All 10 required permissions are defined with correct categories', () {
      final defs = AppPermissionsService.definitions;
      expect(defs.length, 10);

      final coreTypes = AppPermissionsService.corePermissions;
      expect(coreTypes.length, 6);
      expect(coreTypes, contains(AppPermissionType.adminPrivileges));
      expect(coreTypes, contains(AppPermissionType.backgroundService));
      expect(coreTypes, contains(AppPermissionType.virtualDriver));
      expect(coreTypes, contains(AppPermissionType.firewallAccess));
      expect(coreTypes, contains(AppPermissionType.dnsControl));
      expect(coreTypes, contains(AppPermissionType.ipv6Management));

      final optionalTypes = AppPermissionsService.optionalPermissions;
      expect(optionalTypes.length, 4);
      expect(optionalTypes, contains(AppPermissionType.advancedNetworkStack));
      expect(optionalTypes, contains(AppPermissionType.notifications));
      expect(optionalTypes, contains(AppPermissionType.nearbyDevices));
      expect(optionalTypes, contains(AppPermissionType.appDiagnostics));
    });

    test('Core permissions gate initially blocks connection', () {
      final service = AppPermissionsService.instance;
      expect(service.areCorePermissionsGranted, false);
      expect(service.grantedCount, 0);
    });

    test('Granting single permission persists and updates state', () async {
      final service = AppPermissionsService.instance;
      expect(service.isGranted(AppPermissionType.adminPrivileges), false);

      await service.grantPermission(AppPermissionType.adminPrivileges);
      expect(service.isGranted(AppPermissionType.adminPrivileges), true);
      expect(service.grantedCount, 1);

      // Verify persistence across new instance re-init
      await service.init();
      expect(service.isGranted(AppPermissionType.adminPrivileges), true);
    });

    test('grantAllCore grants all 6 core permissions and sets setup completed', () async {
      final service = AppPermissionsService.instance;
      expect(service.areCorePermissionsGranted, false);

      await service.grantAllCore();
      expect(service.areCorePermissionsGranted, true);
      expect(service.grantedCount, 6);
      expect(AppPreferences.permissionsSetupCompleted, true);
    });

    test('grantAllPermissions grants all 10 system and advanced permissions', () async {
      final service = AppPermissionsService.instance;
      await service.grantAllPermissions();

      expect(service.grantedCount, 10);
      expect(service.areCorePermissionsGranted, true);
      for (final type in AppPermissionType.values) {
        expect(service.isGranted(type), true);
      }
    });

    test('Advanced Network Stack enforces Google Chrome inclusion in tunnel', () async {
      final service = AppPermissionsService.instance;

      // Add chrome to bypassed list first to verify exclusion removal
      await AppPreferences.setBypassedApps(['com.android.chrome', 'com.spotify.music']);

      await service.grantPermission(AppPermissionType.advancedNetworkStack);

      expect(AppPreferences.isChromeIncludedInTunnel, true);
      expect(AppPreferences.killSwitchEnabled, true);

      // Chrome must NOT be in bypassed apps
      final bypassed = AppPreferences.bypassedApps;
      expect(bypassed.contains('com.android.chrome'), false);
      expect(bypassed.contains('com.spotify.music'), true);
    });

    test('CoreController strictly refuses setOn(true) when core permissions are missing', () async {
      final service = AppPermissionsService.instance;
      // Ensure clean ungranted state
      await AppPreferences.setGrantedPermissions({});
      await service.init();
      expect(service.areCorePermissionsGranted, false);

      final controller = CoreController(
        () async => CoreApi(CoreEndpoint(Uri.parse('http://127.0.0.1:10820'), '')),
      );

      // Attempt to connect without core permissions
      await controller.setOn(true);
      expect(controller.isVpnOn, false);
      expect(controller.switchingProxy, false);

      // Now grant core permissions and verify setOn(true) is permitted
      await service.grantAllCore();
      expect(service.areCorePermissionsGranted, true);

      await controller.setOn(true);
      expect(controller.isVpnOn, true);
    });

    testWidgets('PermissionsSetupScreen renders properly with all options', (tester) async {
      bool finished = false;

      await tester.pumpWidget(
        MaterialApp(
          home: PermissionsSetupScreen(
            onFinished: () => finished = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Permissions & System Access'), findsOneWidget);
      expect(find.text('Administrative Privileges (UAC)'), findsOneWidget);
      expect(find.text('TeroVPN Background Service'), findsOneWidget);
      expect(find.text('Network & Virtual Driver (TAP / Wintun)'), findsOneWidget);
      expect(find.text('Windows Defender Firewall Access'), findsOneWidget);
      expect(find.text('Encrypted DNS Control'), findsOneWidget);
      expect(find.text('IPv6 Traffic Management'), findsOneWidget);
      expect(find.text('Kill Switch & Split Tunneling'), findsOneWidget);
      expect(find.text('Desktop System Notifications'), findsOneWidget);
      expect(find.text('Nearby Devices (LAN Sync)'), findsOneWidget);
      expect(find.text('App Diagnostics & Telemetry'), findsOneWidget);

      // Tap Grant All Permissions
      final grantAllBtn = find.text('Grant All Permissions (Recommended)');
      expect(grantAllBtn, findsOneWidget);
      await tester.tap(grantAllBtn);
      await tester.pumpAndSettle();

      expect(AppPermissionsService.instance.areCorePermissionsGranted, true);

      // Tap Continue
      final continueBtn = find.text('Continue');
      expect(continueBtn, findsOneWidget);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();
      expect(finished, true);
    });

    testWidgets('PermissionsScreen in Settings displays status and grant actions', (tester) async {
      await AppPermissionsService.instance.init();

      await tester.pumpWidget(
        const MaterialApp(
          home: PermissionsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Permissions'), findsOneWidget);
      expect(find.textContaining('SYSTEMS OPERATIONAL', findRichText: true).evaluate().isNotEmpty ||
             find.textContaining('PERMISSIONS', findRichText: true).evaluate().isNotEmpty, true);
    });
  });
}
