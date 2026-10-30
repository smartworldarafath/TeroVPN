import 'package:flutter/material.dart';
import '../../core/core_controller.dart';
import '../../core/app_preferences.dart';
import '../components/country_flag.dart';
import '../components/signin_dialog.dart';

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

  @override
  void initState() {
    super.initState();
    _activeProfileTitle = AppPreferences.selectedProfile;
    if (_activeProfileTitle.isEmpty) {
      _activeProfileTitle = 'Streaming US';
    }
  }

  Future<void> _selectProfile(String title, String countryCode) async {
    setState(() => _activeProfileTitle = title);
    await AppPreferences.setSelectedProfile(title);
    await AppPreferences.setSelectedLocation(countryCode);
    await widget.controller.setLocation(countryCode.toLowerCase());
    widget.onProfileSelected(countryCode);

    if (widget.controller.isVpnOn) {
      if (!widget.controller.hasAccount) {
        if (mounted) SignInDialog.show(context, widget.controller);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Profiles',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pre-configured setups optimized for streaming, gaming, and privacy.',
            style: TextStyle(
              color: Color(0xFF8E8B9D),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 24),

          // Fast Presets Header
          const Text(
            'Fast Presets',
            style: TextStyle(
              color: Color(0xFF9E9BAE),
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
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildPresetCard(
                  title: 'Low Latency Gaming',
                  subtitle: 'Instant lowest-ping routing via Netherlands (18ms)',
                  icon: Icons.sports_esports_outlined,
                  flagCode: 'NL',
                  countryCode: 'NL',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPresetCard(
                  title: 'Secure P2P Germany',
                  subtitle: 'High-throughput Frankfurt node with Kill Switch',
                  icon: Icons.file_download_outlined,
                  flagCode: 'DE',
                  countryCode: 'DE',
                ),
              ),
              const SizedBox(width: 14),
              const Spacer(),
            ],
          ),

          const SizedBox(height: 32),

          // Account & Rotation Header
          const Text(
            'Account & Rotation',
            style: TextStyle(
              color: Color(0xFF9E9BAE),
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Multi-Account Token Pool Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF161426),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF261D4C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.layers_rounded,
                      color: Color(0xFF8B6BFF),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Multi-Account Token Pool',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Rotates across Fastly MASQUE edge sessions to maintain uninterrupted 50GB high-speed bandwidth.',
                        style: TextStyle(
                          color: Color(0xFF8E8B9D),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                SizedBox(
                  width: 270,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF261D4C),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '0 Tokens',
                          style: TextStyle(
                            color: Color(0xFF8B6BFF),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Monthly Bandwidth Used: 10.0 GB / 50.0 GB',
                        style: TextStyle(
                          color: Color(0xFF9E9BAE),
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: 0.20,
                          minHeight: 5,
                          backgroundColor: const Color(0xFF221F36),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2CFFCC)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String flagCode,
    required String countryCode,
  }) {
    final isActive = _activeProfileTitle == title;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectProfile(title, countryCode),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF161426),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF6B42FF)
                  : Colors.white.withValues(alpha: 0.06),
              width: isActive ? 1.5 : 1.0,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF6B42FF).withValues(alpha: 0.22),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF221D3F),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: isActive ? const Color(0xFF8B6BFF) : const Color(0xFF9E9BAE),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF133226),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                color: Color(0xFF2CFFCC),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF8E8B9D),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              CountryFlag(countryCode: flagCode, width: 30, height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
