import 'package:flutter/material.dart';
import '../../core/core_controller.dart';
import '../../core/app_preferences.dart';
import '../components/country_flag.dart';
import '../components/signin_dialog.dart';
import '../countries/country_manager.dart';

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
    _spinController.forward(from: 0.0);
    await CountryManager.instance.refresh();
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
      listenable: Listenable.merge([CountryManager.instance, widget.controller]),
      builder: (context, _) {
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
                  const Text(
                    'Countries',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const Spacer(),
                  // Search Box
                  Container(
                    width: 250,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF141222),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF757286),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: 'Search countries...',
                              hintStyle: TextStyle(color: Color(0xFF757286), fontSize: 13),
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
                            child: const Icon(Icons.close_rounded, color: Color(0xFF757286), size: 16),
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
                            color: const Color(0xFF141222),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.refresh_rounded,
                            color: Color(0xFF8E8B9D),
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
                  _buildFilterChip('All', null),
                  const SizedBox(width: 8),
                  _buildFilterChip('Secure Core', Icons.shield_outlined),
                  const SizedBox(width: 8),
                  _buildFilterChip('P2P', Icons.compare_arrows_rounded),
                  const SizedBox(width: 8),
                  _buildFilterChip('Tor', Icons.public_rounded),
                ],
              ),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                'All countries (${allCountries.length})',
                style: const TextStyle(
                  color: Color(0xFF8E8B9D),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 10),

              // Fastest Country Featured Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF161426),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF6B42FF),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B42FF).withValues(alpha: 0.2),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF133226),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(Icons.bolt_rounded, color: Color(0xFF1FE5BD), size: 22),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fastest country',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Connects to closest edge server',
                            style: TextStyle(
                              color: Color(0xFF8E8B9D),
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
                            color: Color(0xFF2CFFCC),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${fastest.load}% load',
                          style: const TextStyle(
                            color: Color(0xFF9E9BAE),
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
                                color: const Color(0xFF261D4C),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Connect',
                                style: TextStyle(
                                  color: Color(0xFF8B6BFF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
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
                        onTap: () => _connectTo(item.code),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161426),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF6B42FF)
                                  : Colors.white.withValues(alpha: 0.05),
                              width: 1,
                            ),
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
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.cities,
                                      style: const TextStyle(
                                        color: Color(0xFF8E8B9D),
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
                                      color: Color(0xFF2CFFCC),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${item.load}% load',
                                    style: const TextStyle(
                                      color: Color(0xFF8E8B9D),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF261D4C),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Connect',
                                      style: TextStyle(
                                        color: Color(0xFF8B6BFF),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Color(0xFF757286),
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

  Widget _buildFilterChip(String label, IconData? icon) {
    final isSelected = _selectedFilter == label;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB)
              : const Color(0xFF161426),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B82F6)
                : Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF9E9BAE),
                size: 14,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF9E9BAE),
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
