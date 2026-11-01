import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terovpn/core/app_preferences.dart';
import 'package:terovpn/core/models.dart';
import 'package:terovpn/core/qr_auth_sync_service.dart';
import 'package:terovpn/theme/theme_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
    ThemeManager.instance.init();
  });

  group('v1.1.7 Cross-Device QR Handshake & Theme Tests', () {
    test('QrAuthSyncService creates real LAN session and generates payload', () async {
      final session = await QrAuthSyncService.createSessionAsync(deviceName: 'TeroVPN Desktop');
      expect(session.sessionId.isNotEmpty, true);
      expect(session.localPort, greaterThan(0));
      expect(session.localIp.isNotEmpty, true);

      final payload = QrAuthSyncService.generateSessionPayload(
        session.sessionId,
        localIp: session.localIp,
        port: session.localPort,
      );

      expect(payload.startsWith('terovpn://pair?sid='), true);
      expect(payload.contains('ip=${session.localIp}'), true);
      expect(payload.contains('port=${session.localPort}'), true);
      expect(payload.contains('relay=ntfy.sh'), true);

      QrAuthSyncService.cancelSession(session.sessionId);
    });

    test('Cross-device simulated phone scan authorizes desktop successfully', () async {
      final session = await QrAuthSyncService.createSessionAsync(deviceName: 'TeroVPN Desktop');
      final payload = QrAuthSyncService.generateSessionPayload(
        session.sessionId,
        localIp: session.localIp,
        port: session.localPort,
      );

      // Phone extracts session details from scanned QR payload
      final scannedUri = Uri.parse(payload);
      final sid = scannedUri.queryParameters['sid']!;
      final ip = scannedUri.queryParameters['ip'];
      final port = int.tryParse(scannedUri.queryParameters['port'] ?? '0');

      expect(sid, session.sessionId);
      expect(ip, session.localIp);
      expect(port, session.localPort);

      final phoneAccount = Account(
        id: 'acc_mobile_verified_123',
        email: 'scanner.user@proton.me',
        name: 'Scanner User',
      );

      // Background wait on desktop
      final desktopAuthFuture = QrAuthSyncService.waitForAuthorization(
        session.sessionId,
        timeout: const Duration(seconds: 5),
      );

      // Phone triggers remote authorization
      final sendSuccess = await QrAuthSyncService.authorizeRemoteSession(
        sessionId: sid,
        account: phoneAccount,
        ip: ip,
        port: port,
        token: 'auth_masque_jwt_token_xyz',
      );
      expect(sendSuccess, true);

      // Desktop receives the authorized account
      final authorizedAccount = await desktopAuthFuture;
      expect(authorizedAccount, isNotNull);
      expect(authorizedAccount!.email, 'scanner.user@proton.me');
      expect(authorizedAccount.name, 'Scanner User');

      QrAuthSyncService.cancelSession(session.sessionId);
    });

    test('ThemeManager adaptive light and dark mode colors resolution', () async {
      // 1. Dark Mode verification
      await ThemeManager.instance.setDarkMode(true);
      expect(ThemeManager.instance.isDarkMode, true);
      expect(ThemeManager.instance.backgroundColor.toARGB32(), 0xFF0C0916);
      expect(ThemeManager.instance.textPrimaryColor.toARGB32(), 0xFFFFFFFF);
      expect(ThemeManager.instance.textSecondaryColor.toARGB32(), 0xFF8F8C9E);

      // 2. Light Mode verification
      await ThemeManager.instance.setDarkMode(false);
      expect(ThemeManager.instance.isDarkMode, false);
      expect(ThemeManager.instance.backgroundColor.toARGB32(), 0xFFF5F6FC);
      expect(ThemeManager.instance.textPrimaryColor.toARGB32(), 0xFF1D1536);
      expect(ThemeManager.instance.textSecondaryColor.toARGB32(), 0xFF6E6B80);
    });
  });
}
