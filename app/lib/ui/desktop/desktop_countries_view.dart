import 'package:flutter/material.dart';
import '../../core/core_controller.dart';
import '../../core/app_preferences.dart';
import '../../theme/theme_manager.dart';
import '../components/country_flag.dart';
import '../components/signin_dialog.dart';
import '../countries/country_manager.dart';
import '../countries/country_details_sheet.dart';

class DesktopCountriesView extends StatefulWidget {
  final CoreController controller;
  final ValueChanged<String> onCountrySelected;

  const DesktopCountriesView({
    super.key,
    required this.controller,
    required this.onCountrySelected,
  });

  @override
  State<DesktopCountriesView> createState() => _DesktopCountriesViewState();
}

class _DesktopCountriesViewState extends State<DesktopCountriesView> with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String _selectedFilter = 'All';
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

  Future<void> _handleRefresh() async {
    if (_spinController.isAnimating) return;
    _spinController.forward(from: 0.0);
    await CountryManager.instance.refresh();
    if (mounted) {
      final isDark = ThemeManager.instance.isDarkMode;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Server ping & loads refreshed in real-time.'),
          backgroundColor: isDark ? const Color(0xFF161426) : Colors.white,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  List<DynamicCountry> _getFilteredCountries(List<DynamicCountry> all) {
    var result = all;
    if (_selectedFilter == 'Secure Core') {
      result = result.where((c) => ['CH', 'IS', 'SE', 'NO', 'FI'].contains(c.code.toUpperCase())).toList();
    } else if (_selectedFilter == 'P2P') {
      result = result.where((c) => ['NL', 'DE', 'CH', 'CA', 'ES', 'SE'].contains(c.code.toUpperCase())).toList();
    } else if (_selectedFilter == 'Tor') {
      result = result.where((c) => ['CH', 'IS', 'SE'].contains(c.code.toUpperCase())).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((c) {
        final matchesName = c.name.toLowerCase().contains(query);
        final matchesCode = c.code.toLowerCase().contains(query);
        final matchesCities = c.cities.toLowerCase().contains(query);
        return matchesName || matchesCode || matchesCities;
      }).toList();
    }
    return result;
  }

  Future<void> _connectTo(String code) async {
    await widget.controller.setLocation(code.toLowerCase());
    await AppPreferences.setSelectedLocation(code);
    widget.onCountrySelected(code);

    if (!widget.controller.isVpnOn) {
      if (!widget.controller.hasAccount) {
        if (mounted) SignInDialog.show(context, widget.controller);
        return;
      }
      widget.controller.setOn(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([CountryManager.instance, widget.controller, ThemeManager.instance]),
      builder: (context, _) {
        final isDark = ThemeManager.instance.isDarkMode;
        final isLiquid = ThemeManager.instance.isLiquidGlass;

        final textPrimary = isDark ? Colors.white : const Color(0xFF1D1536);
        final textSecondary = isDark ? const Color(0xFF8E8B9D) : const Color(0xFF6E6B80);

        final searchBg = isDark
            ? const Color(0xFF141222)
            : Colors.white;

        final cardBg = isDark
            ? const Color(0xFF161426)
            : (isLiquid ? Colors.white.withValues(alpha: 0.90) : Colors.white);

        final cardBorder = isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFF5D5380).withValues(alpha: 0.10);

        final allCountries = CountryManager.instance.countries;
        final filteredCountries = _getFilteredCountries(allCountries);
        final fastest = CountryManager.instance.getFastestCountry();
        final activeCode = widget.controller.status?.proxy?.countryCode.toUpperCase() ?? '';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Title + Search + Refresh
              Row(
                children: [
                  Text(
                    'Countries',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const Spacer(),
                  // Search Box
                  Container(
                    width: 220,
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: searchBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: cardBorder,
                        width: 1,
                      ),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: const Color(0xFF5D5380).withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: textSecondary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(color: textPrimary, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Search countries...',
                              hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (val) => setState(() => _searchQuery = val),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: Icon(Icons.close_rounded, color: textSecondary, size: 16),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Refresh Button
                  RotationTransition(
                    turns: _spinController,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _handleRefresh,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: searchBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: cardBorder,
                              width: 1,
                            ),
                            boxShadow: isDark
                                ? null
                                : [
                                    BoxShadow(
                                      color: const Color(0xFF5D5380).withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Icon(
                            Icons.refresh_rounded,
                            color: textSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Filter Chips
              Row(
                children: [
                  _buildFilterChip('All', null, isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('Secure Core', Icons.shield_outlined, isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('P2P', Icons.compare_arrows_rounded, isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('Tor', Icons.public_rounded, isDark),
                ],
              ),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                'All countries (${allCountries.length})',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 10),

              // Fastest Country Featured Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF6B42FF),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B42FF).withValues(alpha: isDark ? 0.2 : 0.12),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF261D4C) : const Color(0xFFEDE9F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.bolt_rounded,
                          color: Color(0xFF8B6BFF),
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fastest country',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Connects to closest edge server (${fastest.name})',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00C896),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${fastest.load}% load',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _connectTo(fastest.code),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF261D4C) : const Color(0xFFEDE9F8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Connect',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF8B6BFF) : const Color(0xFF5B34DB),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFF6B42FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, size: 13, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 2-Column Responsive Grid of Countries
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 68,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: filteredCountries.length,
                  itemBuilder: (context, index) {
                    final item = filteredCountries[index];
                    final isSelected = activeCode == item.code.toUpperCase();

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          CountryDetailsSheet.show(
                            context,
                            country: item,
                            controller: widget.controller,
                            onServerSelected: (c) => _connectTo(c),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF6B42FF)
                                  : cardBorder,
                              width: 1,
                            ),
                            boxShadow: isDark
                                ? null
                                : [
                                    BoxShadow(
                                      color: const Color(0xFF5D5380).withValues(alpha: 0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Row(
                            children: [
                              CountryFlag(countryCode: item.code, width: 34, height: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.cities,
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF00C896),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${item.load}% load',
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _connectTo(item.code),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF261D4C) : const Color(0xFFEDE9F8),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Connect',
                                          style: TextStyle(
                                            color: isDark ? const Color(0xFF8B6BFF) : const Color(0xFF5B34DB),
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: textSecondary,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, IconData? icon, bool isDark) {
    final isSelected = _selectedFilter == label;
    final chipBg = isSelected
        ? const Color(0xFF6B42FF)
        : (isDark ? const Color(0xFF161426) : Colors.white);

    final chipBorder = isSelected
        ? const Color(0xFF6B42FF)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFF5D5380).withValues(alpha: 0.12));

    final textColor = isSelected
        ? Colors.white
        : (isDark ? const Color(0xFF9E9BAE) : const Color(0xFF6E6B80));

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: chipBorder,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6B42FF).withValues(alpha: isDark ? 0.3 : 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: textColor,
                size: 14,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
