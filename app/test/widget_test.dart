import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terovpn/main.dart';
import 'package:terovpn/core/core_controller.dart';
import 'package:terovpn/core/core_api.dart';
import 'package:terovpn/core/app_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
    await AppPreferences.init();
  });

  testWidgets('TeroVPN app smoke test and brand title verification', (WidgetTester tester) async {
    final controller = CoreController(
      () async => CoreApi(CoreEndpoint(Uri.parse('http://127.0.0.1:10820'), '')),
    );

    await tester.pumpWidget(TeroVpnApp(controller: controller));
    // Advance splash controller to Phase 2 brand reveal (t >= 0.50)
    await tester.pump(const Duration(milliseconds: 2200));

    // Verify splash kinetic typography elements
    expect(find.text('tero'), findsOneWidget);

    // Complete splash animation (3.2 seconds total) to reveal MainNavigationShell
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();

    expect(find.text('TeroVPN'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Countries'), findsOneWidget);
    expect(find.text('Profiles'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    controller.dispose();
  });
}
