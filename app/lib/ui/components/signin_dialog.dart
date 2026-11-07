import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
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
  bool _isSuccess = false;
  String? _errorMessage;

  SignInState? _state;
  Timer? _emailLinkPollTimer;

  @override
  void dispose() {
    _emailLinkPollTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
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
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _submitAnswer() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter the verification code.');
      return;
    }

    if (_state == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final state = await widget.controller.answerSignIn(_state!.id, code);
      _handleState(state);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
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
      // First try answering with 'continue' (Fastly/Mozilla convention)
      final state = await widget.controller.answerSignIn(_state!.id, 'continue');
      _handleState(state);
    } catch (_) {
      // Otherwise immediately poll current sign in state
      try {
        final state = await widget.controller.signInState(_state!.id);
        _handleState(state);
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _openBrowserSignIn() async {
    try {
      final uri = await widget.controller.dashboardLink();
      final urlString = uri.toString();
      if (Platform.isAndroid) {
        await AndroidCore.openUrl(urlString);
      } else if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', urlString]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [urlString]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [urlString]);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not open browser: $e';
      });
    }
  }

  void _handleState(SignInState state) {
    _state = state;

    if (state.step == SignInStep.working) {
      _pollSignInState(state.id);
      return;
    }

    if (state.step == SignInStep.needEmailLink) {
      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
      // Start polling for email link confirmation automatically
      _startEmailLinkPolling(state.id);
      return;
    } else {
      _emailLinkPollTimer?.cancel();
    }

    if (state.step == SignInStep.done) {
      _emailLinkPollTimer?.cancel();
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      if (email.isNotEmpty && password.isNotEmpty) {
        AppPreferences.setSavedAccountPassword(email, password);
      }
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
      widget.controller.refresh(accountsToo: true);
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) Navigator.of(context).pop(true);
      });
    } else if (state.step == SignInStep.failed) {
      _emailLinkPollTimer?.cancel();
      setState(() {
        _isLoading = false;
        _errorMessage = state.message.isNotEmpty
            ? state.message
            : _friendlyError(state.errorCode);
      });
    } else if (state.needsAnswer) {
      _emailLinkPollTimer?.cancel();
      setState(() {
        _isLoading = false;
      });
      _codeController.clear();
    } else {
      _emailLinkPollTimer?.cancel();
      setState(() => _isLoading = false);
    }
  }

  void _startEmailLinkPolling(String id) {
    _emailLinkPollTimer?.cancel();
    _emailLinkPollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      try {
        final state = await widget.controller.signInState(id);
        if (state.step != SignInStep.needEmailLink && state.step != SignInStep.working) {
          timer.cancel();
          _handleState(state);
        }
      } catch (_) {}
    });
  }

  Future<void> _pollSignInState(String id) async {
    while (mounted && _isLoading) {
      await Future.delayed(const Duration(milliseconds: 600));
      try {
        final state = await widget.controller.signInState(id);
        if (state.step != SignInStep.working) {
          _handleState(state);
          break;
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = e.toString().replaceFirst('Exception: ', '');
          });
        }
        break;
      }
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case SignInError.wrongPassword:
        return 'Incorrect password. Please try again.';
      case SignInError.noAccount:
        return 'No Firefox Account found with this email.';
      case SignInError.wrongCode:
        return 'Invalid verification code. Please check and re-enter.';
      case SignInError.wrongTotp:
        return 'Invalid authenticator code. Please check and re-enter.';
      case SignInError.unblockCodeRejected:
        return 'Authorization unblock code was rejected or expired.';
      case SignInError.tooManyAttempts:
        return 'Too many sign-in attempts. Please try again later.';
      case SignInError.tooManyCodes:
        return 'Too many incorrect codes entered. Please wait before retrying.';
      case SignInError.timedOut:
        return 'Sign in request timed out. Please try again.';
      case SignInError.network:
        return 'Network connection error to auth server.';
      default:
        return 'Sign-in failed. Please verify your credentials.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEmailLinkStep = _state != null && _state!.step == SignInStep.needEmailLink;
    final isVerificationStep = _state != null && _state!.needsAnswer;
    final isDark = ThemeManager.instance.isDarkMode;

    String headerTitle = 'Sign In with Firefox Account';
    String headerSubtitle = 'Firefox Account credentials for Fastly MASQUE';
    IconData headerIcon = Icons.account_circle_rounded;

    if (_isSuccess) {
      headerTitle = 'Sign In Complete!';
      headerSubtitle = 'Session authenticated with Fastly MASQUE backend';
      headerIcon = Icons.check_circle_rounded;
    } else if (isEmailLinkStep) {
      headerTitle = 'Confirm Sign In via Email';
      headerSubtitle = 'Mozilla sent a confirmation link to your email';
      headerIcon = Icons.mark_email_read_rounded;
    } else if (isVerificationStep) {
      if (_state?.step == SignInStep.needUnblockCode) {
        headerTitle = 'Account Unblock Code';
        headerSubtitle = 'Enter the authorization code sent to your email';
        headerIcon = Icons.lock_open_rounded;
      } else if (_state?.step == SignInStep.needTotp) {
        headerTitle = 'Two-Factor Authentication';
        headerSubtitle = 'Enter the 6-digit code from your authenticator app';
        headerIcon = Icons.phonelink_lock_rounded;
      } else if (_state?.step == SignInStep.needCaptcha) {
        headerTitle = 'Security Verification';
        headerSubtitle = 'Enter the characters shown in the image below';
        headerIcon = Icons.security_rounded;
      } else {
        headerTitle = 'Verification Code';
        headerSubtitle = 'Enter the 6-digit code sent to your email';
        headerIcon = Icons.verified_user_rounded;
      }
    }

    return Padding(
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
                    color: _isSuccess ? ProtonColors.connected : const Color(0xFF6B42FF),
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
            // Email link confirmation UI
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B1630) : const Color(0xFFF7F6FB),
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
                    'Check your email',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: ThemeManager.instance.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'We sent a sign-in confirmation link to:\n${_emailController.text.trim()}',
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
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B6BFF)),
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
            // Code Input Step
            if (_state?.captcha.isNotEmpty == true) ...[
              Center(
                child: Image.memory(
                  base64Decode(_state!.captcha.split(',').last),
                  height: 60,
                ),
              ),
              const SizedBox(height: 12),
            ],

            TextField(
              controller: _codeController,
              keyboardType: _state?.step == SignInStep.needUnblockCode
                  ? TextInputType.text
                  : TextInputType.number,
              textCapitalization: _state?.step == SignInStep.needUnblockCode
                  ? TextCapitalization.characters
                  : TextCapitalization.none,
              autofocus: true,
              style: ProtonTypography.titleLarge.copyWith(
                letterSpacing: _state?.step == SignInStep.needUnblockCode ? 2 : 4,
                color: ThemeManager.instance.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: _state?.step == SignInStep.needUnblockCode
                    ? 'Enter unblock code'
                    : 'Enter 6-digit code',
                hintStyle: ProtonTypography.bodyLarge.copyWith(
                  color: ThemeManager.instance.textMutedColor,
                  letterSpacing: 1,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF131122) : const Color(0xFFF4F3F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ThemeManager.instance.cardBorderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ThemeManager.instance.cardBorderColor),
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
                labelStyle: TextStyle(color: ThemeManager.instance.textSecondaryColor),
                prefixIcon: Icon(Icons.email_outlined, color: ThemeManager.instance.textSecondaryColor, size: 20),
                filled: true,
                fillColor: isDark ? const Color(0xFF131122) : const Color(0xFFF4F3F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ThemeManager.instance.cardBorderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ThemeManager.instance.cardBorderColor),
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
              style: ProtonTypography.bodyLarge.copyWith(
                color: ThemeManager.instance.textPrimaryColor,
              ),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: ThemeManager.instance.textSecondaryColor),
                prefixIcon: Icon(Icons.lock_outline_rounded, color: ThemeManager.instance.textSecondaryColor, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: ThemeManager.instance.textSecondaryColor,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF131122) : const Color(0xFFF4F3F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ThemeManager.instance.cardBorderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ThemeManager.instance.cardBorderColor),
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
              onPressed: _isLoading
                  ? null
                  : (isEmailLinkStep
                      ? _confirmEmailLink
                      : (isVerificationStep ? _submitAnswer : _submitInitial)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSuccess ? ProtonColors.connected : const Color(0xFF6B42FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Signing in...', style: TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    )
                  : (_isSuccess
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text('Sign In Complete', style: TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        )
                      : Text(
                          isEmailLinkStep
                              ? 'I Confirmed in Email'
                              : (isVerificationStep ? 'Verify Code' : 'Sign In'),
                          style: ProtonTypography.labelLarge,
                        )),
            ),
          ),

          const SizedBox(height: 16),

          // Browser Sign-In Fallback Button
          OutlinedButton.icon(
            onPressed: _openBrowserSignIn,
            icon: const Icon(Icons.open_in_browser_rounded, size: 18),
            label: const Text('Sign In via Web Browser Fallback'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8B6BFF),
              side: BorderSide(color: const Color(0xFF8B6BFF).withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size.fromHeight(42),
            ),
          ),

          if (!isVerificationStep && !isEmailLinkStep) ...[
            const SizedBox(height: 14),
            // Don't have a Firefox Account link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have a Firefox Account? ",
                  style: ProtonTypography.bodySmall.copyWith(color: ThemeManager.instance.textSecondaryColor),
                ),
                GestureDetector(
                  onTap: () => AndroidCore.openUrl('https://accounts.firefox.com/signup'),
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
            // Forgot password link
            Center(
              child: GestureDetector(
                onTap: () => AndroidCore.openUrl('https://accounts.firefox.com/reset_password'),
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
