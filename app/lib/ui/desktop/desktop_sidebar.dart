import 'package:flutter/material.dart';
import '../../theme/proton_typography.dart';
import '../../core/models.dart';
import '../components/details_sheet.dart';

class DesktopSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final CoreStatus? status;

  const DesktopSidebar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0C15),
        border: Border(
          right: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B42FF),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6B42FF).withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.shield_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'TeroVPN',
                    style: ProtonTypography.titleMedium.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF7E7B8E),
                    size: 18,
                  ),
                  tooltip: 'Connection Details',
                  onPressed: () => DetailsSheet.show(context, status: status),
                ),
              ],
            ),
          ),

          // Navigation Items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_rounded,
                  label: 'Home',
                ),
                const SizedBox(height: 6),
                _buildNavItem(
                  index: 1,
                  icon: Icons.public_rounded,
                  label: 'Countries',
                ),
                const SizedBox(height: 6),
                _buildNavItem(
                  index: 2,
                  icon: Icons.bookmark_border_rounded,
                  label: 'Profiles',
                ),
                const SizedBox(height: 6),
                _buildNavItem(
                  index: 3,
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                ),
              ],
            ),
          ),

          const Spacer(),

          // Version Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Text(
              'v1.0.9 Desktop',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.25),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTabSelected(index),
        borderRadius: BorderRadius.circular(12),
        hoverColor: Colors.white.withValues(alpha: 0.04),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF282046)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: const Color(0xFF6B42FF).withValues(alpha: 0.35), width: 1)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF8A889A),
                size: 20,
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF8A889A),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
