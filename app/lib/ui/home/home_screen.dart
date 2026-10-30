import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';
import '../../core/core_controller.dart';
import '../../core/app_preferences.dart';
import '../components/signin_dialog.dart';
import '../components/top_dock_toast.dart';
import '../countries/country_manager.dart';
import '../components/details_sheet.dart';
import 'world_map_atmosphere.dart';
import 'vpn_status_view.dart';
import 'vpn_connection_card.dart';
import 'recents_list.dart';
import 'default_connection_sheet.dart';

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
        final isConnected = controller.isConnected;
        final isConnecting = controller.isConnecting;
        final isVpnOn = controller.isVpnOn;
        final proxy = status?.proxy;

        final isFastestMode = AppPreferences.defaultConnectionType == 'fastest' || AppPreferences.selectedLocation.toLowerCase() == 'fastest';
        final countryCode = (!isConnected && !isConnecting && isFastestMode) ? 'fastest' : (proxy?.countryCode ?? AppPreferences.selectedLocation);
        final countryName = (!isConnected && !isConnecting && isFastestMode) ? 'Fastest country' : (proxy?.countryName ?? 'Netherlands');
        final cityName = (!isConnected && !isConnecting && isFastestMode) ? 'Auto-Routing (lowest latency)' : (proxy?.cityName ?? 'Amsterdam #12');

        // Dynamic 3 recent servers from live Fastly countries
        final dynamicCountries = CountryManager.instance.countries;
        final nl = dynamicCountries.firstWhere(
          (c) => c.code == 'NL',
          orElse: () => DynamicCountry(code: 'NL', name: 'Netherlands', cities: 'Amsterdam #12', load: 32, pingMs: 18),
        );
        final de = dynamicCountries.firstWhere(
          (c) => c.code == 'DE',
          orElse: () => DynamicCountry(code: 'DE', name: 'Germany', cities: 'Frankfurt #8', load: 54, pingMs: 24),
        );
        final us = dynamicCountries.firstWhere(
          (c) => c.code == 'US',
          orElse: () => DynamicCountry(code: 'US', name: 'United States', cities: 'New York #102', load: 68, pingMs: 82),
        );

        final recentItems = [nl, de, us].map((item) {
          return RecentServerItem(
            code: item.code,
            name: item.name,
            city: item.cities.split(',').first,
            latencyMs: item.pingMs,
            load: item.load,
          );
        }).toList();

        final textPrimary = ThemeManager.instance.textPrimaryColor;
        final textSecondary = ThemeManager.instance.textSecondaryColor;

        return Scaffold(
          backgroundColor: Colors.transparent,
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
                    // Top App Bar matching photo_1 & photo_12
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6B42FF),
                                  borderRadius: BorderRadius.circular(11),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6B42FF).withValues(alpha: 0.45),
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
                              const SizedBox(width: 12),
                              Text(
                                'TeroVPN',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.info_outline_rounded,
                              color: textSecondary,
                              size: 24,
                            ),
                            tooltip: 'Connection Details',
                            onPressed: () => DetailsSheet.show(context, status: status),
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
                            const SizedBox(height: 24),
                            // Default connection selector matching video_20261030_222613.mp4
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: InkWell(
                                  onTap: () => DefaultConnectionSheet.show(
                                    context,
                                    controller: controller,
                                    onSelected: (_) {},
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Default connection',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: textSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(Icons.arrow_drop_down_rounded, size: 20, color: textSecondary),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
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
                                  if (AppPreferences.defaultConnectionType == 'fastest' || AppPreferences.selectedLocation.toLowerCase() == 'fastest') {
                                    final fastest = CountryManager.instance.getFastestCountry();
                                    await controller.setLocation(fastest.code.toLowerCase());
                                    await AppPreferences.setSelectedLocation(fastest.code);
                                    controller.setOn(true);
                                    if (context.mounted) {
                                      TopDockToast.show(
                                        context,
                                        title: 'Connecting to Fastest Country',
                                        message: '${fastest.name} · ${fastest.pingMs} ms (Load: ${fastest.load}%)',
                                        icon: Icons.bolt_rounded,
                                        iconColor: const Color(0xFF00E676),
                                      );
                                    }
                                  } else {
                                    await controller.setLocation(countryCode.toLowerCase());
                                    controller.setOn(true);
                                  }
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
