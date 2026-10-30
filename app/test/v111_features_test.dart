import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terovpn/core/app_preferences.dart';
import 'package:terovpn/ui/countries/country_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
  });

  test('Fastest Country real-time calculation test', () {
    final manager = CountryManager.instance;
    final fastest = manager.getFastestCountry();
    expect(fastest, isNotNull);
    expect(fastest.pingMs, isPositive);
    expect(fastest.code.isNotEmpty, isTrue);

    // Verify all countries have valid ping and load
    for (final c in manager.countries) {
      expect(c.pingMs, greaterThan(0));
      expect(c.load, greaterThanOrEqualTo(0));
      // Fastest country score must be <= any other country
      final fastestScore = fastest.pingMs + (fastest.load * 0.15);
      final score = c.pingMs + (c.load * 0.15);
      expect(fastestScore, lessThanOrEqualTo(score + 0.001));
    }
  });

  test('AppPreferences default connection and toast mode', () async {
    expect(AppPreferences.defaultConnectionType, equals('fastest'));
    expect(AppPreferences.toastAnimationMode, equals('auto'));

    await AppPreferences.setToastAnimationMode('island');
    expect(AppPreferences.toastAnimationMode, equals('island'));

    await AppPreferences.setToastAnimationMode('droplet');
    expect(AppPreferences.toastAnimationMode, equals('droplet'));
  });
}
