import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/android_core.dart';
import 'core/app_preferences.dart';
import 'core/core_api.dart';
import 'core/core_controller.dart';
import 'theme/proton_theme.dart';
import 'theme/theme_manager.dart';
import 'ui/shell/main_navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPreferences.init();

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
  if (Platform.isAndroid) {
    try {
      final dataDir = await AndroidCore.dataDir();
      androidCore = AndroidCore(dataDir);
    } catch (_) {}
  }

  final controller = CoreController(
    () async {
      if (androidCore != null) {
        return await androidCore.connect();
      }
      return CoreApi(
        CoreEndpoint(Uri.parse('http://127.0.0.1:10820'), ''),
      );
    },
    turnOn: Platform.isAndroid
        ? (on) => AndroidCore.setOn(on)
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
