import 'dart:convert';
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
  static const _keyCustomDnsPrimary = 'custom_dns_primary';
  static const _keyCustomDnsSecondary = 'custom_dns_secondary';
  static const _keyCustomDnsServers = 'custom_dns_servers';
  static const _keyDnsLeakProtection = 'dns_leak_protection';
  static const _keyModerateNat = 'moderate_nat';
  static const _keyAutoConnectOnLaunch = 'auto_connect_on_launch';
  static const _keyTunnelMtu = 'tunnel_mtu';
  static const _keyPortForwarding = 'port_forwarding';
  static const _keyCustomMtu = 'custom_mtu';
  static const _keyPermissionsSetupCompleted = 'permissions_setup_completed_v119';
  static const _keyGrantedPermissions = 'granted_permissions_set';
  static const _keyChromeSplitTunnelIncluded = 'chrome_split_tunnel_included';
  static const _keyAppDiagnosticsEnabled = 'app_diagnostics_enabled';

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
      _prefs?.getString(_keySelectedProtocol) ?? 'Smart (Automatic)';

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
  static bool get customDnsEnabled =>
      _prefs?.getBool(_keyCustomDnsEnabled) ?? false;
  static Future<void> setCustomDnsEnabled(bool val) async =>
      await _prefs?.setBool(_keyCustomDnsEnabled, val);

  static String get customDnsPrimary =>
      _prefs?.getString(_keyCustomDnsPrimary) ?? '1.1.1.1';
  static Future<void> setCustomDnsPrimary(String val) async =>
      await _prefs?.setString(_keyCustomDnsPrimary, val);

  static String get customDnsSecondary =>
      _prefs?.getString(_keyCustomDnsSecondary) ?? '1.0.0.1';
  static Future<void> setCustomDnsSecondary(String val) async =>
      await _prefs?.setString(_keyCustomDnsSecondary, val);

  static String get customDnsServers =>
      _prefs?.getString(_keyCustomDnsServers) ?? '1.1.1.1, 1.0.0.1';
  static Future<void> setCustomDnsServers(String val) async =>
      await _prefs?.setString(_keyCustomDnsServers, val);

  static bool get dnsLeakProtection =>
      _prefs?.getBool(_keyDnsLeakProtection) ?? true;
  static Future<void> setDnsLeakProtection(bool val) async =>
      await _prefs?.setBool(_keyDnsLeakProtection, val);

  static bool get alternativeRouting =>
      _prefs?.getBool(_keyAlternativeRouting) ?? true;
  static Future<void> setAlternativeRouting(bool val) async =>
      await _prefs?.setBool(_keyAlternativeRouting, val);

  static bool get moderateNat =>
      _prefs?.getBool(_keyModerateNat) ?? false;
  static Future<void> setModerateNat(bool val) async =>
      await _prefs?.setBool(_keyModerateNat, val);

  static bool get autoConnectOnLaunch =>
      _prefs?.getBool(_keyAutoConnectOnLaunch) ?? true;
  static Future<void> setAutoConnectOnLaunch(bool val) async =>
      await _prefs?.setBool(_keyAutoConnectOnLaunch, val);

  static int get tunnelMtu =>
      _prefs?.getInt(_keyTunnelMtu) ?? (_prefs?.getInt(_keyCustomMtu) ?? 1420);
  static Future<void> setTunnelMtu(int val) async {
    await _prefs?.setInt(_keyTunnelMtu, val);
    await _prefs?.setInt(_keyCustomMtu, val);
  }

  static int get customMtu => tunnelMtu;
  static Future<void> setCustomMtu(int val) => setTunnelMtu(val);

  static bool get portForwarding =>
      _prefs?.getBool(_keyPortForwarding) ?? false;
  static Future<void> setPortForwarding(bool val) async =>
      await _prefs?.setBool(_keyPortForwarding, val);

  static const _keyBetaFeaturesEnabled = 'beta_features_enabled';
  static const _keySelectedDockStyle = 'selected_dock_style';
  static const _keyCustomProfiles = 'custom_profiles';

  static bool get betaFeaturesEnabled =>
      _prefs?.getBool(_keyBetaFeaturesEnabled) ?? false;
  static Future<void> setBetaFeaturesEnabled(bool val) async =>
      await _prefs?.setBool(_keyBetaFeaturesEnabled, val);

  static String get selectedDockStyle =>
      _prefs?.getString(_keySelectedDockStyle) ?? 'default';
  static Future<void> setSelectedDockStyle(String val) async =>
      await _prefs?.setString(_keySelectedDockStyle, val);

  static List<String> get customProfiles =>
      _prefs?.getStringList(_keyCustomProfiles) ?? [];
  static Future<void> setCustomProfiles(List<String> list) async =>
      await _prefs?.setStringList(_keyCustomProfiles, list);
  static Future<void> addCustomProfile(String jsonStr) async {
    final list = customProfiles.toList();
    list.add(jsonStr);
    await setCustomProfiles(list);
  }

  // Cross-device pairing & active account persistence
  static const _keySavedActiveAccount = 'saved_active_account_json';
  static const _keySavedAuthPassword = 'saved_auth_password_';

  static Map<String, dynamic>? get savedActiveAccount {
    final raw = _prefs?.getString(_keySavedActiveAccount);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> setSavedActiveAccount(Map<String, dynamic> accountJson) async {
    await _prefs?.setString(_keySavedActiveAccount, jsonEncode(accountJson));
  }

  static Future<void> clearSavedActiveAccount() async {
    await _prefs?.remove(_keySavedActiveAccount);
  }

  static String? getSavedAuthPassword(String email) {
    if (email.isEmpty) return null;
    final cleanEmail = email.toLowerCase().trim();
    return _prefs?.getString('$_keySavedAuthPassword$cleanEmail') ??
        _prefs?.getString('pwd_$cleanEmail');
  }

  static Future<void> setSavedAuthPassword(String email, String password) async {
    if (email.isEmpty || password.isEmpty) return;
    final cleanEmail = email.toLowerCase().trim();
    await _prefs?.setString('$_keySavedAuthPassword$cleanEmail', password);
    await _prefs?.setString('pwd_$cleanEmail', password);
  }

  static String? getSavedAccountPassword(String email) => getSavedAuthPassword(email);
  static Future<void> setSavedAccountPassword(String email, String password) => setSavedAuthPassword(email, password);

  // v1.1.9 Permissions & Diagnostics
  static bool get permissionsSetupCompleted =>
      _prefs?.getBool(_keyPermissionsSetupCompleted) ?? false;
  static Future<void> setPermissionsSetupCompleted(bool val) async =>
      await _prefs?.setBool(_keyPermissionsSetupCompleted, val);

  static Set<String> get grantedPermissions {
    final list = _prefs?.getStringList(_keyGrantedPermissions);
    if (list == null) return {};
    return list.toSet();
  }
  static Future<void> setGrantedPermissions(Set<String> set) async {
    await _prefs?.setStringList(_keyGrantedPermissions, set.toList());
  }

  static bool get isChromeIncludedInTunnel =>
      _prefs?.getBool(_keyChromeSplitTunnelIncluded) ?? true;
  static Future<void> setChromeIncludedInTunnel(bool val) async =>
      await _prefs?.setBool(_keyChromeSplitTunnelIncluded, val);

  static bool get appDiagnosticsEnabled =>
      _prefs?.getBool(_keyAppDiagnosticsEnabled) ?? true;
  static Future<void> setAppDiagnosticsEnabled(bool val) async =>
      await _prefs?.setBool(_keyAppDiagnosticsEnabled, val);
}
