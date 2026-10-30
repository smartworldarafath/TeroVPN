import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';
import '../../core/core_controller.dart';
import '../../core/app_preferences.dart';
import '../components/country_flag.dart';
import 'country_manager.dart';

class CountryDetailsSheet extends StatefulWidget {
  final DynamicCountry country;
  final CoreController controller;
  final ValueChanged<String> onServerSelected;

  const CountryDetailsSheet({
    super.key,
    required this.country,
    required this.controller,
    required this.onServerSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required DynamicCountry country,
    required CoreController controller,
    required ValueChanged<String> onServerSelected,
  }) {
    final isDark = ThemeManager.instance.isDarkMode;
    final isLiquid = ThemeManager.instance.isLiquidGlass;

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final content = CountryDetailsSheet(
          country: country,
          controller: controller,
          onServerSelected: onServerSelected,
        );

        if (isLiquid) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF161324).withValues(alpha: 0.88)
                      : Colors.white.withValues(alpha: 0.92),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.95),
                      width: 1.2,
                    ),
                  ),
                ),
                child: content,
              ),
            ),
          );
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF181526) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: isDark ? const Color(0xFF2E2A42) : const Color(0xFFE5E3ED),
                width: 1,
              ),
            ),
          ),
          child: content,
        );
      },
    );
  }

  @override
  State<CountryDetailsSheet> createState() => _CountryDetailsSheetState();
}

class _CountryDetailsSheetState extends State<CountryDetailsSheet> {
  String _activeTab = 'Cities'; // 'Cities' or 'P2P'
  String? _selectedCity;

  List<String> get _cityList {
    if (widget.country.cities.isEmpty) {
      return ['Default Edge'];
    }
    return widget.country.cities
        .split(',')
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _generateServers(String city) {
    final code = widget.country.code.toUpperCase();
    final baseLoad = widget.country.load;
    final basePing = widget.country.pingMs;

    return [
      {'name': '$code#12', 'load': (baseLoad * 0.85).round().clamp(15, 95), 'ping': basePing, 'p2p': true},
      {'name': '$code#35', 'load': (baseLoad * 0.92).round().clamp(18, 95), 'ping': basePing + 2, 'p2p': true},
      {'name': '$code#58', 'load': (baseLoad * 1.05).round().clamp(22, 95), 'ping': basePing + 4, 'p2p': true},
      {'name': '$code#54', 'load': (baseLoad * 1.10).round().clamp(25, 95), 'ping': basePing + 6, 'p2p': true},
      {'name': '$code#25', 'load': (baseLoad * 1.15).round().clamp(28, 95), 'ping': basePing + 8, 'p2p': false},
      {'name': '$code#50', 'load': (baseLoad * 1.20).round().clamp(30, 95), 'ping': basePing + 10, 'p2p': true},
      {'name': '$code#39', 'load': (baseLoad * 1.25).round().clamp(32, 95), 'ping': basePing + 12, 'p2p': true},
      {'name': '$code#40', 'load': (baseLoad * 1.28).round().clamp(34, 95), 'ping': basePing + 14, 'p2p': true},
    ];
  }

  void _showSmartRoutingInfo() {
    final isDark = ThemeManager.instance.isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1A2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF6B42FF).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.location_on_rounded, color: Color(0xFF6B42FF), size: 36),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Smart Routing',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: ThemeManager.instance.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Smart Routing allows us to provide VPN coverage in hard-to-reach countries.\n\nWhen you connect to a Smart Routing server, you will appear to be browsing in your destination country, even though the physical server is located in an adjacent high-capacity edge region.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: ThemeManager.instance.textSecondaryColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B42FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Got It', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = ThemeManager.instance.textPrimaryColor;
    final textSecondary = ThemeManager.instance.textSecondaryColor;
    final dividerColor = ThemeManager.instance.dividerColor;
    final isDark = ThemeManager.instance.isDarkMode;

