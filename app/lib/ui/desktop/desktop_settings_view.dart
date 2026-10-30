import 'package:flutter/material.dart';
import '../../core/core_controller.dart';
import '../../core/app_preferences.dart';
import '../components/signin_dialog.dart';

class DesktopSettingsView extends StatefulWidget {
  final CoreController controller;

  const DesktopSettingsView({
    super.key,
    required this.controller,
  });

  @override
  State<DesktopSettingsView> createState() => _DesktopSettingsViewState();
}

class _DesktopSettingsViewState extends State<DesktopSettingsView> {
  late bool _netShieldEnabled;
  late bool _killSwitchEnabled;

  @override
  void initState() {
    super.initState();
    _netShieldEnabled = AppPreferences.netShieldEnabled;
    _killSwitchEnabled = AppPreferences.killSwitchEnabled;
  }

  void _promptSignIn(String feature) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161426),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign In Required', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        content: Text(
          'Please sign in with your Firefox Account to configure $feature.',
          style: const TextStyle(color: Color(0xFF8E8B9D), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF8E8B9D))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B42FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              SignInDialog.show(context, widget.controller);
            },
            child: const Text('Sign In', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),

          const SizedBox(height: 22),

          // ACCOUNT Section
          const Text(
            'ACCOUNT',
            style: TextStyle(
              color: Color(0xFF8E8B9D),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF161426),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person_add_outlined,
                  color: Color(0xFF9E9BAE),
                  size: 22,
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Sign in with Firefox Account for Fastly MASQUE',
                        style: TextStyle(
                          color: Color(0xFF8E8B9D),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => SignInDialog.show(context, widget.controller),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF6B42FF), width: 1.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '+ SIGN IN',
                        style: TextStyle(
                          color: Color(0xFF8B6BFF),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          // FEATURES Section
          const Text(
            'FEATURES',
            style: TextStyle(
              color: Color(0xFF8E8B9D),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF161426),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // NetShield Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: Color(0xFF9E9BAE),
                        size: 22,
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NetShield Ad-blocker',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Block malware, tracking, and intrusive ads',
                              style: TextStyle(
                                color: Color(0xFF8E8B9D),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _netShieldEnabled,
                        activeThumbColor: const Color(0xFF6B42FF),
                        activeTrackColor: const Color(0xFF261D4C),
                        inactiveThumbColor: const Color(0xFF757286),
                        inactiveTrackColor: const Color(0xFF1E1C2F),
                        onChanged: (val) async {
                          if (!widget.controller.hasAccount) {
                            _promptSignIn('NetShield Ad-blocker');
                            return;
                          }
                          setState(() => _netShieldEnabled = val);
                          await AppPreferences.setNetShieldEnabled(val);
                        },
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, thickness: 1, color: Colors.white.withValues(alpha: 0.04)),

                // Kill Switch Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.gpp_maybe_outlined,
                        color: Color(0xFF9E9BAE),
                        size: 22,
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kill Switch',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Disable internet traffic if VPN connection drops',
                              style: TextStyle(
                                color: Color(0xFF8E8B9D),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _killSwitchEnabled,
                        activeThumbColor: const Color(0xFF6B42FF),
                        activeTrackColor: const Color(0xFF261D4C),
                        inactiveThumbColor: const Color(0xFF757286),
                        inactiveTrackColor: const Color(0xFF1E1C2F),
                        onChanged: (val) async {
                          if (!widget.controller.hasAccount) {
                            _promptSignIn('Kill Switch');
                            return;
                          }
                          setState(() => _killSwitchEnabled = val);
                          await AppPreferences.setKillSwitchEnabled(val);
                        },
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, thickness: 1, color: Colors.white.withValues(alpha: 0.04)),

                // Split Tunneling Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.call_split_rounded,
                        color: Color(0xFF9E9BAE),
                        size: 22,
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Split Tunneling',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Choose which apps bypass the VPN',
                              style: TextStyle(
                                color: Color(0xFF8E8B9D),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFF757286),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          // CONNECTION Section
          const Text(
            'CONNECTION',
            style: TextStyle(
              color: Color(0xFF8E8B9D),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF161426),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.security_rounded,
                  color: Color(0xFF9E9BAE),
                  size: 22,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Protocol',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'WireGuard MASQUE (HTTP/3)',
                        style: TextStyle(
                          color: Color(0xFF8E8B9D),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFF757286),
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
