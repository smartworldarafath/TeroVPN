import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/app_preferences.dart';

/// 100% Faithful Implementation of "onboarding.html"
/// 60fps Butter Smooth Catmull-Rom Bezier Fluid Liquid Wave Animation
///
/// Features:
/// - Exact 900ms SVG Catmull-Rom Bezier fluid liquid wave morphing (liquidX & liquid)
/// - 40 sample points Gaussian bell morphing curve ($e^{-0.5 ((x-220)/95)^2}$)
/// - Slide 0 -> 1: falling white water drop flood, violet slab rising
/// - Slide 1 -> 2: inverted drop color exchange
/// - Illustration parallax translation, scaling, and opacity cross-fade
/// - Ambient aurora orbs shifting per slide
/// - Soft liquid glass SKIP button & CTA button (Continue -> Continue -> Get in)
/// - Back chevron button visible on slides 1 & 2
/// - Horizontal drag/swipe with fluid resistance
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const OnboardingScreen({super.key, required this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  static const int _kTotalSlides = 3;
  static const List<String> _kLabels = ['Continue', 'Continue', 'Get in'];

  static const List<Map<String, String>> _slides = [
    {
      'title': 'Be Safe',
      'desc':
          'You can browse the internet in the most secure possible way. We let you anonymously browse the internet and protect your private information.',
    },
    {
      'title': 'Online Freedom',
      'desc':
          'Bypass censorship and get unlimited access to all of your favourite websites and apps without any fear being monitored by someone.',
    },
    {
      'title': 'Privacy and Security',
      'desc':
          'Using Wi-fi and open connections puts your information at risk. We will keep your sensitive information away from hackers and ISPs.',
    },
  ];

  int _currentSlide = 0;
  int _fromSlide = 0;
  int _toSlide = 0;
  String _transitionKind = 'F'; // 'F' (into slide 1), 'R' (out of slide 1), 'V' (0 <-> 2)
  bool _isTransitioning = false;

  late AnimationController _waveController;

  // Drag tracking
  double? _dragStartX;
  double? _dragStartY;
  double _dragDistanceX = 0.0;
  int _dragStartTime = 0;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _goToSlide(int target) {
    if (_isTransitioning || target == _currentSlide || target < 0 || target >= _kTotalSlides) {
      return;
    }

    final from = _currentSlide;
    // Determine transition kind matching onboarding.html:
    // F: into slide 1 (white down / violet up)
    // R: out of slide 1 (violet down / white up)
    // V: 0 <-> 2 direct
    final kind = target == 1 ? 'F' : (from == 1 ? 'R' : 'V');

    setState(() {
      _fromSlide = from;
      _toSlide = target;
      _transitionKind = kind;
      _isTransitioning = true;
    });

    _waveController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _currentSlide = target;
          _isTransitioning = false;
        });
      }
    });
  }

  void _nextSlide() {
    if (_currentSlide < _kTotalSlides - 1) {
      _goToSlide(_currentSlide + 1);
    } else {
      _completeOnboarding();
    }
  }

  void _prevSlide() {
    if (_currentSlide > 0) {
      _goToSlide(_currentSlide - 1);
    }
  }

  void _completeOnboarding() {
    AppPreferences.setOnboardingCompleted(true);
    widget.onFinished();
  }

  void _onPointerDown(PointerDownEvent e) {
    if (_isTransitioning) return;
    _dragStartX = e.position.dx;
    _dragStartY = e.position.dy;
    _dragDistanceX = 0.0;
    _dragStartTime = DateTime.now().millisecondsSinceEpoch;
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (_dragStartX == null || _dragStartY == null || _isTransitioning) return;
    final dx = e.position.dx - _dragStartX!;
    final dy = e.position.dy - _dragStartY!;
    if (dx.abs() > dy.abs()) {
      setState(() {
        _dragDistanceX = dx;
      });
    }
  }

  void _onPointerUp(PointerUpEvent e) {
    if (_dragStartX == null || _isTransitioning) return;
    final dx = _dragDistanceX;
    final dt = math.max(1, DateTime.now().millisecondsSinceEpoch - _dragStartTime);
    final velocity = dx.abs() / dt;
    _dragStartX = null;
    _dragStartY = null;
    _dragDistanceX = 0.0;

    final isFastSwipe = dx.abs() > 24 && velocity > 0.45;
    final isLongSwipe = dx.abs() > 50;

    if (isFastSwipe || isLongSwipe) {
      if (dx < 0 && _currentSlide < _kTotalSlides - 1) {
        _goToSlide(_currentSlide + 1);
      } else if (dx > 0 && _currentSlide > 0) {
        _goToSlide(_currentSlide - 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final progress = _isTransitioning ? _waveController.value : 0.0;
    final activeSlide = _isTransitioning && progress >= 0.5 ? _toSlide : _currentSlide;
    final isInverse = activeSlide == 1;

    return Scaffold(
      backgroundColor: const Color(0xFF070312),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440, maxHeight: 956),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF522196),
                Color(0xFF37116D),
                Color(0xFF210746),
              ],
              stops: [0.0, 0.58, 1.0],
            ),
            borderRadius: size.width > 460 ? BorderRadius.circular(36) : BorderRadius.zero,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.75),
                blurRadius: 50,
                offset: const Offset(0, 25),
              ),
            ],
          ),
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUp,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Ambient Aurora Orbs
                _buildAuroraOrbs(size, activeSlide),

                // 2. 60fps Catmull-Rom Bezier Fluid Liquid Wave Layer
                Positioned.fill(
                  child: CustomPaint(
                    painter: _LiquidMorphPainter(
                      currentSlide: _currentSlide,
                      fromSlide: _fromSlide,
                      toSlide: _toSlide,
                      transitionKind: _transitionKind,
                      isTransitioning: _isTransitioning,
                      progress: progress,
                    ),
                  ),
                ),

                // 3. Top Navigation Bar (Back Chevron & Soft Liquid Glass SKIP pill)
                Positioned(
                  top: topPadding > 0 ? (topPadding + 10) : 26,
                  left: 24,
                  right: 24,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Chevron
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: activeSlide > 0 ? 1.0 : 0.0,
                        child: GestureDetector(
                          onTap: activeSlide > 0 ? _prevSlide : null,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isInverse
                                  ? Colors.white.withValues(alpha: 0.22)
                                  : const Color(0xFF7C3AED).withValues(alpha: 0.18),
                              border: Border.all(
                                color: isInverse
                                    ? Colors.white.withValues(alpha: 0.45)
                                    : const Color(0xFF7C3AED).withValues(alpha: 0.28),
                                width: 1.0,
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 16,
                              color: isInverse ? Colors.white : const Color(0xFF7C3AED),
                            ),
                          ),
                        ),
                      ),

                      // Soft Liquid Glass SKIP Button
                      GestureDetector(
                        onTap: _completeOnboarding,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF9333EA),
                                Color(0xFF6D28D9),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.50),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6D28D9).withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Text(
                            'SKIP',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. Parallax Content (Illustrations + Texts)
                Positioned.fill(
                  child: _buildParallaxContent(size),
                ),

                // 5. Bottom Controls (Pagination Dots + Liquid Glass CTA Button)
                Positioned(
                  left: 34,
                  right: 34,
                  bottom: bottomPadding > 0 ? (bottomPadding + 18) : 38,
                  child: _buildBottomControls(activeSlide, isInverse),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuroraOrbs(Size size, int activeSlide) {
    final orbOffsets = [
      [-80.0, 0.08, -70.0, -40.0],
      [-20.0, 0.45, -120.0, 0.35],
      [40.0, 0.10, -140.0, -25.0],
    ][activeSlide];

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              left: orbOffsets[0],
              bottom: size.height * orbOffsets[1],
              width: 320,
              height: 320,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFA855F7).withValues(alpha: 0.35),
                      const Color(0xFFA855F7).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              right: orbOffsets[2],
              bottom: orbOffsets[3] < 0 ? orbOffsets[3] : size.height * orbOffsets[3],
              width: 300,
              height: 300,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF7C3AED).withValues(alpha: 0.40),
                      const Color(0xFF7C3AED).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParallaxContent(Size size) {
    final progress = _isTransitioning ? _waveController.value : 0.0;

    return Stack(
      fit: StackFit.expand,
      children: List.generate(_kTotalSlides, (idx) {
        double opacity = 0.0;
        double translateY = 0.0;
        double scale = 1.0;

        if (!_isTransitioning) {
          if (idx == _currentSlide) {
            opacity = 1.0;
            translateY = _dragDistanceX * 0.15;
          }
        } else {
          final isFrom = idx == _fromSlide;
          final isTo = idx == _toSlide;
          final fwd = _transitionKind == 'F';
          final illDir = fwd ? 1.0 : -1.0;

          if (isFrom) {
            final o = _seg(progress, 0.0, 0.35);
            opacity = 1.0 - _smooth(o);
            translateY = _easeIn(o) * 120.0 * illDir;
            scale = 1.0 - 0.05 * o;
          } else if (isTo) {
            final q = _seg(progress, 0.55, 1.0);
            opacity = _smooth(q);
            translateY = -(1.0 - _easeOut(q)) * 70.0 * illDir;
          }
        }

        if (opacity <= 0.001) return const SizedBox.shrink();

        final slide = _slides[idx];
        final isSlide1 = idx == 1;

        return IgnorePointer(
          ignoring: idx != (_isTransitioning ? _toSlide : _currentSlide),
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, translateY),
              child: Transform.scale(
                scale: scale,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Illustration position
                    Positioned(
                      top: isSlide1 ? size.height * 0.52 : size.height * 0.08,
                      left: 20,
                      right: 20,
                      height: size.height * 0.34,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: _buildIllustration(idx),
                        ),
                      ),
                    ),

                    // Texts position
                    Positioned(
                      top: isSlide1 ? size.height * 0.12 : size.height * 0.58,
                      left: 32,
                      right: 32,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            slide['title']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: isSlide1 ? Colors.white : Colors.white,
                              shadows: const [
                                Shadow(
                                  color: Color(0x6612042D),
                                  blurRadius: 18,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            slide['desc']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w400,
                              height: 1.55,
                              color: isSlide1 ? const Color(0xFFF3E8FF) : const Color(0xFFF3E8FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBottomControls(int activeSlide, bool isInverse) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 3 Pagination Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_kTotalSlides, (idx) {
            final isActive = idx == activeSlide;

            return GestureDetector(
              onTap: () => _goToSlide(idx),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: isActive ? 12 : 8,
                height: isActive ? 12 : 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? (isInverse ? const Color(0xFF6D28D9) : Colors.white)
                      : (isInverse
                          ? const Color(0xFF5B21B6).withValues(alpha: 0.30)
                          : Colors.white.withValues(alpha: 0.35)),
                  shape: BoxShape.circle,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: isInverse
                                ? const Color(0xFF6D28D9).withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.85),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 22),

        // Soft Liquid Glass CTA Button (Continue -> Continue -> Get in)
        GestureDetector(
          onTap: _nextSlide,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 240),
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFA855F7),
                  Color(0xFF8B5CF6),
                  Color(0xFF7C3AED),
                ],
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.55),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF110429).withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _kLabels[activeSlide],
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Color(0x661E0744), blurRadius: 4, offset: Offset(0, 1)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIllustration(int index) {
    switch (index) {
      case 0:
        return CustomPaint(
          size: const Size(340, 270),
          painter: _Slide1IllustrationPainter(),
        );
      case 1:
        return CustomPaint(
          size: const Size(340, 270),
          painter: _Slide2IllustrationPainter(),
        );
      case 2:
      default:
        return CustomPaint(
          size: const Size(340, 270),
          painter: _Slide3IllustrationPainter(),
        );
    }
  }

  static double _clamp(double v) => math.max(0.0, math.min(1.0, v));
  static double _seg(double p, double a, double b) => _clamp((p - a) / (b - a));
  static double _smooth(double x) => x * x * (3.0 - 2.0 * x);
  static double _easeIn(double x) => x * x;
  static double _easeOut(double x) => 1.0 - math.pow(1.0 - x, 3.0);
}

/// 60fps Catmull-Rom Bezier Spline Fluid Liquid Wave Painter
/// Directly translated from "onboarding.html"
class _LiquidMorphPainter extends CustomPainter {
  final int currentSlide;
  final int fromSlide;
  final int toSlide;
  final String transitionKind;
  final bool isTransitioning;
  final double progress;

  static const int _kSamples = 40;

  _LiquidMorphPainter({
    required this.currentSlide,
    required this.fromSlide,
    required this.toSlide,
    required this.transitionKind,
    required this.isTransitioning,
    required this.progress,
  });

  static double _clamp(double v) => math.max(0.0, math.min(1.0, v));
  static double _seg(double p, double a, double b) => _clamp((p - a) / (b - a));
  static double _easeIO(double x) =>
      x < 0.5 ? 4.0 * x * x * x : 1.0 - math.pow(-2.0 * x + 2.0, 3.0) / 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Build base 40 sample points scaled to size.width & size.height
    final xs = <double>[];
    final g = <double>[];
    final yr = <double>[];
    final yd = <double>[];

    final archBase = h * 0.44;
    final archPeak = h * 0.08;

    for (int i = 0; i <= _kSamples; i++) {
      final x = i * w / _kSamples;
      xs.add(x);
      g.add(math.exp(-0.5 * math.pow((x - w * 0.5) / (w * 0.22), 2)));
      yr.add(archBase + archPeak * 4.0 * (x / w) * (1.0 - x / w));
      yd.add(h - yr[i]);
    }

    final whitePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, Color(0xFFFBF9FF)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final rimPaint = Paint()
      ..color = const Color(0xFFC084FC).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final shadowPaint = Paint()
      ..color = const Color(0xFF13052C).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);

    if (!isTransitioning) {
      if (currentSlide != 1) {
        // Resting Slide 0 or 2: Top White Arch
        final pts = List.generate(_kSamples + 1, (i) => Offset(xs[i], yr[i]));
        final path = _buildSplinePath(pts, w, h, isTopWhite: true);
        final edge = _buildEdgePath(pts);

        canvas.drawPath(edge, shadowPaint);
        canvas.drawPath(path, whitePaint);
        canvas.drawPath(edge, rimPaint);
      } else {
        // Resting Slide 1: Inverted Bottom White Arch
        final pts = List.generate(_kSamples + 1, (i) => Offset(xs[i], yd[i]));
        final path = _buildSplinePath(pts, w, h, isTopWhite: false);
        final edge = _buildEdgePath(pts);

        canvas.drawPath(edge, shadowPaint);
        canvas.drawPath(path, whitePaint);
        canvas.drawPath(edge, rimPaint);
      }
      return;
    }

    // Dynamic 900ms Fluid Liquid Morph
    final p = progress;
    final isMirror = transitionKind == 'R';

    if (transitionKind == 'V') {
      // 0 <-> 2 Direct Wave
      final pA = _seg(p, 0.0, 0.62);
      final pB = _seg(p, 0.38, 1.0);
      final eA = _easeIO(pA);
      final eB = _easeIO(pB);
      final sA = math.sin(math.pi * pA);
      final sB = math.sin(math.pi * pB);

      final bot = List.generate(_kSamples + 1, (i) {
        final front = yr[i] + eA * (h - archBase + 140.0) + sA * 230.0 * g[i];
        final rise = yr[i] + (1.0 - eB) * (h - archBase + 90.0) - sB * 170.0 * g[i];
        return Offset(xs[i], math.min(front, rise));
      });

      final path = _buildSplinePath(bot, w, h, isTopWhite: true);
      final edge = _buildEdgePath(bot);
      canvas.drawPath(edge, shadowPaint);
      canvas.drawPath(path, whitePaint);
      canvas.drawPath(edge, rimPaint);
    } else {
      // liquidX: Color exchange with Gaussian bell morphing
      final pA = _seg(p, 0.0, 0.55);
      final pB = _seg(p, 0.26, 1.0);
      final eA = _easeIO(pA);
      final eB = _easeIO(pB);
      final sA = math.sin(math.pi * pA);
      final sB = math.sin(math.pi * pB);

      final pts = List.generate(_kSamples + 1, (i) {
        double y = yr[i] + eA * (h - archBase + 140.0) + sA * 230.0 * g[i];
        if (pB > 0.0) {
          final rise = (h + 120.0) - eB * (h + 370.0) - sB * 170.0 * g[i];
          y = math.min(y, rise);
        }
        if (isMirror) {
          y = h - y;
        }
        return Offset(xs[i], y);
      });

      final path = _buildSplinePath(pts, w, h, isTopWhite: !isMirror);
      final edge = _buildEdgePath(pts);
      canvas.drawPath(edge, shadowPaint);
      canvas.drawPath(path, whitePaint);
      canvas.drawPath(edge, rimPaint);
    }
  }

  /// Converts points into smooth Catmull-Rom Bezier Spline Path
  Path _buildSplinePath(List<Offset> points, double w, double h, {required bool isTopWhite}) {
    final path = Path();
    if (isTopWhite) {
      path.moveTo(0, 0);
      path.lineTo(points[0].dx, points[0].dy);
      _appendCatmullRom(path, points);
      path.lineTo(w, 0);
      path.close();
    } else {
      path.moveTo(0, h);
      path.lineTo(points[0].dx, points[0].dy);
      _appendCatmullRom(path, points);
      path.lineTo(w, h);
      path.close();
    }
    return path;
  }

  Path _buildEdgePath(List<Offset> points) {
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    _appendCatmullRom(path, points);
    return path;
  }

  void _appendCatmullRom(Path path, List<Offset> p) {
    for (int i = 0; i < p.length - 1; i++) {
      final a = i > 0 ? p[i - 1] : p[i];
      final b = p[i];
      final c = p[i + 1];
      final e = i < p.length - 2 ? p[i + 2] : c;

      final cp1 = Offset(b.dx + (c.dx - a.dx) / 6.0, b.dy + (c.dy - a.dy) / 6.0);
      final cp2 = Offset(c.dx - (e.dx - b.dx) / 6.0, c.dy - (e.dy - b.dy) / 6.0);

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, c.dx, c.dy);
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidMorphPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.currentSlide != currentSlide ||
        oldDelegate.isTransitioning != isTransitioning;
  }
}

// ==============================================================================
// Pixel-Perfect Vector Illustrations (Slide 1, Slide 2, Slide 3)
// ==============================================================================

class _Slide1IllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.65;

    // Floor Platform Ellipse
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: 260, height: 90),
      Paint()..color = const Color(0xFFF3F0F9),
    );

    // Isometric Laptop Screen Lid
    final laptopScreen = Path()
      ..moveTo(cx - 75, cy - 145)
      ..lineTo(cx + 30, cy - 185)
      ..lineTo(cx + 30, cy - 90)
      ..lineTo(cx - 75, cy - 50)
      ..close();
    canvas.drawPath(laptopScreen, Paint()..color = const Color(0xFF1E293B));

    final screenInner = Path()
      ..moveTo(cx - 70, cy - 140)
      ..lineTo(cx + 25, cy - 177)
      ..lineTo(cx + 25, cy - 95)
      ..lineTo(cx - 70, cy - 58)
      ..close();
    canvas.drawPath(
      screenInner,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF6D28D9), Color(0xFF4C1D95)],
        ).createShader(Rect.fromLTWH(cx - 75, cy - 185, 105, 135)),
    );

    canvas.drawCircle(Offset(cx - 20, cy - 135), 9, Paint()..color = Colors.white);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx - 20, cy - 105), width: 44, height: 7),
          const Radius.circular(3.5)),
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );

    // Keyboard Deck
    final keyboardDeck = Path()
      ..moveTo(cx - 75, cy - 50)
      ..lineTo(cx + 30, cy - 90)
      ..lineTo(cx + 85, cy - 60)
      ..lineTo(cx - 20, cy - 20)
      ..close();
    canvas.drawPath(keyboardDeck, Paint()..color = const Color(0xFF334155));

    // Floating Purple Shield
    final shieldCenter = Offset(cx + 35, cy - 95);
    final shieldPath = Path()
      ..moveTo(shieldCenter.dx, shieldCenter.dy - 40)
      ..lineTo(shieldCenter.dx + 28, shieldCenter.dy - 25)
      ..lineTo(shieldCenter.dx + 28, shieldCenter.dy + 8)
      ..cubicTo(shieldCenter.dx + 28, shieldCenter.dy + 32, shieldCenter.dx,
          shieldCenter.dy + 48, shieldCenter.dx, shieldCenter.dy + 48)
      ..cubicTo(shieldCenter.dx, shieldCenter.dy + 48, shieldCenter.dx - 28,
          shieldCenter.dy + 32, shieldCenter.dx - 28, shieldCenter.dy + 8)
      ..lineTo(shieldCenter.dx - 28, shieldCenter.dy - 25)
      ..close();

    canvas.drawPath(
      shieldPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF9333EA), Color(0xFF5B21B6)],
        ).createShader(Rect.fromLTWH(shieldCenter.dx - 28, shieldCenter.dy - 40, 56, 88)),
    );

    // Keyhole
    canvas.drawCircle(Offset(shieldCenter.dx, shieldCenter.dy - 4), 6,
        Paint()..color = const Color(0xFF1E1B4B));
    final keyStem = Path()
      ..moveTo(shieldCenter.dx - 4, shieldCenter.dy - 1)
      ..lineTo(shieldCenter.dx + 4, shieldCenter.dy - 1)
      ..lineTo(shieldCenter.dx + 5, shieldCenter.dy + 14)
      ..lineTo(shieldCenter.dx - 5, shieldCenter.dy + 14)
      ..close();
    canvas.drawPath(keyStem, Paint()..color = const Color(0xFF1E1B4B));

    // Standing Character
    final charX = cx + 80;
    final charY = cy - 65;
    canvas.drawCircle(Offset(charX, charY - 26), 7, Paint()..color = const Color(0xFFFDE68A));
    canvas.drawRect(Rect.fromLTWH(charX - 7, charY - 14, 14, 28),
        Paint()..color = const Color(0xFF7C3AED));
    canvas.drawLine(Offset(charX - 3, charY + 14), Offset(charX - 3, charY + 45),
        Paint()..color = const Color(0xFF1E293B)..strokeWidth = 4.5);
    canvas.drawLine(Offset(charX + 4, charY + 14), Offset(charX + 4, charY + 45),
        Paint()..color = const Color(0xFF334155)..strokeWidth = 4.5);

    // Purple Key
    final keyPaint = Paint()
      ..color = const Color(0xFF7C3AED)
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(cx - 50, cy - 5), 8, keyPaint);
    canvas.drawLine(Offset(cx - 42, cy - 5), Offset(cx - 15, cy - 5), keyPaint);
    canvas.drawLine(Offset(cx - 24, cy - 5), Offset(cx - 24, cy + 3), keyPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Slide2IllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.65;

    // Floor shadow
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 10), width: 190, height: 26),
        Paint()..color = const Color(0xFFF1F5F9));

    // Rocket
    final rocketCenter = Offset(cx + 60, cy - 140);
    final rocketBody = Path()
      ..moveTo(rocketCenter.dx, rocketCenter.dy - 20)
      ..quadraticBezierTo(rocketCenter.dx + 12, rocketCenter.dy, rocketCenter.dx + 12,
          rocketCenter.dy + 20)
      ..lineTo(rocketCenter.dx - 12, rocketCenter.dy + 20)
      ..quadraticBezierTo(rocketCenter.dx - 12, rocketCenter.dy, rocketCenter.dx,
          rocketCenter.dy - 20)
      ..close();
    canvas.drawPath(rocketBody, Paint()..color = const Color(0xFF1E293B));
    canvas.drawCircle(Offset(rocketCenter.dx, rocketCenter.dy), 4,
        Paint()..color = const Color(0xFFA855F7));

    // Flame
    canvas.drawPath(
      Path()
        ..moveTo(rocketCenter.dx - 5, rocketCenter.dy + 20)
        ..lineTo(rocketCenter.dx, rocketCenter.dy + 30)
        ..lineTo(rocketCenter.dx + 5, rocketCenter.dy + 20)
        ..close(),
      Paint()..color = const Color(0xFFC084FC),
    );

    // Cross-legged person
    final charCenter = Offset(cx, cy - 40);
    canvas.drawCircle(Offset(charCenter.dx, charCenter.dy - 45), 11,
        Paint()..color = const Color(0xFFFDE68A));
    canvas.drawCircle(Offset(charCenter.dx, charCenter.dy - 50), 12,
        Paint()..color = const Color(0xFF1E293B));

    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(charCenter.dx, charCenter.dy - 15), width: 34, height: 38),
            const Radius.circular(8)),
        Paint()..color = const Color(0xFF1E1B4B));

    canvas.drawOval(
        Rect.fromCenter(center: Offset(charCenter.dx, charCenter.dy + 12), width: 70, height: 22),
        Paint()..color = const Color(0xFF1E1B4B));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(charCenter.dx, charCenter.dy - 2), width: 38, height: 24),
          const Radius.circular(3)),
      Paint()..color = const Color(0xFF9333EA),
    );
    canvas.drawCircle(Offset(charCenter.dx, charCenter.dy - 2), 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Slide3IllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.60;

    // Monitor
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy - 40), width: 170, height: 110),
            const Radius.circular(8)),
        Paint()..color = const Color(0xFF1E1B4B));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy - 40), width: 154, height: 94),
            const Radius.circular(4)),
        Paint()..color = const Color(0xFF7C3AED));

    // Shield
    final shieldPath = Path()
      ..moveTo(cx, cy - 80)
      ..lineTo(cx + 42, cy - 62)
      ..lineTo(cx + 42, cy - 20)
      ..cubicTo(cx + 42, cy + 18, cx, cy + 42, cx, cy + 42)
      ..cubicTo(cx, cy + 42, cx - 42, cy + 18, cx - 42, cy - 20)
      ..lineTo(cx - 42, cy - 62)
      ..close();

    canvas.drawPath(
      shieldPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF3B0764)],
        ).createShader(Rect.fromLTWH(cx - 42, cy - 80, 84, 122)),
    );

    // Glowing Checkmark
    canvas.drawCircle(Offset(cx, cy - 22), 22, Paint()..color = const Color(0xFF7C3AED));
    canvas.drawCircle(Offset(cx, cy - 22), 22,
        Paint()..color = const Color(0xFFC084FC)..style = PaintingStyle.stroke..strokeWidth = 2);

    final checkPath = Path()
      ..moveTo(cx - 10, cy - 22)
      ..lineTo(cx - 3, cy - 15)
      ..lineTo(cx + 12, cy - 30);
    canvas.drawPath(
      checkPath,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 4.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
