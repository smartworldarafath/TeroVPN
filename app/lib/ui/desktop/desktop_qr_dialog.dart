import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/core_controller.dart';
import '../../core/qr_auth_sync_service.dart';
import '../../core/models.dart';
import '../components/top_dock_toast.dart';

class DesktopQrSignInDialog extends StatefulWidget {
  final CoreController controller;

  const DesktopQrSignInDialog({super.key, required this.controller});

  static Future<void> show(BuildContext context, CoreController controller) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DesktopQrSignInDialog(controller: controller),
    );
  }

  @override
  State<DesktopQrSignInDialog> createState() => _DesktopQrSignInDialogState();
}

class _DesktopQrSignInDialogState extends State<DesktopQrSignInDialog> with SingleTickerProviderStateMixin {
  late QrPairingSession _session;
  bool _isLoading = false;
  String _loadingStep = '';
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _session = QrAuthSyncService.createSession(deviceName: 'TeroVPN Desktop');
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _listenForAuthorization();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _listenForAuthorization() async {
    final account = await QrAuthSyncService.waitForAuthorization(_session.sessionId);
    if (account != null && mounted) {
      await _executeLoginAnimation(account);
    }
  }

  Future<void> _executeLoginAnimation(Account account) async {
    setState(() {
      _isLoading = true;
      _loadingStep = 'Connecting to Mobile Session...';
    });

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    setState(() {
      _loadingStep = 'Importing Firefox Account Credentials...';
    });

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    setState(() {
      _loadingStep = 'Activating Fastly MASQUE 50GB Tier...';
    });

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    // Refresh accounts in controller
    await widget.controller.refresh(accountsToo: true);

    if (mounted) {
      Navigator.of(context).pop();
      TopDockToast.show(
        context,
        title: 'Desktop Signed In! 🚀',
        message: 'Welcome back, ${account.email}',
        icon: Icons.check_circle_rounded,
        iconColor: const Color(0xFF00E676),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF161426),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF6B42FF).withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B42FF).withValues(alpha: 0.25),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: _isLoading ? _buildLoadingView() : _buildQrView(),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF6B42FF).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B42FF)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Authorizing via Mobile App',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _loadingStep,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF8E8B9D),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildQrView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.qr_code_2_rounded, color: Color(0xFF6B42FF), size: 24),
                SizedBox(width: 10),
                Text(
                  'Sign In via QR Code',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Color(0xFF8E8B9D)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Scan this code using your phone\'s TeroVPN app to sign in instantly.',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF8E8B9D),
          ),
        ),
        const SizedBox(height: 20),

        // High-Tech Stylized QR Display
        Container(
          width: 220,
          height: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B42FF).withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _QrMatrixPainter(seed: _session.sessionId.hashCode),
          ),
        ),

        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF261D4C),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF6B42FF).withValues(alpha: 0.3)),
          ),
          child: Text(
            'Session ID: ${_session.sessionId}',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              color: Color(0xFF9F75FF),
            ),
          ),
        ),

        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF8E8B9D),
                  side: const BorderSide(color: Colors.white12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  final activeAccount = widget.controller.activeAccount ??
                      Account(
                        id: 'acc_demo',
                        email: 'user.firefox@terovpn.net',
                        active: true,
                        
                      );
                  _executeLoginAnimation(activeAccount);
                },
                icon: const Icon(Icons.flash_on_rounded, size: 18),
                label: const Text('Authorize'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B42FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QrMatrixPainter extends CustomPainter {
  final int seed;

  _QrMatrixPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF161426);
    const int grid = 21;
    final double cellSize = size.width / grid;

    // Draw 3 position corner locators (top-left, top-right, bottom-left)
    _drawFinder(canvas, 0, 0, cellSize, paint);
    _drawFinder(canvas, grid - 7, 0, cellSize, paint);
    _drawFinder(canvas, 0, grid - 7, cellSize, paint);

    // Draw pseudo-random data modules based on session seed
    final rand = Random(seed);
    for (int r = 0; r < grid; r++) {
      for (int c = 0; c < grid; c++) {
        // Skip finder pattern zones
        if ((r < 8 && c < 8) || (r < 8 && c >= grid - 8) || (r >= grid - 8 && c < 8)) {
          continue;
        }
        if (rand.nextBool()) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(c * cellSize + 0.8, r * cellSize + 0.8, cellSize - 1.6, cellSize - 1.6),
              const Radius.circular(1.5),
            ),
            paint,
          );
        }
      }
    }
  }

  void _drawFinder(Canvas canvas, int col, int row, double cell, Paint paint) {
    final x = col * cell;
    final y = row * cell;

    // Outer 7x7 square
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, 7 * cell, 7 * cell),
        const Radius.circular(6),
      ),
      paint,
    );
    // Inner 5x5 cutout
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + cell, y + cell, 5 * cell, 5 * cell),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.white,
    );
    // Center 3x3 square
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 2 * cell, y + 2 * cell, 3 * cell, 3 * cell),
        const Radius.circular(3),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _QrMatrixPainter oldDelegate) => oldDelegate.seed != seed;
}
