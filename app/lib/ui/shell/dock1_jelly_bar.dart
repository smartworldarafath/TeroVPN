import 'package:flutter/material.dart';

class Dock1JellyBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final bool isInteractivePreview;

  const Dock1JellyBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.isInteractivePreview = false,
  });

  @override
  State<Dock1JellyBar> createState() => _Dock1JellyBarState();
}

class _Dock1JellyBarState extends State<Dock1JellyBar> {
  static const List<Map<String, dynamic>> _tabs = [
    {'label': 'Home', 'icon': Icons.home_rounded, 'inactiveIcon': Icons.home_outlined},
    {'label': 'Countries', 'icon': Icons.public_rounded, 'inactiveIcon': Icons.public_outlined},
    {'label': 'Profiles', 'icon': Icons.bookmark_rounded, 'inactiveIcon': Icons.bookmark_border_rounded},
    {'label': 'Settings', 'icon': Icons.settings_rounded, 'inactiveIcon': Icons.settings_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final slotWidth = totalWidth / _tabs.length;
        const trayWidth = 72.0;
        const trayHeight = 62.0;

        final trayLeft = (widget.currentIndex * slotWidth) + (slotWidth / 2) - (trayWidth / 2);

        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            height: 76,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1E182E),
                  Color(0xFF120D1E),
                  Color(0xFF181226),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5A30AF).withValues(alpha: 0.45),
                  blurRadius: 32,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.70),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Top Specular Horizon Arc Highlight
                Positioned(
                  top: 0,
                  left: 28,
                  right: 28,
                  height: 32,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(999)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.16),
                          Colors.white.withValues(alpha: 0.03),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Animated Sliding Jelly Capsule Tray
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 480),
                  curve: Curves.easeOutBack,
                  left: trayLeft,
                  top: 7,
                  child: Container(
                    width: trayWidth,
                    height: trayHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF52447E).withValues(alpha: 0.45),
                          const Color(0xFF302650).withValues(alpha: 0.38),
                          const Color(0xFF483A70).withValues(alpha: 0.52),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      // 3D Glossy Purple Jelly Capsule
                      child: Container(
                        width: 58,
                        height: 34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF8B5CF6),
                              Color(0xFF6B42FF),
                              Color(0xFF4C1D95),
                            ],
                          ),
                          border: Border.all(
                            color: const Color(0xFFC084FC).withValues(alpha: 0.65),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6B42FF).withValues(alpha: 0.65),
                              blurRadius: 16,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 4 Interactive Navigation Buttons
                Row(
                  children: List.generate(_tabs.length, (index) {
                    final tab = _tabs[index];
                    final isSelected = widget.currentIndex == index;

                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => widget.onTabSelected(index),
                        child: SizedBox(
                          height: 76,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedScale(
                                scale: isSelected ? 1.12 : 1.0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutBack,
                                child: Icon(
                                  isSelected ? tab['icon'] as IconData : tab['inactiveIcon'] as IconData,
                                  color: isSelected ? Colors.white : const Color(0xFF9086AB),
                                  size: 23,
                                  shadows: isSelected
                                      ? [
                                          const BoxShadow(
                                            color: Colors.white,
                                            blurRadius: 8,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                tab['label'] as String,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? Colors.white : const Color(0xFF887E9F),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
