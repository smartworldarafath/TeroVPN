import 'package:flutter/material.dart';

import '../../core/app_preferences.dart';



class OnboardingScreen extends StatefulWidget {

  final VoidCallback onFinished;



  const OnboardingScreen({super.key, required this.onFinished});



  @override

  State<OnboardingScreen> createState() => _OnboardingScreenState();

}



class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {

  int _currentSlide = 0;

  late PageController _pageController;



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



  @override

  void initState() {

    super.initState();

    _pageController = PageController();

  }



  @override

  void dispose() {

    _pageController.dispose();

    super.dispose();

  }



  void _nextSlide() {

    if (_currentSlide < _slides.length - 1) {

      _pageController.nextPage(

        duration: const Duration(milliseconds: 450),

        curve: Curves.easeInOutCubic,

      );

    } else {

      _completeOnboarding();

    }

  }



  void _prevSlide() {

    if (_currentSlide > 0) {

      _pageController.previousPage(

        duration: const Duration(milliseconds: 450),

        curve: Curves.easeInOutCubic,

      );

    }

  }



  void _goToSlide(int index) {

    _pageController.animateToPage(

      index,

      duration: const Duration(milliseconds: 450),

      curve: Curves.easeInOutCubic,

    );

  }



  void _completeOnboarding() {

    AppPreferences.setOnboardingCompleted(true);

    widget.onFinished();

  }



  @override

  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;

    final topPadding = MediaQuery.of(context).padding.top;

    final bottomPadding = MediaQuery.of(context).padding.bottom;



    // Screen 1 (index 1) has inverted scheme in reference onboarding.html

    final isInverse = _currentSlide == 1;



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

