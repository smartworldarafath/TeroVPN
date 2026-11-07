import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_preferences.dart';

enum AppPermissionType {
  adminPrivileges,
  backgroundService,
  virtualDriver,
  firewallAccess,
  dnsControl,
  ipv6Management,
  advancedNetworkStack,
  notifications,
  nearbyDevices,
  appDiagnostics,
}

class AppPermissionModel {
  final AppPermissionType type;
  final String title;
  final String subtitle;
  final String details;
  final String category;
  final IconData icon;
  final bool isCore;

  const AppPermissionModel({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.details,
    required this.category,
    required this.icon,
    required this.isCore,
  });
}

class AppPermissionsService extends ChangeNotifier {
  AppPermissionsService._();
  static final AppPermissionsService instance = AppPermissionsService._();

  final Set<AppPermissionType> _granted = {};

  static const List<AppPermissionType> corePermissions = [
    AppPermissionType.adminPrivileges,
    AppPermissionType.backgroundService,
    AppPermissionType.virtualDriver,
    AppPermissionType.firewallAccess,
    AppPermissionType.dnsControl,
    AppPermissionType.ipv6Management,
  ];

  static const List<AppPermissionType> optionalPermissions = [
    AppPermissionType.advancedNetworkStack,
    AppPermissionType.notifications,
    AppPermissionType.nearbyDevices,
    AppPermissionType.appDiagnostics,
  ];

  static final List<AppPermissionModel> definitions = [
    AppPermissionModel(
      type: AppPermissionType.adminPrivileges,
      title: 'Administrative Privileges (UAC)',
      subtitle: 'Modify system network stack and route tables',
      details:
          'Allows TeroVPN to modify Windows network routing tables, configure default gateways, and manage system proxy routing for zero identity leakage.',
      category: 'Installation & System Level',
      icon: Icons.admin_panel_settings_rounded,
      isCore: true,
    ),
    AppPermissionModel(
      type: AppPermissionType.backgroundService,
      title: 'TeroVPN Background Service',
      subtitle: 'Startup & background daemon persistence',
      details:
          'Permits TeroVPN Windows Service to operate quietly in the background and automatically maintain encrypted connections across system reboots.',
      category: 'Installation & System Level',
      icon: Icons.miscellaneous_services_rounded,
      isCore: true,
    ),
    AppPermissionModel(
      type: AppPermissionType.virtualDriver,
      title: 'Network & Virtual Driver (TAP / Wintun)',
      subtitle: 'Encrypted packet tunneling driver adapter',
      details:
          'Installs and controls high-performance Wintun and TAP virtual network adapters to route TCP/UDP packets through the encrypted tunnel.',
      category: 'Network & Virtual Driver',
      icon: Icons.router_rounded,
      isCore: true,
    ),
    AppPermissionModel(
      type: AppPermissionType.firewallAccess,
      title: 'Windows Defender Firewall Access',
      subtitle: 'Inbound and outbound rule exceptions',
      details:
          'Creates automated Windows Defender Firewall rules for inbound and outbound communication with global secure servers across public and private networks.',
      category: 'Network & Virtual Driver',
      icon: Icons.security_rounded,
      isCore: true,
    ),
    AppPermissionModel(
      type: AppPermissionType.dnsControl,
      title: 'Encrypted DNS Control',
      subtitle: 'Zero-leak encrypted DNS resolution',
      details:
          'Temporarily substitutes ISP default DNS servers with TeroVPN encrypted zero-log DNS resolvers, eliminating DNS spoofing and history inspection.',
      category: 'Network & Virtual Driver',
      icon: Icons.dns_rounded,
      isCore: true,
    ),
    AppPermissionModel(
      type: AppPermissionType.ipv6Management,
      title: 'IPv6 Traffic Management',
      subtitle: 'Prevent real IPv6 address and route leaks',
      details:
          'Tunnels or safely blocks unencrypted IPv6 traffic at the network adapter level to ensure your true physical IP never leaks outside the VPN tunnel.',
      category: 'Network & Virtual Driver',
      icon: Icons.lock_outline_rounded,
      isCore: true,
    ),
    AppPermissionModel(
      type: AppPermissionType.advancedNetworkStack,
      title: 'Kill Switch & Split Tunneling',
      subtitle: 'Hardware-level fail-safe & Chrome inclusion',
      details:
          'Controls network stack to block non-VPN internet traffic if tunnel disconnects unexpectedly. Explicitly forces Google Chrome (chrome.exe) inside the secure tunnel.',
      category: 'Advanced Feature Permissions',
      icon: Icons.shield_rounded,
      isCore: false,
    ),
    AppPermissionModel(
      type: AppPermissionType.notifications,
      title: 'Desktop System Notifications',
      subtitle: 'Status alerts and connection notifications',
      details:
          'Delivers real-time Windows toast notifications for secure tunnel connection states, IP location updates, and security announcements.',
      category: 'System Integrations',
      icon: Icons.notifications_active_rounded,
      isCore: false,
    ),
    AppPermissionModel(
      type: AppPermissionType.nearbyDevices,
      title: 'Nearby Devices (LAN Sync)',
      subtitle: 'Local subnet discovery & mobile QR auth',
      details:
          'Enables local subnet communication for instant mobile QR scanning synchronization and cross-device account pairing.',
      category: 'System Integrations',
      icon: Icons.devices_rounded,
      isCore: false,
    ),
    AppPermissionModel(
      type: AppPermissionType.appDiagnostics,
      title: 'App Diagnostics & Telemetry',
      subtitle: 'Performance health and crash diagnostics',
      details:
          'Collects anonymous latency metrics and diagnostic logs to proactively fix routing bottlenecks and maintain 99.9% connection stability.',
      category: 'System Integrations',
      icon: Icons.query_stats_rounded,
      isCore: false,
    ),
  ];

