import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
import '../../theme/theme_manager.dart';
import '../../core/core_controller.dart';
import '../../core/models.dart';
import '../../core/app_preferences.dart';
import '../components/signin_dialog.dart';
import '../countries/country_data.dart';
import '../countries/country_manager.dart';
import '../components/details_sheet.dart';
import 'world_map_atmosphere.dart';
import 'vpn_status_view.dart';
import 'vpn_connection_card.dart';
import 'recents_list.dart';

class HomeScreen extends StatelessWidget {
  final CoreController controller;
  final VoidCallback onNavigateToCountries;

  const HomeScreen({
    super.key,
    required this.controller,
    required this.onNavigateToCountries,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, ThemeManager.instance]),
      builder: (context, _) {
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

        final recentCodes = AppPreferences.recentLocations;
        final recentItems = recentCodes.map((code) {
          final item = kFastlyCountries.firstWhere(
            (c) => c.code.toUpperCase() == code.toUpperCase(),
            orElse: () => CountryItem(code: code, name: code, cities: 'Edge', load: 30, pingMs: 25),
          );
          return RecentServerItem(
            code: item.code,
            name: item.name,
            city: item.cities.split(',').first,
            latencyMs: item.pingMs,
            load: item.load,
          );
        }).toList();

        final isLiquid = ThemeManager.instance.isLiquidGlass;

        return Scaffold(
          backgroundColor: isLiquid ? const Color(0xFF0D0C15) : ProtonColors.background,
          body: Stack(
            children: [
              WorldMapAtmosphere(
                isConnected: isConnected,
                isConnecting: isConnecting,
              ),

              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Top App Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: ProtonColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6D4AFF).withValues(alpha: 0.4),
                                      blurRadius: 8,
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
                              Text(
                                'TeroVPN',
                                style: ProtonTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              if (!isLiquid) ...[
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isConnected
                                        ? ProtonColors.connected.withValues(alpha: 0.15)
                                        : (isConnecting
                                            ? ProtonColors.connecting.withValues(alpha: 0.15)
                                            : ProtonColors.surfaceDark),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isConnected
                                          ? ProtonColors.connected.withValues(alpha: 0.4)
                                          : (isConnecting
                                              ? ProtonColors.connecting.withValues(alpha: 0.4)
                                              : ProtonColors.cardBorder),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isConnected
                                            ? Icons.lock_rounded
                                            : (isConnecting ? Icons.sync_rounded : Icons.lock_open_rounded),
                                        color: isConnected
                                            ? ProtonColors.connected
                                            : (isConnecting ? ProtonColors.connecting : ProtonColors.textMuted),
                                        size: 15,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        isConnected
                                            ? 'LOCKED'
                                            : (isConnecting ? 'TUNNELING' : 'UNLOCKED'),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                          color: isConnected
                                              ? ProtonColors.connected
                                              : (isConnecting ? ProtonColors.connecting : ProtonColors.textMuted),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              IconButton(
                                icon: Icon(
                                  Icons.info_outline_rounded,
                                  color: isLiquid ? const Color(0xFF8F8C9E) : ProtonColors.textSecondary,
                                  size: 24,
                                ),
                                tooltip: 'Connection Details',
                                onPressed: () => DetailsSheet.show(context, status: status),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Scrollable Content
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: 16,
                          bottom: 120, // Space for bottom dock
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            VpnStatusView(
                              isConnected: isConnected,
                              isConnecting: isConnecting,
                              exitCountry: proxy?.countryName,
                            ),
                            const SizedBox(height: 32),
                            VpnConnectionCard(
                              countryCode: countryCode,
                              countryName: countryName,
                              cityName: cityName,
                              isConnected: isConnected,
                              isConnecting: isConnecting,
                              isVpnOn: isVpnOn,
                              onToggle: () async {
                                if (isVpnOn || isConnected || isConnecting) {
                                  controller.setOn(false);
                                } else {
                                  if (!controller.hasAccount) {
                                    SignInDialog.show(context, controller);
                                    return;
                                  }
                                  // Connect to the fastest available server in real-time
                                  final fastest = CountryManager.instance.getFastestCountry();
                                  await controller.setLocation(fastest.code.toLowerCase());
                                  await AppPreferences.setSelectedLocation(fastest.code);
                                  controller.setOn(true);
                                }
                              },
                              onChangeServer: onNavigateToCountries,
                            ),
                            const SizedBox(height: 28),
                            RecentsList(
                              items: recentItems,
                              onSelect: (item) {
                                controller.setLocation(item.code);
                                if (!isVpnOn) {
                                  if (!controller.hasAccount) {
                                    SignInDialog.show(context, controller);
                                    return;
                                  }
                                  controller.setOn(true);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
