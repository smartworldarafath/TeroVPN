import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../core/core_controller.dart';
import '../home/home_screen.dart';
import '../countries/countries_screen.dart';
import '../profiles/profiles_screen.dart';
import '../settings/settings_screen.dart';
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
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProtonColors.background,
      body: Stack(
        children: [
          // Smooth Sliding Screen PageView
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

          // Floating Bottom Proton Dock
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
  }
}
