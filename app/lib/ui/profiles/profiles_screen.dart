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
import '../../core/app_permissions_service.dart';
import '../permissions/permissions_setup_screen.dart';

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
      if (!AppPermissionsService.instance.areCorePermissionsGranted) {
        if (mounted) {
          await PermissionsSetupScreen.showAsModal(context);
        }
        if (!AppPermissionsService.instance.areCorePermissionsGranted) {
          return;
        }
      }
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
                      // Proton VPN Info button
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          TopDockToast.show(
                            context,
                            title: 'Profiles Info',
                            message: 'Profiles allow one-tap connection with custom routing & security rules.',
                            icon: Icons.info_outline_rounded,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Info',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: ThemeManager.instance.textMutedColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: ThemeManager.instance.textMutedColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 5 Proton VPN Default Profiles matching photo_1
                  ...defaults.map((profile) => _buildProtonProfileRow(profile, isDark)),

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
                    ..._customProfiles.map((profile) => _buildProtonProfileRow(profile, isDark)),
                  ],

                  const SizedBox(height: 20),

                  // Big Create Profile Button matching photo_1 exactly
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B42FF),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6B42FF).withValues(alpha: 0.45),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _openCreateProfileWizard,
                        child: const Center(
                          child: Text(
                            'Create profile',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
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

  Widget _buildProtonProfileRow(VpnProfile profile, bool isDark) {
    final isActive = _activeProfileTitle == profile.name;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isActive
            ? (isDark ? const Color(0xFF221A3D) : const Color(0xFFECE7FB))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _selectProfile(profile),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            child: Row(
              children: [
                // Custom Proton Icon with badge
                _buildProtonIcon(profile),

                const SizedBox(width: 16),

                // Name & Subtitle
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
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF9E97B4) : const Color(0xFF6B667D),
                        ),
                      ),
                    ],
                  ),
                ),

                // Trailing 3-dots more options matching photo_1
                IconButton(
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    color: isDark ? const Color(0xFF8B84A0) : const Color(0xFF8B84A0),
                    size: 22,
                  ),
                  onPressed: () => _selectProfile(profile),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProtonIcon(VpnProfile profile) {
    Widget iconWidget;
    Widget? badgeWidget;

    switch (profile.id) {
      case 'streaming_us':
        iconWidget = const Icon(Icons.smart_display_rounded, color: Colors.white, size: 22);
        badgeWidget = Container(
          width: 17,
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2.5),
            border: Border.all(color: Colors.white, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 4,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: const CountryFlag(countryCode: 'US', width: 17, height: 12),
        );
        break;

      case 'gaming':
        iconWidget = const Icon(Icons.sports_esports_rounded, color: Colors.white, size: 22);
        badgeWidget = _buildLightningBadge();
        break;

      case 'anti_censorship':
        iconWidget = const _SpyHatGlassesIcon();
        badgeWidget = _buildLightningBadge();
        break;

      case 'max_security':
        iconWidget = const _ShieldSparkleIcon();
        badgeWidget = _buildLightningBadge();
        break;

      case 'work_school':
        iconWidget = const Icon(Icons.business_center_rounded, color: Colors.white, size: 22);
        badgeWidget = _buildLightningBadge();
        break;

      default:
        iconWidget = Icon(profile.iconData, color: Colors.white, size: 22);
        if (profile.countryCode != 'fastest') {
          badgeWidget = Container(
            width: 17,
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2.5),
              border: Border.all(color: Colors.white, width: 0.8),
            ),
            clipBehavior: Clip.antiAlias,
            child: CountryFlag(countryCode: profile.countryCode, width: 17, height: 12),
          );
        } else {
          badgeWidget = _buildLightningBadge();
        }
    }

    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Purple gradient squircle matching photo_1
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF9967FF),
                  Color(0xFF632FF0),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B42FF).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(child: iconWidget),
          ),

          // Badge overlapping bottom-right
          Positioned(
            bottom: 0,
            right: 0,
            child: badgeWidget,
          ),
        ],
      ),
    );
  }

  static Widget _buildLightningBadge() {
    return Container(
      width: 18,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFF00E676),
        borderRadius: BorderRadius.circular(3.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E676).withValues(alpha: 0.5),
            blurRadius: 4,
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.bolt_rounded,
          color: Color(0xFF0A2B19),
          size: 13,
        ),
      ),
    );
  }
}

/// Exact Proton VPN Spy Hat + Sunglasses Icon
class _SpyHatGlassesIcon extends StatelessWidget {
  const _SpyHatGlassesIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(
        painter: _SpyPainter(),
      ),
    );
  }
}

class _SpyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // Hat brim
    final brimPath = Path();
    brimPath.moveTo(size.width * 0.1, size.height * 0.44);
    brimPath.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.38,
      size.width * 0.9,
      size.height * 0.44,
    );
    brimPath.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.48,
      size.width * 0.1,
      size.height * 0.44,
    );
    canvas.drawPath(brimPath, paint);

    // Hat crown
    final crownPath = Path();
    crownPath.moveTo(size.width * 0.28, size.height * 0.42);
    crownPath.cubicTo(
      size.width * 0.28,
      size.height * 0.14,
      size.width * 0.42,
      size.height * 0.22,
      size.width * 0.5,
      size.height * 0.16,
    );
    crownPath.cubicTo(
      size.width * 0.58,
      size.height * 0.22,
      size.width * 0.72,
      size.height * 0.14,
      size.width * 0.72,
      size.height * 0.42,
    );
    crownPath.close();
    canvas.drawPath(crownPath, paint);

    // Sunglasses
    final leftLens = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.18, size.height * 0.56, size.width * 0.28, size.height * 0.26),
      const Radius.circular(3),
    );
    final rightLens = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.54, size.height * 0.56, size.width * 0.28, size.height * 0.26),
      const Radius.circular(3),
    );
    canvas.drawRRect(leftLens, paint);
    canvas.drawRRect(rightLens, paint);

    // Sunglasses bridge
    canvas.drawLine(
      Offset(size.width * 0.44, size.height * 0.62),
      Offset(size.width * 0.56, size.height * 0.62),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Exact Proton VPN Shield with Sparkle Stars Icon
class _ShieldSparkleIcon extends StatelessWidget {
  const _ShieldSparkleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: Stack(
        children: [
          const Center(
            child: Icon(Icons.shield_rounded, color: Colors.white, size: 20),
          ),
          Positioned(
            top: 1,
            right: 0,
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Color(0xFFE9D5FF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 3,
            left: 0,
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFFE9D5FF),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
