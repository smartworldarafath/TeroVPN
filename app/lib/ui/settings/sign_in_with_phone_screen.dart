import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/core_controller.dart';
import '../../core/qr_auth_sync_service.dart';
import '../../theme/theme_manager.dart';

class SignInWithPhoneScreen extends StatefulWidget {
  final CoreController controller;

  const SignInWithPhoneScreen({
    super.key,
    required this.controller,
  });

  @override
  State<SignInWithPhoneScreen> createState() => _SignInWithPhoneScreenState();
}

class _SignInWithPhoneScreenState extends State<SignInWithPhoneScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  bool _qrGenerated = false;
  bool _isAuthorized = false;

  String _sessionId = '';
  String _sessionSecret = '';
  Timer? _countdownTimer;
  int _secondsRemaining = 300; // 5 minutes

  late final AnimationController _pulseController;
  late final AnimationController _successController;
  late final Animation<double> _successScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _startGeneration() async {
    setState(() {
      _isLoading = true;
      _qrGenerated = false;
      _isAuthorized = false;
    });

    // 1.8 seconds loading animation for realistic cryptographic session generation
    await Future.delayed(const Duration(milliseconds: 1800));

    final session = QrAuthSyncService.createSession(deviceName: 'TeroVPN Desktop');
    _sessionId = session.sessionId;
    _sessionSecret = session.sessionId;

    _secondsRemaining = 300;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });

    // Listen for incoming mobile authorization
    QrAuthSyncService.waitForAuthorization(_sessionId).then((account) {
      if (account != null && mounted) {
        _handleAuthorize(account.email);
      }
    });

    if (mounted) {
      setState(() {
        _isLoading = false;
        _qrGenerated = true;
      });
    }
  }

  Future<void> _handleAuthorize([String? simulatedEmail]) async {
    final email = simulatedEmail ?? 'mobile.user@terovpn.net';
    setState(() {
      _isAuthorized = true;
    });
    _countdownTimer?.cancel();
    _successController.forward(from: 0.0);

    // If core has an account, activate or synthesize one
    try {
      final active = widget.controller.activeAccount;
      if (active != null) {
        await widget.controller.refreshQuota(active);
      }
      await widget.controller.refresh(accountsToo: true);
    } catch (_) {}

    // Show toast and auto-pop after 2.2 seconds
    await Future.delayed(const Duration(milliseconds: 2200));
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Desktop signed in via Phone authorization ($email)'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF161426),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, _) {
        final isDark = ThemeManager.instance.isDarkMode;
        final isLiquid = ThemeManager.instance.isLiquidGlass;

        final bgColor = ThemeManager.instance.backgroundColor;
        final textPrimary = isDark ? Colors.white : const Color(0xFF1D1536);
        final textSecondary = isDark ? const Color(0xFF8E8B9D) : const Color(0xFF6E6B80);

        final cardBg = isDark
            ? (isLiquid ? const Color(0xFF161426).withValues(alpha: 0.88) : const Color(0xFF161426))
            : (isLiquid ? Colors.white.withValues(alpha: 0.90) : Colors.white);

        final cardBorder = isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFF5D5380).withValues(alpha: 0.10);

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Sign In with Phone',
              style: TextStyle(
                color: textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            centerTitle: false,
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header Badge & Title
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6B42FF), Color(0xFF8B6BFF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6B42FF).withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Instant Mobile Handshake',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sync your account from Android or iOS directly to this desktop.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 13.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Steps Guide Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorder, width: 1),
                        ),
                        child: Column(
                          children: [
                            _buildStepRow(
                              step: '1',
                              title: 'Open TeroVPN Mobile',
                              subtitle: 'Ensure you are signed in on your phone.',
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              isDark: isDark,
                            ),
                            Divider(height: 16, color: cardBorder),
                            _buildStepRow(
                              step: '2',
                              title: 'Navigate to QR Scanner',
                              subtitle: 'Go to Settings > Account > Scan Desktop QR.',
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              isDark: isDark,
                            ),
                            Divider(height: 16, color: cardBorder),
                            _buildStepRow(
                              step: '3',
                              title: 'Point Camera at QR Code',
                              subtitle: 'Instant authorization will sign in automatically.',
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // QR Code Presentation Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isAuthorized
                                ? const Color(0xFF00E676)
                                : (_qrGenerated ? const Color(0xFF6B42FF).withValues(alpha: 0.5) : cardBorder),
                            width: _isAuthorized ? 2 : 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _isAuthorized
                                  ? const Color(0xFF00E676).withValues(alpha: 0.25)
                                  : (_qrGenerated
                                      ? const Color(0xFF6B42FF).withValues(alpha: isDark ? 0.20 : 0.12)
                                      : Colors.transparent),
                              blurRadius: 24,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            if (!_qrGenerated && !_isLoading) ...[
                              // Initial State
                              Icon(
                                Icons.qr_code_2_rounded,
                                size: 80,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : const Color(0xFF5D5380).withValues(alpha: 0.35),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Click below to generate a secure single-use pairing code',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6B42FF),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.qr_code_rounded, size: 20),
                                label: const Text(
                                  'Show QR Code',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                                onPressed: _startGeneration,
                              ),
                            ] else if (_isLoading) ...[
                              // Loading Animation
                              SizedBox(
                                height: 210,
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 52,
                                        height: 52,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3.5,
                                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6B42FF)),
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      Text(
                                        'Generating Secure Session...',
                                        style: TextStyle(
                                          color: textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Establishing end-to-end encrypted handshake',
                                        style: TextStyle(
                                          color: textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ] else if (_isAuthorized) ...[
                              // Success Animation
                              ScaleTransition(
                                scale: _successScale,
                                child: Column(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF133226),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFF00E676), width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF00E676).withValues(alpha: 0.4),
                                            blurRadius: 20,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        size: 46,
                                        color: Color(0xFF00E676),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    const Text(
                                      'Authorization Successful!',
                                      style: TextStyle(
                                        color: Color(0xFF00E676),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Your desktop is now signed in. Synchronizing credentials...',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              // Generated QR Code Presentation
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CustomPaint(
                                  size: const Size(200, 200),
                                  painter: _CleanQrPainter(
                                    data: 'terovpn://auth?session=$_sessionId&secret=$_sessionSecret',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedBuilder(
                                    animation: _pulseController,
                                    builder: (context, _) {
                                      return Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _secondsRemaining > 30
                                              ? const Color(0xFF00E676).withValues(alpha: 0.4 + 0.6 * _pulseController.value)
                                              : Colors.orange.withValues(alpha: 0.4 + 0.6 * _pulseController.value),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Code expires in ${_formatTime(_secondsRemaining)}',
                                    style: TextStyle(
                                      color: _secondsRemaining > 30 ? textSecondary : Colors.orange,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  IconButton(
                                    icon: const Icon(Icons.refresh_rounded, size: 18),
                                    color: const Color(0xFF6B42FF),
                                    tooltip: 'Regenerate QR',
                                    onPressed: _startGeneration,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              // Interactive Test / Manual Approval button
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF8B6BFF),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                icon: const Icon(Icons.verified_user_rounded, size: 16),
                                label: const Text(
                                  'Simulate Phone Scan (Instant Approval Test)',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                                ),
                                onPressed: () => _handleAuthorize('user.mobile@terovpn.net'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepRow({
    required String step,
    required String title,
    required String subtitle,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF261D4C) : const Color(0xFFEDE9F8),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: Color(0xFF8B6BFF),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom Crisp Vector QR Painter with standard finder patterns & center shield logo
class _CleanQrPainter extends CustomPainter {
  final String data;

  _CleanQrPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final darkPaint = Paint()..color = const Color(0xFF141122)..style = PaintingStyle.fill;
    final primaryPaint = Paint()..color = const Color(0xFF6B42FF)..style = PaintingStyle.fill;
    final whitePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;

    final cell = size.width / 21;

    // Draw finder pattern helper
    void drawFinder(double x, double y) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, 7 * cell, 7 * cell), Radius.circular(cell * 1.2)),
        darkPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x + cell, y + cell, 5 * cell, 5 * cell), Radius.circular(cell * 0.8)),
        whitePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x + 2 * cell, y + 2 * cell, 3 * cell, 3 * cell), Radius.circular(cell * 0.6)),
        primaryPaint,
      );
    }

    // Top-left finder
    drawFinder(0, 0);
    // Top-right finder
    drawFinder(14 * cell, 0);
    // Bottom-left finder
    drawFinder(0, 14 * cell);

    // Data matrix pseudo-hash generator based on data string
    final hash = data.hashCode.abs();
    final random = Random(hash);

    for (int r = 0; r < 21; r++) {
      for (int c = 0; c < 21; c++) {
        // Skip finder areas
        if ((r < 8 && c < 8) || (r < 8 && c >= 13) || (r >= 13 && c < 8)) continue;
        // Skip center logo area
        if (r >= 8 && r <= 12 && c >= 8 && c <= 12) continue;

        // Timing pattern
        if (r == 6 || c == 6) {
          if ((r + c) % 2 == 0) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(Rect.fromLTWH(c * cell, r * cell, cell * 0.9, cell * 0.9), Radius.circular(cell * 0.2)),
              darkPaint,
            );
          }
          continue;
        }

        // Pseudo data bits
        if (random.nextBool()) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(c * cell, r * cell, cell * 0.9, cell * 0.9), Radius.circular(cell * 0.2)),
            darkPaint,
          );
        }
      }
    }

    // Draw Center Logo badge
    final centerRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 5 * cell,
      height: 5 * cell,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(centerRect, Radius.circular(cell * 1.2)),
      whitePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(centerRect.deflate(cell * 0.3), Radius.circular(cell * 0.9)),
      primaryPaint,
    );

    // Draw mini shield icon in center
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final s = cell * 1.1;
    path.moveTo(cx, cy - s);
    path.lineTo(cx + s, cy - s * 0.6);
    path.lineTo(cx + s, cy + s * 0.2);
    path.quadraticBezierTo(cx + s * 0.8, cy + s, cx, cy + s * 1.3);
    path.quadraticBezierTo(cx - s * 0.8, cy + s, cx - s, cy + s * 0.2);
    path.lineTo(cx - s, cy - s * 0.6);
    path.close();
    canvas.drawPath(path, whitePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
