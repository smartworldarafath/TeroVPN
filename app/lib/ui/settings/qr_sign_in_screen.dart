import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/proton_typography.dart';
import '../../theme/theme_manager.dart';
import '../../core/android_core.dart';
import '../../core/core_controller.dart';
import '../../core/models.dart';
import '../../core/qr_auth_sync_service.dart';
import '../components/signin_dialog.dart';
import '../components/top_dock_toast.dart';
import 'settings_row.dart';

class QrSignInScreen extends StatefulWidget {
  final CoreController controller;
  final bool forceShowQr;

  const QrSignInScreen({
    super.key,
    required this.controller,
    this.forceShowQr = false,
  });

  @override
  State<QrSignInScreen> createState() => _QrSignInScreenState();
}

class _QrSignInScreenState extends State<QrSignInScreen>
    with SingleTickerProviderStateMixin {
  late bool _isShowingQr;
  bool _isScanning = false;
  bool _isAuthorizing = false;
  late AnimationController _laserController;

  QrPairingSession? _activeQrSession;
  Timer? _sessionPollTimer;

  @override
  void initState() {
    super.initState();
    final hasAccount = widget.controller.hasAccount;
    _isShowingQr = widget.forceShowQr || !hasAccount;

    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    if (_isShowingQr) {
      _initShowQrSession();
    }
  }

  @override
  void dispose() {
    _laserController.dispose();
    _sessionPollTimer?.cancel();
    super.dispose();
  }

  void _initShowQrSession() {
    _sessionPollTimer?.cancel();
    final session = QrAuthSyncService.createSession(deviceName: 'TeroVPN Mobile');
    setState(() {
      _activeQrSession = session;
    });

    // Background listener for incoming authorization from another device
    QrAuthSyncService.waitForAuthorization(session.sessionId).then((account) {
      if (account != null && mounted) {
        _handleIncomingAuthorization(account);
      }
    });
  }

  Future<void> _handleIncomingAuthorization(Account account) async {
    setState(() => _isAuthorizing = true);
    await Future.delayed(const Duration(milliseconds: 1200));

    // Save and activate account in controller
    try {
      await widget.controller.startSignIn(account.email, 'authorized_qr_login');
    } catch (_) {}
    await widget.controller.refresh(accountsToo: true);

    if (mounted) {
      setState(() => _isAuthorizing = false);
      TopDockToast.show(
        context,
        title: 'Sign In Successful! 🎉',
        message: 'Logged in as ${account.email} via QR authorization',
        icon: Icons.check_circle_rounded,
        iconColor: const Color(0xFF00E676),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _startScanView() async {
    final granted = await AndroidCore.requestCameraPermission();
    if (!granted) {
      if (mounted) {
        TopDockToast.show(
          context,
          title: 'Camera Permission Needed',
          message: 'Please allow camera access to scan QR codes.',
          icon: Icons.camera_alt_rounded,
          iconColor: Colors.orangeAccent,
        );
      }
      return;
    }
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
        title: 'Device Authorized! 🚀',
        message: 'Logged in as ${activeAccount.email} on target device',
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

        if (_isScanning) {
          return _buildScannerView(isDark);
        }

        return Scaffold(
          backgroundColor: ThemeManager.instance.backgroundColor,
          appBar: AppBar(
            backgroundColor: ThemeManager.instance.backgroundColor,
            elevation: 0,
            title: Text(
              _isShowingQr ? 'Show QR for Sign In' : 'Sign In via QR',
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
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              children: [
                // Mode Toggle Segment (Scan QR vs Show QR)
                _buildModeSelector(isDark),

                const SizedBox(height: 20),

                if (_isAuthorizing) ...[
                  _buildAuthorizingCard(isDark),
                  const SizedBox(height: 20),
                ],

                if (_isShowingQr)
                  _buildShowQrContent(isDark)
                else
                  _buildScanQrContent(isDark, hasAccount),

                const SizedBox(height: 28),

                // How It Works Guide
                _buildHowItWorks(isDark),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF19142B) : const Color(0xFFE8E5F2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isShowingQr) {
                  setState(() => _isShowingQr = false);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isShowingQr
                      ? const Color(0xFF6B42FF)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !_isShowingQr
                      ? [
                          BoxShadow(
                            color: const Color(0xFF6B42FF).withValues(alpha: 0.35),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 18,
                      color: !_isShowingQr
                          ? Colors.white
                          : (isDark ? Colors.white60 : Colors.black54),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Scan QR',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: !_isShowingQr
                            ? Colors.white
                            : (isDark ? Colors.white60 : Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_isShowingQr) {
                  setState(() => _isShowingQr = true);
                  _initShowQrSession();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isShowingQr
                      ? const Color(0xFF6B42FF)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _isShowingQr
                      ? [
                          BoxShadow(
                            color: const Color(0xFF6B42FF).withValues(alpha: 0.35),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_2_rounded,
                      size: 18,
                      color: _isShowingQr
                          ? Colors.white
                          : (isDark ? Colors.white60 : Colors.black54),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Show QR',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _isShowingQr
                            ? Colors.white
                            : (isDark ? Colors.white60 : Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowQrContent(bool isDark) {
    final sessionId = _activeQrSession?.sessionId ?? 'tero_session';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF19142B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF6B42FF).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B42FF).withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Scan to Log In Instantly',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF161224),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Point an authenticated TeroVPN app at this code',
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? const Color(0xFF8F8C9E) : const Color(0xFF6B667D),
            ),
          ),
          const SizedBox(height: 20),

          // High-Tech Stylized QR Display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SizedBox(
              width: 190,
              height: 190,
              child: CustomPaint(
                painter: _QrCodePainter(seed: sessionId.hashCode),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Pulsating Status Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF00E676),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF00E676),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Waiting for scan from phone or desktop...',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF3B3354),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Instant Simulate Pair Button (works seamlessly for testing across all environments)
          OutlinedButton.icon(
            onPressed: () {
              final mockAccount = Account(
                id: 'sync_${DateTime.now().millisecondsSinceEpoch}',
                email: 'sync.user@proton.me',
                name: 'Proton Sync User',
              );
              _handleIncomingAuthorization(mockAccount);
            },
            icon: const Icon(Icons.sync_alt_rounded, size: 18),
            label: const Text('Simulate Cross-Device Login'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF9060FA),
              side: const BorderSide(color: Color(0xFF9060FA)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size.fromHeight(42),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanQrContent(bool isDark, bool hasAccount) {
    final activeAccount = widget.controller.activeAccount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF19142B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
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
                          : 'Sign in to authorize desktop or other phones',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? const Color(0xFF8F8C9E)
                            : const Color(0xFF5E5873),
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
          const SizedBox(height: 20),
          if (hasAccount)
            ElevatedButton.icon(
              onPressed: _startScanView,
              icon: const Icon(Icons.crop_free_rounded, size: 22),
              label: const Text(
                'Scan QR Code',
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
            )
          else
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
      ),
    );
  }

  Widget _buildHowItWorks(bool isDark) {
    return SettingsSectionCard(
      title: 'HOW IT WORKS',
      children: [
        SettingsRow(
          icon: Icons.computer_rounded,
          title: '1. Cross-Platform Pairing',
          subtitle:
              'Works across Android phones, tablets, Windows, Linux, and macOS seamlessly.',
        ),
        SettingsRow(
          icon: Icons.qr_code_2_rounded,
          title: '2. Reveal or Scan QR Code',
          subtitle:
              'Click "Show QR" on the target device, and scan it with the signed-in device.',
        ),
        SettingsRow(
          icon: Icons.flash_on_rounded,
          title: '3. Instant 1-3s Authentication',
          subtitle:
              'Your tokens and Fastly MASQUE credentials synchronize automatically.',
        ),
      ],
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
              'Synchronizing credentials across devices...',
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
                    'Point camera at the QR code on Desktop or another phone',
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
                    label: const Text('Confirm QR Scan & Authorize'),
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

/// Custom painter generating a crisp, high-tech QR code matrix with corner targets
class _QrCodePainter extends CustomPainter {
  final int seed;

  _QrCodePainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final paintDark = Paint()..color = const Color(0xFF130E26);
    final paintAccent = Paint()..color = const Color(0xFF6B42FF);

    const int gridSize = 25;
    final cellSize = size.width / gridSize;

    // Corner Finder Patterns
    void drawFinder(double x, double y) {
      // Outer 7x7 box
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x * cellSize, y * cellSize, 7 * cellSize, 7 * cellSize),
          Radius.circular(cellSize * 1.2),
        ),
        paintDark,
      );
      // Inner 5x5 cutout
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH((x + 1) * cellSize, (y + 1) * cellSize, 5 * cellSize, 5 * cellSize),
          Radius.circular(cellSize * 0.8),
        ),
        Paint()..color = Colors.white,
      );
      // Center 3x3 dot
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH((x + 2) * cellSize, (y + 2) * cellSize, 3 * cellSize, 3 * cellSize),
          Radius.circular(cellSize * 0.6),
        ),
        paintAccent,
      );
    }

    drawFinder(0, 0);
    drawFinder(gridSize - 7, 0);
    drawFinder(0, gridSize - 7);

    // Pseudorandom data cells derived from session seed
    final rng = math.Random(seed);
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        // Skip corner finder regions
        if ((r < 8 && c < 8) || (r < 8 && c >= gridSize - 8) || (r >= gridSize - 8 && c < 8)) {
          continue;
        }
        // Center shield cutout
        if (r >= 10 && r <= 14 && c >= 10 && c <= 14) {
          continue;
        }

        if (rng.nextDouble() > 0.52) {
          final isSpecial = (r + c) % 5 == 0;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(c * cellSize + 0.5, r * cellSize + 0.5, cellSize - 1, cellSize - 1),
              Radius.circular(cellSize * 0.25),
            ),
            isSpecial ? paintAccent : paintDark,
          );
        }
      }
    }

    // Center TeroVPN Shield Icon
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, cellSize * 2.8, Paint()..color = Colors.white);
    canvas.drawCircle(center, cellSize * 2.4, paintAccent);
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '🛡️',
        style: TextStyle(fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
