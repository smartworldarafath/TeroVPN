import 'package:flutter/material.dart';
import '../../core/core_controller.dart';
import '../../core/app_preferences.dart';
import '../../theme/theme_manager.dart';
import '../components/country_flag.dart';
import '../components/signin_dialog.dart';
import '../countries/country_manager.dart';
import '../profiles/account_pool_card.dart';
import '../settings/account_management_screen.dart';

class DesktopProfilesView extends StatefulWidget {
  final CoreController controller;
  final ValueChanged<String> onProfileSelected;

  const DesktopProfilesView({
    super.key,
    required this.controller,
    required this.onProfileSelected,
  });

  @override
  State<DesktopProfilesView> createState() => _DesktopProfilesViewState();
}

class _DesktopProfilesViewState extends State<DesktopProfilesView> {
  late String _activeProfileTitle;
  late DynamicCountry _lowestLatencyCountry;

  @override
  void initState() {
    super.initState();
    _activeProfileTitle = AppPreferences.selectedProfile;
    if (_activeProfileTitle.isEmpty) {
      _activeProfileTitle = 'Streaming US';
    }
    _lowestLatencyCountry = CountryManager.instance.getFastestCountry();
  }

  Future<void> _selectProfile(String title, String countryCode, {bool autoConnect = false}) async {
    setState(() => _activeProfileTitle = title);
    await AppPreferences.setSelectedProfile(title);
    await AppPreferences.setSelectedLocation(countryCode);
    await widget.controller.setLocation(countryCode.toLowerCase());
    widget.onProfileSelected(countryCode);

    if (autoConnect || widget.controller.isVpnOn) {
      if (!widget.controller.hasAccount) {
        if (mounted) SignInDialog.show(context, widget.controller);
        return;
      }
      if (!widget.controller.isVpnOn) {
        await widget.controller.setOn(true);
      }
    }

    if (mounted) {
      final isDark = ThemeManager.instance.isDarkMode;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Switched to profile: $title ($countryCode)'),
          backgroundColor: isDark ? const Color(0xFF161426) : Colors.white,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.controller, CountryManager.instance, ThemeManager.instance]),
      builder: (context, _) {
        _lowestLatencyCountry = CountryManager.instance.getFastestCountry();

        final isDark = ThemeManager.instance.isDarkMode;
        final textPrimary = isDark ? Colors.white : const Color(0xFF1D1536);
        final textSecondary = isDark ? const Color(0xFF8E8B9D) : const Color(0xFF6E6B80);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Profiles',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pre-configured setups optimized for streaming, gaming, and privacy.',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 24),

              // Fast Presets Header
              Text(
                'Fast Presets',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // Presets Grid (2-column layout)
              Row(
                children: [
                  Expanded(
                    child: _buildPresetCard(
                      title: 'Streaming US',
                      subtitle: 'Fast 4K media delivery via US East MASQUE Edge',
                      icon: Icons.play_circle_outline_rounded,
                      flagCode: 'US',
                      countryCode: 'US',
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildPresetCard(
                      title: 'Low Latency Gaming',
                      subtitle: 'Lowest-ping routing via ${_lowestLatencyCountry.name} (${_lowestLatencyCountry.pingMs}ms)',
                      icon: Icons.sports_esports_outlined,
                      flagCode: _lowestLatencyCountry.code,
                      countryCode: _lowestLatencyCountry.code,
                      autoConnect: true,
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _buildPresetCard(
                      title: 'Secure P2P Germany',
                      subtitle: 'High-throughput Frankfurt node with Kill Switch',
                      icon: Icons.download_rounded,
                      flagCode: 'DE',
                      countryCode: 'DE',
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(), // Empty placeholder for symmetry
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Account & Rotation Header with Manage Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Account & Rotation',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AccountManagementScreen(controller: widget.controller),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.manage_accounts_rounded,
                              color: isDark ? const Color(0xFF8B6BFF) : const Color(0xFF5B34DB),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Manage Accounts',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF8B6BFF) : const Color(0xFF5B34DB),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Live Account Pool Card
              AccountPoolCard(
                accounts: widget.controller.accounts,
                controller: widget.controller,
                onRefresh: () async {
                  final active = widget.controller.activeAccount;
                  if (active != null) {
                    await widget.controller.refreshQuota(active);
                  }
                  await widget.controller.refresh(accountsToo: true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Multi-Account Token Pool & bandwidth refreshed.'),
                        backgroundColor: isDark ? const Color(0xFF161426) : Colors.white,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPresetCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String flagCode,
    required String countryCode,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    bool autoConnect = false,
  }) {
    final isActive = _activeProfileTitle == title;
    final cardBg = isDark ? const Color(0xFF161426) : Colors.white;
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFF5D5380).withValues(alpha: 0.10);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectProfile(title, countryCode, autoConnect: autoConnect),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? const Color(0xFF6B42FF) : cardBorder,
              width: isActive ? 1.5 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF6B42FF).withValues(alpha: isDark ? 0.25 : 0.15),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ]
                : (isDark
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(0xFF5D5380).withValues(alpha: 0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ]),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF261D4C) : const Color(0xFFEDE9F8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: isDark ? const Color(0xFF8B6BFF) : const Color(0xFF5B34DB),
                      size: 20,
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF133226) : const Color(0xFFD8F5EB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF00C896).withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF00C896),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  CountryFlag(countryCode: flagCode, width: 22, height: 16),
                  const SizedBox(width: 8),
                  Text(
                    countryCode,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
