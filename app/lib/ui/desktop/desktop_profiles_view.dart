import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/core_controller.dart';
import '../../core/app_preferences.dart';
import '../../theme/theme_manager.dart';
import '../components/country_flag.dart';
import '../components/signin_dialog.dart';
import '../countries/country_manager.dart';
import '../profiles/account_pool_card.dart';
import '../profiles/profile_model.dart';
import '../profiles/create_profile_wizard.dart';
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
  List<VpnProfile> _customProfiles = [];

  @override
  void initState() {
    super.initState();
    _activeProfileTitle = AppPreferences.selectedProfile;
    if (_activeProfileTitle.isEmpty) {
      _activeProfileTitle = 'Streaming US';
    }
    _lowestLatencyCountry = CountryManager.instance.getFastestCountry();
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

    // Protocol adaptation
    if (profile.protocol.contains('Stealth')) {
      await widget.controller.setProtocol('Fastly HTTP/2 MASQUE');
    } else if (profile.protocol.contains('WireGuard')) {
      await widget.controller.setProtocol('WireGuard MASQUE (HTTP/3)');
    } else {
      await widget.controller.setProtocol('Smart (Automatic)');
    }

    // Feature toggles
    if (profile.netShield == 'Off') {
      await AppPreferences.setNetShieldEnabled(false);
    } else {
      await AppPreferences.setNetShieldEnabled(true);
    }

    if (profile.lanConnections) {
      await AppPreferences.setLanBypass(true);
    }

    if (profile.id == 'max_security') {
      await AppPreferences.setKillSwitchEnabled(true);
    }

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
      final isDark = ThemeManager.instance.isDarkMode;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Switched to profile: ${profile.name} ($targetCountry)'),
          backgroundColor: isDark ? const Color(0xFF161426) : Colors.white,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _openCreateProfileWizard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateProfileWizard(
          onProfileCreated: (newProfile) async {
            final list = AppPreferences.customProfiles;
            final updated = List<String>.from(list)..add(jsonEncode(newProfile.toJson()));
            await AppPreferences.setCustomProfiles(updated);
            _loadCustomProfiles();
            if (mounted) {
              await _selectProfile(newProfile);
            }
          },
        ),
      ),
    );
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

        final protonProfiles = VpnProfile.protonDefaults;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with + New Profile Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                        'Official Proton VPN profile presets optimized for streaming, gaming, censorship, and security.',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _openCreateProfileWizard,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(
                      'New Profile',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B42FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Official Proton Profiles Header
              Text(
                'Proton Profiles',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // Row 1: Streaming US & Gaming
              Row(
                children: [
                  Expanded(
                    child: _buildProfileCard(
                      profile: protonProfiles[0], // Streaming US
                      featureBadge: '4K STREAMING',
                      effectiveCountryCode: 'US',
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildProfileCard(
                      profile: protonProfiles[1], // Gaming
                      featureBadge: 'LOW PING · ${_lowestLatencyCountry.pingMs}ms',
                      effectiveCountryCode: _lowestLatencyCountry.code,
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Row 2: Anti-censorship & Max security
              Row(
                children: [
                  Expanded(
                    child: _buildProfileCard(
                      profile: protonProfiles[2], // Anti-censorship
                      featureBadge: 'STEALTH TLS · DPI BYPASS',
                      effectiveCountryCode: 'CH',
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildProfileCard(
                      profile: protonProfiles[3], // Max security
                      featureBadge: 'SECURE CORE · KILL SWITCH',
                      effectiveCountryCode: 'IS',
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Row 3: Work/School & [First Custom Profile or New Profile placeholder]
              Row(
                children: [
                  Expanded(
                    child: _buildProfileCard(
                      profile: protonProfiles[4], // Work/School
                      featureBadge: 'PORT 443 · LAN BYPASS',
                      effectiveCountryCode: 'NL',
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _customProfiles.isNotEmpty
                        ? _buildProfileCard(
                            profile: _customProfiles[0],
                            featureBadge: 'CUSTOM PROFILE',
                            effectiveCountryCode: _customProfiles[0].countryCode == 'fastest'
                                ? _lowestLatencyCountry.code
                                : _customProfiles[0].countryCode,
                            isDark: isDark,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          )
                        : _buildCreateProfilePlaceholder(isDark, textSecondary),
                  ),
                ],
              ),

              if (_customProfiles.length > 1) ...[
                const SizedBox(height: 24),
                Text(
                  'Custom Profiles',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: _customProfiles.length - 1,
                  itemBuilder: (context, idx) {
                    final p = _customProfiles[idx + 1];
                    return _buildProfileCard(
                      profile: p,
                      featureBadge: 'CUSTOM',
                      effectiveCountryCode: p.countryCode == 'fastest'
                          ? _lowestLatencyCountry.code
                          : p.countryCode,
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    );
                  },
                ),
              ],

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

  Widget _buildProfileCard({
    required VpnProfile profile,
    required String featureBadge,
    required String effectiveCountryCode,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final isActive = _activeProfileTitle == profile.name;
    final cardBg = isDark ? const Color(0xFF161426) : Colors.white;
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFF5D5380).withValues(alpha: 0.10);

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectProfile(profile, autoConnect: false),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive ? profile.color : cardBorder,
                width: isActive ? 1.5 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: profile.color.withValues(alpha: isDark ? 0.30 : 0.18),
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
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: profile.color.withValues(alpha: isDark ? 0.20 : 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        profile.iconData,
                        color: profile.color,
                        size: 20,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF0EDFA),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            featureBadge,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: profile.color,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF133226) : const Color(0xFFD8F5EB),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF00C896).withValues(alpha: 0.5),
                              ),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF00C896),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  profile.name,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.subtitle.isNotEmpty ? profile.subtitle : profile.countryName,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CountryFlag(countryCode: effectiveCountryCode, width: 22, height: 16),
                        const SizedBox(width: 8),
                        Text(
                          effectiveCountryCode.toUpperCase(),
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      profile.protocol,
                      style: TextStyle(
                        color: textSecondary.withValues(alpha: 0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateProfilePlaceholder(bool isDark, Color textSecondary) {
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openCreateProfileWizard,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121020) : const Color(0xFFF7F6FC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFF5D5380).withValues(alpha: 0.12),
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    color: isDark ? const Color(0xFF8B6BFF) : const Color(0xFF5B34DB),
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create Custom Profile',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1D1536),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Customize protocol, server, and DNS',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
