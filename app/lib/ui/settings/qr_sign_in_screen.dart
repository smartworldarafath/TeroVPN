import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/proton_typography.dart';
import '../../theme/theme_manager.dart';
import '../../core/core_controller.dart';
import '../../core/qr_auth_sync_service.dart';
import '../components/signin_dialog.dart';
import '../components/top_dock_toast.dart';
import 'settings_row.dart';

class QrSignInScreen extends StatefulWidget {
  final CoreController controller;

  const QrSignInScreen({super.key, required this.controller});

  @override
  State<QrSignInScreen> createState() => _QrSignInScreenState();
}

class _QrSignInScreenState extends State<QrSignInScreen> with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  bool _isAuthorizing = false;
  late AnimationController _laserController;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserController.dispose();
    super.dispose();
  }

  void _startScanView() {
    setState(() {
      _isScanning = true;
    });
  }

  Future<void> _handleScanSuccess(String scannedPayload) async {
    setState(() {
      _isScanning = false;
      _isAuthorizing = true;
    });

    final activeAccount = widget.controller.activeAccount;
    if (activeAccount == null) {
      setState(() => _isAuthorizing = false);
      TopDockToast.show(
        context,
        title: 'Sign In Required',
        message: 'No active account on phone to authorize.',
        icon: Icons.error_outline_rounded,
        iconColor: Colors.redAccent,
      );
      return;
    }

    // Extract session ID
    String sessionId = 'demo_desktop_session';
    final uri = Uri.tryParse(scannedPayload);
    if (uri != null && uri.queryParameters.containsKey('sid')) {
      sessionId = uri.queryParameters['sid']!;
    }

    // 1-2s smooth authorizing simulation & sync
    await Future.delayed(const Duration(milliseconds: 1400));
    await QrAuthSyncService.authorizeSession(sessionId, activeAccount);

    if (mounted) {
      setState(() => _isAuthorizing = false);
      TopDockToast.show(
        context,
        title: 'Desktop Authorized! 🚀',
        message: 'Logged in as ${activeAccount.email} on Desktop',
        icon: Icons.check_circle_rounded,
        iconColor: const Color(0xFF00E676),
      );
      Navigator.of(context).pop();
    }
  }

  String _maskEmail(String email) {
    if (!email.contains('@')) return email;
    final parts = email.split('@');
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return '$name••@$domain';
    return '${name.substring(0, 2)}•••••@$domain';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.controller, ThemeManager.instance]),
      builder: (context, _) {
        final isDark = ThemeManager.instance.isDarkMode;
        final hasAccount = widget.controller.hasAccount;
        final activeAccount = widget.controller.activeAccount;

        if (_isScanning) {
          return _buildScannerView(isDark);
        }

        return Scaffold(
          backgroundColor: ThemeManager.instance.backgroundColor,
          appBar: AppBar(
            backgroundColor: ThemeManager.instance.backgroundColor,
            elevation: 0,
            title: Text(
              'Sign In via QR',
              style: ProtonTypography.titleLarge.copyWith(
                fontSize: 20,
                color: ThemeManager.instance.textPrimaryColor,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: ThemeManager.instance.textPrimaryColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                if (_isAuthorizing) ...[
                  _buildAuthorizingCard(isDark),
                  const SizedBox(height: 20),
                ],

                // Active Account Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF19142B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: hasAccount
                          ? const Color(0xFF6B42FF).withValues(alpha: 0.4)
                          : (isDark ? Colors.white12 : Colors.black12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: hasAccount
                            ? const Color(0xFF6B42FF).withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6B42FF).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner_rounded,
                              color: Color(0xFF6B42FF),
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hasAccount ? 'Mobile Account Ready' : 'No Account Logged In',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF161224),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  hasAccount
                                      ? _maskEmail(activeAccount?.email ?? 'user')
                                      : 'Sign in on phone first to authorize desktop',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? const Color(0xFF8F8C9E) : const Color(0xFF5E5873),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (hasAccount)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E676).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF00E676),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (hasAccount) ...[
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _startScanView,
                          icon: const Icon(Icons.crop_free_rounded, size: 22),
                          label: const Text(
                            'Scan Desktop QR Code',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B42FF),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: () => SignInDialog.show(context, widget.controller),
                          icon: const Icon(Icons.login_rounded, size: 20),
                          label: const Text('Sign In on Phone'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B42FF),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // How it works
                SettingsSectionCard(
                  title: 'HOW IT WORKS',
                  children: [
                    SettingsRow(
                      icon: Icons.computer_rounded,
                      title: '1. Open TeroVPN Desktop',
                      subtitle: 'Launch TeroVPN on your PC or Mac and navigate to Settings → Account.',
                    ),
                    SettingsRow(
                      icon: Icons.qr_code_2_rounded,
                      title: '2. Display Desktop QR',
                      subtitle: 'Click "Sign in via QR" on your desktop to reveal your unique pairing QR code.',
                    ),
                    SettingsRow(
                      icon: Icons.camera_alt_rounded,
                      title: '3. Scan with Phone',
                      subtitle: 'Tap the Scan button above. Your phone account will authenticate the desktop in 1-3s.',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuthorizingCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF6B42FF).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6B42FF).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B42FF)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Authorizing desktop session with your Firefox Account token...',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF161224),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerView(bool isDark) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background viewfinder overlay
          Container(
            color: Colors.black.withValues(alpha: 0.85),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                        onPressed: () => setState(() => _isScanning = false),
                      ),
                      const Text(
                        'Align QR in Frame',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                const Spacer(),

                // Scanner Target Frame
                Center(
                  child: SizedBox(
                    width: 260,
                    height: 260,
                    child: Stack(
                      children: [
                        // Viewfinder border
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF6B42FF),
                              width: 2.5,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),

                        // Animated Laser Sweep
                        AnimatedBuilder(
                          animation: _laserController,
                          builder: (context, _) {
                            final topPos = _laserController.value * 230.0;
                            return Positioned(
                              top: topPos,
                              left: 12,
                              right: 12,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00E676),
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0xFF00E676),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Point camera at the QR code on TeroVPN Desktop',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13.5),
                  ),
                ),

                const Spacer(),

                // Simulate Scan / Pair button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: ElevatedButton.icon(
                    onPressed: () => _handleScanSuccess('terovpn://pair?sid=desktop_${DateTime.now().millisecondsSinceEpoch}'),
                    icon: const Icon(Icons.flash_on_rounded),
                    label: const Text('Confirm Desktop Scan & Authorize'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B42FF),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
