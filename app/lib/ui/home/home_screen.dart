import 'package:flutter/material.dart';
import '../../theme/proton_colors.dart';
import '../../theme/proton_typography.dart';
import '../../core/core_controller.dart';
import '../../core/models.dart';
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
      listenable: controller,
      builder: (context, _) {
        final status = controller.status;
        final phase = status?.state.phase ?? Phase.off;
        final isConnected = phase == Phase.running;
        final isConnecting = phase == Phase.starting || controller.switchingProxy;

        final proxy = status?.proxy;
        final countryCode = proxy?.countryCode ?? 'NL';
        final countryName = proxy?.countryName.isNotEmpty == true
            ? proxy!.countryName
            : 'Netherlands';
        final cityName = proxy?.cityName.isNotEmpty == true
            ? proxy!.cityName
            : 'Amsterdam #12';

        return Scaffold(
          backgroundColor: ProtonColors.background,
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
                                      color: ProtonColors.primary.withOpacity(0.4),
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
                          IconButton(
                            icon: const Icon(
                              Icons.info_outline_rounded,
                              color: ProtonColors.textSecondary,
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
                            const SizedBox(height: 32),
                            VpnConnectionCard(
                              countryCode: countryCode,
                              countryName: countryName,
                              cityName: cityName,
                              isConnected: isConnected,
                              isConnecting: isConnecting,
                              onToggle: () {
                                if (isConnected || isConnecting) {
                                  controller.setOn(false);
                                } else {
                                  controller.setOn(true);
                                }
                              },
                              onChangeServer: onNavigateToCountries,
                            ),
                            const SizedBox(height: 28),
                            RecentsList(
                              items: const [
                                RecentServerItem(
                                  code: 'NL',
                                  name: 'Netherlands',
                                  city: 'Amsterdam #12',
                                  latencyMs: 18,
                                  load: 32,
                                ),
                                RecentServerItem(
                                  code: 'DE',
                                  name: 'Germany',
                                  city: 'Frankfurt #8',
                                  latencyMs: 24,
                                  load: 54,
                                ),
                                RecentServerItem(
                                  code: 'US',
                                  name: 'United States',
                                  city: 'New York #102',
                                  latencyMs: 82,
                                  load: 68,
                                ),
                              ],
                              onSelect: (item) {
                                controller.setLocation(item.code);
                                if (!isConnected) {
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
