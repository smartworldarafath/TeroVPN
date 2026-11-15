import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
import '../../theme/theme_manager.dart';
import '../../core/core_controller.dart';
import '../../core/models.dart';
import '../../core/android_core.dart';
import '../../core/app_preferences.dart';

class SignInDialog extends StatefulWidget {
  final CoreController controller;

  const SignInDialog({super.key, required this.controller});

  static Future<bool?> show(BuildContext context, CoreController controller) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThemeManager.instance.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SignInDialog(controller: controller),
    );
  }

  @override
  State<SignInDialog> createState() => _SignInDialogState();
}

class _SignInDialogState extends State<SignInDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isCompletingSignIn = false;
  bool _isSuccess = false;
  String? _errorMessage;

  SignInState? _state;
  String? _retainedVerificationStep;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_onCodeChanged);
    if (!identical(0, 0.0) && Platform.isAndroid) {
      AndroidCore.setMozillaBrowserSessionListener(_onMozillaBrowserSession);
    }
  }

  void _onCodeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _codeController.removeListener(_onCodeChanged);
    if (!identical(0, 0.0) && Platform.isAndroid) {
      AndroidCore.setMozillaBrowserSessionListener(null);
    }
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _onMozillaBrowserSession(String email, String sessionToken) async {
    if (!mounted) return;
    final targetEmail = email.trim().isNotEmpty
        ? email.trim()
        : _emailController.text.trim();
    if (targetEmail.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final state = await widget.controller.startBrowserSignIn(
        targetEmail,
        sessionToken,
      );
      _handleState(state);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _submitInitial() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isSuccess = false;
    });

    try {
      final state = await widget.controller.startSignIn(email, password);
      _handleState(state);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _openMailApp() async {
    final opened = await AndroidCore.openMailApp();
    if (!opened && mounted) {
      setState(() {
        _errorMessage =
            'Could not open mail app automatically. Please open your email inbox manually.';
      });
    }
  }

  Future<void> _submitAnswer() async {
    final code = _codeController.text.trim();
    final activeStep = _state?.needsAnswer == true
        ? _state!.step
        : (_retainedVerificationStep ?? SignInStep.needEmailCode);
    if (code.isEmpty) {
      setState(() {
        _errorMessage = activeStep == SignInStep.needCaptcha
            ? 'Please enter the characters shown in the image.'
            : 'Please enter the verification code sent to your email.';
      });
      return;
    }

    if (_state == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // If the prior flow already finished/closed in Go core (e.g. timed out while user
      // was checking email), refresh state first before answering to avoid raw
      // "this sign-in is not waiting for input" dead-ends.
      var targetState = _state!;
      if (!targetState.needsAnswer) {
        try {
          targetState = await widget.controller.signInState(targetState.id);
        } catch (_) {}
      }

      if (targetState.step == SignInStep.done) {
        _handleState(targetState);
        return;
      }

      if (!targetState.needsAnswer) {
        final email = _emailController.text.trim();
        final password = _passwordController.text;
        if (email.isNotEmpty && password.isNotEmpty) {
          final restarted = await widget.controller.startSignIn(email, password);
          if (restarted.needsAnswer &&
              (restarted.step == SignInStep.needEmailCode ||
                  restarted.step == SignInStep.needUnblockCode ||
                  restarted.step == SignInStep.needTotp)) {
            final submitted = await widget.controller.answerSignIn(
              restarted.id,
              code,
            );
            _handleState(submitted);
            return;
          }
          _handleState(restarted);
          return;
        }
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Incorrect or expired verification code. Please check your inbox and try again.';
        });
        return;
      }

      final state = await widget.controller.answerSignIn(targetState.id, code);
      _handleState(state);
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString().replaceFirst('Exception: ', '');
      final lower = raw.toLowerCase();
      if (lower.contains('not waiting for input')) {
        try {
          final latest = await widget.controller.signInState(_state!.id);
          if (latest.step == SignInStep.done) {
            _handleState(latest);
            return;
          }
        } catch (_) {}
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _retainedVerificationStep ??= activeStep;
          _errorMessage =
              'Incorrect or expired verification code. Please check your inbox and try again.';
        });
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = raw;
      });
    }
  }

  Future<void> _confirmEmailLink() async {
    if (_state == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final state = await widget.controller.answerSignIn(_state!.id, 'continue');
      _handleState(state);
    } catch (_) {
      try {
        final state = await widget.controller.signInState(_state!.id);
        _handleState(state);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _openBrowserSignIn() async {
    final email = _emailController.text.trim();
    try {
      if (Platform.isAndroid) {
        await AndroidCore.openMozillaWebViewSignIn(email);
      } else {
        final uri = Uri.https('accounts.firefox.com', '/', {
          'context': 'fx_desktop_v3',
          'service': 'sync',
          'action': 'email',
          if (email.isNotEmpty) 'email': email,
        });
        final urlString = uri.toString();
        if (Platform.isWindows) {
          await Process.run('cmd', ['/c', 'start', '', urlString]);
        } else if (Platform.isLinux) {
          await Process.run('xdg-open', [urlString]);
        } else if (Platform.isMacOS) {
          await Process.run('open', [urlString]);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not open Mozilla sign-in: $e';
      });
    }
  }

  void _resetToCredentials() {
    _pollTimer?.cancel();
    final oldId = _state?.id;
    if (oldId != null && _state?.finished == false) {
      widget.controller.cancelSignIn(oldId).ignore();
    }
    setState(() {
      _state = null;
      _retainedVerificationStep = null;
      _isLoading = false;
      _isCompletingSignIn = false;
      _errorMessage = null;
      _codeController.clear();
    });
  }

  void _handleState(SignInState state) {
    if (!mounted) return;
    final previousStep = _state?.step;
    _state = state;

    if (state.step == SignInStep.working) {
      setState(() {
        _isLoading = true;
      });
      _startPolling(state.id);
      return;
    }

    if (state.step == SignInStep.needEmailLink) {
      _retainedVerificationStep = SignInStep.needEmailLink;
      setState(() {
        _isLoading = false;
        _errorMessage = state.error.isNotEmpty ? state.error : null;
      });
      _startPolling(state.id);
      return;
    }

    _pollTimer?.cancel();

    if (state.step == SignInStep.done) {
      if (!identical(0, 0.0) && Platform.isAndroid) {
        AndroidCore.closeMozillaWebViewSignIn();
      }
      final email = state.email.isNotEmpty
          ? state.email
          : _emailController.text.trim();
      final password = _passwordController.text;
      if (email.isNotEmpty && password.isNotEmpty) {
        AppPreferences.setSavedAccountPassword(email, password);
      }
      setState(() {
        _isCompletingSignIn = true;
        _isLoading = true;
        _isSuccess = false;
        _errorMessage = null;
      });
      widget.controller.refresh(accountsToo: true);
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (!mounted) return;
        setState(() {
          _isCompletingSignIn = false;
          _isLoading = false;
          _isSuccess = true;
        });
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) Navigator.of(context).pop(true);
        });
      });
    } else if (state.step == SignInStep.failed ||
        state.step == SignInStep.cancelled) {
      // If email or password was wrong, return to credentials form so user can edit immediately
      if (state.errorCode == SignInError.wrongPassword ||
          state.errorCode == SignInError.noAccount) {
        _retainedVerificationStep = null;
        setState(() {
          _state = null;
          _isLoading = false;
          _errorMessage = _friendlyError(state.errorCode);
        });
      } else if (state.errorCode == SignInError.wrongCode ||
          state.errorCode == SignInError.unblockCodeRejected ||
          state.errorCode == SignInError.wrongTotp ||
          state.errorCode == SignInError.tooManyCodes ||
          _retainedVerificationStep != null) {
        final msg =
            (state.errorCode == SignInError.wrongCode ||
                state.errorCode == SignInError.unblockCodeRejected)
            ? 'Incorrect verification code. Please check your inbox and try again.'
            : (state.errorCode.isNotEmpty
                  ? _friendlyError(state.errorCode)
                  : (state.error.isNotEmpty
                        ? state.error
                        : 'Incorrect verification code. Please check your inbox and try again.'));
        setState(() {
          _isLoading = false;
          _errorMessage = msg;
        });
      } else {
        final errText = state.error.isNotEmpty
            ? state.error
            : (state.errorCode.isNotEmpty
                  ? _friendlyError(state.errorCode)
                  : (state.message.isNotEmpty
                        ? state.message
                        : 'Sign-in failed. Please verify your credentials.'));
        setState(() {
          _isLoading = false;
          _errorMessage = errText;
        });
      }
    } else if (state.needsAnswer) {
      _retainedVerificationStep = state.step;
      if (previousStep != state.step) {
        _codeController.clear();
      }
      final msg =
          (state.errorCode == SignInError.wrongCode ||
              state.errorCode == SignInError.unblockCodeRejected)
          ? 'Incorrect verification code. Please check your inbox and try again.'
          : (state.error.isNotEmpty
                ? state.error
                : (state.errorCode.isNotEmpty
                      ? _friendlyError(state.errorCode)
                      : null));
      setState(() {
        _isLoading = false;
        _errorMessage = msg;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _startPolling(String id) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      try {
        final next = await widget.controller.signInState(id);
        if (!mounted) return;
        if (next.step != SignInStep.working &&
            next.step != SignInStep.needEmailLink) {
          timer.cancel();
          _handleState(next);
        } else if (next.message != _state?.message) {
          setState(() => _state = next);
        }
      } catch (_) {}
    });
  }

  String _friendlyError(String code) {
    switch (code) {
      case SignInError.wrongPassword:
        return 'Incorrect password. Please check your password and try again.';
      case SignInError.noAccount:
        return 'No Firefox Account found with this email address.';
      case SignInError.noPassword:
        return 'This account uses Google/Apple sign-in and has no password set.';
      case SignInError.wrongCode:
        return 'Incorrect verification code. Please check your inbox and try again.';
      case SignInError.wrongTotp:
        return 'Invalid authenticator code. Please check your 2FA app and re-enter.';
      case SignInError.unblockCodeRejected:
        return 'Incorrect verification code. Please check your inbox and try again.';
      case SignInError.tooManyAttempts:
        return 'Too many sign-in attempts. Please wait a few minutes and try again.';
      case SignInError.tooManyCodes:
        return 'Too many incorrect codes entered. Please start sign-in again.';
      case SignInError.timedOut:
        return 'Sign-in request timed out. Please try again.';
      case SignInError.network:
        return 'Network connection error reaching Mozilla Accounts.';
      case SignInError.blocked:
      case SignInError.tokenBlocked:
        return 'Mozilla security check requested browser verification. Tap "Sign In with Official Mozilla WebView" below.';
      default:
        return 'Sign-in failed. Please verify your credentials.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final activeVerificationStep = _state?.needsAnswer == true
        ? _state!.step
        : _retainedVerificationStep;
    final isEmailLinkStep =
        _state != null && _state!.step == SignInStep.needEmailLink;
    final isVerificationStep =
        !_isCompletingSignIn &&
        !_isSuccess &&
        _state != null &&
        (_state!.needsAnswer ||
            (_retainedVerificationStep != null &&
                _retainedVerificationStep != SignInStep.needEmailLink));
    final isFailedStep =
        !isVerificationStep &&
        _state != null &&
        (_state!.step == SignInStep.failed ||
            _state!.step == SignInStep.cancelled);
    final isDark = ThemeManager.instance.isDarkMode;
    final targetEmail = (_state?.email.isNotEmpty == true)
        ? _state!.email
        : _emailController.text.trim();
    final hasTypedCode = _codeController.text.trim().isNotEmpty;

    String headerTitle = 'Sign In with Firefox Account';
    String headerSubtitle = 'Mozilla Account authentication for Fastly MASQUE';
    IconData headerIcon = Icons.account_circle_rounded;

    if (_isSuccess) {
      headerTitle = 'Sign In Complete!';
      headerSubtitle = 'Session authenticated with Fastly MASQUE backend';
      headerIcon = Icons.check_circle_rounded;
    } else if (_isCompletingSignIn) {
      headerTitle = 'Signing In...';
      headerSubtitle = 'Finalizing secure session for $targetEmail';
      headerIcon = Icons.verified_user_rounded;
    } else if (isEmailLinkStep) {
      headerTitle = 'Confirm Sign In via Email';
      headerSubtitle =
          'A verification link has been sent to your email. Please check your inbox.';
      headerIcon = Icons.mark_email_read_rounded;
    } else if (isVerificationStep) {
      if (activeVerificationStep == SignInStep.needUnblockCode) {
        headerTitle = 'Email Verification';
        headerSubtitle =
            'A verification code has been sent to your email. Please check your inbox.';
        headerIcon = Icons.lock_open_rounded;
      } else if (activeVerificationStep == SignInStep.needTotp) {
        headerTitle = 'Two-Factor Authentication';
        headerSubtitle = 'Enter the 6-digit code from your authenticator app';
        headerIcon = Icons.phonelink_lock_rounded;
      } else if (activeVerificationStep == SignInStep.needCaptcha) {
        headerTitle = 'Mozilla Security Check';
        headerSubtitle =
            'Enter the characters shown in the image below, or use Official Mozilla WebView below.';
        headerIcon = Icons.security_rounded;
      } else {
        headerTitle = 'Email Verification';
        headerSubtitle =
            'A verification code has been sent to your email. Please check your inbox.';
        headerIcon = Icons.mark_email_unread_rounded;
      }
    }

    final isNumericCode =
        activeVerificationStep == SignInStep.needEmailCode ||
        activeVerificationStep == SignInStep.needTotp;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: bottomInset + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: ThemeManager.instance.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF6B42FF).withValues(alpha: 0.15)
                      : const Color(0xFFF0EDFA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    headerIcon,
                    color: _isSuccess
                        ? ProtonColors.connected
                        : const Color(0xFF6B42FF),
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headerTitle,
                      style: ProtonTypography.titleMedium.copyWith(
                        color: ThemeManager.instance.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      headerSubtitle,
                      style: ProtonTypography.bodySmall.copyWith(
                        color: ThemeManager.instance.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: ProtonColors.disconnected.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: ProtonColors.disconnected.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: ProtonColors.disconnected,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: ProtonTypography.bodySmall.copyWith(
                        color: isDark ? Colors.white : const Color(0xFFB00020),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          if (isEmailLinkStep) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1B1630)
                    : const Color(0xFFF7F6FB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF6B42FF).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.email_outlined,
                    size: 44,
                    color: Color(0xFF8B6BFF),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Check your Gmail inbox',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: ThemeManager.instance.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Mozilla sent a sign-in confirmation link to:\n$targetEmail',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: ThemeManager.instance.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF8B6BFF),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Waiting for link confirmation...',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: ThemeManager.instance.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else if (isVerificationStep) ...[
            if (activeVerificationStep == SignInStep.needEmailCode ||
                activeVerificationStep == SignInStep.needUnblockCode) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1B1630)
                      : const Color(0xFFF3F0FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6B42FF).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.mail_lock_rounded,
                      color: Color(0xFF8B6BFF),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'A verification code has been sent to your email. Please check your inbox.',
                        style: ProtonTypography.bodySmall.copyWith(
                          color: ThemeManager.instance.textPrimaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ] else if (activeVerificationStep == SignInStep.needCaptcha &&
                _state?.captcha.isNotEmpty == true) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Image.memory(
                    base64Decode(_state!.captcha.split(',').last),
                    height: 84,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            TextField(
              key: ValueKey(activeVerificationStep ?? 'code_input'),
              controller: _codeController,
              keyboardType: isNumericCode
                  ? TextInputType.number
                  : TextInputType.visiblePassword,
              inputFormatters: isNumericCode
                  ? [FilteringTextInputFormatter.digitsOnly]
                  : null,
              textCapitalization:
                  activeVerificationStep == SignInStep.needEmailCode
                  ? TextCapitalization.none
                  : TextCapitalization.characters,
              autofocus: true,
              style: ProtonTypography.titleLarge.copyWith(
                letterSpacing: isNumericCode ? 6 : 2,
                color: ThemeManager.instance.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
              onSubmitted: (_) {
                if (hasTypedCode) {
                  _submitAnswer();
                } else if (activeVerificationStep != SignInStep.needCaptcha) {
                  _openMailApp();
                }
              },
              decoration: InputDecoration(
                hintText: switch (activeVerificationStep) {
                  SignInStep.needCaptcha => 'Enter characters shown above',
                  SignInStep.needUnblockCode => 'Enter verification code',
                  SignInStep.needTotp => 'Enter 6-digit authenticator code',
                  _ => 'Enter 6-digit verification code',
                },
                hintStyle: ProtonTypography.bodyLarge.copyWith(
                  color: ThemeManager.instance.textMutedColor,
                  letterSpacing: 0.5,
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF131122)
                    : const Color(0xFFF4F3F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: ThemeManager.instance.cardBorderColor,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: ThemeManager.instance.cardBorderColor,
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFF6B42FF), width: 1.5),
                ),
              ),
            ),
          ] else ...[
            // Initial Email & Password Fields
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              style: ProtonTypography.bodyLarge.copyWith(
                color: ThemeManager.instance.textPrimaryColor,
              ),
              decoration: InputDecoration(
                labelText: 'Email Address',
                labelStyle: TextStyle(
                  color: ThemeManager.instance.textSecondaryColor,
                ),
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: ThemeManager.instance.textSecondaryColor,
                  size: 20,
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF131122)
                    : const Color(0xFFF4F3F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: ThemeManager.instance.cardBorderColor,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: ThemeManager.instance.cardBorderColor,
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFF6B42FF), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              onSubmitted: (_) => _submitInitial(),
              style: ProtonTypography.bodyLarge.copyWith(
                color: ThemeManager.instance.textPrimaryColor,
              ),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(
                  color: ThemeManager.instance.textSecondaryColor,
                ),
                prefixIcon: Icon(
                  Icons.lock_outline_rounded,
                  color: ThemeManager.instance.textSecondaryColor,
                  size: 20,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: ThemeManager.instance.textSecondaryColor,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF131122)
                    : const Color(0xFFF4F3F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: ThemeManager.instance.cardBorderColor,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: ThemeManager.instance.cardBorderColor,
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFF6B42FF), width: 1.5),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Primary Action Button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: (_isLoading || _isCompletingSignIn)
                  ? null
                  : (isEmailLinkStep
                        ? () async {
                            await _openMailApp();
                            await _confirmEmailLink();
                          }
                        : (isVerificationStep
                              ? ((activeVerificationStep !=
                                            SignInStep.needCaptcha &&
                                        !hasTypedCode)
                                    ? _openMailApp
                                    : _submitAnswer)
                              : (isFailedStep
                                    ? _resetToCredentials
                                    : _submitInitial))),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSuccess
                    ? ProtonColors.connected
                    : const Color(0xFF6B42FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: (_isLoading || _isCompletingSignIn)
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isCompletingSignIn
                              ? 'Signing in...'
                              : ((_state?.message.isNotEmpty == true)
                                    ? _state!.message
                                    : 'Signing in...'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    )
                  : (_isSuccess
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Sign In Complete',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          )
                        : Text(
                            isEmailLinkStep
                                ? 'Continue to Mail Code'
                                : (isVerificationStep
                                      ? ((activeVerificationStep !=
                                                  SignInStep.needCaptcha &&
                                              !hasTypedCode)
                                            ? 'Continue to Mail Code'
                                            : 'Verify')
                                      : (isFailedStep
                                            ? 'Try Again'
                                            : 'Sign In')),
                            style: ProtonTypography.labelLarge,
                          )),
            ),
          ),

          if (_isCompletingSignIn) ...[
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.08, end: 1.0),
              duration: const Duration(milliseconds: 1550),
              curve: Curves.easeInOutCubic,
              builder: (context, value, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 5,
                    backgroundColor: const Color(0xFF6B42FF)
                        .withValues(alpha: 0.16),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF6B42FF),
                    ),
                  ),
                );
              },
            ),
          ],

          if (isVerificationStep || isEmailLinkStep) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _isLoading ? null : _resetToCredentials,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Start Over / Change Email'),
              style: TextButton.styleFrom(
                foregroundColor: ThemeManager.instance.textSecondaryColor,
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Official Mozilla WebView Sign-In Button
          OutlinedButton.icon(
            onPressed: _openBrowserSignIn,
            icon: const Icon(Icons.verified_user_outlined, size: 18),
            label: Text(
              Platform.isAndroid
                  ? 'Sign In with Official Mozilla WebView'
                  : 'Sign In via Mozilla Accounts Browser',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8B6BFF),
              side: BorderSide(
                color: const Color(0xFF8B6BFF).withValues(alpha: 0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size.fromHeight(44),
            ),
          ),

          if (!isVerificationStep && !isEmailLinkStep) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have a Firefox Account? ",
                  style: ProtonTypography.bodySmall.copyWith(
                    color: ThemeManager.instance.textSecondaryColor,
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      AndroidCore.openUrl('https://accounts.firefox.com/signup'),
                  child: const Text(
                    'Create Account',
                    style: TextStyle(
                      color: Color(0xFF6B42FF),
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: GestureDetector(
                onTap: () => AndroidCore.openUrl(
                  'https://accounts.firefox.com/reset_password',
                ),
                child: Text(
                  'Forgot password?',
                  style: ProtonTypography.bodySmall.copyWith(
                    color: ThemeManager.instance.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
