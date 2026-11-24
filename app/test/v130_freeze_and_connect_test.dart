import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terovpn/core/app_permissions_service.dart';
import 'package:terovpn/core/app_preferences.dart';
import 'package:terovpn/core/app_update_service.dart';
import 'package:terovpn/core/core_api.dart';
import 'package:terovpn/core/core_controller.dart';
import 'package:terovpn/core/models.dart';
import 'package:terovpn/theme/theme_manager.dart';
import 'package:terovpn/ui/components/liquid_glass_card.dart';
import 'package:terovpn/ui/home/proton_world_map.dart';

class _MockCoreApi extends CoreApi {
  _MockCoreApi() : super(CoreEndpoint(Uri.parse('http://127.0.0.1:10820'), 'tok'));

  String phase = 'off';
  String stateCode = '';
  String connectFailure = '';
  String wakeError = '';
  String wakeErrorCode = '';
  String location = 'nl';
  String transport = 'h3';
  bool rejectUnknownLocation = false;
  Set<String> supportedLocations = {'nl', 'sg', 'us', 'de', 'pt', 'gb', 'jp'};

  int setPowerCalls = 0;
  int setLocationCalls = 0;
  int retryCalls = 0;
  int saveSettingsCalls = 0;
  final List<String> callOrder = [];

  @override
  Future<CoreStatus> status() async {
    return CoreStatus.fromJson({
      'state': {'phase': phase, 'code': stateCode},
      'proxy': {
        'country_code': location.toUpperCase(),
        'country_name': location.toUpperCase(),
        'city_name': 'Edge #1',
        'transport': transport,
        'wake_error': wakeError,
        'wake_error_code': wakeErrorCode,
      },
      'traffic': {'up_rate': 0, 'down_rate': 0},
      'notices': [],
      'accounts': {'total': 1, 'ready': 1, 'running': 1, 'configured': 1},
      'switch_threshold_percent': 10.0,
      'version': '1.3.0',
      'can_exit': true,
      'system_proxy': 'off',
      'system_proxy_supported': false,
      'tun_supported': false,
      'auto_connecting': false,
      'connect_failure': connectFailure,
      'selection': location,
      'selection_name': location.toUpperCase(),
    });
  }

  @override
  Future<AccountList> accounts() async {
    return AccountList.fromJson({
      'accounts': [
        {
          'id': 'acc_1',
          'email': 'test@example.com',
          'name': 'Test User',
          'active': true,
          'enabled': true,
          'status': AccountStatus.ready,
        },
      ],
      'switch_threshold_percent': 10.0,
    });
  }

  @override
  Future<LocationList> locations() async {
    return LocationList.fromJson({
      'locations': [
        for (final code in supportedLocations)
          {
            'code': code,
            'name': code.toUpperCase(),
            'city': 'City',
            'server': '$code.example.com',
            'recommended': code == 'nl',
            'ping_ms': 30,
          },
      ],
    });
  }

  @override
  Future<void> setLocation(String country) async {
    setLocationCalls++;
    callOrder.add('setLocation:$country');
    if (rejectUnknownLocation &&
        country != 'fastest' &&
        !supportedLocations.contains(country.toLowerCase())) {
      throw const CoreApiException(400, 'unknown location');
    }
    location = country;
  }

  @override
  Future<void> setPower(bool on) async {
    setPowerCalls++;
    callOrder.add('setPower:$on');
    phase = on ? 'running' : 'off';
  }

  @override
  Future<void> retry() async {
    retryCalls++;
    callOrder.add('retry');
  }

  @override
  Future<Map<String, Object?>> settings() async {
    return {
      'proxy': {'transport': transport, 'listen': '127.0.0.1:10810'},
    };
  }

  @override
  Future<void> saveSettings(Map<String, Object?> config) async {
    saveSettingsCalls++;
    final proxy = config['proxy'];
    if (proxy is Map && proxy['transport'] is String) {
      transport = proxy['transport'] as String;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
    await AppPermissionsService.instance.init();
    await AppPermissionsService.instance.grantAllCore();
    ThemeManager.instance.init();
  });

