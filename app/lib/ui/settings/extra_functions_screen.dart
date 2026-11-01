import 'package:flutter/material.dart';



import '../../theme/proton_typography.dart';



import '../../theme/theme_manager.dart';



import '../../core/app_preferences.dart';



import '../components/top_dock_toast.dart';



import 'settings_row.dart';







class ExtraFunctionsScreen extends StatefulWidget {



  const ExtraFunctionsScreen({super.key});







  @override



  State<ExtraFunctionsScreen> createState() => _ExtraFunctionsScreenState();



}







class _ExtraFunctionsScreenState extends State<ExtraFunctionsScreen> {

  bool get _isDark => ThemeManager.instance.isDarkMode;



  late bool _alternativeRouting;



  late bool _customDnsEnabled;



  late String _customDnsServers;



  late bool _allowLan;



  late bool _moderateNat;



  late bool _portForwarding;



  late bool _vpnAccelerator;



  late int _customMtu;



  late bool _ipv6Leak;



  late bool _dnsFallback;



  late bool _hardwareAccel;



  late bool _desktopMode;







  @override



  void initState() {



    super.initState();



    _alternativeRouting = AppPreferences.alternativeRouting;



    _customDnsEnabled = AppPreferences.customDnsEnabled;



    _customDnsServers = AppPreferences.customDnsServers;



    _allowLan = AppPreferences.lanBypass;



    _moderateNat = AppPreferences.moderateNat;



    _portForwarding = AppPreferences.portForwarding;



    _vpnAccelerator = AppPreferences.vpnAcceleratorEnabled;



    _customMtu = AppPreferences.customMtu;



    _ipv6Leak = AppPreferences.ipv6LeakProtection;



    _dnsFallback = AppPreferences.dnsFallback;



    _hardwareAccel = AppPreferences.hardwareAcceleration;



    _desktopMode = AppPreferences.desktopModeEnabled;



  }







  void _showCustomDnsDialog() {



        final controller = TextEditingController(text: _customDnsServers);







    showDialog(



      context: context,



      builder: (ctx) => AlertDialog(



        backgroundColor: _isDark ? const Color(0xFF1B162E) : Colors.white,



        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),



        title: Row(



          children: const [



            Icon(Icons.dns_rounded, color: Color(0xFF6B42FF), size: 24),



            SizedBox(width: 10),



            Text(



              'Custom DNS Servers',



              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),



            ),



          ],



        ),



        content: Column(



          mainAxisSize: MainAxisSize.min,



          crossAxisAlignment: CrossAxisAlignment.start,



          children: [



            Text(



              'Enter primary and secondary DNS server IPv4 or IPv6 addresses separated by commas (e.g. 1.1.1.1, 9.9.9.9):',



              style: TextStyle(



                fontSize: 13,



                color: _isDark ? const Color(0xFF8F8C9E) : const Color(0xFF5E5873),



                height: 1.4,



              ),



            ),



            const SizedBox(height: 16),



            TextField(



              controller: controller,



              style: TextStyle(



                color: _isDark ? Colors.white : const Color(0xFF161224),



                fontWeight: FontWeight.w600,



              ),



              decoration: InputDecoration(



                filled: true,



                fillColor: _isDark ? const Color(0xFF120E22) : const Color(0xFFF3F0FA),



                hintText: '1.1.1.1, 1.0.0.1',



                hintStyle: TextStyle(



                  color: _isDark ? Colors.white30 : Colors.black26,



                ),



                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),



                border: OutlineInputBorder(



                  borderRadius: BorderRadius.circular(12),



                  borderSide: BorderSide(



                    color: const Color(0xFF6B42FF).withValues(alpha: 0.4),



                  ),



                ),



                focusedBorder: OutlineInputBorder(



                  borderRadius: BorderRadius.circular(12),



                  borderSide: const BorderSide(



                    color: Color(0xFF6B42FF),



                    width: 1.8,



                  ),



                ),



              ),



            ),



          ],



        ),



