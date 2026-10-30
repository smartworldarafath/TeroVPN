import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/android_core.dart';
import 'core/app_preferences.dart';
import 'core/core_api.dart';
import 'core/core_controller.dart';
import 'core/core_process.dart';
import 'core/ports.dart';
import 'core/tun_service.dart';
import 'theme/proton_theme.dart';
import 'theme/theme_manager.dart';
import 'ui/shell/main_navigation_shell.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPreferences.init();
  ThemeManager.instance.init();

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

  AndroidCore? androidCore;
  CoreProcess? desktopProcess;
  String? dataDir;

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

  final controller = CoreController(
    () async {
      if (androidCore != null) {
        return await androidCore.connect();
      }
      if (desktopProcess != null) {
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
    turnOn: Platform.isAndroid
        ? (on) => AndroidCore.setOn(on)
        : null,
    moveStoppedCore: desktopProcess != null && dataDir != null
        ? (port) async {
            final dir = dataDir!;
            final listen = await CoreLocator.dashboardListen(dir);
            await CoreLocator.setDashboardListen(dir, withPort(listen, port));
            desktopProcess?.retryNow();
          }
        : null,
    retryStoppedCore: desktopProcess != null ? () async => desktopProcess?.retryNow() : null,
    tunService: (Platform.isWindows || Platform.isLinux || Platform.isMacOS) && desktopProcess != null
        ? TunService.besideCore(desktopProcess.executable)
        : null,
  );

  controller.start();

  // Restore saved location
  final savedLoc = AppPreferences.selectedLocation;
  if (savedLoc.isNotEmpty && savedLoc.toLowerCase() != 'nl') {
    controller.setLocation(savedLoc);
  }

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
        return MaterialApp(
          title: 'TeroVPN',
          debugShowCheckedModeBanner: false,
          theme: ProtonTheme.darkTheme,
          home: MainNavigationShell(controller: controller),
        );
      },
    );
  }
}