  group('v1.3.0 Bug 2: Country Tap & Stuck Connecting Fixes', () {
    test('connectToLocation switches country cleanly without racing setOn(false)/setOn(true)', () async {
      final api = _MockCoreApi()..phase = 'running'..location = 'nl';
      final controller = CoreController(() async => api);
      await controller.refresh(accountsToo: true);
      expect(controller.isConnected, true);

      final used = await controller.connectToLocation('sg');
      expect(used, 'sg');
      expect(api.location, 'sg');
      // Must NOT toggle power off then back on when already running — core restarts cleanly on setLocation
      expect(api.callOrder.where((c) => c == 'setPower:false'), isEmpty);
      expect(api.setLocationCalls, 1);

      controller.dispose();
    });

    test('connectToLocation falls back cleanly if core rejects an unsupported country code', () async {
      final api = _MockCoreApi()
        ..phase = 'off'
        ..rejectUnknownLocation = true;
      final controller = CoreController(() async => api);
      await controller.refresh(accountsToo: true);

      final used = await controller.connectToLocation('gh');
      expect(used, 'fastest');
      expect(api.location, 'fastest');
      expect(api.phase, 'running');
      expect(controller.isConnected, true);

      controller.dispose();
    });

    test('connectToLocation while already connecting calls retry instead of getting stuck', () async {
      final api = _MockCoreApi()..phase = 'starting'..location = 'pt';
      final controller = CoreController(() async => api);
      await controller.refresh(accountsToo: true);
      expect(controller.isConnecting, true);

      final used = await controller.connectToLocation('de');
      expect(used, 'de');
      expect(api.location, 'de');
      expect(api.retryCalls, greaterThanOrEqualTo(1));

      controller.dispose();
    });

    test('Stalled connecting watchdog triggers retry, TCP fallback (h2), and timeout recovery', () async {
      final api = _MockCoreApi()..phase = 'starting'..location = 'pt';
      final controller = CoreController(() async => api);
      await controller.refresh(accountsToo: true);
      expect(controller.isConnecting, true);

      // Simulate stall starting 10s ago -> triggers retry
      controller.debugSetConnectingSince(DateTime.now().subtract(const Duration(seconds: 10)));
      await controller.refresh();
      expect(api.retryCalls, 1);

      // Simulate stall starting 18s ago -> triggers HTTP/2 TCP fallback when ISP blocks QUIC/h3
      controller.debugSetConnectingSince(DateTime.now().subtract(const Duration(seconds: 18)));
      await controller.refresh();
      expect(api.transport, 'h2');
      expect(api.saveSettingsCalls, 1);

      // Simulate stall > 34s -> stops hanging in Connecting and exposes clear error
      controller.debugSetConnectingSince(DateTime.now().subtract(const Duration(seconds: 34)));
      await controller.refresh();
      expect(api.phase, 'off');
      expect(controller.isConnecting, false);
      expect(controller.lastConnectError, isNotNull);

      controller.dispose();
    });

    test('waiting phase with no_usable_account does not stay stuck showing isConnecting=true', () async {
      final api = _MockCoreApi()
        ..phase = 'waiting'
        ..stateCode = StateCode.noUsableAccount;
      final controller = CoreController(() async => api);
      await controller.refresh(accountsToo: true);

      expect(controller.isConnecting, false);
      expect(controller.lastConnectError, isNotNull);

      controller.dispose();
    });
  });

  group('v1.3.0 Bug 1: Freeze & White-Screen Prevention Tests', () {
    testWidgets('LiquidGlassCard supports enableBlur=false to avoid GPU BackdropFilter overload in lists', (tester) async {
      await ThemeManager.instance.setTheme('Proton UI (Liquid Glass)');
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                LiquidGlassCard(
                  enableBlur: false,
                  child: Text('Row Item'),
                ),
                LiquidGlassCard(
                  enableBlur: true,
                  child: Text('Hero Card'),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Row Item'), findsOneWidget);
      expect(find.text('Hero Card'), findsOneWidget);
      // Only Hero Card should emit a BackdropFilter
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('ProtonWorldMap pauses ticker when app lifecycle moves to paused and resumes cleanly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProtonWorldMap(
              isConnected: true,
              destinationCountryCode: 'PT',
              destinationCountryName: 'Portugal',
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Protected'), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Protected'), findsOneWidget);
    });

    test('Android CoreService & MainActivity offload JNI calls from main thread', () {
      final coreService = File('android/app/src/main/kotlin/com/terovpn/android/CoreService.kt').readAsStringSync();
      final mainActivity = File('android/app/src/main/kotlin/com/terovpn/android/MainActivity.kt').readAsStringSync();

      expect(coreService.contains('worker.execute'), true);
      expect(mainActivity.contains('CoreService.runOnCoreExecutor') || mainActivity.contains('worker.execute'), true);
    });

    test('App version is bumped to 1.3.0', () {
      expect(AppUpdateService.currentVersion, '1.3.0');
      expect(AppUpdateService.isNewerVersion('v1.3.1', '1.3.0'), true);
      expect(AppUpdateService.isNewerVersion('v1.3.0', '1.3.0'), false);
    });
  });
}