    return Column(
      children: [
        // Top Handle
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFD8D5E5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Header View
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              if (_selectedCity != null)
                IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
                  onPressed: () => setState(() => _selectedCity = null),
                ),
              CountryFlag(
                countryCode: widget.country.code,
                width: 36,
                height: 25,
                borderRadius: 4,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.country.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    if (_selectedCity != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _selectedCity!,
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Divider(height: 1, color: dividerColor),

        // Sub View: Server Drill-down vs Cities List
        Expanded(
          child: _selectedCity != null
              ? _buildServersView()
              : _buildCitiesView(),
        ),
      ],
    );
  }

  // View 1: Cities & P2P Tabs
  Widget _buildCitiesView() {
    final textPrimary = ThemeManager.instance.textPrimaryColor;
    final textSecondary = ThemeManager.instance.textSecondaryColor;
    final isDark = ThemeManager.instance.isDarkMode;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        // Tabs row: Cities vs P2P matching screen recording
        Row(
          children: [
            InkWell(
              onTap: () => setState(() => _activeTab = 'Cities'),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: _activeTab == 'Cities'
                      ? const Color(0xFF6B42FF)
                      : (isDark ? const Color(0xFF231E38) : const Color(0xFFF1F0F7)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Cities',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _activeTab == 'Cities' ? Colors.white : textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () => setState(() => _activeTab = 'P2P'),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _activeTab == 'P2P'
                      ? const Color(0xFF6B42FF)
                      : (isDark ? const Color(0xFF231E38) : const Color(0xFFF1F0F7)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.swap_horiz_rounded,
                      size: 16,
                      color: _activeTab == 'P2P' ? Colors.white : textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'P2P',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _activeTab == 'P2P' ? Colors.white : textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Section Title: Cities (count)
        Text(
          'Cities (${_cityList.length})',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 8),

        ..._cityList.map((city) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _selectedCity = city),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 20, color: textSecondary),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        city,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    Icon(Icons.more_horiz_rounded, color: textSecondary, size: 22),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // View 2: Servers List Drill-down matching screen recording
  Widget _buildServersView() {
    final servers = _generateServers(_selectedCity!);
    final textPrimary = ThemeManager.instance.textPrimaryColor;
    final textSecondary = ThemeManager.instance.textSecondaryColor;
    final isDark = ThemeManager.instance.isDarkMode;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        // Smart Routing Info Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF201C30) : const Color(0xFFF4F3F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E3ED),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.alt_route_rounded, size: 18, color: const Color(0xFF6B42FF)),
                      const SizedBox(width: 8),
                      Text(
                        'Smart Routing',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: _showSmartRoutingInfo,
                    child: Row(
                      children: [
                        Text('Info', style: TextStyle(fontSize: 12, color: textSecondary)),
                        const SizedBox(width: 2),
                        Icon(Icons.info_outline_rounded, size: 16, color: textSecondary),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Connects you to your destination country through servers physically located in adjacent edge datacenters.',
                style: TextStyle(fontSize: 12, color: textSecondary, height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Subheader row: Servers on left, Server load (i) on right
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Servers', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecondary)),
            Row(
              children: [
                Text('Server load', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary)),
                const SizedBox(width: 4),
                Icon(Icons.info_outline_rounded, size: 15, color: textSecondary),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        ...servers.map((server) {
          final int load = server['load'];
          final String name = server['name'];
          final bool p2p = server['p2p'];
          final int ping = server['ping'];

          final Color loadColor = load > 75
              ? const Color(0xFFFF4D4F)
              : (load > 50 ? const Color(0xFFFAAD14) : const Color(0xFF00E676));

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                await AppPreferences.setSelectedLocation(widget.country.code);
                await AppPreferences.setLastConnection(widget.country.code);
                await widget.controller.setLocation(widget.country.code.toLowerCase());
                widget.onServerSelected(name);
                if (mounted) Navigator.of(context).pop();
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (p2p)
                      Icon(Icons.swap_horiz_rounded, size: 16, color: textSecondary),
                    const Spacer(),
                    // Mini server load bar
                    Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A263D) : const Color(0xFFE4E1EE),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (load / 100).clamp(0.1, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: loadColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$load%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                        Text(
                          '$ping ms',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: textSecondary.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
