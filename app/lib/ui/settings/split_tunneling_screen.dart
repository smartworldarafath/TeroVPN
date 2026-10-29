import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
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
    return Scaffold(
      backgroundColor: ProtonColors.background,
      appBar: AppBar(
        title: Text('Split Tunneling', style: ProtonTypography.titleMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ProtonColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // Switch Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ProtonColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ProtonColors.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.alt_route_rounded, color: ProtonColors.primary, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enable Split Tunneling',
                          style: ProtonTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Exclude specific apps from VPN routing',
                          style: ProtonTypography.bodySmall.copyWith(color: ProtonColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _splitTunnelingEnabled,
                    activeThumbColor: ProtonColors.primary,
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
                          color: ProtonColors.textSecondary,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_selectedPackages.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: ProtonColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_selectedPackages.length} Bypassed',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: ProtonColors.activeLabel,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search Filter Field
                  TextField(
                    onChanged: (v) => setState(() => _searchFilter = v.trim()),
                    style: ProtonTypography.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Search installed apps...',
                      hintStyle: ProtonTypography.bodySmall.copyWith(color: ProtonColors.textMuted),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: ProtonColors.textSecondary),
                      filled: true,
                      fillColor: ProtonColors.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  ),
                  const SizedBox(height: 12),

                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: ProtonColors.primary),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: ProtonColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ProtonColors.cardBorder),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredApps.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: ProtonColors.cardBorder,
                          indent: 68,
                        ),
                        itemBuilder: (context, index) {
                          final app = _filteredApps[index];
                          final isChecked = _selectedPackages.contains(app.package);
                          return CheckboxListTile(
                            value: isChecked,
                            activeColor: ProtonColors.primary,
                            checkColor: Colors.white,
                            title: Text(
                              app.label,
                              style: ProtonTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              app.package,
                              style: ProtonTypography.bodySmall.copyWith(
                                color: ProtonColors.textMuted,
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
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: ProtonColors.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ProtonColors.cardBorder.withValues(alpha: 0.6),
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
          : const Center(
              child: Icon(
                Icons.android_rounded,
                color: ProtonColors.textSecondary,
                size: 22,
              ),
            ),
    );
  }
}
