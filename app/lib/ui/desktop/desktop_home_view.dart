import 'package:flutter/material.dart';
import '../../core/core_controller.dart';
import '../../core/models.dart';
import '../../core/app_preferences.dart';
import '../components/country_flag.dart';
import '../components/signin_dialog.dart';
import '../components/details_sheet.dart';
import '../countries/country_data.dart';
import '../countries/country_manager.dart';

class DesktopHomeView extends StatelessWidget {
  final CoreController controller;
  final VoidCallback onNavigateToCountries;

  const DesktopHomeView({
    super.key,
    required this.controller,
    required this.onNavigateToCountries,
  });

  @override
  Widget build(BuildContext context) {
    final status = controller.status;
    final phase = status?.state.phase ?? Phase.off;
    final isConnected = phase == Phase.running;
    final isConnecting = phase == Phase.starting || controller.switchingProxy;
    final isVpnOn = controller.isVpnOn || isConnected;

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
        : ['DE', 'US', 'NL', 'DE', 'US'];
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
                color: const Color(0xFF131120).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                  width: 1,
                ),
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
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                (isConnected ? const Color(0xFF2CFFCC) : const Color(0xFFE53950))
                                    .withValues(alpha: 0.16),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        // Padlock Ring Container
                        Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF161426),
                            border: Border.all(
                              color: (isConnected ? const Color(0xFF2CFFCC) : const Color(0xFFE53950))
                                  .withValues(alpha: 0.65),
                              width: 2.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isConnected ? const Color(0xFF2CFFCC) : const Color(0xFFE53950))
                                    .withValues(alpha: 0.25),
                                blurRadius: 20,
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
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B42FF)),
                                    ),
                                  )
                                : Icon(
                                    isConnected ? Icons.lock_rounded : Icons.lock_open_rounded,
                                    color: isConnected ? const Color(0xFF2CFFCC) : const Color(0xFFE53950),
                                    size: 38,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Status Label
                  Text(
                    isConnecting
                        ? 'CONNECTING'
                        : (isConnected ? 'CONNECTED' : 'DISCONNECTED'),
                    style: TextStyle(
                      color: isConnecting
                          ? const Color(0xFFFFB800)
                          : (isConnected ? const Color(0xFF2CFFCC) : const Color(0xFFE53950)),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isConnected
                        ? 'Your network traffic is encrypted and private'
                        : 'Your network traffic is unencrypted',
                    style: const TextStyle(
                      color: Color(0xFF8E8B9D),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Quick Connect Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isConnected ? const Color(0xFF221F38) : const Color(0xFF6B42FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: isConnected
                              ? BorderSide(color: Colors.white.withValues(alpha: 0.12))
                              : BorderSide.none,
                        ),
                        shadowColor: const Color(0xFF6B42FF).withValues(alpha: 0.4),
                      ),
                      onPressed: () async {
                        if (isVpnOn || isConnected || isConnecting) {
                          controller.setOn(false);
                        } else {
                          if (!controller.hasAccount) {
                            SignInDialog.show(context, controller);
                            return;
                          }
                          final fastest = CountryManager.instance.getFastestCountry();
                          await controller.setLocation(fastest.code.toLowerCase());
                          await AppPreferences.setSelectedLocation(fastest.code);
                          controller.setOn(true);
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
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
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
                              style: const TextStyle(
                                color: Color(0xFF8E8B9D),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Protocol: ${AppPreferences.selectedProtocol}',
                              style: const TextStyle(
                                color: Color(0xFF8E8B9D),
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
                              color: const Color(0xFF261D4C),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF6B42FF).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.info_outline_rounded, color: Color(0xFF8B6BFF), size: 15),
                                SizedBox(width: 5),
                                Text(
                                  'Details',
                                  style: TextStyle(
                                    color: Color(0xFF8B6BFF),
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
                  // Selected Location Header
                  const Text(
                    'Selected Location',
                    style: TextStyle(
                      color: Color(0xFF9E9BAE),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Selected Location Card
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onNavigateToCountries,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                            CountryFlag(countryCode: matchedCountry.code, width: 34, height: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    countryName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    cityName,
                                    style: const TextStyle(
                                      color: Color(0xFF8E8B9D),
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
                                    color: Color(0xFF2CFFCC),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${matchedCountry.load}% ${matchedCountry.pingMs} ms',
                                  style: const TextStyle(
                                    color: Color(0xFF9E9BAE),
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
                  const Text(
                    'Recents',
                    style: TextStyle(
                      color: Color(0xFF9E9BAE),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Recent Items List
                  ...recentItems.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161426),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                          width: 1,
                        ),
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
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.cities.split(',').first,
                                  style: const TextStyle(
                                    color: Color(0xFF8E8B9D),
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
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2CFFCC),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${item.pingMs} ms',
                                style: const TextStyle(
                                  color: Color(0xFF8E8B9D),
                                  fontSize: 11.5,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () async {
                                    await controller.setLocation(item.code.toLowerCase());
                                    await AppPreferences.setSelectedLocation(item.code);
                                    if (!isVpnOn) {
                                      if (!controller.hasAccount) {
                                        if (context.mounted) {
                                          SignInDialog.show(context, controller);
                                        }
                                        return;
                                      }
                                      controller.setOn(true);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF261D4C),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Connect',
                                      style: TextStyle(
                                        color: Color(0xFF8B6BFF),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
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
  }
}
