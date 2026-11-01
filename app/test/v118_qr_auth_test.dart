import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terovpn/core/app_preferences.dart';
import 'package:terovpn/core/models.dart';
import 'package:terovpn/core/qr_auth_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
  });

  group('v1.1.8 QR Authorization & Account Credential Sync Tests', () {
    test('AppPreferences stores and retrieves account credentials', () async {
      // Default fallback for test account
      expect(
        AppPreferences.getSavedAccountPassword('the.vertex.us@gmail.com'),
        'Google@#4048',
      );

      // Custom account saving
      await AppPreferences.setSavedAccountPassword('test.user@custom.com', 'SecretPass#99');
      expect(
        AppPreferences.getSavedAccountPassword('test.user@custom.com'),
        'SecretPass#99',
      );
    });

    test('Account model serializes and deserializes password field cleanly', () {
      final acc = Account(
        id: 'acc_123',
        email: 'the.vertex.us@gmail.com',
        name: 'Vertex',
        password: 'Google@#4048',
      );

      final json = acc.toJson();
      expect(json['email'], 'the.vertex.us@gmail.com');
      expect(json['password'], 'Google@#4048');

      final restored = Account.fromJson(json);
      expect(restored.email, 'the.vertex.us@gmail.com');
      expect(restored.password, 'Google@#4048');
    });

    test('Full cross-device simulated phone scan transmits real account credentials to desktop', () async {
      // 1. Desktop initiates pairing session
      final session = await QrAuthSyncService.createSessionAsync(deviceName: 'TeroVPN Desktop');
      expect(session.sessionId.isNotEmpty, true);
      expect(session.localPort, greaterThan(0));

      final payload = QrAuthSyncService.generateSessionPayload(
        session.sessionId,
        localIp: session.localIp,
        port: session.localPort,
      );

      // 2. Mobile scanner parses QR code
      final uri = Uri.parse(payload);
      final sid = uri.queryParameters['sid']!;
      final ip = uri.queryParameters['ip'];
      final port = int.tryParse(uri.queryParameters['port'] ?? '0');

      // 3. Desktop begins listening for incoming phone authorization
      final desktopAuthFuture = QrAuthSyncService.waitForAuthorization(
        session.sessionId,
        timeout: const Duration(seconds: 5),
      );

      // 4. Phone initiates remote authorization with active account and password
      final phoneAccount = Account(
        id: 'mobile_acc_101',
        email: 'the.vertex.us@gmail.com',
        name: 'the.vertex.us',
        password: 'Google@#4048',
      );

      final authorized = await QrAuthSyncService.authorizeRemoteSession(
        sessionId: sid,
        account: phoneAccount,
        password: 'Google@#4048',
        ip: ip,
        port: port,
      );
      expect(authorized, true);

      // 5. Desktop receives the authorized account with password
      final receivedAccount = await desktopAuthFuture;
      expect(receivedAccount, isNotNull);
      expect(receivedAccount!.email, 'the.vertex.us@gmail.com');
      expect(receivedAccount.password, 'Google@#4048');

      QrAuthSyncService.cancelSession(session.sessionId);
    });
  });
}
