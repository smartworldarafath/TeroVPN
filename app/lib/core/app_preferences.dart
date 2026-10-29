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
}
