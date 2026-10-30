import '../components/liquid_glass_card.dart';
import '../components/liquid_glass_atmosphere.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../theme/proton_typography.dart';
import '../../theme/theme_manager.dart';
import '../../core/android_core.dart';
import '../../core/app_preferences.dart';

class SplitTunnelingScreen extends StatefulWidget {
  const SplitTunnelingScreen({super.key});

  @override
  State<SplitTunnelingScreen> createState() => _SplitTunnelingScreenState();
}

class _SplitTunnelingScreenState extends State<SplitTunnelingScreen> {
  late bool _splitTunnelingEnabled;
  List<InstalledApp> _apps = [];
  final Set<String> _selectedPackages = {};
  bool _loading = true;
  String _searchFilter = '';

  @override
  void initState() {
    super.initState();
    _splitTunnelingEnabled = AppPreferences.splitTunnelingEnabled;
    _selectedPackages.addAll(AppPreferences.bypassedApps);
    _loadApps();
  }

  Future<void> _loadApps() async {
    try {
      final apps = await AndroidCore.installedApps();
      if (mounted) {
        setState(() {
          _apps = apps;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _apps = [
            const InstalledApp('com.google.android.youtube', 'YouTube'),
            const InstalledApp('com.netflix.mediaclient', 'Netflix'),
            const InstalledApp('com.spotify.music', 'Spotify'),
            const InstalledApp('org.telegram.messenger', 'Telegram'),
            const InstalledApp('com.whatsapp', 'WhatsApp'),
            const InstalledApp('com.google.android.apps.maps', 'Google Maps'),
            const InstalledApp('com.android.chrome', 'Google Chrome'),
          ];
          _loading = false;
        });
      }
    }
  }

  Future<void> _applyRouting() async {
    try {
      final routing = AppRouting(
        onlyChosen: false,
        bypass: _splitTunnelingEnabled ? _selectedPackages : {},
        only: {},
        suggested: {},
      );
      await AndroidCore.setAppRouting(routing, apply: true);
    } catch (_) {}
  }

  List<InstalledApp> get _filteredApps {
    if (_searchFilter.isEmpty) return _apps;
    final q = _searchFilter.toLowerCase();
    return _apps.where((a) {
      return a.label.toLowerCase().contains(q) || a.package.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, _) {
        final isDark = ThemeManager.instance.isDarkMode;

        return LiquidGlassAtmosphere(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Split Tunneling',
              style: ProtonTypography.titleMedium.copyWith(
                color: ThemeManager.instance.textPrimaryColor,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: ThemeManager.instance.textPrimaryColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                // Switch Card
                LiquidGlassCard(
                  radius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.alt_route_rounded, color: Color(0xFF6B42FF), size: 24),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Enable Split Tunneling',
                              style: ProtonTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                color: ThemeManager.instance.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Exclude specific apps from VPN routing',
                              style: ProtonTypography.bodySmall.copyWith(
                                color: ThemeManager.instance.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _splitTunnelingEnabled,
                        activeThumbColor: const Color(0xFF6B42FF),
                        onChanged: (val) async {
                          setState(() => _splitTunnelingEnabled = val);
                          await AppPreferences.setSplitTunnelingEnabled(val);
                          _applyRouting();
                        },
                      ),
                    ],
                  ),
                ),

                // Animated Expandable Apps Section
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 300),
                  firstCurve: Curves.easeInOutCubic,
                  secondCurve: Curves.easeInOutCubic,
                  crossFadeState: _splitTunnelingEnabled
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'INSTALLED APPLICATIONS (${_apps.length})',
                            style: ProtonTypography.labelSmall.copyWith(
                              color: ThemeManager.instance.textSecondaryColor,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (_selectedPackages.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF6B42FF).withValues(alpha: 0.2)
                                    : const Color(0xFFF0EDFA),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${_selectedPackages.length} Bypassed',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6B42FF),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Search Filter Field
                      TextField(
                        onChanged: (v) => setState(() => _searchFilter = v.trim()),
                        style: ProtonTypography.bodyMedium.copyWith(
                          color: ThemeManager.instance.textPrimaryColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search installed apps...',
                          hintStyle: ProtonTypography.bodySmall.copyWith(
                            color: ThemeManager.instance.textMutedColor,
                          ),
                          prefixIcon: Icon(Icons.search_rounded, size: 20, color: ThemeManager.instance.textSecondaryColor),
                          filled: true,
                          fillColor: ThemeManager.instance.surfaceColor,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: ThemeManager.instance.cardBorderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: ThemeManager.instance.cardBorderColor),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(color: Color(0xFF6B42FF), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (_loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(color: Color(0xFF6B42FF)),
                          ),
                        )
                      else
                        LiquidGlassCard(
                          radius: 22,
                          padding: EdgeInsets.zero,
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _filteredApps.length,
                            separatorBuilder: (_, _) => Divider(
                              height: 1,
                              color: ThemeManager.instance.dividerColor,
                              indent: 68,
                            ),
                            itemBuilder: (context, index) {
                              final app = _filteredApps[index];
                              final isChecked = _selectedPackages.contains(app.package);
                              return CheckboxListTile(
                                value: isChecked,
                                activeColor: const Color(0xFF6B42FF),
                                checkColor: Colors.white,
                                title: Text(
                                  app.label,
                                  style: ProtonTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: ThemeManager.instance.textPrimaryColor,
                                  ),
                                ),
                                subtitle: Text(
                                  app.package,
                                  style: ProtonTypography.bodySmall.copyWith(
                                    color: ThemeManager.instance.textSecondaryColor,
                                    fontSize: 11,
                                  ),
                                ),
                                secondary: AppIconWidget(package: app.package),
                                onChanged: (val) async {
                                  setState(() {
                                    if (val == true) {
                                      _selectedPackages.add(app.package);
                                    } else {
                                      _selectedPackages.remove(app.package);
                                    }
                                  });
                                  await AppPreferences.setBypassedApps(_selectedPackages.toList());
                                  _applyRouting();
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                  secondChild: const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

}

class AppIconWidget extends StatefulWidget {
  final String package;
  const AppIconWidget({super.key, required this.package});

  @override
  State<AppIconWidget> createState() => _AppIconWidgetState();
}

class _AppIconWidgetState extends State<AppIconWidget> {
  static final Map<String, Uint8List?> _iconCache = {};
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _loadIcon();
  }

  @override
  void didUpdateWidget(covariant AppIconWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.package != widget.package) {
      _loadIcon();
    }
  }

  Future<void> _loadIcon() async {
    if (_iconCache.containsKey(widget.package)) {
      if (mounted) {
        setState(() {
          _bytes = _iconCache[widget.package];
        });
      }
      return;
    }
    try {
      final bytes = await AndroidCore.appIcon(widget.package);
      _iconCache[widget.package] = bytes;
      if (mounted) {
        setState(() {
          _bytes = bytes;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.instance.isDarkMode;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131122) : const Color(0xFFF4F3F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ThemeManager.instance.cardBorderColor,
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: _bytes != null && _bytes!.isNotEmpty
          ? Image.memory(
              _bytes!,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            )
          : Center(
              child: Icon(
                Icons.android_rounded,
                color: ThemeManager.instance.textSecondaryColor,
                size: 22,
              ),
            ),
    );
  }
}
