import 'package:flutter/material.dart';
import '../../core/app_permissions_service.dart';
import '../../theme/theme_manager.dart';
import '../components/liquid_glass_atmosphere.dart';

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final permissionsService = AppPermissionsService.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([ThemeManager.instance, permissionsService]),
      builder: (context, _) {
        final isDark = ThemeManager.instance.isDarkMode;
        final isLiquid = ThemeManager.instance.isLiquidGlass;

        final cardBg = isDark
            ? (isLiquid ? const Color(0xFF161426).withValues(alpha: 0.85) : const Color(0xFF1C192E))
            : (isLiquid ? Colors.white.withValues(alpha: 0.90) : Colors.white);

        final cardBorder = isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFF5D5380).withValues(alpha: 0.12);

        final textPrimary = isDark ? Colors.white : const Color(0xFF1D1536);
        final textSecondary = isDark ? const Color(0xFF9E9BAC) : const Color(0xFF6E6B80);

        final grantedCount = permissionsService.grantedCount;
        final totalCount = permissionsService.totalCount;
        final areAllGranted = grantedCount == totalCount;
        final areCoreGranted = permissionsService.areCorePermissionsGranted;

        return LiquidGlassAtmosphere(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'Permissions',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                // Top Status Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? (areAllGranted
                              ? [const Color(0xFF0F2B22), const Color(0xFF15222E)]
                              : [const Color(0xFF261D4C), const Color(0xFF1A1633)])
                          : (areAllGranted
                              ? [const Color(0xFFE6F9F3), const Color(0xFFEEF8FB)]
                              : [const Color(0xFFEDE8FC), const Color(0xFFF3F0FD)]),
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: areAllGranted
                          ? const Color(0xFF00C896).withValues(alpha: 0.4)
                          : const Color(0xFF6B42FF).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: areAllGranted
                              ? const Color(0xFF00C896).withValues(alpha: 0.18)
                              : const Color(0xFF6B42FF).withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          areAllGranted ? Icons.security_rounded : Icons.shield_outlined,
                          color: areAllGranted ? const Color(0xFF00C896) : const Color(0xFF9065FF),
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              areAllGranted
                                  ? 'All Systems Operational'
                                  : (areCoreGranted
                                      ? 'Core VPN Protected'
                                      : 'Action Required: Core Incomplete'),
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              areAllGranted
                                  ? '$grantedCount of $totalCount system permissions granted. Zero-leak tunnel, Kill Switch and firewall protection active.'
                                  : '$grantedCount of $totalCount permissions granted. Grant missing permissions below to unlock maximum security.',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 12.5,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: areAllGranted
                              ? const Color(0xFF00C896).withValues(alpha: 0.15)
                              : const Color(0xFF6B42FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$grantedCount / $totalCount',
                          style: TextStyle(
                            color: areAllGranted ? const Color(0xFF00C896) : const Color(0xFF9065FF),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // If some permissions are missing, show Grant All button
                if (!areAllGranted) ...[
                  SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B42FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.done_all_rounded, size: 18),
                      label: const Text(
                        'Grant All Missing Permissions',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                      onPressed: () => permissionsService.grantAllPermissions(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Categories
                ..._buildCategoryGroup(
                  categoryName: 'Installation & System Level Permissions',
                  models: AppPermissionsService.definitions
                      .where((p) => p.category == 'Installation & System Level')
                      .toList(),
                  permissionsService: permissionsService,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),

                const SizedBox(height: 20),

                ..._buildCategoryGroup(
                  categoryName: 'Network & Virtual Driver Permissions (Crucial)',
                  models: AppPermissionsService.definitions
                      .where((p) => p.category == 'Network & Virtual Driver')
                      .toList(),
                  permissionsService: permissionsService,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),

                const SizedBox(height: 20),

                ..._buildCategoryGroup(
                  categoryName: 'Advanced Feature Permissions',
                  models: AppPermissionsService.definitions
                      .where((p) => p.category == 'Advanced Feature Permissions')
                      .toList(),
                  permissionsService: permissionsService,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),

                const SizedBox(height: 20),

                ..._buildCategoryGroup(
                  categoryName: 'System Integrations',
                  models: AppPermissionsService.definitions
                      .where((p) => p.category == 'System Integrations')
                      .toList(),
                  permissionsService: permissionsService,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildCategoryGroup({
    required String categoryName,
    required List<AppPermissionModel> models,
    required AppPermissionsService permissionsService,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(
          categoryName.toUpperCase(),
          style: TextStyle(
            color: textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
      ...models.map(
        (m) {
          final isGranted = permissionsService.isGranted(m.type);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isGranted
                    ? const Color(0xFF00C896).withValues(alpha: 0.25)
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
                    m.icon,
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
                            m.title,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (m.isCore) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE53950).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'CORE',
                                style: TextStyle(
                                  color: Color(0xFFE53950),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        m.subtitle,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        m.details,
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
                // Granted Status Badge or Clickable Grant Button
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
                      backgroundColor: const Color(0xFF6B42FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => permissionsService.grantPermission(m.type),
                    child: const Text(
                      'Grant',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    ];
  }
}
