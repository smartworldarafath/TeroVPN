import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terovpn/core/app_preferences.dart';
import 'package:terovpn/core/app_update_service.dart';
import 'package:terovpn/core/qr_auth_sync_service.dart';
import 'package:terovpn/core/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
  });

  test('AppUpdateService version comparison test', () {
    expect(AppUpdateService.isNewerVersion('v1.1.4', '1.1.3'), isTrue);
    expect(AppUpdateService.isNewerVersion('1.2.0', '1.1.3'), isTrue);
    expect(AppUpdateService.isNewerVersion('v2.0.0', '1.1.3'), isTrue);
    expect(AppUpdateService.isNewerVersion('v1.1.3', '1.1.3'), isFalse);
    expect(AppUpdateService.isNewerVersion('v1.1.1', '1.1.3'), isFalse);
    expect(AppUpdateService.isNewerVersion('v1.0.8', '1.1.3'), isFalse);
  });

  test('AppPreferences v1.1.3 settings persistence test', () async {
    // Desktop mode toggle for tablets
    expect(AppPreferences.desktopModeEnabled, isFalse);
    await AppPreferences.setDesktopModeEnabled(true);
    expect(AppPreferences.desktopModeEnabled, isTrue);

    // Onboarding
    expect(AppPreferences.onboardingCompleted, isFalse);
    await AppPreferences.setOnboardingCompleted(true);
    expect(AppPreferences.onboardingCompleted, isTrue);

    // Proton VPN Advanced settings
    expect(AppPreferences.alternativeRouting, isTrue);
    await AppPreferences.setAlternativeRouting(false);
    expect(AppPreferences.alternativeRouting, isFalse);

    expect(AppPreferences.customDnsEnabled, isFalse);
    await AppPreferences.setCustomDnsEnabled(true);
    expect(AppPreferences.customDnsEnabled, isTrue);

    expect(AppPreferences.customDnsServers, contains('1.1.1.1'));
    await AppPreferences.setCustomDnsServers('9.9.9.9, 149.112.112.112');
    expect(AppPreferences.customDnsServers, equals('9.9.9.9, 149.112.112.112'));

    expect(AppPreferences.moderateNat, isFalse);
    await AppPreferences.setModerateNat(true);
    expect(AppPreferences.moderateNat, isTrue);

    expect(AppPreferences.portForwarding, isFalse);
    await AppPreferences.setPortForwarding(true);
    expect(AppPreferences.portForwarding, isTrue);

    expect(AppPreferences.customMtu, equals(1420));
    await AppPreferences.setCustomMtu(1280);
    expect(AppPreferences.customMtu, equals(1280));
  });

  test('QrAuthSyncService session creation and authorization test', () async {
    final session = QrAuthSyncService.createSession(deviceName: 'Test Desktop');
    expect(session.sessionId, startsWith('tero_'));
    expect(session.isAuthorized, isFalse);

    final payload = QrAuthSyncService.generateSessionPayload(session.sessionId);
    expect(payload, contains(session.sessionId));
    expect(payload, startsWith('terovpn://pair'));

    final account = Account(
      id: 'acc_test',
      email: 'pilot@terovpn.net',
      active: true,
    );

    final authResult = await QrAuthSyncService.authorizeSession(session.sessionId, account);
    expect(authResult, isTrue);
    expect(session.isAuthorized, isTrue);
    expect(session.account?.email, equals('pilot@terovpn.net'));
  });
}