          child: Stack(

            fit: StackFit.expand,

            children: [

              // Ambient Aurora Orbs

              _buildAuroraOrbs(size, isInverse),



              // Liquid Dynamic Wave Arch Layer

              Positioned.fill(

                child: CustomPaint(

                  painter: _LiquidArchPainter(slideIndex: _currentSlide),

                ),

              ),



              // Top Bar: Back Chevron & SKIP Button

              Positioned(

                top: topPadding > 0 ? (topPadding + 6) : 26,

                left: 20,

                right: 20,

                child: Row(

                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [

                    // Back Chevron (hidden on slide 0)

                    AnimatedOpacity(

                      opacity: _currentSlide > 0 ? 1.0 : 0.0,

                      duration: const Duration(milliseconds: 250),

                      child: GestureDetector(

                        onTap: _currentSlide > 0 ? _prevSlide : null,

                        child: Container(

                          width: 38,

                          height: 38,

                          decoration: BoxDecoration(

                            color: isInverse ? Colors.white.withValues(alpha: 0.15) : const Color(0xFF7C3AED).withValues(alpha: 0.10),

                            shape: BoxShape.circle,

                            border: Border.all(

                              color: isInverse ? Colors.white30 : const Color(0xFF7C3AED).withValues(alpha: 0.20),

                            ),

                          ),

                          child: Icon(

                            Icons.chevron_left_rounded,

                            color: isInverse ? Colors.white : const Color(0xFF6D28D9),

                            size: 24,

                          ),

                        ),

                      ),

                    ),



                    // Soft Liquid Glass SKIP Pill

                    GestureDetector(

                      onTap: _completeOnboarding,

                      child: Container(

                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),

                        decoration: BoxDecoration(

                          gradient: const LinearGradient(

                            colors: [Color(0xFF9333EA), Color(0xFF6D28D9)],

                          ),

                          borderRadius: BorderRadius.circular(999),

                          border: Border.all(color: Colors.white.withValues(alpha: 0.45)),

                          boxShadow: [

                            BoxShadow(

                              color: const Color(0xFF6D28D9).withValues(alpha: 0.35),

                              blurRadius: 16,

                              offset: const Offset(0, 6),

                            ),

                          ],

                        ),

                        child: const Text(

                          'SKIP',

                          style: TextStyle(

                            fontSize: 11.5,

                            fontWeight: FontWeight.w800,

                            letterSpacing: 0.8,

                            color: Colors.white,

                          ),

                        ),

                      ),

                    ),

                  ],

                ),

              ),



              // Main Swipeable Content

              PageView.builder(

                controller: _pageController,

                itemCount: _slides.length,

                onPageChanged: (idx) {

                  setState(() => _currentSlide = idx);

                },

                itemBuilder: (context, index) {

                  return _buildSlideContent(index, size);

                },

              ),



              // Bottom Controls: Pagination Dots & Liquid Glass CTA Button

              Positioned(

                left: 34,

                right: 34,

                bottom: bottomPadding > 0 ? (bottomPadding + 18) : 38,

                child: Column(

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    // 3 Pagination Dots

                    Row(

                      mainAxisAlignment: MainAxisAlignment.center,

                      children: List.generate(3, (idx) {

                        final isActive = idx == _currentSlide;

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

                                  : (isInverse ? const Color(0xFF5B21B6).withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.35)),

                              shape: BoxShape.circle,

                              boxShadow: isActive

                                  ? [

                                      BoxShadow(

                                        color: isInverse ? const Color(0xFF6D28D9).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.85),

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



                    // Soft Liquid Glass CTA Button

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

                          border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.2),

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

                            _currentSlide == 2 ? 'Get in' : 'Continue',

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

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }



  Widget _buildAuroraOrbs(Size size, bool isInverse) {

    return Positioned.fill(

      child: IgnorePointer(

        child: Stack(

          children: [

            Positioned(

              left: -80,

              bottom: isInverse ? size.height * 0.4 : size.height * 0.08,

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

            Positioned(

              right: -70,

              bottom: isInverse ? size.height * 0.35 : -40,

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



  Widget _buildSlideContent(int index, Size size) {
    final slide = _slides[index];
    final isInverse = index == 1;

    if (!isInverse) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: size.height * 0.08,
            left: 20,
            right: 20,
            height: size.height * 0.35,
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: _buildIllustration(index),
              ),
            ),
          ),
          Positioned(
            top: size.height * 0.52,
            left: 32,
            right: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  slide['title']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Color(0x5512042D), blurRadius: 18, offset: Offset(0, 4)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  slide['desc']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w400,
                    height: 1.55,
                    color: Color(0xFFF3E8FF),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: size.height * 0.12,
            left: 32,
            right: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  slide['title']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Color(0x5512042D), blurRadius: 18, offset: Offset(0, 4)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  slide['desc']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w400,
                    height: 1.55,
                    color: Color(0xFFF3E8FF),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: size.height * 0.44,
            left: 20,
            right: 20,
            height: size.height * 0.34,
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: _buildIllustration(index),
              ),
            ),
          ),
        ],
      );
    }
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

}



/// Liquid Arch Wave separating upper and lower regions

class _LiquidArchPainter extends CustomPainter {
  final int slideIndex;

  _LiquidArchPainter({required this.slideIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final isInverse = slideIndex == 1;

    final whiteGrad = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.white, Color(0xFFFBF9FF)],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    if (!isInverse) {
      final archPath = Path()
        ..moveTo(0, 0)
        ..lineTo(w, 0)
        ..lineTo(w, h * 0.44)
        ..quadraticBezierTo(w * 0.5, h * 0.51, 0, h * 0.44)
        ..close();

      final shadowPath = Path()
        ..moveTo(0, h * 0.44 + 8)
        ..quadraticBezierTo(w * 0.5, h * 0.51 + 8, w, h * 0.44 + 8);
      canvas.drawPath(
        shadowPath,
        Paint()
          ..color = const Color(0xFF13052C).withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 20
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      canvas.drawPath(archPath, Paint()..shader = whiteGrad);

      final rimPath = Path()
        ..moveTo(0, h * 0.44)
        ..quadraticBezierTo(w * 0.5, h * 0.51, w, h * 0.44);
      canvas.drawPath(
        rimPath,
        Paint()
          ..color = const Color(0xFFC084FC).withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    } else {
      final archPath = Path()
        ..moveTo(0, h * 0.43)
        ..quadraticBezierTo(w * 0.5, h * 0.36, w, h * 0.43)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();

      final shadowPath = Path()
        ..moveTo(0, h * 0.43 - 8)
        ..quadraticBezierTo(w * 0.5, h * 0.36 - 8, w, h * 0.43 - 8);
      canvas.drawPath(
        shadowPath,
        Paint()
          ..color = const Color(0xFF13052C).withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 20
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      canvas.drawPath(archPath, Paint()..shader = whiteGrad);

      final rimPath = Path()
        ..moveTo(0, h * 0.43)
        ..quadraticBezierTo(w * 0.5, h * 0.36, w, h * 0.43);
      canvas.drawPath(
        rimPath,
        Paint()
          ..color = const Color(0xFFC084FC).withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidArchPainter oldDelegate) =>
      oldDelegate.slideIndex != slideIndex;
}

class _Slide1IllustrationPainter extends CustomPainter {

  @override

  void paint(Canvas canvas, Size size) {

    final cx = size.width * 0.5;

    final cy = size.height * 0.65;



    // Soft Floor Platform Ellipse

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



    // Avatar circle and dots on laptop

    canvas.drawCircle(Offset(cx - 20, cy - 135), 9, Paint()..color = Colors.white);

    canvas.drawRRect(

      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - 20, cy - 105), width: 44, height: 7), const Radius.circular(3.5)),

      Paint()..color = Colors.white.withValues(alpha: 0.9),

    );



    // Laptop Keyboard Deck

    final keyboardDeck = Path()

      ..moveTo(cx - 75, cy - 50)

      ..lineTo(cx + 30, cy - 90)

      ..lineTo(cx + 85, cy - 60)

      ..lineTo(cx - 20, cy - 20)

      ..close();

    canvas.drawPath(keyboardDeck, Paint()..color = const Color(0xFF334155));



    // Floating Purple Shield with Keyhole

    final shieldCenter = Offset(cx + 35, cy - 95);

    final shieldPath = Path()

      ..moveTo(shieldCenter.dx, shieldCenter.dy - 40)

      ..lineTo(shieldCenter.dx + 28, shieldCenter.dy - 25)

      ..lineTo(shieldCenter.dx + 28, shieldCenter.dy + 8)

      ..cubicTo(shieldCenter.dx + 28, shieldCenter.dy + 32, shieldCenter.dx, shieldCenter.dy + 48, shieldCenter.dx, shieldCenter.dy + 48)

      ..cubicTo(shieldCenter.dx, shieldCenter.dy + 48, shieldCenter.dx - 28, shieldCenter.dy + 32, shieldCenter.dx - 28, shieldCenter.dy + 8)

      ..lineTo(shieldCenter.dx - 28, shieldCenter.dy - 25)

      ..close();



    canvas.drawPath(

      shieldPath,

      Paint()

        ..shader = const LinearGradient(

          colors: [Color(0xFF9333EA), Color(0xFF5B21B6)],

        ).createShader(Rect.fromLTWH(shieldCenter.dx - 28, shieldCenter.dy - 40, 56, 88)),

    );



    // Shield Keyhole

    canvas.drawCircle(Offset(shieldCenter.dx, shieldCenter.dy - 4), 6, Paint()..color = const Color(0xFF1E1B4B));

    final keyStem = Path()

      ..moveTo(shieldCenter.dx - 4, shieldCenter.dy - 1)

      ..lineTo(shieldCenter.dx + 4, shieldCenter.dy - 1)

      ..lineTo(shieldCenter.dx + 5, shieldCenter.dy + 14)

      ..lineTo(shieldCenter.dx - 5, shieldCenter.dy + 14)

      ..close();

    canvas.drawPath(keyStem, Paint()..color = const Color(0xFF1E1B4B));



    // Character standing next to shield

    final charX = cx + 80;

    final charY = cy - 65;

    canvas.drawCircle(Offset(charX, charY - 26), 7, Paint()..color = const Color(0xFFFDE68A));

    canvas.drawRect(Rect.fromLTWH(charX - 7, charY - 14, 14, 28), Paint()..color = const Color(0xFF7C3AED));

    canvas.drawLine(Offset(charX - 3, charY + 14), Offset(charX - 3, charY + 45), Paint()..color = const Color(0xFF1E293B)..strokeWidth = 4.5);

    canvas.drawLine(Offset(charX + 4, charY + 14), Offset(charX + 4, charY + 45), Paint()..color = const Color(0xFF334155)..strokeWidth = 4.5);



    // Foreground Purple Key

    final keyPaint = Paint()..color = const Color(0xFF7C3AED)..strokeWidth = 4.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(cx - 50, cy - 5), 8, keyPaint);

    canvas.drawLine(Offset(cx - 42, cy - 5), Offset(cx - 15, cy - 5), keyPaint);

    canvas.drawLine(Offset(cx - 24, cy - 5), Offset(cx - 24, cy + 3), keyPaint);

  }



  @override

  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

}



/// Slide 2 Illustration: Person Cross-Legged with Laptop & Launching Rocket

class _Slide2IllustrationPainter extends CustomPainter {

  @override

  void paint(Canvas canvas, Size size) {

    final cx = size.width * 0.5;

    final cy = size.height * 0.65;



    // Floor shadow

    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 10), width: 190, height: 26), Paint()..color = const Color(0xFFF1F5F9));



    // Launching Rocket on upper right

    final rocketCenter = Offset(cx + 60, cy - 140);

    final rocketBody = Path()

      ..moveTo(rocketCenter.dx, rocketCenter.dy - 20)

      ..quadraticBezierTo(rocketCenter.dx + 12, rocketCenter.dy, rocketCenter.dx + 12, rocketCenter.dy + 20)

      ..lineTo(rocketCenter.dx - 12, rocketCenter.dy + 20)

      ..quadraticBezierTo(rocketCenter.dx - 12, rocketCenter.dy, rocketCenter.dx, rocketCenter.dy - 20)

      ..close();

    canvas.drawPath(rocketBody, Paint()..color = const Color(0xFF1E293B));

    canvas.drawCircle(Offset(rocketCenter.dx, rocketCenter.dy), 4, Paint()..color = const Color(0xFFA855F7));

    // Rocket flame

    canvas.drawPath(

      Path()

        ..moveTo(rocketCenter.dx - 5, rocketCenter.dy + 20)

        ..lineTo(rocketCenter.dx, rocketCenter.dy + 30)

        ..lineTo(rocketCenter.dx + 5, rocketCenter.dy + 20)

        ..close(),

      Paint()..color = const Color(0xFFC084FC),

    );



    // Character sitting cross-legged with laptop

    final charCenter = Offset(cx, cy - 40);

    // Head

    canvas.drawCircle(Offset(charCenter.dx, charCenter.dy - 45), 11, Paint()..color = const Color(0xFFFDE68A));

    canvas.drawCircle(Offset(charCenter.dx, charCenter.dy - 50), 12, Paint()..color = const Color(0xFF1E293B));

    // Dotted sweater

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(charCenter.dx, charCenter.dy - 15), width: 34, height: 38), const Radius.circular(8)), Paint()..color = const Color(0xFF1E1B4B));

