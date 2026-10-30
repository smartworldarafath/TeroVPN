import 'package:flutter/material.dart';
import '../../theme/proton_typography.dart';
import '../../theme/theme_manager.dart';
import '../../core/core_controller.dart';
import '../../core/app_preferences.dart';
import '../countries/country_manager.dart';
import '../components/signin_dialog.dart';
import 'profile_card.dart';
import 'account_pool_card.dart';
import '../components/top_dock_toast.dart';

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
  late DynamicCountry _lowestLatencyCountry;

  @override
  void initState() {
    super.initState();
    _activeProfileTitle = AppPreferences.selectedProfile;
    // Pre-calculate lowest latency server so it's instantly ready
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
      TopDockToast.show(
        context,
        title: 'Profile Activated',
        message: '$title ($countryCode) ready for high speed',
        icon: Icons.vpn_lock_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.controller, ThemeManager.instance]),
      builder: (context, _) {
        final isLiquid = ThemeManager.instance.isLiquidGlass;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: 120,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profiles',
                    style: isLiquid
                        ? TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: ThemeManager.instance.textPrimaryColor,
                            letterSpacing: -0.5,
                          )
                        : ProtonTypography.titleLarge.copyWith(
                            color: ThemeManager.instance.textPrimaryColor,
                          ),
                  ),
              const SizedBox(height: 8),
              Text(
                'Pre-configured setups optimized for streaming, gaming, and privacy.',
                style: ProtonTypography.bodySmall.copyWith(
                  color: ThemeManager.instance.textMutedColor,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Fast Presets',
                style: ProtonTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ThemeManager.instance.textSecondaryColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              ProfileCard(
                title: 'Streaming US',
                description: 'Fast 4K media delivery via US East MASQUE Edge',
                countryCode: 'US',
                countryName: 'United States',
                icon: Icons.play_circle_outline_rounded,
                isActive: _activeProfileTitle == 'Streaming US',
                onTap: () => _selectProfile('Streaming US', 'US'),
              ),

              ProfileCard(
                title: 'Low Latency Gaming',
                description: 'Instant lowest-ping routing via ${_lowestLatencyCountry.name} (${_lowestLatencyCountry.pingMs}ms)',
                countryCode: _lowestLatencyCountry.code,
                countryName: _lowestLatencyCountry.name,
                icon: Icons.sports_esports_outlined,
                isActive: _activeProfileTitle == 'Low Latency Gaming',
                onTap: () => _selectProfile(
                  'Low Latency Gaming',
                  _lowestLatencyCountry.code,
                  autoConnect: true,
                ),
              ),

              ProfileCard(
                title: 'Secure P2P Germany',
                description: 'High-throughput Frankfurt node with Kill Switch',
                countryCode: 'DE',
                countryName: 'Germany',
                icon: Icons.download_rounded,
                isActive: _activeProfileTitle == 'Secure P2P Germany',
                onTap: () => _selectProfile('Secure P2P Germany', 'DE'),
              ),

              const SizedBox(height: 28),

              Text(
                'Account & Rotation',
                style: ProtonTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ThemeManager.instance.textSecondaryColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              ListenableBuilder(
                listenable: widget.controller,
                builder: (context, _) => AccountPoolCard(
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
