import 'package:flutter/material.dart';
import '../../theme/proton_typography.dart';
import '../../theme/theme_manager.dart';
import '../../core/app_preferences.dart';
import '../components/top_dock_toast.dart';
import '../shell/proton_dock.dart';
import '../shell/dock3_capsule_bar.dart';

/// Screen for customizing the primary Bottom App Dock
/// Options:
/// 1. Old system dock (Classic original Proton dock)
/// 2. Liquid Dock G1 (New default: 3D Obsidian Jelly Bar from dock style 03.html)
class AppDockSettingsScreen extends StatefulWidget {
  const AppDockSettingsScreen({super.key});

  @override
  State<AppDockSettingsScreen> createState() => _AppDockSettingsScreenState();
}

class _AppDockSettingsScreenState extends State<AppDockSettingsScreen> {
  late String _currentStyle;
  int _previewOldIndex = 0;
  int _previewG1Index = 1;

  @override
  void initState() {
    super.initState();
    _currentStyle = AppPreferences.selectedDockStyle;
  }

  bool _isG1Active(String style) {
    // Default is Liquid Dock G1
    return style != 'old_system' && style != 'proton' && style != 'dock1' && style != 'dock2';
  }

  bool _isOldSystemActive(String style) {
    return style == 'old_system' || style == 'proton';
  }

  Future<void> _applyDock(String styleKey, String dockName) async {
    setState(() {
      _currentStyle = styleKey;
    });
    await AppPreferences.setSelectedDockStyle(styleKey);
    ThemeManager.instance.refresh();

    if (mounted) {
      TopDockToast.show(
        context,
        title: '$dockName Activated',
        message: 'Your bottom navigation dock has been updated.',
        icon: Icons.dock_rounded,
        iconColor: const Color(0xFFA855F7),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.instance.isDarkMode;
    final isG1 = _isG1Active(_currentStyle);
    final isOld = _isOldSystemActive(_currentStyle);

    return Scaffold(
      backgroundColor: ThemeManager.instance.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeManager.instance.backgroundColor,
        elevation: 0,
        title: Text(
          'App Dock',
          style: ProtonTypography.titleLarge.copyWith(
            fontSize: 20,
            color: ThemeManager.instance.textPrimaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: ThemeManager.instance.textPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Top Description Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF181329) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B42FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Color(0xFFA855F7),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dock Appearance',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF161224),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Choose the preferred navigation bar style for Firebox VPN.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark
                                ? const Color(0xFF8C869E)
                                : const Color(0xFF6B667D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Option 1: Old system dock (On top as requested)
            _buildDockCard(
              title: 'Old system dock',
              badge: 'CLASSIC',
              description: 'Original system navigation dock with floating pill indicator.',
              isApplied: isOld,
              isDark: isDark,
              onSelect: () => _applyDock('old_system', 'Old system dock'),
              previewWidget: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ProtonDock(
                  currentIndex: _previewOldIndex,
                  onTabSelected: (i) => setState(() => _previewOldIndex = i),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Option 2: Liquid Dock G1 (New Default)
            _buildDockCard(
              title: 'Liquid Dock G1',
              badge: 'DEFAULT · RECOMMENDED',
              description:
                  '3D Obsidian glass bar with royal purple jelly capsule, smooth spring glide, and liquid stretch transitions.',
              isApplied: isG1,
              isDark: isDark,
              onSelect: () => _applyDock('liquid_g1', 'Liquid Dock G1'),
              previewWidget: Dock3CapsuleBar(
                currentIndex: _previewG1Index,
                onTabSelected: (i) => setState(() => _previewG1Index = i),
                isInteractivePreview: true,
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDockCard({
    required String title,
    required String badge,
    required String description,
    required bool isApplied,
    required bool isDark,
    required VoidCallback onSelect,
    required Widget previewWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181329) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isApplied
              ? const Color(0xFF6B42FF)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black12),
          width: isApplied ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isApplied
                ? const Color(0xFF6B42FF).withValues(alpha: 0.22)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Title, Badge, and Applied Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF161224),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9060FA).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF9060FA).withValues(alpha: 0.4),
                              width: 0.6,
                            ),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFC084FC),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF8C869E)
                            : const Color(0xFF6B667D),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isApplied)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF00E676).withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 13, color: Color(0xFF00E676)),
                      SizedBox(width: 4),
                      Text(
                        'ACTIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF00E676),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Interactive Mini Preview
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F0B1A) : const Color(0xFFF6F4FC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFF6B42FF).withValues(alpha: 0.15),
              ),
            ),
            child: previewWidget,
          ),

          const SizedBox(height: 16),

          // Apply / Set as Active Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: isApplied ? null : onSelect,
              icon: Icon(
                isApplied ? Icons.check_circle_rounded : Icons.radio_button_checked_rounded,
                size: 18,
              ),
              label: Text(
                isApplied ? 'Currently Active' : 'Set as Active Dock',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isApplied
                    ? const Color(0xFF00E676).withValues(alpha: 0.2)
                    : const Color(0xFF6B42FF),
                foregroundColor: isApplied
                    ? const Color(0xFF00E676)
                    : Colors.white,
                disabledBackgroundColor:
                    const Color(0xFF00E676).withValues(alpha: 0.15),
                disabledForegroundColor: const Color(0xFF00E676),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
