import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const _keySelectedLocation = 'selected_location';
  static const _keyRecentLocations = 'recent_locations';
  static const _keySelectedProtocol = 'selected_protocol';
  static const _keySelectedProfile = 'selected_profile';
  static const _keyNetShield = 'netshield_enabled';
  static const _keyKillSwitch = 'killswitch_enabled';
  static const _keyVpnAccelerator = 'vpn_accelerator_enabled';
  static const _keyShowSpeedNotification = 'show_speed_notification';
  static const _keySplitTunneling = 'split_tunneling_enabled';
  static const _keyBypassedApps = 'bypassed_apps';
  static const _keyAutoUpdateWifi = 'auto_update_wifi';
  static const _keyAllowUpdateMobile = 'allow_update_mobile';
  static const _keyNotifyUpdates = 'notify_updates';
  static const _keyJoinBeta = 'join_beta';
  static const _keySelectedTheme = 'selected_theme';
  static const _keyIsDarkMode = 'is_dark_mode';
  static const _keyIpv6LeakProtection = 'ipv6_leak_protection';
  static const _keyDnsFallback = 'dns_fallback';
  static const _keyLanBypass = 'lan_bypass';
  static const _keyHardwareAcceleration = 'hardware_acceleration';
  static const _keyDefaultConnectionType = 'default_connection_type';
  static const _keyLastConnection = 'last_connection';
  static const _keyToastAnimationMode = 'toast_animation_mode';
  static const _keyOnboardingCompleted = 'onboarding_completed';
  static const _keyDesktopModeEnabled = 'desktop_mode_enabled';
  static const _keyAlternativeRouting = 'alternative_routing';
  static const _keyCustomDnsEnabled = 'custom_dns_enabled';
  static const _keyCustomDnsServers = 'custom_dns_servers';
  static const _keyModerateNat = 'moderate_nat';
  static const _keyPortForwarding = 'port_forwarding';
  static const _keyCustomMtu = 'custom_mtu';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Selected VPN Location
  static String get selectedLocation =>
      _prefs?.getString(_keySelectedLocation) ?? 'NL';

  static Future<void> setSelectedLocation(String code) async {
    await _prefs?.setString(_keySelectedLocation, code);
    await addRecentLocation(code);
  }

  // Recent Locations
  static List<String> get recentLocations {
    final list = _prefs?.getStringList(_keyRecentLocations);
    if (list == null || list.isEmpty) {
      return ['NL', 'DE', 'US'];
    }
    return list;
  }

  static Future<void> addRecentLocation(String code) async {
    if (code.isEmpty || code.toLowerCase() == 'fastest') return;
    final list = recentLocations.toSet().toList();
    list.remove(code.toUpperCase());
    list.insert(0, code.toUpperCase());
    if (list.length > 5) {
      list.removeRange(5, list.length);
    }
    await _prefs?.setStringList(_keyRecentLocations, list);
  }

  // Protocol Selection
  static String get selectedProtocol =>
      _prefs?.getString(_keySelectedProtocol) ?? 'WireGuard MASQUE (HTTP/3)';

  static Future<void> setSelectedProtocol(String protocol) async {
    await _prefs?.setString(_keySelectedProtocol, protocol);
  }

  // Profile Selection
  static String get selectedProfile =>
      _prefs?.getString(_keySelectedProfile) ?? 'Streaming US';

  static Future<void> setSelectedProfile(String profile) async {
    await _prefs?.setString(_keySelectedProfile, profile);
  }

  // Features
  static bool get netShieldEnabled => _prefs?.getBool(_keyNetShield) ?? true;
  static Future<void> setNetShieldEnabled(bool val) async =>
      await _prefs?.setBool(_keyNetShield, val);

  static bool get killSwitchEnabled => _prefs?.getBool(_keyKillSwitch) ?? true;
  static Future<void> setKillSwitchEnabled(bool val) async =>
      await _prefs?.setBool(_keyKillSwitch, val);

  static bool get vpnAcceleratorEnabled =>
      _prefs?.getBool(_keyVpnAccelerator) ?? true;
  static Future<void> setVpnAcceleratorEnabled(bool val) async =>
      await _prefs?.setBool(_keyVpnAccelerator, val);

  static bool get showSpeedNotification =>
      _prefs?.getBool(_keyShowSpeedNotification) ?? true;
  static Future<void> setShowSpeedNotification(bool val) async =>
      await _prefs?.setBool(_keyShowSpeedNotification, val);

  static bool get splitTunnelingEnabled =>
      _prefs?.getBool(_keySplitTunneling) ?? false;
  static Future<void> setSplitTunnelingEnabled(bool val) async =>
      await _prefs?.setBool(_keySplitTunneling, val);

  static List<String> get bypassedApps =>
      _prefs?.getStringList(_keyBypassedApps) ?? [];
  static Future<void> setBypassedApps(List<String> apps) async =>
      await _prefs?.setStringList(_keyBypassedApps, apps);

  // App Update Preferences
  static bool get autoUpdateWifi => _prefs?.getBool(_keyAutoUpdateWifi) ?? true;
  static Future<void> setAutoUpdateWifi(bool val) async =>
      await _prefs?.setBool(_keyAutoUpdateWifi, val);

  static bool get allowUpdateMobile =>
      _prefs?.getBool(_keyAllowUpdateMobile) ?? false;
  static Future<void> setAllowUpdateMobile(bool val) async =>
      await _prefs?.setBool(_keyAllowUpdateMobile, val);

  static bool get notifyUpdates => _prefs?.getBool(_keyNotifyUpdates) ?? true;
  static Future<void> setNotifyUpdates(bool val) async =>
      await _prefs?.setBool(_keyNotifyUpdates, val);

  static bool get joinBeta => _prefs?.getBool(_keyJoinBeta) ?? false;
  static Future<void> setJoinBeta(bool val) async =>
      await _prefs?.setBool(_keyJoinBeta, val);

  // Theme: 'Proton UI' (default) or 'Proton UI (Liquid Glass)'
  static String get selectedTheme =>
      _prefs?.getString(_keySelectedTheme) ?? 'Proton UI';
  static Future<void> setSelectedTheme(String theme) async =>
      await _prefs?.setString(_keySelectedTheme, theme);

  // Appearance: Dark Mode vs Light Mode
  static bool get isDarkMode => _prefs?.getBool(_keyIsDarkMode) ?? true;
  static Future<void> setIsDarkMode(bool isDark) async =>
      await _prefs?.setBool(_keyIsDarkMode, isDark);

  // Extra Functions
  static bool get ipv6LeakProtection => _prefs?.getBool(_keyIpv6LeakProtection) ?? true;
  static Future<void> setIpv6LeakProtection(bool val) async =>
      await _prefs?.setBool(_keyIpv6LeakProtection, val);

  static bool get dnsFallback => _prefs?.getBool(_keyDnsFallback) ?? true;
  static Future<void> setDnsFallback(bool val) async =>
      await _prefs?.setBool(_keyDnsFallback, val);

  static bool get lanBypass => _prefs?.getBool(_keyLanBypass) ?? true;
  static Future<void> setLanBypass(bool val) async =>
      await _prefs?.setBool(_keyLanBypass, val);

  static bool get hardwareAcceleration => _prefs?.getBool(_keyHardwareAcceleration) ?? true;
  static Future<void> setHardwareAcceleration(bool val) async =>
      await _prefs?.setBool(_keyHardwareAcceleration, val);

  // Default connection: 'fastest' (default), 'last', or country code
  static String get defaultConnectionType =>
      _prefs?.getString(_keyDefaultConnectionType) ?? 'fastest';
  static Future<void> setDefaultConnectionType(String type) async =>
      await _prefs?.setString(_keyDefaultConnectionType, type);

  static String get lastConnection =>
      _prefs?.getString(_keyLastConnection) ?? 'NL';
  static Future<void> setLastConnection(String loc) async =>
      await _prefs?.setString(_keyLastConnection, loc);

  // Toast animation mode: 'auto', 'island', 'corner', 'droplet'
  static String get toastAnimationMode =>
      _prefs?.getString(_keyToastAnimationMode) ?? 'auto';
  static Future<void> setToastAnimationMode(String mode) async =>
      await _prefs?.setString(_keyToastAnimationMode, mode);

  // Onboarding
  static bool get onboardingCompleted =>
      _prefs?.getBool(_keyOnboardingCompleted) ?? false;
  static Future<void> setOnboardingCompleted(bool val) async =>
      await _prefs?.setBool(_keyOnboardingCompleted, val);

  // Tablet Desktop Mode Toggle
  static bool get desktopModeEnabled =>
      _prefs?.getBool(_keyDesktopModeEnabled) ?? false;
  static Future<void> setDesktopModeEnabled(bool val) async =>
      await _prefs?.setBool(_keyDesktopModeEnabled, val);

  // Proton VPN Advanced Features
  static bool get alternativeRouting =>
      _prefs?.getBool(_keyAlternativeRouting) ?? true;
  static Future<void> setAlternativeRouting(bool val) async =>
      await _prefs?.setBool(_keyAlternativeRouting, val);

  static bool get customDnsEnabled =>
      _prefs?.getBool(_keyCustomDnsEnabled) ?? false;
  static Future<void> setCustomDnsEnabled(bool val) async =>
      await _prefs?.setBool(_keyCustomDnsEnabled, val);

  static String get customDnsServers =>
      _prefs?.getString(_keyCustomDnsServers) ?? '1.1.1.1, 1.0.0.1';
  static Future<void> setCustomDnsServers(String val) async =>
      await _prefs?.setString(_keyCustomDnsServers, val);

  static bool get moderateNat =>
      _prefs?.getBool(_keyModerateNat) ?? false;
  static Future<void> setModerateNat(bool val) async =>
      await _prefs?.setBool(_keyModerateNat, val);

  static bool get portForwarding =>
      _prefs?.getBool(_keyPortForwarding) ?? false;
  static Future<void> setPortForwarding(bool val) async =>
      await _prefs?.setBool(_keyPortForwarding, val);

  static int get customMtu =>
      _prefs?.getInt(_keyCustomMtu) ?? 1420;
  static Future<void> setCustomMtu(int val) async =>
      await _prefs?.setInt(_keyCustomMtu, val);
}
