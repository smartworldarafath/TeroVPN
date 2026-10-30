import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/theme_manager.dart';
import '../../core/core_controller.dart';
import '../components/liquid_glass_atmosphere.dart';
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
  int _previousIndex = 0;

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return HomeScreen(
          controller: widget.controller,
          onNavigateToCountries: () => _onTabSelected(1),
        );
      case 1:
        return CountriesScreen(
          controller: widget.controller,
          onCountrySelected: (_) => _onTabSelected(0),
        );
      case 2:
        return ProfilesScreen(
          controller: widget.controller,
          onProfileSelected: (_) => _onTabSelected(0),
        );
      case 3:
        return SettingsScreen(
          controller: widget.controller,
        );
      default:
        return HomeScreen(
          controller: widget.controller,
          onNavigateToCountries: () => _onTabSelected(1),
        );
    }
  }

  Widget _buildDesktopScreen(int index) {
    switch (index) {
      case 0:
        return DesktopHomeView(
          controller: widget.controller,
          onNavigateToCountries: () => _onTabSelected(1),
        );
      case 1:
        return DesktopCountriesView(
          controller: widget.controller,
          onCountrySelected: (_) => _onTabSelected(0),
        );
      case 2:
        return DesktopProfilesView(
          controller: widget.controller,
          onProfileSelected: (_) => _onTabSelected(0),
        );
      case 3:
        return DesktopSettingsView(
          controller: widget.controller,
        );
      default:
        return DesktopHomeView(
          controller: widget.controller,
          onNavigateToCountries: () => _onTabSelected(1),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.controller, ThemeManager.instance]),
      builder: (context, _) {
        final isDark = ThemeManager.instance.isDarkMode;
        final isConnected = widget.controller.isConnected;
        final isConnecting = widget.controller.isConnecting;

        // Dynamic System Status Bar & Navigation Bar brightness (native only)
        if (!kIsWeb) {
          try {
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
          } catch (_) {}
        }

        final isDesktop = (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) ||
            MediaQuery.of(context).size.width >= 768;

        final isForward = _currentIndex >= _previousIndex;

        if (isDesktop) {
          // Native Desktop Shell matching Telegram Reference Screenshots with Ultra-Smooth AnimatedSwitcher
          return LiquidGlassAtmosphere(
            isConnected: isConnected,
            isConnecting: isConnecting,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Row(
                children: [
                  DesktopSidebar(
                    currentIndex: _currentIndex,
                    onTabSelected: _onTabSelected,
                    status: widget.controller.status,
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final inOffset = Tween<Offset>(
                          begin: Offset(0.0, isForward ? 0.025 : -0.025),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ));

                        return FadeTransition(
                          opacity: CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOut,
                          ),
                          child: SlideTransition(
                            position: inOffset,
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey<int>(_currentIndex),
                        child: _buildDesktopScreen(_currentIndex),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return LiquidGlassAtmosphere(
          isConnected: isConnected,
          isConnecting: isConnecting,
          child: Stack(
            children: [
              // Ultra-Smooth 120Hz Zero-Lag Tab Switcher
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final inOffset = Tween<Offset>(
                    begin: Offset(isForward ? 0.04 : -0.04, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ));

                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: inOffset,
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_currentIndex),
                  child: _buildScreen(_currentIndex),
                ),
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
