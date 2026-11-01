import 'package:flutter/material.dart';
import '../../core/app_permissions_service.dart';
import '../../theme/theme_manager.dart';
import '../components/liquid_glass_atmosphere.dart';

class PermissionsSetupScreen extends StatefulWidget {
  final VoidCallback onFinished;
  final bool isModal;

  const PermissionsSetupScreen({
    super.key,
    required this.onFinished,
    this.isModal = false,
  });

  static Future<void> showAsModal(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780, maxHeight: 720),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: PermissionsSetupScreen(
              onFinished: () => Navigator.of(ctx).pop(),
              isModal: true,
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<PermissionsSetupScreen> createState() => _PermissionsSetupScreenState();
}

class _PermissionsSetupScreenState extends State<PermissionsSetupScreen> {
  bool _grantingAll = false;

  @override
  Widget build(BuildContext context) {
    final permissionsService = AppPermissionsService.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([ThemeManager.instance, permissionsService]),
      builder: (context, _) {
        final isDark = ThemeManager.instance.isDarkMode;
        final isLiquid = ThemeManager.instance.isLiquidGlass;

        final bgColor = isDark
            ? (isLiquid ? const Color(0xFF110E1E).withValues(alpha: 0.94) : const Color(0xFF131120))
            : (isLiquid ? Colors.white.withValues(alpha: 0.95) : const Color(0xFFF7F6FB));

        final cardBg = isDark ? const Color(0xFF1C192E) : Colors.white;
        final cardBorder = isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFF5D5380).withValues(alpha: 0.12);

        final textPrimary = isDark ? Colors.white : const Color(0xFF1D1536);
        final textSecondary = isDark ? const Color(0xFF9E9BAC) : const Color(0xFF6E6B80);

        final areCoreGranted = permissionsService.areCorePermissionsGranted;
        final grantedCount = permissionsService.grantedCount;
        final totalCount = permissionsService.totalCount;

        return LiquidGlassAtmosphere(
          child: Scaffold(
            backgroundColor: widget.isModal ? bgColor : Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6B42FF), Color(0xFFA855F7)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Permissions & System Access',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: areCoreGranted
                          ? const Color(0xFF00C896).withValues(alpha: 0.15)
                          : const Color(0xFFFFB800).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: areCoreGranted
                            ? const Color(0xFF00C896).withValues(alpha: 0.4)
                            : const Color(0xFFFFB800).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      areCoreGranted ? 'Core Ready ($grantedCount/$totalCount)' : 'Action Required ($grantedCount/$totalCount)',
                      style: TextStyle(
                        color: areCoreGranted ? const Color(0xFF00C896) : const Color(0xFFFFB800),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (widget.isModal) ...[
                    const SizedBox(width: 10),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: textSecondary),
                      onPressed: () {
                        if (areCoreGranted) {
                          widget.onFinished();
                        } else {
                          _showRequiredNotice(context);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    children: [
                      // Overview Banner
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [const Color(0xFF261D4C), const Color(0xFF1B1633)]
                                : [const Color(0xFFEDE8FC), const Color(0xFFF3F0FD)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF6B42FF).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6B42FF).withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.verified_user_rounded, color: Color(0xFF9065FF), size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Secure Tunnel Permissions Setup',
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'TeroVPN requires system and virtual adapter permissions to route your network traffic through our encrypted zero-log tunnel. Core permissions must be granted to connect.',
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Core Permissions Header
                      _buildCategoryHeader(
                        title: 'Installation & Core Network Permissions',
                        subtitle: 'Mandatory permissions to route internet traffic through the VPN',
                        isCore: true,
                        areAllGranted: areCoreGranted,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 12),

                      // Core Permission Cards
                      ...AppPermissionsService.definitions.where((p) => p.isCore).map(
                            (p) => _buildPermissionCard(
                              model: p,
                              isGranted: permissionsService.isGranted(p.type),
                              cardBg: cardBg,
                              cardBorder: cardBorder,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              onGrant: () => permissionsService.grantPermission(p.type),
                            ),
                          ),

                      const SizedBox(height: 24),

                      // Advanced Features Header
                      _buildCategoryHeader(
                        title: 'Advanced Features & System Integrations',
                        subtitle: 'Optional permissions for Kill Switch, Chrome split tunneling & sync',
                        isCore: false,
                        areAllGranted: false,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 12),

                      // Advanced Permission Cards
                      ...AppPermissionsService.definitions.where((p) => !p.isCore).map(
                            (p) => _buildPermissionCard(
                              model: p,
                              isGranted: permissionsService.isGranted(p.type),
                              cardBg: cardBg,
                              cardBorder: cardBorder,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              onGrant: () => permissionsService.grantPermission(p.type),
                            ),
                          ),
                    ],
                  ),
                ),

                // Bottom Action Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF141122) : Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFF5D5380).withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Grant All Button
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B42FF),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _grantingAll
                                ? null
                                : () async {
                                    setState(() => _grantingAll = true);
                                    await permissionsService.grantAllPermissions();
                                    if (mounted) {
                                      setState(() => _grantingAll = false);
                                    }
                                  },
                            child: _grantingAll
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.done_all_rounded, size: 20),
                                      SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          'Grant All Permissions (Recommended)',
                                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Continue Button
                      SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: areCoreGranted
                                  ? const Color(0xFF00C896)
                                  : (isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFCCC8DC)),
                              width: 1.5,
                            ),
                            foregroundColor: areCoreGranted
                                ? (isDark ? const Color(0xFF00E676) : const Color(0xFF00A36C))
                                : textSecondary,
                            backgroundColor: areCoreGranted
                                ? const Color(0xFF00C896).withValues(alpha: 0.08)
                                : Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            if (areCoreGranted) {
                              widget.onFinished();
                            } else {
                              _showRequiredNotice(context);
                            }
                          },
                          child: const Row(
                            children: [
                              Text(
                                'Continue',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryHeader({
    required String title,
    required String subtitle,
    required bool isCore,
    required bool areAllGranted,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isCore
                          ? (areAllGranted
                              ? const Color(0xFF00C896).withValues(alpha: 0.15)
                              : const Color(0xFFE53950).withValues(alpha: 0.15))
                          : const Color(0xFF6B42FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isCore ? (areAllGranted ? 'COMPLETED' : 'REQUIRED') : 'FEATURE',
                      style: TextStyle(
                        color: isCore
                            ? (areAllGranted ? const Color(0xFF00C896) : const Color(0xFFE53950))
                            : const Color(0xFF9065FF),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionCard({
    required AppPermissionModel model,
    required bool isGranted,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
    required VoidCallback onGrant,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isGranted
              ? const Color(0xFF00C896).withValues(alpha: 0.3)
              : cardBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isGranted
                  ? const Color(0xFF00C896).withValues(alpha: 0.12)
                  : const Color(0xFF6B42FF).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              model.icon,
              color: isGranted ? const Color(0xFF00C896) : const Color(0xFF9065FF),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      model.title,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (model.isCore) ...[
                      const SizedBox(width: 6),
                      const Text(
                        '*',
                        style: TextStyle(
                          color: Color(0xFFE53950),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  model.subtitle,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  model.details,
                  style: TextStyle(
                    color: textSecondary.withValues(alpha: 0.8),
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Status or Action Button (Cannot revoke)
          if (isGranted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF00C896).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF00C896).withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF00C896), size: 16),
                  SizedBox(width: 6),
                  Text(
                    'GRANTED',
                    style: TextStyle(
                      color: Color(0xFF00C896),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            )
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: model.isCore ? const Color(0xFF6B42FF) : const Color(0xFF261D4C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: onGrant,
              child: const Text(
                'Grant',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  void _showRequiredNotice(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFFB800), size: 24),
            SizedBox(width: 10),
            Text(
              'Core Permissions Required',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: const Text(
          'TeroVPN cannot tunnel internet traffic or protect your IP address without essential Administrative, Virtual Driver, Firewall, and DNS control permissions. Please grant all core permissions to proceed.',
          style: TextStyle(color: Color(0xFFB3AFCE), fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Back to Setup', style: TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B42FF),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await AppPermissionsService.instance.grantAllCore();
            },
            child: const Text('Grant All Core', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
