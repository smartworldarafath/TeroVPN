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
      await AppPreferences.setSavedAccountPassword('mock.user@example.com', 'DUMMY_MOCK_PASSWORD_123');
      expect(AppPreferences.getSavedAccountPassword('mock.user@example.com'), 'DUMMY_MOCK_PASSWORD_123');

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
        email: 'mock.user@example.com',
        name: 'Vertex',
        password: 'DUMMY_MOCK_PASSWORD_123',
      );

      final json = acc.toJson();
      expect(json['email'], 'mock.user@example.com');
      expect(json['password'], 'DUMMY_MOCK_PASSWORD_123');

      final restored = Account.fromJson(json);
      expect(restored.email, 'mock.user@example.com');
      expect(restored.password, 'DUMMY_MOCK_PASSWORD_123');
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
        email: 'mock.user@example.com',
        name: 'the.vertex.us',
        password: 'DUMMY_MOCK_PASSWORD_123',
      );

      final authorized = await QrAuthSyncService.authorizeRemoteSession(
        sessionId: sid,
        account: phoneAccount,
        password: 'DUMMY_MOCK_PASSWORD_123',
        ip: ip,
        port: port,
      );
      expect(authorized, true);

      // 5. Desktop receives the authorized account with password
      final receivedAccount = await desktopAuthFuture;
      expect(receivedAccount, isNotNull);
      expect(receivedAccount!.email, 'mock.user@example.com');
      expect(receivedAccount.password, 'DUMMY_MOCK_PASSWORD_123');

      QrAuthSyncService.cancelSession(session.sessionId);
    });
  });
}
