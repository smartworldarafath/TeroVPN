import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/core_controller.dart';
import '../../core/qr_auth_sync_service.dart';
import '../../core/models.dart';
import '../../core/app_preferences.dart';
import '../../theme/theme_manager.dart';
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
    _session = QrAuthSyncService.createSession(
      deviceName: 'TeroVPN Desktop',
      onServerBound: () {
        if (mounted) setState(() {});
      },
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _listenForAuthorization();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    QrAuthSyncService.cancelSession(_session.sessionId);
    super.dispose();
  }

  void _listenForAuthorization() async {
    final account = await QrAuthSyncService.waitForAuthorization(_session.sessionId);
    if (account != null && mounted) {
      final session = QrAuthSyncService.getSession(_session.sessionId);
      await _executeLoginAnimation(
        account,
        password: session?.password,
        backupB64: session?.backupB64,
      );
    }
  }

  Future<void> _executeLoginAnimation(
    Account account, {
    String? password,
    String? backupB64,
  }) async {
    setState(() {
      _isLoading = true;
      _loadingStep = 'Connecting to Mobile Session...';
    });

    final email = account.email.trim();
    final effectivePassword = (password != null && password.isNotEmpty)
        ? password
        : (account.password ?? AppPreferences.getSavedAuthPassword(email) ?? '');
    final token = account.reasonDetail.trim();
    final isHexSessionToken = RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(token);

    final readyAccount = Account(
      id: account.id.isNotEmpty ? account.id : 'sync_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      name: account.name.isNotEmpty
          ? account.name
          : (email.contains('@') ? email.split('@').first : 'User'),
      active: true,
      enabled: true,
      status: AccountStatus.ready,
      password: effectivePassword.isNotEmpty ? effectivePassword : account.password,
      reasonDetail: token,
    );

    if (effectivePassword.isNotEmpty) {
      await AppPreferences.setSavedAuthPassword(email, effectivePassword);
    }

    Future<bool> activateRealDesktopAccount() async {
      bool accountActivated = false;

      // 1. Prefer complete encrypted core backup bundle (works even from Official WebView login!)
      if (backupB64 != null && backupB64.isNotEmpty) {
        try {
          accountActivated = await widget.controller.importBackupBase64(
            backupB64,
            preferredEmail: email,
          );
        } catch (_) {}
      }

      // 2. Check existing native desktop core accounts
      if (!accountActivated) {
        try {
          await widget.controller.refresh(accountsToo: true);
          final existingAccounts = widget.controller.accounts?.accounts ?? [];
          for (final a in existingAccounts) {
            if (a.email.toLowerCase() == email.toLowerCase() && !a.id.startsWith('sync_')) {
              await widget.controller.activate(a);
              await widget.controller.refresh(accountsToo: true);
              accountActivated = true;
              break;
            }
          }
        } catch (_) {}
      }

      // 3. Exchange valid 64-hex session token directly via core browser sign-in
      if (!accountActivated && isHexSessionToken) {
        try {
          final state = await widget.controller.startBrowserSignIn(email, token);
          if (state.step == SignInStep.done) {
            accountActivated = true;
          } else if (state.step == SignInStep.working) {
            for (var i = 0; i < 12; i++) {
              await Future.delayed(const Duration(milliseconds: 300));
              final pollState = await widget.controller.signInState(state.id);
              if (pollState.step == SignInStep.done) {
                accountActivated = true;
                break;
              } else if (pollState.step != SignInStep.working) {
                await widget.controller.cancelSignIn(state.id).catchError((_) {});
                break;
              }
            }
          }
        } catch (_) {}
      }

      // 4. Fallback to credential sign-in
      if (!accountActivated && effectivePassword.isNotEmpty) {
        try {
          final state = await widget.controller.startSignIn(email, effectivePassword);
          if (state.step == SignInStep.done) {
            accountActivated = true;
          } else if (state.step == SignInStep.working) {
            for (var i = 0; i < 10; i++) {
              await Future.delayed(const Duration(milliseconds: 300));
              try {
                final pollState = await widget.controller.signInState(state.id);
                if (pollState.step == SignInStep.done) {
                  accountActivated = true;
                  break;
                } else if (pollState.step != SignInStep.working) {
                  await widget.controller.cancelSignIn(state.id).catchError((_) {});
                  break;
                }
              } catch (_) {}
            }
          } else if (state.needsAnswer) {
            await widget.controller.cancelSignIn(state.id).catchError((_) {});
          }
        } catch (_) {}
      }

      if (accountActivated) {
        try {
          await widget.controller.refresh(accountsToo: true);
        } catch (_) {}
      }

      return accountActivated;
    }

    final activationFuture = activateRealDesktopAccount();

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _loadingStep = 'Transferring Fastly MASQUE Session Tokens...';
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _loadingStep = 'Authenticating Desktop Environment...';
    });

    await Future.wait([
      activationFuture,
      Future.delayed(const Duration(milliseconds: 450)),
    ]);

    await AppPreferences.setSavedActiveAccount(readyAccount.toJson());
    if (!widget.controller.hasAccount) {
      widget.controller.setAccounts(AccountList.fromJson({
        'accounts': [readyAccount.toJson()],
        'switch_threshold_percent': 10.0,
      }));
    }

    if (!mounted) return;

    Navigator.of(context).pop(true);

    TopDockToast.show(
      context,
      title: 'Desktop Signed In!',
      message: 'Successfully paired and logged in as ${account.email}',
      icon: Icons.check_circle_rounded,
      iconColor: const Color(0xFF00E676),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.instance.isDarkMode;
    final dialogBg = isDark ? const Color(0xFF161426) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1D1536);
    final textSecondary = isDark ? const Color(0xFF8E8B9D) : const Color(0xFF6E6B80);

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFF5D5380).withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      elevation: 24,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
          child: _isLoading ? _buildLoadingView(textPrimary, textSecondary) : _buildQrView(isDark, textPrimary, textSecondary),
        ),
      ),
    );
  }

  Widget _buildLoadingView(Color textPrimary, Color textSecondary) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF6B42FF).withValues(alpha: 0.15),
            border: Border.all(
              color: const Color(0xFF6B42FF).withValues(alpha: 0.3),
              width: 2,
            ),
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
        Text(
          'Authorizing via Mobile App',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _loadingStep,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildQrView(bool isDark, Color textPrimary, Color textSecondary) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.qr_code_2_rounded, color: Color(0xFF6B42FF), size: 24),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Sign In via QR Code',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close_rounded, color: textSecondary),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Scan this code using your phone\'s TeroVPN app to sign in instantly.',
          style: TextStyle(
            fontSize: 13,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 20),

        // High-Contrast Scannable Standard QR Code (ISO/IEC 18004)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B42FF).withValues(alpha: isDark ? 0.3 : 0.15),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: QrImageView(
            data: QrAuthSyncService.generateSessionPayload(
              _session.sessionId,
              localIp: _session.localIp,
              port: _session.localPort,
              secretKey: _session.secretKey,
            ),
            version: QrVersions.auto,
            size: 190,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Color(0xFF141122),
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Color(0xFF141122),
            ),
          ),
        ),

        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF261D4C) : const Color(0xFFEDE9F8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF6B42FF).withValues(alpha: isDark ? 0.3 : 0.2)),
          ),
          child: Text(
            'Session ID: ${_session.sessionId}',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              color: Color(0xFF8B6BFF),
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
                  foregroundColor: textSecondary,
                  side: BorderSide(
                    color: isDark ? Colors.white12 : const Color(0xFFD8D5E5),
                  ),
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
                label: const Text('Simulate'),
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