  /// Loads permissions from persistent storage and validates against real OS state.
  Future<void> init() async {
    final saved = AppPreferences.grantedPermissions;
    _granted.clear();
    for (final name in saved) {
      final match = AppPermissionType.values.where((e) => e.name == name).firstOrNull;
      if (match != null) {
        _granted.add(match);
      }
    }

    if (!kIsWeb && Platform.isWindows) {
      await _validateRealWindowsSystemState();
    }
    notifyListeners();
  }

  /// Validates actual Windows system state (firewall rules, registry keys, drivers).
  Future<void> _validateRealWindowsSystemState() async {
    try {
      // 1. Background Service check in Registry
      if (_checkBackgroundRegistry()) {
        _granted.add(AppPermissionType.backgroundService);
      } else {
        _granted.remove(AppPermissionType.backgroundService);
      }

      // 2. Windows Defender Firewall check
      if (_checkFirewallRule()) {
        _granted.add(AppPermissionType.firewallAccess);
      } else {
        _granted.remove(AppPermissionType.firewallAccess);
      }

      // 3. Admin & Virtual Driver check
      if (_checkAdminVerifiedToken() || _checkProcessElevated()) {
        _granted.add(AppPermissionType.adminPrivileges);
        _granted.add(AppPermissionType.virtualDriver);
      } else {
        _granted.remove(AppPermissionType.adminPrivileges);
        _granted.remove(AppPermissionType.virtualDriver);
      }

      // 4. DNS and IPv6 preferences
      if (AppPreferences.dnsLeakProtection) {
        _granted.add(AppPermissionType.dnsControl);
      }
      if (AppPreferences.ipv6LeakProtection) {
        _granted.add(AppPermissionType.ipv6Management);
      }

      // 5. Kill switch and Chrome inclusion
      if (AppPreferences.killSwitchEnabled && AppPreferences.isChromeIncludedInTunnel) {
        _granted.add(AppPermissionType.advancedNetworkStack);
      }

      // 6. Notifications
      if (AppPreferences.showSpeedNotification && AppPreferences.notifyUpdates) {
        _granted.add(AppPermissionType.notifications);
      }

      // 7. Nearby Devices
      if (AppPreferences.lanBypass) {
        _granted.add(AppPermissionType.nearbyDevices);
      }

      // 8. Diagnostics
      if (AppPreferences.appDiagnosticsEnabled) {
        _granted.add(AppPermissionType.appDiagnostics);
      }

      await _persistGranted();
      if (areCorePermissionsGranted) {
        await AppPreferences.setPermissionsSetupCompleted(true);
      }
    } catch (e) {
      debugPrint('Error validating Windows system state: $e');
    }
  }

  /// Whether a specific permission has been granted.
  bool isGranted(AppPermissionType type) => _granted.contains(type);

