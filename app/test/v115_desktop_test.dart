import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terovpn/core/app_preferences.dart';
import 'package:terovpn/ui/profiles/profile_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
  });

  group('v1.1.5 Desktop Features & Proton Profiles Test', () {
    test('Proton 5 default profiles contain exact requested names and settings', () {
      final defaults = VpnProfile.protonDefaults;
      expect(defaults.length, 5);

      final names = defaults.map((p) => p.name).toList();
      expect(names, contains('Streaming US'));
      expect(names, contains('Gaming'));
      expect(names, contains('Anti-censorship'));
      expect(names, contains('Max security'));
      expect(names, contains('Work/School'));

      // Check specific parameters
      final streaming = defaults.firstWhere((p) => p.name == 'Streaming US');
      expect(streaming.countryCode, 'US');

      final gaming = defaults.firstWhere((p) => p.name == 'Gaming');
      expect(gaming.natType, 'Moderate');
      expect(gaming.protocol, 'WireGuard');

      final antiCensorship = defaults.firstWhere((p) => p.name == 'Anti-censorship');
      expect(antiCensorship.protocol, 'Stealth');

      final maxSecurity = defaults.firstWhere((p) => p.name == 'Max security');
      expect(maxSecurity.connectionType, 'Secure Core');

      final workSchool = defaults.firstWhere((p) => p.name == 'Work/School');
      expect(workSchool.netShield, 'Malware only');
    });

    test('Branding assets exist for dynamic light/dark desktop switching', () {
      expect(File('assets/branding/app_icon_light.png').existsSync(), isTrue);
      expect(File('assets/branding/app_icon_dark.png').existsSync(), isTrue);
    });

    test('Profile preference selection persists correctly', () async {
      await AppPreferences.setSelectedProfile('Gaming');
      expect(AppPreferences.selectedProfile, 'Gaming');

      await AppPreferences.setSelectedProfile('Max security');
      expect(AppPreferences.selectedProfile, 'Max security');
    });
  });
}
