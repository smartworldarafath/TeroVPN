import 'package:flutter/material.dart';

class Dock2LensBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final bool isInteractivePreview;

  const Dock2LensBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.isInteractivePreview = false,
  });

  @override
  State<Dock2LensBar> createState() => _Dock2LensBarState();
}

class _Dock2LensBarState extends State<Dock2LensBar> {
  static const List<Map<String, dynamic>> _tabs = [
    {'label': 'Home', 'icon': Icons.shield_rounded, 'inactiveIcon': Icons.shield_outlined},
    {'label': 'Countries', 'icon': Icons.language_rounded, 'inactiveIcon': Icons.language_outlined},
    {'label': 'Profiles', 'icon': Icons.layers_rounded, 'inactiveIcon': Icons.layers_outlined},
    {'label': 'Settings', 'icon': Icons.tune_rounded, 'inactiveIcon': Icons.tune_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final slotWidth = totalWidth / _tabs.length;
        const lensWidth = 74.0;
        const lensHeight = 66.0;

        final lensLeft = (widget.currentIndex * slotWidth) + (slotWidth / 2) - (lensWidth / 2);

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
                  Color(0xFF1B142E),
                  Color(0xFF0F0B1A),
                  Color(0xFF150F24),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6E46DC).withValues(alpha: 0.40),
                  blurRadius: 36,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.75),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Upper Specular Highlight Streak
                Positioned(
                  top: 0,
                  left: 32,
                  right: 32,
                  height: 34,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(999)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.20),
                          Colors.white.withValues(alpha: 0.02),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Animated Elevated Liquid Glass Refractive Lens
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 480),
                  curve: Curves.easeOutCubic,
                  left: lensLeft,
                  top: 5,
                  child: Container(
                    width: lensWidth,
                    height: lensHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.22),
                          const Color(0xFF7C3AED).withValues(alpha: 0.20),
                          const Color(0xFF4C1D95).withValues(alpha: 0.35),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.45),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.50),
                          blurRadius: 24,
                          spreadRadius: 1,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Lens Upper Curved Reflection Meniscus
                        Positioned(
                          top: 2,
                          left: 8,
                          right: 8,
                          height: 14,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.75),
                                  Colors.white.withValues(alpha: 0.1),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Lens Bottom Specular Rim
                        Positioned(
                          bottom: 2,
                          left: 12,
                          right: 12,
                          height: 6,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: const Color(0xFFC084FC).withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
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
                                scale: isSelected ? 1.15 : 1.0,
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeOutBack,
                                child: Icon(
                                  isSelected ? tab['icon'] as IconData : tab['inactiveIcon'] as IconData,
                                  color: isSelected ? Colors.white : const Color(0xFF8B81A5),
                                  size: 24,
                                  shadows: isSelected
                                      ? [
                                          const BoxShadow(
                                            color: Color(0xFFC084FC),
                                            blurRadius: 12,
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
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                  color: isSelected ? Colors.white : const Color(0xFF80759B),
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