    // Crossed legs

    canvas.drawOval(Rect.fromCenter(center: Offset(charCenter.dx, charCenter.dy + 12), width: 70, height: 22), Paint()..color = const Color(0xFF1E293B));



    // Laptop on lap

    canvas.drawRRect(

      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(charCenter.dx, charCenter.dy - 2), width: 38, height: 24), const Radius.circular(3)),

      Paint()..color = const Color(0xFF9333EA),

    );

    canvas.drawCircle(Offset(charCenter.dx, charCenter.dy - 2), 3, Paint()..color = Colors.white);

  }



  @override

  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

}



/// Slide 3 Illustration: Giant Security Shield with Glowing Checkmark & Collaboration

class _Slide3IllustrationPainter extends CustomPainter {

  @override

  void paint(Canvas canvas, Size size) {

    final cx = size.width * 0.5;

    final cy = size.height * 0.60;



    // Monitor behind shield

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy - 40), width: 170, height: 110), const Radius.circular(8)), Paint()..color = const Color(0xFF1E1B4B));

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy - 40), width: 154, height: 94), const Radius.circular(4)), Paint()..color = const Color(0xFF7C3AED));



    // Giant Security Shield with Checkmark in foreground

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



    // Glowing Checkmark Circle inside Shield

    canvas.drawCircle(Offset(cx, cy - 22), 22, Paint()..color = const Color(0xFF7C3AED));

    canvas.drawCircle(Offset(cx, cy - 22), 22, Paint()..color = const Color(0xFFC084FC)..style = PaintingStyle.stroke..strokeWidth = 2);



    final checkPath = Path()

      ..moveTo(cx - 10, cy - 22)

      ..lineTo(cx - 3, cy - 15)

      ..lineTo(cx + 12, cy - 30);

    canvas.drawPath(checkPath, Paint()..color = Colors.white..strokeWidth = 4.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);

  }



  @override

  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

}

