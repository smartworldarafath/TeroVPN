import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terovpn/core/app_preferences.dart';
import 'package:terovpn/core/app_update_service.dart';
import 'package:terovpn/ui/profiles/profile_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
  });

  test('VpnProfile Proton VPN 5 default profiles verification', () {
    final defaults = VpnProfile.protonDefaults;
    expect(defaults.length, 5);

    final names = defaults.map((p) => p.name).toList();
    expect(names, contains('Streaming US'));
    expect(names, contains('Gaming'));
    expect(names, contains('Anti-censorship'));
    expect(names, contains('Max security'));
    expect(names, contains('Work/School'));

    // Check Streaming US
    final streaming = defaults.firstWhere((p) => p.name == 'Streaming US');
    expect(streaming.countryCode, 'US');
    expect(streaming.subtitle, 'United States');

    // Check Gaming
    final gaming = defaults.firstWhere((p) => p.name == 'Gaming');
    expect(gaming.protocol, 'WireGuard');
    expect(gaming.natType, 'Moderate');

    // Check Anti-censorship
    final anti = defaults.firstWhere((p) => p.name == 'Anti-censorship');
    expect(anti.protocol, 'Stealth');

    // Check Max security
    final maxSec = defaults.firstWhere((p) => p.name == 'Max security');
    expect(maxSec.connectionType, 'Secure Core');

    // Check Work/School
    final work = defaults.firstWhere((p) => p.name == 'Work/School');
    expect(work.countryCode, 'fastest');
  });

  test('VpnProfile serialization and deserialization', () {
    const profile = VpnProfile(
      id: 'custom_123',
      name: 'Tokyo P2P',
      subtitle: 'Japan High Speed',
      colorHex: '#3B82F6',
      iconCodePoint: 58000,
      connectionType: 'P2P',
      countryCode: 'JP',
      countryName: 'Japan',
      netShield: 'Block malware only',
      protocol: 'WireGuard',
      natType: 'Moderate',
      lanConnections: true,
      connectOnLaunch: true,
      customDns: true,
      customDnsPrimary: '8.8.8.8',
      customDnsSecondary: '8.8.4.4',
    );

    final json = profile.toJson();
    final restored = VpnProfile.fromJson(json);

    expect(restored.id, 'custom_123');
    expect(restored.name, 'Tokyo P2P');
    expect(restored.connectionType, 'P2P');
    expect(restored.countryCode, 'JP');
    expect(restored.customDnsPrimary, '8.8.8.8');
  });

  test('Beta Features & Dock Style preferences persistence', () async {
    expect(AppPreferences.betaFeaturesEnabled, false);
    expect(AppPreferences.selectedDockStyle, 'default');

    await AppPreferences.setBetaFeaturesEnabled(true);
    expect(AppPreferences.betaFeaturesEnabled, true);

    await AppPreferences.setSelectedDockStyle('dock1');
    expect(AppPreferences.selectedDockStyle, 'dock1');

    await AppPreferences.setSelectedDockStyle('dock2');
    expect(AppPreferences.selectedDockStyle, 'dock2');

    await AppPreferences.setSelectedDockStyle('default');
    expect(AppPreferences.selectedDockStyle, 'default');
  });

  test('AppUpdateService version bump to 1.1.7', () {
    expect(AppUpdateService.currentVersion, '1.1.7');
    expect(AppUpdateService.isNewerVersion('v1.1.8', '1.1.7'), true);
    expect(AppUpdateService.isNewerVersion('v1.1.7', '1.1.7'), false);
    expect(AppUpdateService.isNewerVersion('v1.1.6', '1.1.7'), false);
  });
}
