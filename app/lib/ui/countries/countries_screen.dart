import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';
import '../../core/core_controller.dart';
import '../../core/app_preferences.dart';
import '../components/liquid_glass_card.dart';
import '../components/liquid_glass_atmosphere.dart';
import '../components/filter_chip_button.dart';
import '../components/top_dock_toast.dart';
import 'country_manager.dart';
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

class _CountriesScreenState extends State<CountriesScreen>
    with TickerProviderStateMixin {
  String _selectedFilter = 'All'; // 'All', 'Secure Core', 'P2P', 'Tor'
  bool _isSearchOpen = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _spinController;
  late AnimationController _searchAnimController;
  late Animation<double> _searchExpandAnimation;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _searchAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _searchExpandAnimation = CurvedAnimation(
      parent: _searchAnimController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _spinController.dispose();
    _searchAnimController.dispose();
    super.dispose();
  }

  void _handleManualRefresh() async {
    if (_spinController.isAnimating) return;
    _spinController.forward(from: 0.0);
    await CountryManager.instance.refresh();
    final fastest = CountryManager.instance.getFastestCountry();
    if (mounted) {
      TopDockToast.show(
        context,
        title: 'Country Latencies Synchronized',
        message: 'Fastest: ${fastest.name} (${fastest.pingMs} ms) · All loads updated',
        icon: Icons.refresh_rounded,
        iconColor: const Color(0xFF00E676),
      );
    }
  }

  void _toggleSearch() {
    if (_isSearchOpen) {
      _searchAnimController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isSearchOpen = false;
            _searchQuery = '';
            _searchController.clear();
          });
        }
      });
    } else {
      setState(() {
        _isSearchOpen = true;
      });
      _searchAnimController.forward();
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
    return ListenableBuilder(
      listenable: Listenable.merge([widget.controller, CountryManager.instance, ThemeManager.instance]),
      builder: (context, _) {
        final textPrimary = ThemeManager.instance.textPrimaryColor;
        final textSecondary = ThemeManager.instance.textSecondaryColor;

        final allCountries = CountryManager.instance.countries;
        final filteredCountries = _getFilteredCountries(allCountries);
        final activeCode = widget.controller.status?.proxy?.countryCode.toUpperCase() ??
            AppPreferences.selectedLocation.toUpperCase();
        final fastestCountry = CountryManager.instance.getFastestCountry();

        return LiquidGlassAtmosphere(
          isConnected: widget.controller.isConnected,
          isConnecting: widget.controller.isConnecting,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Countries',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Row(
                          children: [
                            // Refresh Icon with rotation animation
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
                            // Search Icon with morphing animation
                            IconButton(
                              icon: AnimatedRotation(
                                turns: _isSearchOpen ? 0.25 : 0.0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutBack,
                                child: Icon(
                                  _isSearchOpen ? Icons.close_rounded : Icons.search_rounded,
                                  color: _isSearchOpen ? const Color(0xFF6B42FF) : textSecondary,
                                  size: 24,
                                ),
                              ),
                              tooltip: _isSearchOpen ? 'Close Search' : 'Search Countries',
                              onPressed: _toggleSearch,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Buttery-smooth expanding/collapsing Search Bar originating from top-right
                SizeTransition(
                  sizeFactor: _searchExpandAnimation,
                  child: FadeTransition(
                    opacity: _searchExpandAnimation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.88, end: 1.0).animate(_searchExpandAnimation),
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        child: LiquidGlassCard(
                          radius: 16,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          child: TextField(
                            controller: _searchController,
                            autofocus: _isSearchOpen,
                            style: TextStyle(color: textPrimary, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Search countries or cities...',
                              hintStyle: TextStyle(
                                color: textSecondary,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.search_rounded, color: textSecondary, size: 20),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear_rounded, color: textSecondary, size: 18),
                                      onPressed: () {
                                        setState(() {
                                          _searchQuery = '';
                                          _searchController.clear();
                                        });
                                      },
                                    )
                                  : null,
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
                        icon: Icons.vpn_lock_outlined,
                        isSelected: _selectedFilter == 'Tor',
                        onTap: () => setState(() => _selectedFilter = 'Tor'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Country List View with Bottom Dock Clearance
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      _handleManualRefresh();
                    },
                    color: const Color(0xFF6B42FF),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 96),
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: filteredCountries.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            final isFastestSelected = AppPreferences.defaultConnectionType == 'fastest' ||
                                activeCode.isEmpty ||
                                activeCode == 'FASTEST';
                            return CountryItemRow(
                              code: 'fastest',
                              name: 'Fastest country',
                              subtitle: 'Auto-Routing (${fastestCountry.name})',
                              load: fastestCountry.load,
                              pingMs: fastestCountry.pingMs,
                              isFastest: true,
                              isSelected: isFastestSelected,
                              onTap: () async {
                                final fastest = CountryManager.instance.getFastestCountry();
                                await AppPreferences.setDefaultConnectionType('fastest');
                                await AppPreferences.setSelectedLocation(fastest.code);
                                await widget.controller.setLocation(fastest.code.toLowerCase());
                                if (widget.controller.hasAccount) {
                                  if (widget.controller.isConnected) {
                                    widget.controller.setOn(false);
                                    Future.delayed(const Duration(milliseconds: 200), () {
                                      widget.controller.setOn(true);
                                    });
                                  } else {
                                    widget.controller.setOn(true);
                                  }
                                }
                                widget.onCountrySelected('fastest');
                                if (context.mounted) {
                                  TopDockToast.show(
                                    context,
                                    title: 'Connected to Fastest Country',
                                    message: '${fastest.name} · ${fastest.pingMs} ms (Load: ${fastest.load}%)',
                                    icon: Icons.bolt_rounded,
                                    iconColor: const Color(0xFF00E676),
                                  );
                                }
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
                              if (widget.controller.hasAccount && !widget.controller.isConnected) {
                                widget.controller.setOn(true);
                              }
                              widget.onCountrySelected(country.code);
                              if (context.mounted) {
                                TopDockToast.show(
                                  context,
                                  title: 'Connecting to ${country.name}',
                                  message: '${country.pingMs} ms · Load: ${country.load}%',
                                  icon: Icons.location_on_rounded,
                                );
                              }
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