        actions: [



          TextButton(



            onPressed: () => Navigator.of(ctx).pop(),



            child: Text(



              'Cancel',



              style: TextStyle(



                color: _isDark ? const Color(0xFF8F8C9E) : const Color(0xFF757288),



              ),



            ),



          ),



          ElevatedButton(



            style: ElevatedButton.styleFrom(



              backgroundColor: const Color(0xFF6B42FF),



              foregroundColor: Colors.white,



              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),



            ),



            onPressed: () {



              final val = controller.text.trim();



              if (val.isNotEmpty) {



                setState(() {



                  _customDnsServers = val;



                  _customDnsEnabled = true;



                });



                AppPreferences.setCustomDnsServers(val);



                AppPreferences.setCustomDnsEnabled(true);



                TopDockToast.show(



                  context,



                  title: 'Custom DNS Active',



                  message: 'Applied: $val',



                  icon: Icons.dns_rounded,



                );



              }



              Navigator.of(ctx).pop();



            },



            child: const Text('Save'),



          ),



        ],



      ),



    );



  }







  void _showMtuDialog() {



        final options = [1420, 1280, 1360, 1400, 1500];







    showDialog(



      context: context,



      builder: (ctx) => AlertDialog(



        backgroundColor: _isDark ? const Color(0xFF1B162E) : Colors.white,



        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),



        title: const Text(



          'Maximum Transmission Unit (MTU)',



          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),



        ),



        content: Column(



          mainAxisSize: MainAxisSize.min,



          children: options.map((mtu) {



            final isSelected = _customMtu == mtu;



            final label = mtu == 1420 ? '1420 bytes (Recommended / Auto)' : '$mtu bytes';



            return ListTile(



              contentPadding: EdgeInsets.zero,



              leading: Icon(



                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,



                color: isSelected ? const Color(0xFF6B42FF) : Colors.grey,



              ),



              title: Text(



                label,



                style: TextStyle(



                  fontSize: 14,



                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,



                  color: isSelected ? const Color(0xFF6B42FF) : (_isDark ? Colors.white : Colors.black87),



                ),



              ),



              onTap: () {



                setState(() => _customMtu = mtu);



                AppPreferences.setCustomMtu(mtu);



                Navigator.of(ctx).pop();



                TopDockToast.show(



                  context,



                  title: 'MTU Updated',



                  message: 'Set to $mtu bytes',



                  icon: Icons.tune_rounded,



                );



              },



            );



          }).toList(),



        ),



      ),



    );



  }







  @override



  Widget build(BuildContext context) {



    return ListenableBuilder(



      listenable: ThemeManager.instance,



      builder: (context, _) {



                final screenWidth = MediaQuery.of(context).size.width;



        final isTabletOrLarge = MediaQuery.of(context).size.shortestSide >= 550 || screenWidth >= 600;







        return Scaffold(



          backgroundColor: ThemeManager.instance.backgroundColor,



          appBar: AppBar(



            backgroundColor: ThemeManager.instance.backgroundColor,



            elevation: 0,



            title: Text(



              'Extra Functions',



              style: ProtonTypography.titleLarge.copyWith(



                fontSize: 20,



                color: ThemeManager.instance.textPrimaryColor,



              ),



            ),



            leading: IconButton(



              icon: Icon(Icons.arrow_back_rounded, color: ThemeManager.instance.textPrimaryColor),



              onPressed: () => Navigator.of(context).pop(),



            ),



          ),



          body: SafeArea(



            child: ListView(



              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),



              children: [



                // SECTION 1: PROTON VPN ADVANCED NETWORK



                SettingsSectionCard(



                  title: 'PROTON VPN ADVANCED NETWORK',



                  children: [



                    SettingsRow(



                      icon: Icons.alt_route_rounded,



                      title: 'Alternative Routing',



                      subtitle: 'Bypass firewalls and ISP blocks by tunneling through anti-censorship CDN paths',



                      trailing: Switch(



                        value: _alternativeRouting,



                        activeThumbColor: const Color(0xFF6B42FF),



                        activeTrackColor: const Color(0xFF6B42FF).withValues(alpha: 0.5),



                        onChanged: (val) {



                          setState(() => _alternativeRouting = val);



                          AppPreferences.setAlternativeRouting(val);



                        },



                      ),



                    ),



                    SettingsRow(



                      icon: Icons.dns_rounded,



                      title: 'Custom DNS',



                      subtitle: _customDnsEnabled



                          ? 'Active: $_customDnsServers · Tap to change'



                          : 'Override default resolver with custom DNS servers',



                      trailing: Switch(



                        value: _customDnsEnabled,



                        activeThumbColor: const Color(0xFF6B42FF),



                        activeTrackColor: const Color(0xFF6B42FF).withValues(alpha: 0.5),



                        onChanged: (val) {



                          if (val) {



                            _showCustomDnsDialog();



                          } else {



                            setState(() => _customDnsEnabled = false);



                            AppPreferences.setCustomDnsEnabled(false);



                          }



                        },



                      ),



                      onTap: _showCustomDnsDialog,



                    ),



                    SettingsRow(



                      icon: Icons.lan_rounded,



                      title: 'Allow LAN Connections',



                      subtitle: 'Access local devices (printers, smart TVs, and NAS) on your home Wi-Fi',



                      trailing: Switch(



                        value: _allowLan,



                        activeThumbColor: const Color(0xFF6B42FF),



                        activeTrackColor: const Color(0xFF6B42FF).withValues(alpha: 0.5),



                        onChanged: (val) {



                          setState(() => _allowLan = val);



                          AppPreferences.setLanBypass(val);



                        },



                      ),



                    ),



                    SettingsRow(



                      icon: Icons.compare_arrows_rounded,



                      title: 'Moderate NAT',



                      subtitle: 'Keep consistent outbound port mapping for smooth online gaming and VoIP calls',



                      trailing: Switch(



                        value: _moderateNat,



                        activeThumbColor: const Color(0xFF6B42FF),



                        activeTrackColor: const Color(0xFF6B42FF).withValues(alpha: 0.5),



                        onChanged: (val) {



                          setState(() => _moderateNat = val);



                          AppPreferences.setModerateNat(val);



                        },



                      ),



                    ),



                    SettingsRow(



                      icon: Icons.move_to_inbox_rounded,



                      title: 'Port Forwarding',



                      subtitle: 'Direct incoming traffic through firewall for high-speed torrenting and P2P transfers',



                      trailing: Switch(



                        value: _portForwarding,



                        activeThumbColor: const Color(0xFF6B42FF),



                        activeTrackColor: const Color(0xFF6B42FF).withValues(alpha: 0.5),



                        onChanged: (val) {



                          setState(() => _portForwarding = val);



                          AppPreferences.setPortForwarding(val);



                        },



                      ),



                    ),



                  ],



                ),







                const SizedBox(height: 18),







                // SECTION 2: SPEED & PRIVACY HARDENING



                SettingsSectionCard(



                  title: 'SPEED & PRIVACY HARDENING',



                  children: [



                    SettingsRow(



                      icon: Icons.speed_rounded,



                      title: 'VPN Accelerator',



                      subtitle: 'Combine BBR congestion control and QUIC multiplexing to boost speed up to 400%',



                      trailing: Switch(



                        value: _vpnAccelerator,



                        activeThumbColor: const Color(0xFF6B42FF),



                        activeTrackColor: const Color(0xFF6B42FF).withValues(alpha: 0.5),



                        onChanged: (val) {



                          setState(() => _vpnAccelerator = val);



                          AppPreferences.setVpnAcceleratorEnabled(val);



                        },



                      ),



                    ),



                    SettingsRow(



                      icon: Icons.tune_rounded,



                      title: 'Custom MTU Size',



                      subtitle: _customMtu == 1420



                          ? 'Auto (1420 bytes) · Optimized for mobile carrier networks'



                          : '$_customMtu bytes · Custom packet size active',



                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),



                      onTap: _showMtuDialog,



                    ),



                    SettingsRow(



                      icon: Icons.security_rounded,



                      title: 'IPv6 Leak Protection',



                      subtitle: 'Completely drop untunneled IPv6 packets to prevent real identity leaks',



                      trailing: Switch(



                        value: _ipv6Leak,



                        activeThumbColor: const Color(0xFF6B42FF),



                        activeTrackColor: const Color(0xFF6B42FF).withValues(alpha: 0.5),



                        onChanged: (val) {



                          setState(() => _ipv6Leak = val);



                          AppPreferences.setIpv6LeakProtection(val);



                        },



                      ),



                    ),



                    SettingsRow(



                      icon: Icons.cloud_sync_rounded,



                      title: 'DNS Fallback',



                      subtitle: 'Automatic failover to Cloudflare DNS (1.1.1.1) if primary resolver stalls',



                      trailing: Switch(



                        value: _dnsFallback,



                        activeThumbColor: const Color(0xFF6B42FF),



                        activeTrackColor: const Color(0xFF6B42FF).withValues(alpha: 0.5),



                        onChanged: (val) {



                          setState(() => _dnsFallback = val);



                          AppPreferences.setDnsFallback(val);



                        },



                      ),



                    ),



                  ],



                ),







                const SizedBox(height: 18),







                // SECTION 3: DISPLAY & HARDWARE



                SettingsSectionCard(



                  title: 'DISPLAY & HARDWARE',



                  children: [



                    // User Requirement 7: 'Desktop Mode' option with ON/OFF switch



                    SettingsRow(



                      icon: Icons.tablet_mac_rounded,



                      title: 'Desktop Mode',



                      subtitle: isTabletOrLarge



                          ? 'Tablet display detected. Turn ON to switch to desktop sidebar navigation'



                          : 'Switch to multi-column desktop layout on tablets and large screen devices',



                      trailing: Switch(



                        value: _desktopMode,



                        activeThumbColor: const Color(0xFF6B42FF),



                        activeTrackColor: const Color(0xFF6B42FF).withValues(alpha: 0.5),



                        onChanged: (val) {



                          setState(() => _desktopMode = val);



                          AppPreferences.setDesktopModeEnabled(val);



                          TopDockToast.show(



                            context,



                            title: val ? 'Desktop Mode ON' : 'Phone Dock Mode ON',



                            message: val ? 'Sidebar navigation active on tablet' : 'Standard mobile dock navigation active',



                            icon: val ? Icons.desktop_windows_rounded : Icons.phone_android_rounded,



                          );



                        },



                      ),



                    ),



                    SettingsRow(



                      icon: Icons.bolt_rounded,



                      title: 'Hardware Shader Acceleration',



                      subtitle: 'GPU Vulkan/OpenGL acceleration for liquid glass blurring and 120Hz physics',



                      trailing: Switch(



                        value: _hardwareAccel,



                        activeThumbColor: const Color(0xFF6B42FF),



                        activeTrackColor: const Color(0xFF6B42FF).withValues(alpha: 0.5),



                        onChanged: (val) {



                          setState(() => _hardwareAccel = val);



                          AppPreferences.setHardwareAcceleration(val);



                        },



                      ),



                    ),



                  ],



                ),



              ],



            ),



          ),



        );



      },



    );



  }



}



