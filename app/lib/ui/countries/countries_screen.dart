import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
import '../../theme/theme_manager.dart';
import '../../core/core_controller.dart';
import '../../core/app_preferences.dart';
import '../components/filter_chip_button.dart';
import 'country_manager.dart';
import 'country_item_row.dart';

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
  String _searchQuery = '';
  String _selectedFilter = 'All';
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  late final AnimationController _spinController;

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

  Future<void> _handleManualRefresh() async {
    _spinController.forward(from: 0.0);
    await CountryManager.instance.refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Country latency & server load updated in real-time.'),
          backgroundColor: ProtonColors.surfaceDark,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  List<DynamicCountry> _getFilteredCountries(List<DynamicCountry> all) {
    return all.where((c) {
      if (_selectedFilter == 'Secure Core' && !c.isSecureCore) return false;
      if (_selectedFilter == 'P2P' && !c.isP2p) return false;
      if (_selectedFilter == 'Tor' && !c.isTor) return false;

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = c.name.toLowerCase().contains(query);
        final matchesCode = c.code.toLowerCase().contains(query);
        final matchesCities = c.cities.toLowerCase().contains(query);
        return matchesName || matchesCode || matchesCities;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final activeCode = widget.controller.status?.proxy?.countryCode.toUpperCase() ?? '';

    return ListenableBuilder(
      listenable: CountryManager.instance,
      builder: (context, _) {
        final allCountries = CountryManager.instance.countries;
        final filteredCountries = _getFilteredCountries(allCountries);
        final isLiquid = ThemeManager.instance.isLiquidGlass;

        return Scaffold(
          backgroundColor: isLiquid ? const Color(0xFF0B0A13) : ProtonColors.background,
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
                        style: ProtonTypography.titleLarge,
                      ),
                      Row(
                        children: [
                          // Refresh Icon
                          IconButton(
                            icon: RotationTransition(
                              turns: _spinController,
                              child: const Icon(
                                Icons.refresh_rounded,
                                color: ProtonColors.textSecondary,
                                size: 24,
                              ),
                            ),
                            tooltip: 'Refresh Latencies & Load in Real-Time',
                            onPressed: _handleManualRefresh,
                          ),
                          // Search Icon
                          IconButton(
                            icon: Icon(
                              _isSearchOpen ? Icons.close_rounded : Icons.search_rounded,
                              color: ProtonColors.textSecondary,
                              size: 26,
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

                // Live Search Bar
                if (_isSearchOpen)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: ProtonTypography.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Search countries or cities...',
                        hintStyle: ProtonTypography.bodyMedium.copyWith(color: ProtonColors.textMuted),
                        filled: true,
                        fillColor: isLiquid
                            ? const Color(0xFF1E1B2E).withValues(alpha: 0.65)
                            : ProtonColors.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        prefixIcon: const Icon(Icons.search_rounded, color: ProtonColors.textSecondary, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(isLiquid ? 16 : 12),
                          borderSide: BorderSide(
                            color: isLiquid ? Colors.white.withValues(alpha: 0.10) : ProtonColors.cardBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(isLiquid ? 16 : 12),
                          borderSide: BorderSide(
                            color: isLiquid ? Colors.white.withValues(alpha: 0.10) : ProtonColors.cardBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(isLiquid ? 16 : 12),
                          borderSide: const BorderSide(color: Color(0xFF6D4AFF), width: 1.5),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim();
                        });
                      },
                    ),
                  ),

                // Filter Chips Row
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
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

                const SizedBox(height: 12),

                // Section Count Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Text(
                    'All countries (${filteredCountries.length}) · Auto-refreshes hourly',
                    style: ProtonTypography.bodySmall.copyWith(
                      color: ProtonColors.textMuted,
                      fontWeight: FontWeight.w600,
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
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 120),
                        itemCount: filteredCountries.length + 1,
                        separatorBuilder: (_, _) => isLiquid
                            ? const SizedBox(height: 2)
                            : const Divider(
                                height: 1,
                                color: ProtonColors.cardBorder,
                                indent: 68,
                              ),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            final isFastestSelected = activeCode.isEmpty || activeCode == 'FASTEST';
                            return CountryItemRow(
                              code: 'fastest',
                              name: 'Fastest country',
                              subtitle: 'Connects to closest edge server',
                              load: 22,
                              isFastest: true,
                              isSelected: isFastestSelected,
                              onTap: () async {
                                await AppPreferences.setSelectedLocation('fastest');
                                await widget.controller.setLocation('fastest');
                                widget.onCountrySelected('fastest');
                              },
                            );
                          }

                          final country = filteredCountries[index - 1];
                          final isSelected = activeCode == country.code;

                          return CountryItemRow(
                            code: country.code,
                            name: country.name,
                            subtitle: country.cities,
                            load: country.load,
                            isSelected: isSelected,
                            onTap: () async {
                              await AppPreferences.setSelectedLocation(country.code);
                              await widget.controller.setLocation(country.code.toLowerCase());
                              widget.onCountrySelected(country.code);
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
