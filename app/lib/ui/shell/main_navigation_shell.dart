import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/theme_manager.dart';
import '../../core/core_controller.dart';
import '../home/home_screen.dart';
import '../countries/countries_screen.dart';
import '../profiles/profiles_screen.dart';
import '../settings/settings_screen.dart';
import '../desktop/desktop_sidebar.dart';
import '../desktop/desktop_home_view.dart';
import '../desktop/desktop_countries_view.dart';
import '../desktop/desktop_profiles_view.dart';
import '../desktop/desktop_settings_view.dart';
import 'proton_dock.dart';

class MainNavigationShell extends StatefulWidget {
  final CoreController controller;

  const MainNavigationShell({
    super.key,
    required this.controller,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.controller, ThemeManager.instance]),
      builder: (context, _) {
        final isDark = ThemeManager.instance.isDarkMode;
        final bgColor = ThemeManager.instance.backgroundColor;

        // Dynamic System Status Bar & Navigation Bar brightness
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarDividerColor: Colors.transparent,
          ),
        );

        final isDesktop = (Platform.isWindows || Platform.isLinux || Platform.isMacOS) ||
            MediaQuery.of(context).size.width >= 768;

        if (isDesktop) {
          // Native Desktop Shell matching Telegram Reference Screenshots
          return Scaffold(
            backgroundColor: const Color(0xFF0D0C15),
            body: Row(
              children: [
                DesktopSidebar(
                  currentIndex: _currentIndex,
                  onTabSelected: _onTabSelected,
                  status: widget.controller.status,
                ),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: [
                      DesktopHomeView(
                        controller: widget.controller,
                        onNavigateToCountries: () => _onTabSelected(1),
                      ),
                      DesktopCountriesView(
                        controller: widget.controller,
                        onCountrySelected: (_) => _onTabSelected(0),
                      ),
                      DesktopProfilesView(
                        controller: widget.controller,
                        onProfileSelected: (_) => _onTabSelected(0),
                      ),
                      DesktopSettingsView(
                        controller: widget.controller,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile Layout with Proton Dock
        return Scaffold(
          backgroundColor: bgColor,
          body: Stack(
            children: [
              PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                children: [
                  HomeScreen(
                    controller: widget.controller,
                    onNavigateToCountries: () => _onTabSelected(1),
                  ),
                  CountriesScreen(
                    controller: widget.controller,
                    onCountrySelected: (_) => _onTabSelected(0),
                  ),
                  ProfilesScreen(
                    controller: widget.controller,
                    onProfileSelected: (_) => _onTabSelected(0),
                  ),
                  SettingsScreen(
                    controller: widget.controller,
                  ),
                ],
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).padding.bottom + 14,
                child: ProtonDock(
                  currentIndex: _currentIndex,
                  onTabSelected: _onTabSelected,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
