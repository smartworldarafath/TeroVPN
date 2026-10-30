import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/android_core.dart';
import 'core/app_preferences.dart';
import 'core/core_api.dart';
import 'core/core_controller.dart';
import 'core/core_process.dart';
import 'core/models.dart';
import 'core/ports.dart';
import 'core/tun_service.dart';
import 'theme/proton_theme.dart';
import 'theme/theme_manager.dart';
import 'ui/shell/main_navigation_shell.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPreferences.init();
  ThemeManager.instance.init();

  if (!kIsWeb) {
    try {
      // Edge-to-edge layout with transparent status and navigation bars
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
      );
    } catch (_) {}
  }

  AndroidCore? androidCore;
  CoreProcess? desktopProcess;
  String? dataDir;

  if (!kIsWeb) {
    if (Platform.isAndroid) {
      try {
        final androidDataDir = await AndroidCore.dataDir();
        androidCore = AndroidCore(androidDataDir);
      } catch (_) {}
    } else {
      try {
        dataDir = CoreLocator.dataDir(args);
        desktopProcess = CoreProcess(
          executable: CoreProcess.executableFrom(args),
          dataDir: dataDir,
        );
      } catch (_) {}
    }
  }

  final controller = CoreController(
    () async {
      if (!kIsWeb && androidCore != null) {
        return await androidCore.connect();
      }
      if (!kIsWeb && desktopProcess != null) {
        try {
          return await desktopProcess.connect();
        } on CoreUnavailable catch (e) {
          if (e.problem == CoreProblem.noCore) {
            try {
              final api = CoreApi(CoreEndpoint(Uri.parse('http://127.0.0.1:10820'), ''));
              await api.status();
              return api;
            } catch (_) {
              rethrow;
            }
          }
          rethrow;
        }
      }
      return CoreApi(
        CoreEndpoint(Uri.parse('http://127.0.0.1:10820'), ''),
      );
    },
    turnOn: !kIsWeb && Platform.isAndroid
        ? (on) => AndroidCore.setOn(on)
        : null,
    moveStoppedCore: !kIsWeb && desktopProcess != null && dataDir != null
        ? (port) async {
            final dir = dataDir!;
            final listen = await CoreLocator.dashboardListen(dir);
            await CoreLocator.setDashboardListen(dir, withPort(listen, port));
            desktopProcess?.retryNow();
          }
        : null,
    retryStoppedCore: !kIsWeb && desktopProcess != null ? () async => desktopProcess?.retryNow() : null,
    tunService: !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS) && desktopProcess != null
        ? TunService.besideCore(desktopProcess.executable)
        : null,
  );

  // Setup Web preview mock data so the app can be inspected visually on localhost
  if (kIsWeb) {
    controller.status = CoreStatus.fromJson({
      'state': {'phase': 'off'},
      'proxy': {
        'country_code': AppPreferences.selectedLocation,
        'country_name': 'Netherlands',
        'city_name': 'Amsterdam #12',
        'ip': '185.156.172.45',
        'port': 51820,
      },
      'traffic': {'up_bps': 0, 'down_bps': 0},
      'notices': [],
      'accounts': {'running': 1, 'configured': 2},
      'switch_threshold_percent': 10.0,
      'version': '1.1.0',
      'can_exit': true,
      'system_proxy': 'off',
      'system_proxy_supported': true,
      'tun_supported': true,
      'auto_connecting': false,
      'connect_failure': '',
      'selection': AppPreferences.selectedLocation,
      'selection_name': 'Netherlands',
    });
    controller.accounts = AccountList.fromJson({
      'accounts': [
        {
          'id': 'acc_main',
          'name': 'Premium User',
          'email': 'user@terovpn.net',
          'position': 0,
          'enabled': true,
          'active': true,
          'status': 'ready',
          'reason': '',
          'reason_code': '',
          'reason_detail': '',
          'used_percent': 14.5,
          'has_password': true,
        },
        {
          'id': 'acc_backup',
          'name': 'Backup Account',
          'email': 'backup@terovpn.net',
          'position': 1,
          'enabled': true,
          'active': false,
          'status': 'ready',
          'reason': '',
          'reason_code': '',
          'reason_detail': '',
          'used_percent': 4.0,
          'has_password': true,
        }
      ],
      'switch_threshold_percent': 10.0,
    });
  }

  controller.start();

  runApp(TeroVpnApp(controller: controller));
}

class TeroVpnApp extends StatelessWidget {
  final CoreController controller;

  const TeroVpnApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, _) {
        final isDark = ThemeManager.instance.isDarkMode;
        return MaterialApp(
          title: 'TeroVPN',
          debugShowCheckedModeBanner: false,
          theme: isDark ? ProtonTheme.darkTheme : ProtonTheme.lightTheme,
          home: MainNavigationShell(controller: controller),
        );
      },
    );
  }
}
