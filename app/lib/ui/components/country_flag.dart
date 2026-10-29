import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/proton_colors.dart';

class CountryFlag extends StatelessWidget {
  final String countryCode;
  final double width;
  final double height;
  final double borderRadius;

  const CountryFlag({
    super.key,
    required this.countryCode,
    this.width = 32,
    this.height = 22,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    final code = countryCode.trim().toLowerCase();

    if (code.isEmpty || code == 'fastest' || code == 'any' || code == 'auto') {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: ProtonColors.fastestBolt.withOpacity(0.18),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: ProtonColors.fastestBolt.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.bolt_rounded,
            color: ProtonColors.fastestBolt,
            size: 16,
          ),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SvgPicture.asset(
        'assets/flags/$code.svg',
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => Container(
          color: ProtonColors.surfaceDark,
          alignment: Alignment.center,
          child: Text(
            countryCode.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: ProtonColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
