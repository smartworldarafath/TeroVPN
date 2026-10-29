import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
import '../../core/android_core.dart';

class SplitTunnelingScreen extends StatefulWidget {
  const SplitTunnelingScreen({super.key});

  @override
  State<SplitTunnelingScreen> createState() => _SplitTunnelingScreenState();
}

class _SplitTunnelingScreenState extends State<SplitTunnelingScreen> {
  bool _splitTunnelingEnabled = false;
  List<InstalledApp> _apps = [];
  final Set<String> _selectedPackages = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
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
          ];
          _loading = false;
        });
      }
    }
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
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
                    activeColor: ProtonColors.primary,
                    onChanged: (val) {
                      setState(() => _splitTunnelingEnabled = val);
                    },
                  ),
                ],
              ),
            ),

            if (_splitTunnelingEnabled) ...[
              const SizedBox(height: 24),
              Text(
                'INSTALLED APPLICATIONS',
                style: ProtonTypography.labelSmall.copyWith(
                  color: ProtonColors.textSecondary,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),

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
                    itemCount: _apps.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      color: ProtonColors.cardBorder,
                      indent: 56,
                    ),
                    itemBuilder: (context, index) {
                      final app = _apps[index];
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
                        secondary: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: ProtonColors.surfaceDark,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.android_rounded,
                            color: ProtonColors.textSecondary,
                            size: 20,
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedPackages.add(app.package);
                            } else {
                              _selectedPackages.remove(app.package);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
