import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
import '../../core/core_controller.dart';
import '../components/filter_chip_button.dart';
import 'country_data.dart';
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

class _CountriesScreenState extends State<CountriesScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CountryItem> get _filteredCountries {
    return kFastlyCountries.where((c) {
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

    return Scaffold(
      backgroundColor: ProtonColors.background,
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
                    fillColor: ProtonColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    prefixIcon: const Icon(Icons.search_rounded, color: ProtonColors.textSecondary, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: ProtonColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: ProtonColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: ProtonColors.primary, width: 1.5),
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
                'All countries (${_filteredCountries.length})',
                style: ProtonTypography.bodySmall.copyWith(
                  color: ProtonColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Countries List
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120),
                itemCount: _filteredCountries.length + 1,
                separatorBuilder: (_, __) => const Divider(
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
                      load: 25,
                      isFastest: true,
                      isSelected: isFastestSelected,
                      onTap: () {
                        widget.controller.setLocation('fastest');
                        widget.onCountrySelected('fastest');
                      },
                    );
                  }

                  final country = _filteredCountries[index - 1];
                  final isSelected = activeCode == country.code;

                  return CountryItemRow(
                    code: country.code,
                    name: country.name,
                    subtitle: country.cities,
                    load: country.load,
                    isSelected: isSelected,
                    onTap: () {
                      widget.controller.setLocation(country.code.toLowerCase());
                      widget.onCountrySelected(country.code);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
