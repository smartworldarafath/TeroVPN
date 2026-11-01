import 'dart:convert';
import 'package:flutter/material.dart';
import '../../theme/proton_typography.dart';
import '../../theme/theme_manager.dart';
import '../../core/core_controller.dart';
import '../../core/app_preferences.dart';
import '../countries/country_manager.dart';
import '../components/signin_dialog.dart';
import '../components/country_flag.dart';
import '../components/top_dock_toast.dart';
import 'account_pool_card.dart';
import 'profile_model.dart';
import 'create_profile_wizard.dart';

class ProfilesScreen extends StatefulWidget {
  final CoreController controller;
  final ValueChanged<String> onProfileSelected;

  const ProfilesScreen({
    super.key,
    required this.controller,
    required this.onProfileSelected,
  });

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  late String _activeProfileTitle;
  List<VpnProfile> _customProfiles = [];

  @override
  void initState() {
    super.initState();
    _activeProfileTitle = AppPreferences.selectedProfile;
    _loadCustomProfiles();
  }

  void _loadCustomProfiles() {
    try {
      final list = AppPreferences.customProfiles;
      final parsed = <VpnProfile>[];
      for (final jsonStr in list) {
        try {
          parsed.add(VpnProfile.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>));
        } catch (_) {}
      }
      setState(() {
        _customProfiles = parsed;
      });
    } catch (_) {}
  }

  Future<void> _selectProfile(VpnProfile profile, {bool autoConnect = false}) async {
    setState(() => _activeProfileTitle = profile.name);
    await AppPreferences.setSelectedProfile(profile.name);

    String targetCountry = profile.countryCode;
    if (targetCountry == 'fastest') {
      final fastest = CountryManager.instance.getFastestCountry();
      targetCountry = fastest.code;
    }

    await AppPreferences.setSelectedLocation(targetCountry);
    await widget.controller.setLocation(targetCountry.toLowerCase());
    widget.onProfileSelected(targetCountry);

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
      TopDockToast.show(
        context,
        title: 'Profile Activated',
        message: '${profile.name} (${targetCountry.toUpperCase()}) connected',
        icon: Icons.vpn_lock_rounded,
        iconColor: profile.color,
      );
    }
  }

  void _openCreateProfileWizard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateProfileWizard(
          onProfileCreated: (newProfile) {
            _loadCustomProfiles();
            _selectProfile(newProfile);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.controller, ThemeManager.instance]),
      builder: (context, _) {
        final isDark = ThemeManager.instance.isDarkMode;
        final defaults = VpnProfile.protonDefaults;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: 120,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Profiles',
                        style: ProtonTypography.titleLarge.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: ThemeManager.instance.textPrimaryColor,
                        ),
                      ),
                      // Create Profile Header Icon Button
                      IconButton(
                        onPressed: _openCreateProfileWizard,
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 28),
                        color: const Color(0xFF6B42FF),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pre-configured setups optimized for streaming, gaming, and privacy.',
                    style: ProtonTypography.bodySmall.copyWith(
                      color: ThemeManager.instance.textMutedColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 5 Proton VPN Default Profiles
                  Text(
                    'DEFAULT PROFILES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: isDark ? const Color(0xFF9D94B8) : const Color(0xFF635B7E),
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...defaults.map((profile) => _buildProfileItem(profile, isDark)),

                  // Custom User Profiles (if any)
                  if (_customProfiles.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'MY PROFILES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isDark ? const Color(0xFF9D94B8) : const Color(0xFF635B7E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._customProfiles.map((profile) => _buildProfileItem(profile, isDark)),
                  ],

                  const SizedBox(height: 20),

                  // Big Create Profile Button matching Proton VPN
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F1A33) : const Color(0xFFEDEAF7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF6B42FF).withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _openCreateProfileWizard,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded, color: Color(0xFF6B42FF), size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Create profile',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B42FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Multi-Account Token Pool Card
                  Text(
                    'ACCOUNT & ROTATION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: isDark ? const Color(0xFF9D94B8) : const Color(0xFF635B7E),
                    ),
                  ),
                  const SizedBox(height: 12),

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
                        TopDockToast.show(
                          context,
                          title: 'Multi-Account Token Pool',
                          message: 'Tokens & Fastly MASQUE bandwidth synchronized',
                          icon: Icons.sync_rounded,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileItem(VpnProfile profile, bool isDark) {
    final isActive = _activeProfileTitle == profile.name;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181329) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? const Color(0xFF6B42FF)
              : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black12),
          width: isActive ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? const Color(0xFF6B42FF).withValues(alpha: 0.22)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _selectProfile(profile),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icon Badge with Profile Color
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: profile.color.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: profile.color.withValues(alpha: 0.45),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  profile.iconData,
                  color: profile.color,
                  size: 22,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF161224),
                            ),
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF00E676),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      profile.subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? const Color(0xFF8F8C9E) : const Color(0xFF6B667D),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Country Flag or Fastest bolt
              if (profile.countryCode == 'fastest')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B42FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF6B42FF)),
                      SizedBox(width: 2),
                      Text(
                        'AUTO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6B42FF),
                        ),
                      ),
                    ],
                  ),
                )
              else
                CountryFlag(
                  countryCode: profile.countryCode,
                  width: 32,
                  height: 22,
                  borderRadius: 4,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
