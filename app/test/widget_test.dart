import 'package:flutter_test/flutter_test.dart';
import 'package:terovpn/main.dart';
import 'package:terovpn/core/core_controller.dart';
import 'package:terovpn/core/core_api.dart';

void main() {
  testWidgets('TeroVPN app smoke test and brand title verification', (WidgetTester tester) async {
    final controller = CoreController(
      () async => CoreApi(CoreEndpoint(Uri.parse('http://127.0.0.1:10820'), '')),
    );

    await tester.pumpWidget(TeroVpnApp(controller: controller));
    await tester.pump();

    // Verify TeroVPN branding is displayed
    expect(find.text('TeroVPN'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Countries'), findsOneWidget);
    expect(find.text('Profiles'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
