import 'package:flutter/material.dart';
import '../../core/core_controller.dart';
import '../../core/models.dart';
import '../../core/app_preferences.dart';
import '../../theme/theme_manager.dart';
import '../components/country_flag.dart';
import '../components/signin_dialog.dart';
import '../components/details_sheet.dart';
import '../home/default_connection_sheet.dart';
import '../countries/country_data.dart';
import '../countries/country_manager.dart';

class AnimatedConnectButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isConnected;
  final bool isConnecting;
  final String label;

  const AnimatedConnectButton({
    super.key,
    required this.onTap,
    this.isConnected = false,
    this.isConnecting = false,
    this.label = 'Connect',
  });

  @override
  State<AnimatedConnectButton> createState() => _AnimatedConnectButtonState();
}

class _AnimatedConnectButtonState extends State<AnimatedConnectButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() async {
    await _controller.forward();
    await _controller.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isConn = widget.isConnected;
    final isStarting = widget.isConnecting;
    final isDark = ThemeManager.instance.isDarkMode;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _handleTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: isConn
                  ? const LinearGradient(
                      colors: [Color(0xFF00C896), Color(0xFF00E676)],
                    )
                  : (isStarting
                      ? const LinearGradient(
                          colors: [Color(0xFF7B42FF), Color(0xFFA855F7)],
                        )
                      : LinearGradient(
                          colors: _isHovered
                              ? (isDark
                                  ? [const Color(0xFF3B2E6E), const Color(0xFF4C3691)]
                                  : [const Color(0xFFDDD7F5), const Color(0xFFCEC5F0)])
                              : (isDark
                                  ? [const Color(0xFF261D4C), const Color(0xFF281E48)]
                                  : [const Color(0xFFEDE9F8), const Color(0xFFE8E3F6)]),
                        )),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isConn
                    ? const Color(0xFF00E676)
                    : (_isHovered
                        ? const Color(0xFF8B6BFF)
                        : (isDark ? const Color(0xFF6B42FF).withValues(alpha: 0.45) : const Color(0xFF6B42FF).withValues(alpha: 0.3))),
                width: 1,
              ),
              boxShadow: isConn
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00E676).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : (_isHovered
                      ? [
                          BoxShadow(
                            color: const Color(0xFF6B42FF).withValues(alpha: isDark ? 0.40 : 0.20),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null),
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isStarting) ...[
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Connecting',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ] else if (isConn) ...[
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Connected',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ] else ...[
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: isDark
                            ? (_isHovered ? Colors.white : const Color(0xFF9E85FF))
                            : const Color(0xFF5B34DB),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DesktopHomeView extends StatefulWidget {
  final CoreController controller;
  final VoidCallback onNavigateToCountries;

  const DesktopHomeView({
    super.key,
    required this.controller,
    required this.onNavigateToCountries,
  });

  @override
  State<DesktopHomeView> createState() => _DesktopHomeViewState();
}

class _DesktopHomeViewState extends State<DesktopHomeView> {
  bool _isQuickConnectHovered = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, _) {
        final isDark = ThemeManager.instance.isDarkMode;
        final isLiquid = ThemeManager.instance.isLiquidGlass;

        final status = widget.controller.status;
        final phase = status?.state.phase ?? Phase.off;
        final isConnected = phase == Phase.running;
        final isConnecting = phase == Phase.starting || widget.controller.switchingProxy;
        final isVpnOn = widget.controller.isVpnOn || isConnected;

        final savedCode = AppPreferences.selectedLocation;
        final proxy = status?.proxy;
        final countryCode = proxy?.countryCode.isNotEmpty == true ? proxy!.countryCode : savedCode;
        final matchedCountry = kFastlyCountries.firstWhere(
          (c) => c.code.toUpperCase() == countryCode.toUpperCase(),
          orElse: () => const CountryItem(code: 'NL', name: 'Netherlands', cities: 'Amsterdam', load: 32, pingMs: 18),
        );
        final countryName = proxy?.countryName.isNotEmpty == true
            ? proxy!.countryName
            : (countryCode.toLowerCase() == 'fastest' ? 'Fastest country' : matchedCountry.name);
        final cityName = proxy?.cityName.isNotEmpty == true
            ? proxy!.cityName
            : (countryCode.toLowerCase() == 'fastest' ? 'Auto Anycast Routing' : '${matchedCountry.cities.split(',').first} #1');

        final recentCodes = AppPreferences.recentLocations.isNotEmpty
            ? AppPreferences.recentLocations
            : ['NL', 'DE', 'US'];
        final recentItems = recentCodes.take(5).map((code) {
          final item = kFastlyCountries.firstWhere(
            (c) => c.code.toUpperCase() == code.toUpperCase(),
            orElse: () => CountryItem(code: code, name: code, cities: 'Edge', load: 30, pingMs: 20),
          );
          return item;
        }).toList();

        final currentIp = isConnected
            ? ((status?.exit?.ipv4.isNotEmpty == true)
                ? status!.exit!.ipv4
                : ((status?.exit?.ipv6.isNotEmpty == true) ? status!.exit!.ipv6 : '185.156.73.42'))
            : '103.xxx.xx.xx';

        // Adaptive Light and Dark colors
        final mainCardBg = isDark
            ? (isLiquid
                ? const Color(0xFF131120).withValues(alpha: 0.85)
                : const Color(0xFF171426))
            : (isLiquid
                ? Colors.white.withValues(alpha: 0.88)
                : Colors.white);

        final cardBorder = isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFF5D5380).withValues(alpha: 0.10);

        final textPrimary = isDark ? Colors.white : const Color(0xFF1D1536);
        final textSecondary = isDark ? const Color(0xFF8E8B9D) : const Color(0xFF6E6B80);

        final cardBgSecondary = isDark
            ? const Color(0xFF161426)
            : (isLiquid ? Colors.white.withValues(alpha: 0.90) : const Color(0xFFF9FAFD));

        final ringInnerColor = isDark
            ? const Color(0xFF161426)
            : Colors.white;

        final detailsBtnBg = isDark
            ? const Color(0xFF261D4C)
            : const Color(0xFFEDE9F8);

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Main Section (Status + Padlock + Quick Connect)
              Expanded(
                flex: 11,
                child: Container(
                  decoration: BoxDecoration(
                    color: mainCardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: cardBorder,
                      width: 1,
                    ),
                    boxShadow: isLiquid ? ThemeManager.instance.cardShadow : null,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),

                        // Atmospheric Glow & Padlock Ring
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Soft radial background glow
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOutCubic,
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      (isConnected
                                              ? const Color(0xFF2CFFCC)
                                              : (isConnecting ? const Color(0xFFFFB800) : const Color(0xFFE53950)))
                                          .withValues(alpha: isDark ? 0.18 : 0.14),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              // Padlock Ring Container
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                width: 108,
                                height: 108,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: ringInnerColor,
                                  border: Border.all(
                                    color: (isConnected
                                            ? const Color(0xFF2CFFCC)
                                            : (isConnecting ? const Color(0xFFFFB800) : const Color(0xFFE53950)))
                                        .withValues(alpha: 0.75),
                                    width: 2.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isConnected
                                              ? const Color(0xFF2CFFCC)
                                              : (isConnecting ? const Color(0xFFFFB800) : const Color(0xFFE53950)))
                                          .withValues(alpha: isDark ? 0.28 : 0.18),
                                      blurRadius: 24,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: isConnecting
                                      ? const SizedBox(
                                          width: 32,
                                          height: 32,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFB800)),
                                          ),
                                        )
                                      : Icon(
                                          isConnected ? Icons.lock_rounded : Icons.lock_open_rounded,
                                          size: 40,
                                          color: isConnected ? const Color(0xFF00C896) : const Color(0xFFE53950),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Connection State Label
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: TextStyle(
                            color: isConnecting
                                ? const Color(0xFFFFB800)
                                : (isConnected
                                    ? (isDark ? const Color(0xFF2CFFCC) : const Color(0xFF00A36C))
                                    : const Color(0xFFE53950)),
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                          child: Text(
                            isConnecting
                                ? 'CONNECTING...'
                                : (isConnected ? 'CONNECTED' : 'NOT CONNECTED'),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isConnected
                              ? 'Your network traffic is encrypted and private via Fastly MASQUE'
                              : 'Your network traffic is unencrypted',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Quick Connect Button with Animated Hover & Scale
                        MouseRegion(
                          onEnter: (_) => setState(() => _isQuickConnectHovered = true),
                          onExit: (_) => setState(() => _isQuickConnectHovered = false),
                          cursor: SystemMouseCursors.click,
                          child: AnimatedScale(
                            scale: _isQuickConnectHovered ? 1.02 : 1.0,
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            child: SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isConnected
                                      ? (isDark ? const Color(0xFF221F38) : const Color(0xFFF1EEF9))
                                      : const Color(0xFF6B42FF),
                                  foregroundColor: isConnected
                                      ? (isDark ? Colors.white : const Color(0xFF1D1536))
                                      : Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: isConnected
                                        ? BorderSide(
                                            color: isDark
                                                ? Colors.white.withValues(alpha: 0.12)
                                                : const Color(0xFF5D5380).withValues(alpha: 0.15),
                                          )
                                        : BorderSide.none,
                                  ),
                                  shadowColor: const Color(0xFF6B42FF).withValues(alpha: 0.4),
                                ),
                                onPressed: () async {
                                  if (isVpnOn || isConnected || isConnecting) {
                                    widget.controller.setOn(false);
                                  } else {
                                    if (!widget.controller.hasAccount) {
                                      SignInDialog.show(context, widget.controller);
                                      return;
                                    }
                                    final fastest = CountryManager.instance.getFastestCountry();
                                    await widget.controller.setLocation(fastest.code.toLowerCase());
                                    await AppPreferences.setSelectedLocation(fastest.code);
                                    widget.controller.setOn(true);
                                  }
                                },
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isConnected ? Icons.power_settings_new_rounded : Icons.bolt_rounded,
                                        size: 20,
                                        color: isConnected ? const Color(0xFFE53950) : Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isConnected ? 'Disconnect' : 'Quick Connect',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.2,
                                          color: isConnected
                                              ? (isDark ? Colors.white : const Color(0xFF1D1536))
                                              : Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Bottom Metadata & Details trigger
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current IP: $currentIp',
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Protocol: ${AppPreferences.selectedProtocol}',
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => DetailsSheet.show(context, status: status),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: detailsBtnBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF6B42FF).withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        color: isDark ? const Color(0xFF8B6BFF) : const Color(0xFF5B34DB),
                                        size: 15,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Details',
                                        style: TextStyle(
                                          color: isDark ? const Color(0xFF8B6BFF) : const Color(0xFF5B34DB),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 18),

              // Right Panel (Selected Location & Recents)
              SizedBox(
                width: 320,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selected Location Header with Default Connection Changer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Selected Location',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                DefaultConnectionSheet.show(
                                  context,
                                  controller: widget.controller,
                                  onSelected: (code) async {
                                    await widget.controller.setLocation(code.toLowerCase());
                                    await AppPreferences.setSelectedLocation(code);
                                  },
                                );
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Text(
                                  'Change Default',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF8B6BFF) : const Color(0xFF5B34DB),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Selected Location Card
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.onNavigateToCountries,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: cardBgSecondary,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: cardBorder,
                                width: 1,
                              ),
                              boxShadow: isLiquid ? ThemeManager.instance.cardShadow : null,
                            ),
                            child: Row(
                              children: [
                                CountryFlag(countryCode: matchedCountry.code, width: 34, height: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        countryName,
                                        style: TextStyle(
                                          color: textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        cityName,
                                        style: TextStyle(
                                          color: textSecondary,
                                          fontSize: 11.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF00C896),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${matchedCountry.load}% ${matchedCountry.pingMs} ms',
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Recents Header
                      Text(
                        'Recents',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Recent Items List with AnimatedConnectButton
                      ...recentItems.map((item) {
                        final isThisActive = countryCode.toUpperCase() == item.code.toUpperCase();
                        final isThisConnected = isThisActive && isConnected;
                        final isThisConnecting = isThisActive && isConnecting;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: cardBgSecondary,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isThisConnected
                                  ? const Color(0xFF00E676).withValues(alpha: 0.5)
                                  : (isThisConnecting
                                      ? const Color(0xFFFFB800).withValues(alpha: 0.5)
                                      : cardBorder),
                              width: 1,
                            ),
                            boxShadow: isLiquid ? ThemeManager.instance.cardShadow : null,
                          ),
                          child: Row(
                            children: [
                              CountryFlag(countryCode: item.code, width: 32, height: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.cities.split(',').first,
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: isThisConnected
                                          ? const Color(0xFF00E676)
                                          : (isThisConnecting ? const Color(0xFFFFB800) : const Color(0xFF00C896)),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${item.pingMs} ms',
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Interactive Animated Connect Button
                                  AnimatedConnectButton(
                                    isConnected: isThisConnected,
                                    isConnecting: isThisConnecting,
                                    onTap: () async {
                                      await widget.controller.setLocation(item.code.toLowerCase());
                                      await AppPreferences.setSelectedLocation(item.code);
                                      if (!isVpnOn) {
                                        if (!widget.controller.hasAccount) {
                                          if (context.mounted) {
                                            SignInDialog.show(context, widget.controller);
                                          }
                                          return;
                                        }
                                        widget.controller.setOn(true);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