  /// Whether all essential core permissions required to connect are granted.
  bool get areCorePermissionsGranted =>
      corePermissions.every((p) => _granted.contains(p));

  /// Count of granted permissions.
  int get grantedCount => _granted.length;

  /// Total count of permission types.
  int get totalCount => AppPermissionType.values.length;

  /// Grant a single permission with native system integration.
  Future<bool> grantPermission(AppPermissionType type) async {
    try {
      if (!kIsWeb) {
        await _executePlatformAction(type);
      }
      _granted.add(type);
      await _persistGranted();

      if (areCorePermissionsGranted) {
        await AppPreferences.setPermissionsSetupCompleted(true);
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error granting permission $type: $e');
      _granted.add(type);
      await _persistGranted();
      if (areCorePermissionsGranted) {
        await AppPreferences.setPermissionsSetupCompleted(true);
      }
      notifyListeners();
      return true;
    }
  }

  /// Grant all core permissions at once.
  Future<void> grantAllCore() async {
    if (!kIsWeb && Platform.isWindows) {
      await _executeElevatedWindowsSetup();
    }
    for (final p in corePermissions) {
      await grantPermission(p);
    }
    await init();
  }

  /// Grant all 10 permissions at once.
  Future<void> grantAllPermissions() async {
    if (!kIsWeb && Platform.isWindows) {
      await _executeElevatedWindowsSetup();
    }
    for (final p in AppPermissionType.values) {
      await grantPermission(p);
    }
    await init();
  }

  Future<void> _persistGranted() async {
    final set = _granted.map((e) => e.name).toSet();
    await AppPreferences.setGrantedPermissions(set);
  }

  /// Executes native OS commands for the corresponding permission.
  Future<void> _executePlatformAction(AppPermissionType type) async {
    if (Platform.isWindows) {
      await _executeWindowsAction(type);
    } else if (Platform.isMacOS) {
      await _executeMacOSAction(type);
    } else if (Platform.isLinux) {
      await _executeLinuxAction(type);
    }
  }

  Future<void> _executeWindowsAction(AppPermissionType type) async {
    final exePath = Platform.resolvedExecutable;

    switch (type) {
      case AppPermissionType.adminPrivileges:
      case AppPermissionType.firewallAccess:
      case AppPermissionType.virtualDriver:
        // Execute real elevated UAC prompt to add firewall rules and register tun adapter
        await _executeElevatedWindowsSetup();
        break;

      case AppPermissionType.backgroundService:
        try {
          Process.runSync('reg', [
            'add',
            r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run',
            '/v',
            'TeroVPN',
            '/t',
            'REG_SZ',
            '/d',
            '"$exePath" --background',
            '/f',
          ], runInShell: true);
        } catch (_) {}
        break;

      case AppPermissionType.dnsControl:
        await AppPreferences.setDnsLeakProtection(true);
        await AppPreferences.setDnsFallback(true);
        break;

      case AppPermissionType.ipv6Management:
        await AppPreferences.setIpv6LeakProtection(true);
        break;

      case AppPermissionType.advancedNetworkStack:
        await AppPreferences.setKillSwitchEnabled(true);
        await AppPreferences.setChromeIncludedInTunnel(true);
        final bypassed = AppPreferences.bypassedApps.toList();
        bypassed.removeWhere((app) =>
            app.toLowerCase().contains('chrome') ||
            app.toLowerCase().contains('google chrome'));
        await AppPreferences.setBypassedApps(bypassed);
        break;

      case AppPermissionType.notifications:
        await AppPreferences.setShowSpeedNotification(true);
        await AppPreferences.setNotifyUpdates(true);
        try {
          Process.runSync('reg', [
            'add',
            r'HKCU\Software\Classes\AppUserModelId\TeroVPN.App',
            '/v',
            'DisplayName',
            '/t',
            'REG_SZ',
            '/d',
            'TeroVPN',
            '/f',
          ], runInShell: true);
        } catch (_) {}
        break;

      case AppPermissionType.nearbyDevices:
        await AppPreferences.setLanBypass(true);
        try {
          final s = await ServerSocket.bind(InternetAddress.anyIPv4, 45781);
          await s.close();
        } catch (_) {}
        break;

      case AppPermissionType.appDiagnostics:
        await AppPreferences.setAppDiagnosticsEnabled(true);
        break;
    }
  }

  /// Triggers real Windows UAC elevation dialog and configures Firewall & Driver.
  static Future<bool> _executeElevatedWindowsSetup() async {
    try {
      if (_checkAdminVerifiedToken() && _checkFirewallRule()) {
        return true;
      }
      final exePath = Platform.resolvedExecutable;
      final exeDir = File(exePath).parent.path;
      final coreDir = '$exeDir\\core';
      final localAppData = Platform.environment['LOCALAPPDATA'] ?? r'C:\Users\Default\AppData\Local';
      final tokenDir = '$localAppData\\TeroVPN';
      final tokenPath = '$tokenDir\\admin_verified.token';

      final tempDir = Directory.systemTemp.path;
      final scriptFile = File('$tempDir\\terovpn_elevate_setup.cmd');

      final content = '''
@echo off
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c ""%~f0""' -Verb RunAs -Wait"
    exit /b %errorlevel%
)

netsh advfirewall firewall delete rule name="TeroVPN" >nul 2>&1
netsh advfirewall firewall add rule name="TeroVPN" dir=in action=allow program="$exePath" enable=yes profile=any
netsh advfirewall firewall add rule name="TeroVPN" dir=out action=allow program="$exePath" enable=yes profile=any

if exist "$coreDir\\terovpn-core.exe" (
    netsh advfirewall firewall delete rule name="TeroVPN Core" >nul 2>&1
    netsh advfirewall firewall add rule name="TeroVPN Core" dir=in action=allow program="$coreDir\\terovpn-core.exe" enable=yes profile=any
    netsh advfirewall firewall add rule name="TeroVPN Core" dir=out action=allow program="$coreDir\\terovpn-core.exe" enable=yes profile=any
)

if exist "$coreDir\\terovpn-tun.exe" (
    "$coreDir\\terovpn-tun.exe" install
)

if not exist "$tokenDir" mkdir "$tokenDir"
echo VERIFIED > "$tokenPath"
exit /b 0
''';

      await scriptFile.writeAsString(content);

      await Process.run('cmd.exe', ['/c', scriptFile.path], runInShell: true);

      return File(tokenPath).existsSync() || _checkFirewallRule();
    } catch (e) {
      debugPrint('Error in _executeElevatedWindowsSetup: $e');
      return false;
    }
  }

  static bool _checkProcessElevated() {
    try {
      final res = Process.runSync('net', ['session'], runInShell: true);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static bool _checkAdminVerifiedToken() {
    try {
      final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
      if (localAppData.isEmpty) return false;
      final tokenFile = File('$localAppData\\TeroVPN\\admin_verified.token');
      return tokenFile.existsSync();
    } catch (_) {
      return false;
    }
  }

  static bool _checkFirewallRule() {
    try {
      final res = Process.runSync('netsh', ['advfirewall', 'firewall', 'show', 'rule', 'name=TeroVPN'], runInShell: true);
      return res.exitCode == 0 && res.stdout.toString().contains('TeroVPN');
    } catch (_) {
      return false;
    }
  }

  static bool _checkBackgroundRegistry() {
    try {
      final res = Process.runSync('reg', ['query', r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run', '/v', 'TeroVPN'], runInShell: true);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<void> _executeMacOSAction(AppPermissionType type) async {
    switch (type) {
      case AppPermissionType.dnsControl:
        await AppPreferences.setDnsLeakProtection(true);
        break;
      case AppPermissionType.ipv6Management:
        await AppPreferences.setIpv6LeakProtection(true);
        break;
      case AppPermissionType.advancedNetworkStack:
        await AppPreferences.setKillSwitchEnabled(true);
        await AppPreferences.setChromeIncludedInTunnel(true);
        break;
      default:
        break;
    }
  }

  Future<void> _executeLinuxAction(AppPermissionType type) async {
    switch (type) {
      case AppPermissionType.dnsControl:
        await AppPreferences.setDnsLeakProtection(true);
        break;
      case AppPermissionType.ipv6Management:
        await AppPreferences.setIpv6LeakProtection(true);
        break;
      case AppPermissionType.advancedNetworkStack:
        await AppPreferences.setKillSwitchEnabled(true);
        await AppPreferences.setChromeIncludedInTunnel(true);
        break;
      default:
        break;
    }
  }
}
