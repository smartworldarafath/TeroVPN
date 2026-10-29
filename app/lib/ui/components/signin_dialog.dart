import 'dart:convert';
import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
import '../../core/core_controller.dart';
import '../../core/models.dart';
import '../../core/android_core.dart';

class SignInDialog extends StatefulWidget {
  final CoreController controller;

  const SignInDialog({super.key, required this.controller});

  static Future<bool?> show(BuildContext context, CoreController controller) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ProtonColors.surface,
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

  @override
  void dispose() {
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

  void _handleState(SignInState state) {
    _state = state;

    if (state.step == SignInStep.working) {
      _pollSignInState(state.id);
      return;
    }

    if (state.step == SignInStep.done) {
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
      widget.controller.refresh(accountsToo: true);
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) Navigator.of(context).pop(true);
      });
    } else if (state.step == SignInStep.failed) {
      setState(() {
        _isLoading = false;
        _errorMessage = state.message.isNotEmpty
            ? state.message
            : _friendlyError(state.errorCode);
      });
    } else if (state.needsAnswer) {
      setState(() {
        _isLoading = false;
      });
      _codeController.clear();
    } else {
      setState(() => _isLoading = false);
    }
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
      case SignInError.wrongTotp:
        return 'Invalid verification code. Please check and re-enter.';
      case SignInError.tooManyAttempts:
        return 'Too many attempts. Please try again later.';
      case SignInError.network:
        return 'Network connection error to auth server.';
      default:
        return 'Sign-in failed. Please verify your credentials.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isVerificationStep = _state != null && _state!.needsAnswer;

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
                color: ProtonColors.borderLight,
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
                  color: ProtonColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    _isSuccess ? Icons.check_circle_rounded : Icons.account_circle_rounded,
                    color: _isSuccess ? ProtonColors.connected : ProtonColors.activeLabel,
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
                      _isSuccess
                          ? 'Sign In Complete!'
                          : (isVerificationStep ? 'Verification Code' : 'Sign In with Firefox Account'),
                      style: ProtonTypography.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isSuccess
                          ? 'Session authenticated with Fastly MASQUE backend'
                          : (isVerificationStep
                              ? 'Enter the 6-digit code sent to your email/authenticator'
                              : 'Firefox Account credentials for Fastly MASQUE'),
                      style: ProtonTypography.bodySmall,
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
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          if (!isVerificationStep) ...[
            // Email Field
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              style: ProtonTypography.bodyLarge,
              decoration: InputDecoration(
                labelText: 'Email Address',
                labelStyle: const TextStyle(color: ProtonColors.textSecondary),
                prefixIcon: const Icon(Icons.email_outlined, color: ProtonColors.textSecondary, size: 20),
                filled: true,
                fillColor: ProtonColors.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ProtonColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ProtonColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ProtonColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Password Field
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: ProtonTypography.bodyLarge,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: const TextStyle(color: ProtonColors.textSecondary),
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: ProtonColors.textSecondary, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: ProtonColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                filled: true,
                fillColor: ProtonColors.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ProtonColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ProtonColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ProtonColors.primary, width: 1.5),
                ),
              ),
            ),
          ] else ...[
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
              keyboardType: TextInputType.number,
              autofocus: true,
              style: ProtonTypography.titleLarge.copyWith(letterSpacing: 4),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Enter 6-digit code',
                hintStyle: ProtonTypography.bodyLarge.copyWith(
                  color: ProtonColors.textMuted,
                  letterSpacing: 1,
                ),
                filled: true,
                fillColor: ProtonColors.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ProtonColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ProtonColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ProtonColors.primary, width: 1.5),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Action Button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : (isVerificationStep ? _submitAnswer : _submitInitial),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSuccess ? ProtonColors.connected : ProtonColors.primary,
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
                          isVerificationStep ? 'Verify Code' : 'Sign In',
                          style: ProtonTypography.labelLarge,
                        )),
            ),
          ),

          if (!isVerificationStep) ...[
            const SizedBox(height: 18),
            // Don't have a Firefox Account link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have a Firefox Account? ",
                  style: ProtonTypography.bodySmall.copyWith(color: ProtonColors.textMuted),
                ),
                GestureDetector(
                  onTap: () => AndroidCore.openUrl('https://accounts.firefox.com/signup'),
                  child: Text(
                    'Create Account',
                    style: ProtonTypography.bodySmall.copyWith(
                      color: ProtonColors.activeLabel,
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
                    color: ProtonColors.textSecondary,
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
