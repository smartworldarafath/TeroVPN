import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/android_core.dart';
import '../../core/app_preferences.dart';
import '../../core/core_controller.dart';
import '../../theme/theme_manager.dart';
import '../components/details_sheet.dart';
import '../components/signin_dialog.dart';
import '../components/top_dock_toast.dart';
import '../countries/country_manager.dart';
import '../settings/permissions_screen.dart';
import 'default_connection_sheet.dart';
import 'proton_world_map.dart';
import 'recents_list.dart';
import 'vpn_connection_card.dart';
import 'world_map_atmosphere.dart';
import '../../core/app_permissions_service.dart';
import '../permissions/permissions_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  final CoreController controller;
  final VoidCallback onNavigateToCountries;

  const HomeScreen({
    super.key,
    required this.controller,
    required this.onNavigateToCountries,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _missingVpn = false;
  bool _missingNotif = false;
  Timer? _periodicCheckTimer;
  String? _lastShownConnectError;

  void _onControllerChanged() {
    final err = widget.controller.lastConnectError;
    if (err != null && err.isNotEmpty && err != _lastShownConnectError && mounted) {
      _lastShownConnectError = err;
      TopDockToast.show(
        context,
        title: 'Connection Notice',
        message: err,
        icon: Icons.wifi_tethering_error_rounded,
        iconColor: const Color(0xFFF59E0B),
      );
    } else if (err == null) {
      _lastShownConnectError = null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_onControllerChanged);
    _checkPermissions();

    // Immediately trigger background real-time internet loading speed probe
    // so Quick Connect and Profiles have the fastest country ready within 1 second.
    unawaited(CountryManager.instance.probeRealtimeSpeeds());

    // Periodically check permissions every 2.5 minutes for existing installs
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 150), (_) {
      _checkPermissions(isPeriodic: true);
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    WidgetsBinding.instance.removeObserver(this);
    _periodicCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
      unawaited(CountryManager.instance.probeRealtimeSpeeds());
    }
  }

  Future<void> _checkPermissions({bool isPeriodic = false}) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final perms = await AndroidCore.checkPermissions();
      final vpnMissing = perms['vpn'] != true;
      final notifMissing = perms['notifications'] != true;

      if (mounted) {
        setState(() {
          _missingVpn = vpnMissing;
          _missingNotif = notifMissing;
        });

        // If periodic and VPN permission is still missing, remind user
        if (isPeriodic && vpnMissing && !widget.controller.isConnected) {
          final now = DateTime.now().millisecondsSinceEpoch;
          if (now - AppPreferences.lastPermissionPromptTime > 120000) {
            AppPreferences.setLastPermissionPromptTime(now);
            TopDockToast.show(
              context,
              title: 'Permission Notice',
              message:
                  'TeroVPN needs VPN Configuration permission to protect your network traffic.',
              icon: Icons.shield_outlined,
              iconColor: const Color(0xFFEF4444),
            );
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _handleConnectToggle({
    required bool isVpnOn,
    required bool isConnected,
    required bool isConnecting,
    required String countryCode,
    bool isQuickConnectButton = false,
  }) async {
    if (isVpnOn || isConnected || isConnecting) {
      await widget.controller.setOn(false);
      return;
    }

    if (!widget.controller.hasAccount) {
      if (mounted) SignInDialog.show(context, widget.controller);
      return;
    }

    // Mandatory VPN permission check before connecting on Android
    if (!kIsWeb && Platform.isAndroid) {
      final granted = await AndroidCore.ensureMandatoryVpnPermission();
      await _checkPermissions();
      if (!granted) {
        if (mounted) {
          TopDockToast.show(
            context,
            title: 'Permission Required',
            message:
                'VPN connection cannot start without system permission. Please allow VPN configuration.',
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFEF4444),
          );
        }
        return;
      }
    } else if (!kIsWeb && Platform.isWindows) {
      if (!AppPermissionsService.instance.areCorePermissionsGranted) {
        await PermissionsSetupScreen.showAsModal(context);
        if (!AppPermissionsService.instance.areCorePermissionsGranted) {
          return;
        }
      }
    }

    try {
      final bool useRealtimeFastest =
          isQuickConnectButton &&
              (AppPreferences.defaultConnectionType == 'fastest' ||
                  countryCode.toLowerCase() == 'fastest') ||
          countryCode.toLowerCase() == 'fastest';

      if (useRealtimeFastest) {
        final fastest = CountryManager.instance.getRealtimeFastestCountry();
        await AppPreferences.setSelectedLocation(fastest.code);
        await AppPreferences.setLastConnection(fastest.code);
        await AppPreferences.addRecentLocation(fastest.code);
        await widget.controller.connectToLocation(fastest.code.toLowerCase());
        if (mounted) {
          setState(() {});
          TopDockToast.show(
            context,
            title: 'Quick Connect: ${fastest.name}',
            message:
                'Real-time fastest speed · ${fastest.realtimeSpeedMbps.toStringAsFixed(0)} Mbps',
            icon: Icons.bolt_rounded,
            iconColor: const Color(0xFF00E676),
          );
        }
      } else {
        final resolved = CountryManager.instance.getCountryByCode(countryCode);
        await AppPreferences.setSelectedLocation(resolved.code);
        await AppPreferences.setLastConnection(resolved.code);
        await AppPreferences.addRecentLocation(resolved.code);
        await widget.controller.connectToLocation(resolved.code.toLowerCase());
        if (mounted) {
          setState(() {});
        }
      }
    } on VpnNotAllowed {
      await _checkPermissions();
      if (mounted) {
        TopDockToast.show(
          context,
          title: 'Permission Denied',
          message:
              'Android denied VPN configuration. Please grant VPN permission to connect.',
          icon: Icons.error_outline_rounded,
          iconColor: const Color(0xFFEF4444),
        );
      }
    } catch (e) {
      if (mounted) {
        TopDockToast.show(
          context,
          title: 'Connection Error',
          message: '$e',
          icon: Icons.error_outline_rounded,
          iconColor: const Color(0xFFEF4444),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.controller,
        ThemeManager.instance,
        CountryManager.instance,
      ]),
      builder: (builderContext, _) {
        final status = widget.controller.status;
        final isConnected = widget.controller.isConnected;
        final isConnecting = widget.controller.isConnecting;
        final isVpnOn = widget.controller.isVpnOn;
        final proxy = status?.proxy;

        final isFastestMode =
            AppPreferences.defaultConnectionType == 'fastest' &&
            AppPreferences.selectedLocation.toLowerCase() == 'fastest';

        // Resolve active or selected country accurately from CountryManager (Bug 9 fix)
        final String rawSelectedCode = (isConnected || isConnecting)
            ? ((proxy?.countryCode.isNotEmpty == true)
                  ? proxy!.countryCode
                  : AppPreferences.selectedLocation)
            : (isFastestMode ? 'fastest' : AppPreferences.selectedLocation);

        final DynamicCountry resolvedCountry =
            rawSelectedCode.toLowerCase() == 'fastest'
            ? CountryManager.instance.getRealtimeFastestCountry()
            : CountryManager.instance.getCountryByCode(rawSelectedCode);

        final String countryCode =
            (!isConnected && !isConnecting && isFastestMode)
            ? 'fastest'
            : resolvedCountry.code;
        final String countryName =
            (!isConnected && !isConnecting && isFastestMode)
            ? 'Fastest country'
            : resolvedCountry.name;
        final String cityName =
            (!isConnected && !isConnecting && isFastestMode)
            ? 'Real-time fastest (${resolvedCountry.name} · ${resolvedCountry.realtimeSpeedMbps.toStringAsFixed(0)} Mbps)'
            : resolvedCountry.primaryCity;

        // Build recent servers list from real user connection history (max 5, empty on fresh install)
        final recentCodes = AppPreferences.recentLocations;
        final recentItems = recentCodes.map((code) {
          final item = CountryManager.instance.getCountryByCode(code);
          return RecentServerItem(
            code: item.code,
            name: item.name,
            city: item.primaryCity,
            latencyMs: item.pingMs,
            load: item.load,
          );
        }).toList();

        final textPrimary = ThemeManager.instance.textPrimaryColor;
        final textSecondary = ThemeManager.instance.textSecondaryColor;
        final isDark = ThemeManager.instance.isDarkMode;

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
                    // Top Bar: App icon & 'TeroVPN' title removed per Bug 10; keep info button on right
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 16,
                        top: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.info_outline_rounded,
                              color: textSecondary,
                              size: 22,
                            ),
                            tooltip: 'Connection Details',
                            onPressed: () =>
                                DetailsSheet.show(context, status: status),
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
                          top: 4,
                          bottom: 120, // Space for bottom dock
                        ),
                        child: Column(
                          children: [
                            // Missing Permissions Warning Banner
                            if (_missingVpn || _missingNotif)
                              GestureDetector(
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PermissionsScreen(
                                        controller: widget.controller,
                                      ),
                                    ),
                                  );
                                  _checkPermissions();
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (_missingVpn
                                                ? const Color(0xFFEF4444)
                                                : const Color(0xFFF59E0B))
                                            .withValues(
                                              alpha: isDark ? 0.16 : 0.08,
                                            ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color:
                                          (_missingVpn
                                                  ? const Color(0xFFEF4444)
                                                  : const Color(0xFFF59E0B))
                                              .withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _missingVpn
                                            ? Icons.warning_amber_rounded
                                            : Icons.notifications_none_rounded,
                                        color: _missingVpn
                                            ? const Color(0xFFEF4444)
                                            : const Color(0xFFF59E0B),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _missingVpn
                                                  ? 'VPN Permission Required'
                                                  : 'Notification Access Pending',
                                              style: TextStyle(
                                                color: textPrimary,
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _missingVpn
                                                  ? 'Tap to allow VPN configuration before connecting.'
                                                  : 'Tap to enable background connection status.',
                                              style: TextStyle(
                                                color: textSecondary,
                                                fontSize: 11.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _missingVpn
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFFF59E0B),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Text(
                                          'Grant',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // ProtonVPN-Style Interactive Animated World Map (Bug 6)
                            ProtonWorldMap(
                              isConnected: isConnected,
                              isConnecting: isConnecting,
                              originCountryCode: 'BD',
                              destinationCountryCode: resolvedCountry.code,
                              destinationCountryName: resolvedCountry.name,
                              destinationCityName: resolvedCountry.primaryCity,
                              clientIp: widget.controller.lastTest?.exitIp,
                            ),
                            const SizedBox(height: 20),

                            // "Browsing safely from" when connected, or "Default connection" selector when disconnected
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                                bottom: 8,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: isConnected
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 4,
                                        ),
                                        child: Text(
                                          'Browsing safely from',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: textSecondary,
                                          ),
                                        ),
                                      )
                                    : InkWell(
                                        onTap: () =>
                                            DefaultConnectionSheet.show(
                                              context,
                                              controller: widget.controller,
                                              onSelected: (_) {
                                                if (mounted) setState(() {});
                                              },
                                            ),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 4,
                                          ),
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
                                              Icon(
                                                Icons.arrow_drop_down_rounded,
                                                size: 20,
                                                color: textSecondary,
                                              ),
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
                              onToggle: () => _handleConnectToggle(
                                isVpnOn: isVpnOn,
                                isConnected: isConnected,
                                isConnecting: isConnecting,
                                countryCode: countryCode,
                                isQuickConnectButton: true,
                              ),
                              onChangeServer: widget.onNavigateToCountries,
                            ),
                            const SizedBox(height: 24),

                            RecentsList(
                              items: recentItems,
                              onSelect: (item) async {
                                await AppPreferences.setDefaultConnectionType(
                                  item.code,
                                );
                                await AppPreferences.setSelectedLocation(
                                  item.code,
                                );
                                await AppPreferences.addRecentLocation(
                                  item.code,
                                );
                                if (!mounted) return;
                                if (!widget.controller.hasAccount) {
                                  if (builderContext.mounted) {
                                    SignInDialog.show(
                                      builderContext,
                                      widget.controller,
                                    );
                                  }
                                  return;
                                }
                                if (!kIsWeb && Platform.isAndroid) {
                                  final granted = await AndroidCore.ensureMandatoryVpnPermission();
                                  await _checkPermissions();
                                  if (!granted) {
                                    if (builderContext.mounted) {
                                      TopDockToast.show(
                                        builderContext,
                                        title: 'Permission Required',
                                        message: 'Please allow VPN configuration to connect.',
                                        icon: Icons.warning_amber_rounded,
                                        iconColor: const Color(0xFFEF4444),
                                      );
                                    }
                                    return;
                                  }
                                }
                                try {
                                  await widget.controller.connectToLocation(
                                    item.code.toLowerCase(),
                                  );
                                  if (mounted) {
                                    setState(() {});
                                  }
                                  if (builderContext.mounted) {
                                    TopDockToast.show(
                                      builderContext,
                                      title: 'Connecting to ${item.name}',
                                      message: '${item.latencyMs} ms · Load: ${item.load}%',
                                      icon: Icons.location_on_rounded,
                                    );
                                  }
                                } catch (e) {
                                  if (builderContext.mounted) {
                                    TopDockToast.show(
                                      builderContext,
                                      title: 'Connection Error',
                                      message: e.toString().replaceFirst('Exception: ', ''),
                                      icon: Icons.error_outline_rounded,
                                      iconColor: const Color(0xFFEF4444),
                                    );
                                  }
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
