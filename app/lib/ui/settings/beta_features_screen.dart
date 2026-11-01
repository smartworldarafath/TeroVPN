import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/proton_typography.dart';
import '../../theme/theme_manager.dart';
import '../../core/app_preferences.dart';
import '../components/top_dock_toast.dart';
import '../shell/dock1_jelly_bar.dart';
import '../shell/dock2_lens_bar.dart';

class BetaFeaturesScreen extends StatefulWidget {
  const BetaFeaturesScreen({super.key});

  @override
  State<BetaFeaturesScreen> createState() => _BetaFeaturesScreenState();
}

class _BetaFeaturesScreenState extends State<BetaFeaturesScreen>
    with TickerProviderStateMixin {
  late bool _betaEnabled;
  late String _activeDock;
  bool _isLoading = false;

  // 900ms Butter-smooth 3D Card Flip Animation for Reset Floating Window
  late AnimationController _resetFlipController;
  late Animation<double> _flipAnimation;
  bool _showResetDialog = false;

  int _previewIndex1 = 0;
  int _previewIndex2 = 1;

  @override
  void initState() {
    super.initState();
    _betaEnabled = AppPreferences.betaFeaturesEnabled;
    _activeDock = AppPreferences.selectedDockStyle;

    _resetFlipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _flipAnimation = CurvedAnimation(
      parent: _resetFlipController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _resetFlipController.dispose();
    super.dispose();
  }

  Future<void> _toggleBeta(bool enabled) async {
    if (enabled) {
      setState(() {
        _isLoading = true;
      });
      // 1-2 second high-tech loading simulation
      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      await AppPreferences.setBetaFeaturesEnabled(true);
      setState(() {
        _betaEnabled = true;
        _isLoading = false;
      });
      if (mounted) {
        TopDockToast.show(
          context,
          title: 'Beta Engine Initialized',
        message: 'Experimental UI features are now unlocked',
        icon: Icons.auto_awesome_rounded,
        iconColor: const Color(0xFFC084FC),
      );
      }
    } else {
      await AppPreferences.setBetaFeaturesEnabled(false);
      await AppPreferences.setSelectedDockStyle('default');
      setState(() {
        _betaEnabled = false;
        _activeDock = 'default';
        _showResetDialog = false;
      });
      _resetFlipController.reset();
      ThemeManager.instance.refresh();
    }
  }

  bool get _hasBetaApplied => _activeDock != 'default';

  void _openResetConfirmation() {
    if (!_hasBetaApplied) return;
    setState(() => _showResetDialog = true);
    _resetFlipController.forward();
  }

  void _cancelResetConfirmation() {
    _resetFlipController.reverse().then((_) {
      if (mounted) setState(() => _showResetDialog = false);
    });
  }

  Future<void> _executeReset() async {
    await AppPreferences.setSelectedDockStyle('default');
    setState(() {
      _activeDock = 'default';
    });
    ThemeManager.instance.refresh();
    _resetFlipController.reverse().then((_) {
      if (mounted) {
        setState(() => _showResetDialog = false);
        TopDockToast.show(
          context,
          title: 'Beta Features Reset',
          message: 'Default official dock and styles restored',
          icon: Icons.check_circle_rounded,
          iconColor: const Color(0xFF00E676),
        );
      }
    });
  }

  Future<void> _applyDock(String dockStyle) async {
    setState(() => _activeDock = dockStyle);
    await AppPreferences.setSelectedDockStyle(dockStyle);
    ThemeManager.instance.refresh();
    if (mounted) {
      TopDockToast.show(
        context,
        title: 'New Dock Applied! ✨',
        message: dockStyle == 'dock1'
            ? '3D Jelly Glassmorphic Bar activated'
            : 'Liquid Glass Lens Bar activated',
        icon: Icons.dock_rounded,
        iconColor: const Color(0xFFA855F7),
      );
    }
  }

  Future<void> _closeDock() async {
    setState(() => _activeDock = 'default');
    await AppPreferences.setSelectedDockStyle('default');
    ThemeManager.instance.refresh();
    if (mounted) {
      TopDockToast.show(
        context,
        title: 'Dock Style Removed',
        message: 'Restored default standard navigation dock',
        icon: Icons.restore_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.instance.isDarkMode;

    return Scaffold(
      backgroundColor: ThemeManager.instance.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeManager.instance.backgroundColor,
        elevation: 0,
        title: Text(
          'Beta features',
          style: ProtonTypography.titleLarge.copyWith(
            fontSize: 20,
            color: ThemeManager.instance.textPrimaryColor,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: ThemeManager.instance.textPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              children: [
                // Header Card with On/Off Switch and Reset Button
                _buildHeaderCard(isDark),

                const SizedBox(height: 24),

                if (_isLoading)
                  _buildLoadingShimmer(isDark)
                else if (!_betaEnabled)
                  _buildDisabledPlaceholder(isDark)
                else ...[
                  // Section: New Dock Styles
                  Row(
                    children: [
                      const Icon(Icons.style_rounded,
                          color: Color(0xFF9060FA), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'NEW DOCK STYLES',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: isDark
                              ? const Color(0xFF9D94B8)
                              : const Color(0xFF635B7E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Dock 1: 3D Jelly Glassmorphic Bar
                  _buildDockCard(
                    dockKey: 'dock1',
                    title: 'Dock 1 : 3D Jelly Glassmorphic Bar',
                    badge: 'Jelly Capsule',
                    description:
                        'Deep obsidian violet glass bar with animated glossy purple jelly capsule indicator.',
                    previewWidget: Dock1JellyBar(
                      currentIndex: _previewIndex1,
                      onTabSelected: (i) => setState(() => _previewIndex1 = i),
                      isInteractivePreview: true,
                    ),
                    isDark: isDark,
                  ),



                  const SizedBox(height: 20),

                  // Dock 2: Liquid Glass Lens Bar
                  _buildDockCard(
                    dockKey: 'dock2',
                    title: 'Dock 2 : Liquid Glass Lens Bar',
                    badge: 'Refractive Lens',
                    description:
                        'Elevated refractive optical lens with dual curved specular reflection meniscus.',
                    previewWidget: Dock2LensBar(
                      currentIndex: _previewIndex2,
                      onTabSelected: (i) => setState(() => _previewIndex2 = i),
                      isInteractivePreview: true,
                    ),
                    isDark: isDark,
                  ),

                  const SizedBox(height: 40),
                ],
              ],
            ),
          ),

          // Floating 900ms 3D Card Flip Confirmation Window
          if (_showResetDialog) _buildFloatingResetDialog(isDark),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181329) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      children: [
                        Text(
                          'Experimental Lab',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF161224),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9060FA).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF9060FA).withValues(alpha: 0.5),
                              width: 0.8,
                            ),
                          ),
                          child: const Text(
                            'BETA 2.2',
                            style: TextStyle(
                              fontSize: 9.0,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFC084FC),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Preview cutting-edge UI components',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF8C869E) : const Color(0xFF6B667D),
                      ),
                    ),
                  ],
                ),
              ),

              // Action Switch & Reset Button Row
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Reset Button (Clickable only if beta applied)
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: _hasBetaApplied ? 1.0 : 0.35,
                    child: GestureDetector(
                      onTap: _hasBetaApplied ? _openResetConfirmation : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: _hasBetaApplied
                              ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _hasBetaApplied
                                ? const Color(0xFFEF4444).withValues(alpha: 0.45)
                                : Colors.white12,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.restart_alt_rounded,
                              size: 15,
                              color: _hasBetaApplied
                                  ? const Color(0xFFEF4444)
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Reset',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: _hasBetaApplied
                                    ? const Color(0xFFEF4444)
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ON/OFF Switch
                  Switch.adaptive(
                    value: _betaEnabled,
                    activeThumbColor: const Color(0xFF6B42FF),
                    onChanged: _toggleBeta,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181329) : Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3.5,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9060FA)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Initializing Beta Modules...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF161224),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Compiling 3D navigation shaders and materials',
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? const Color(0xFF8C869E) : const Color(0xFF6B667D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledPlaceholder(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151024) : const Color(0xFFF0EDF7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.science_outlined,
              size: 44, color: isDark ? const Color(0xFF5E5677) : const Color(0xFF8F88A7)),
          const SizedBox(height: 14),
          Text(
            'Beta Features Are Switched Off',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : const Color(0xFF2C2442),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Turn on the switch above to activate experimental dock styles and visual upgrades.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF7E7796) : const Color(0xFF6B667D),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDockCard({
    required String dockKey,
    required String title,
    required String badge,
    required String description,
    required Widget previewWidget,
    required bool isDark,
  }) {
    final isApplied = _activeDock == dockKey;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181329) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isApplied
              ? const Color(0xFF6B42FF)
              : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black12),
          width: isApplied ? 1.6 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isApplied
                ? const Color(0xFF6B42FF).withValues(alpha: 0.22)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Badge Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF161224),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF8C869E) : const Color(0xFF6B667D),
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
                        'APPLIED',
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

          const SizedBox(height: 18),

          // Interactive Mini Preview of the HTML Dock
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
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

          // 2 Action Buttons: Apply & Close
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _applyDock(dockKey),
                  icon: Icon(
                    isApplied ? Icons.check_rounded : Icons.palette_rounded,
                    size: 18,
                  ),
                  label: Text(
                    isApplied ? 'Applied' : 'Apply',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isApplied
                        ? const Color(0xFF00E676)
                        : const Color(0xFF6B42FF),
                    foregroundColor:
                        isApplied ? const Color(0xFF0A2E1C) : Colors.white,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isApplied ? _closeDock : null,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text(
                    'Close',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white70 : Colors.black87,
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.black12,
                    ),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 900ms Butter-Smooth 3D Card Flip Animation Dialog
  Widget _buildFloatingResetDialog(bool isDark) {
    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, _) {
        final progress = _flipAnimation.value;
        if (progress <= 0.01) return const SizedBox.shrink();

        // 3D Card Flip Matrix
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0014)
          ..rotateY((1.0 - progress) * (math.pi / 2));

        return Stack(
          children: [
            // Scrim
            GestureDetector(
              onTap: _cancelResetConfirmation,
              child: Container(
                color: Colors.black.withValues(alpha: 0.55 * progress),
              ),
            ),

            Center(
              child: Transform(
                transform: matrix,
                alignment: Alignment.topRight,
                child: Transform.scale(
                  scale: 0.4 + 0.6 * progress,
                  alignment: Alignment.topRight,
                  child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1736) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.65),
                        blurRadius: 36,
                        spreadRadius: 4,
                        offset: const Offset(0, 14),
                      ),
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFEF4444),
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Are you sure?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF161224),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This will remove all applied beta dock styles and return your navigation to the official default.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFF9D94B8)
                              : const Color(0xFF6B667D),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _cancelResetConfirmation,
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    isDark ? Colors.white70 : Colors.black87,
                                side: BorderSide(
                                  color: isDark ? Colors.white24 : Colors.black26,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                minimumSize: const Size.fromHeight(44),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _executeReset,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEF4444),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                minimumSize: const Size.fromHeight(44),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Sure',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
