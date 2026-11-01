import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terovpn/core/app_preferences.dart';
import 'package:terovpn/core/desktop_system_proxy_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
  });

  group('v1.1.8 Multi-Platform Desktop System Proxy Tests', () {
    test('DesktopSystemProxyService singleton instance and bypass list definition', () {
      final service = DesktopSystemProxyService.instance;
      expect(service, isNotNull);
      expect(DesktopSystemProxyService.bypassList, contains('localhost'));
      expect(DesktopSystemProxyService.bypassList, contains('127.*'));
      expect(DesktopSystemProxyService.bypassList, contains('<local>'));
    });

    test('DesktopSystemProxyService enable and disable state cycle', () async {
      final service = DesktopSystemProxyService.instance;

      // Enable proxy
      final enabled = await service.enableProxy(port: 10810);
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        expect(enabled, isTrue);
        expect(service.isEnabled, isTrue);
      }

      // Disable proxy
      final disabled = await service.disableProxy();
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        expect(disabled, isTrue);
        expect(service.isEnabled, isFalse);
      }
    });

    test('DesktopSystemProxyService init ensures clean initial direct state', () async {
      final service = DesktopSystemProxyService.instance;
      await service.init(isVpnAlreadyActive: false);
      expect(service.isEnabled, isFalse);
    });
  });
}
