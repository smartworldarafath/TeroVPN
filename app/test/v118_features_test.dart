import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terovpn/core/app_preferences.dart';
import 'package:terovpn/core/core_controller.dart';
import 'package:terovpn/core/models.dart';
import 'package:terovpn/core/qr_auth_sync_service.dart';
import 'package:terovpn/core/app_update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
  });

  group('v1.1.9 Cross-Device QR Auto-Login & Version Tests', () {
    test('Version is bumped to 1.1.9', () {
      expect(AppUpdateService.currentVersion, '1.1.9');
      expect(AppUpdateService.isNewerVersion('v1.2.0', '1.1.9'), true);
      expect(AppUpdateService.isNewerVersion('v1.1.9', '1.1.9'), false);
      expect(AppUpdateService.isNewerVersion('v1.1.8', '1.1.9'), false);
    });

    test('Cross-device QR authorization transmits password and persists session', () async {
      final session = await QrAuthSyncService.createSessionAsync(deviceName: 'TeroVPN Desktop');
      expect(session.sessionId.isNotEmpty, true);

      final payload = QrAuthSyncService.generateSessionPayload(
        session.sessionId,
        localIp: session.localIp,
        port: session.localPort,
      );

      final scannedUri = Uri.parse(payload);
      final sid = scannedUri.queryParameters['sid']!;
      final ip = scannedUri.queryParameters['ip'];
      final port = int.tryParse(scannedUri.queryParameters['port'] ?? '0');

      final phoneAccount = Account(
        id: 'acc_sync_test_888',
        email: 'the.vertex.us@gmail.com',
        name: 'Vertex User',
        active: true,
      );

      final desktopAuthFuture = QrAuthSyncService.waitForAuthorization(
        session.sessionId,
        timeout: const Duration(seconds: 5),
      );

      // Phone triggers remote authorization with credentials
      final sendSuccess = await QrAuthSyncService.authorizeRemoteSession(
        sessionId: sid,
        account: phoneAccount,
        ip: ip,
        port: port,
        password: 'TEST_SECURE_AUTH_PASS_123',
      );
      expect(sendSuccess, true);

      final authorized = await desktopAuthFuture;
      expect(authorized, isNotNull);
      expect(authorized!.email, 'the.vertex.us@gmail.com');

      // Verify session stored password
      final savedSession = QrAuthSyncService.getSession(session.sessionId);
      expect(savedSession, isNotNull);
      expect(savedSession!.password, 'TEST_SECURE_AUTH_PASS_123');

      // Verify AppPreferences storage
      await AppPreferences.setSavedActiveAccount(phoneAccount.toJson());
      await AppPreferences.setSavedAuthPassword(phoneAccount.email, 'TEST_SECURE_AUTH_PASS_123');

      expect(AppPreferences.savedActiveAccount, isNotNull);
      expect(AppPreferences.savedActiveAccount!['email'], 'the.vertex.us@gmail.com');
      expect(AppPreferences.getSavedAuthPassword('the.vertex.us@gmail.com'), 'TEST_SECURE_AUTH_PASS_123');

      QrAuthSyncService.cancelSession(session.sessionId);
    });

    test('CoreController initializes with saved QR active account', () async {
      await AppPreferences.setSavedActiveAccount({
        'id': 'acc_qr_saved_1',
        'email': 'the.vertex.us@gmail.com',
        'name': 'Vertex',
        'active': true,
      });

      final controller = CoreController(() => throw UnimplementedError());
      expect(controller.hasAccount, true);
      expect(controller.activeAccount?.email, 'the.vertex.us@gmail.com');
    });
  });
}
