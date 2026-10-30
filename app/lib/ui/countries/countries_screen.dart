import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/theme_manager.dart';
import 'country_manager.dart';
import '../../core/app_preferences.dart';
import '../../core/core_controller.dart';
import '../components/filter_chip_button.dart';
import '../components/liquid_glass_card.dart';
import 'country_item_row.dart';
import 'country_details_sheet.dart';

class CountriesScreen extends StatefulWidget {
  final CoreController controller;
  final ValueChanged<String> onCountrySelected;

  const CountriesScreen({
    super.key,
    required this.controller,
    required this.onCountrySelected,
  });

  @override
  State<CountriesScreen> createState() => _CountriesScreenState();
}

class _CountriesScreenState extends State<CountriesScreen> with SingleTickerProviderStateMixin {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  void _handleManualRefresh() async {
    if (_spinController.isAnimating) return;
    _spinController.forward(from: 0.0);
    await CountryManager.instance.refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Server ping & loads refreshed in real-time.'),
          backgroundColor: ThemeManager.instance.isDarkMode ? ProtonColors.surfaceDark : Colors.white,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  List<DynamicCountry> _getFilteredCountries(List<DynamicCountry> list) {
    var result = list;

    if (_selectedFilter == 'Secure Core') {
      result = result.where((c) => ['CH', 'IS', 'SE', 'NO', 'FI'].contains(c.code.toUpperCase())).toList();
    } else if (_selectedFilter == 'P2P') {
      result = result.where((c) => ['NL', 'DE', 'CH', 'CA', 'ES', 'SE'].contains(c.code.toUpperCase())).toList();
    } else if (_selectedFilter == 'Tor') {
      result = result.where((c) => ['CH', 'IS', 'SE'].contains(c.code.toUpperCase())).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((c) =>
        c.name.toLowerCase().contains(q) ||
        c.code.toLowerCase().contains(q) ||
        c.cities.toLowerCase().contains(q)
      ).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final activeCode = widget.controller.status?.proxy?.countryCode.toUpperCase() ?? '';

    return ListenableBuilder(
      listenable: Listenable.merge([CountryManager.instance, ThemeManager.instance]),
      builder: (context, _) {
        final allCountries = CountryManager.instance.countries;
        final filteredCountries = _getFilteredCountries(allCountries);
        final textPrimary = ThemeManager.instance.textPrimaryColor;
        final textSecondary = ThemeManager.instance.textSecondaryColor;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 12, top: 12, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Countries',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Row(
                        children: [
                          // Refresh Icon
                          IconButton(
                            icon: RotationTransition(
                              turns: _spinController,
                              child: Icon(
                                Icons.refresh_rounded,
                                color: textSecondary,
                                size: 22,
                              ),
                            ),
                            tooltip: 'Refresh Latencies & Load in Real-Time',
                            onPressed: _handleManualRefresh,
                          ),
                          // Search Icon
                          IconButton(
                            icon: Icon(
                              _isSearchOpen ? Icons.close_rounded : Icons.search_rounded,
                              color: textSecondary,
                              size: 24,
                            ),
                            onPressed: () {
                              setState(() {
                                _isSearchOpen = !_isSearchOpen;
                                if (!_isSearchOpen) {
                                  _searchQuery = '';
                                  _searchController.clear();
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Live Frosted Liquid Glass Search Bar matching photo_3 & photo_10
                if (_isSearchOpen)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: LiquidGlassCard(
                      radius: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: TextStyle(color: textPrimary, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Search countries or cities...',
                          hintStyle: TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search_rounded, color: textSecondary, size: 20),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim();
                          });
                        },
                      ),
                    ),
                  ),

                // Filter Chips Row
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      FilterChipButton(
                        label: 'All',
                        isSelected: _selectedFilter == 'All',
                        onTap: () => setState(() => _selectedFilter = 'All'),
                      ),
                      const SizedBox(width: 8),
                      FilterChipButton(
                        label: 'Secure Core',
                        icon: Icons.shield_outlined,
                        isSelected: _selectedFilter == 'Secure Core',
                        onTap: () => setState(() => _selectedFilter = 'Secure Core'),
                      ),
                      const SizedBox(width: 8),
                      FilterChipButton(
                        label: 'P2P',
                        icon: Icons.swap_horiz_rounded,
                        isSelected: _selectedFilter == 'P2P',
                        onTap: () => setState(() => _selectedFilter = 'P2P'),
                      ),
                      const SizedBox(width: 8),
                      FilterChipButton(
                        label: 'Tor',
                        icon: Icons.vpn_lock_rounded,
                        isSelected: _selectedFilter == 'Tor',
                        onTap: () => setState(() => _selectedFilter = 'Tor'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Section Count Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Text(
                    'All countries (${filteredCountries.length})',
                    style: TextStyle(
                      color: textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // Countries List
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.04, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<String>('$_selectedFilter-$_searchQuery'),
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 120),
                        itemCount: filteredCountries.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            final isFastestSelected = activeCode.isEmpty || activeCode == 'FASTEST';
                            return CountryItemRow(
                              code: 'fastest',
                              name: 'Fastest country',
                              subtitle: 'Connects to closest edge server',
                              load: 25,
                              pingMs: 18,
                              isFastest: true,
                              isSelected: isFastestSelected,
                              onTap: () async {
                                await AppPreferences.setSelectedLocation('fastest');
                                await widget.controller.setLocation('fastest');
                                widget.onCountrySelected('fastest');
                              },
                            );
                          }

                          final countryIndex = index - 1;
                          final country = filteredCountries[countryIndex];
                          final isSelected = activeCode == country.code;

                          return CountryItemRow(
                            code: country.code,
                            name: country.name,
                            subtitle: country.cities,
                            load: country.load,
                            pingMs: country.pingMs,
                            isSelected: isSelected,
                            onTap: () async {
                              await AppPreferences.setSelectedLocation(country.code);
                              await AppPreferences.setLastConnection(country.code);
                              await widget.controller.setLocation(country.code.toLowerCase());
                              widget.onCountrySelected(country.code);
                            },
                            onExpand: () {
                              CountryDetailsSheet.show(
                                context,
                                country: country,
                                controller: widget.controller,
                                onServerSelected: (serverName) {
                                  widget.onCountrySelected(country.code);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
