import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
import '../../core/core_controller.dart';
import 'profile_card.dart';
import 'account_pool_card.dart';

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
  String _activeProfileTitle = 'Streaming US';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProtonColors.background,
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
                style: ProtonTypography.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Pre-configured setups optimized for streaming, gaming, and privacy.',
                style: ProtonTypography.bodySmall.copyWith(
                  color: ProtonColors.textMuted,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Fast Presets',
                style: ProtonTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ProtonColors.textSecondary,
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
                onTap: () {
                  setState(() => _activeProfileTitle = 'Streaming US');
                  widget.controller.setLocation('us');
                  widget.onProfileSelected('US');
                },
              ),

              ProfileCard(
                title: 'Low Latency Gaming',
                description: 'Sub-20ms ping routing via Amsterdam IX',
                countryCode: 'NL',
                countryName: 'Netherlands',
                icon: Icons.sports_esports_outlined,
                isActive: _activeProfileTitle == 'Low Latency Gaming',
                onTap: () {
                  setState(() => _activeProfileTitle = 'Low Latency Gaming');
                  widget.controller.setLocation('nl');
                  widget.onProfileSelected('NL');
                },
              ),

              ProfileCard(
                title: 'Secure P2P Germany',
                description: 'High-throughput Frankfurt node with Kill Switch',
                countryCode: 'DE',
                countryName: 'Germany',
                icon: Icons.download_rounded,
                isActive: _activeProfileTitle == 'Secure P2P Germany',
                onTap: () {
                  setState(() => _activeProfileTitle = 'Secure P2P Germany');
                  widget.controller.setLocation('de');
                  widget.onProfileSelected('DE');
                },
              ),

              const SizedBox(height: 28),

              Text(
                'Account & Rotation',
                style: ProtonTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ProtonColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              ListenableBuilder(
                listenable: widget.controller,
                builder: (context, _) => AccountPoolCard(
                  accounts: widget.controller.accounts,
                  onRotate: () async {
                    final accounts = widget.controller.accounts?.accounts ?? [];
                    if (accounts.length > 1) {
                      final nonActive = accounts.firstWhere((a) => !a.active, orElse: () => accounts.first);
                      await widget.controller.activate(nonActive);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Switched to next active session token.'),
                            backgroundColor: ProtonColors.surfaceDark,
                          ),
                        );
                      }
                    } else {
                      await widget.controller.refresh(accountsToo: true);
                    }
                  },
                  onAddAccount: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account session pool synchronized with Fastly MASQUE backend.'),
                        backgroundColor: ProtonColors.surfaceDark,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
