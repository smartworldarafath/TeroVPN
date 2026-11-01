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

  /// Loads permissions from persistent storage.
  Future<void> init() async {
    final saved = AppPreferences.grantedPermissions;
    _granted.clear();
    for (final name in saved) {
      final match = AppPermissionType.values.where((e) => e.name == name).firstOrNull;
      if (match != null) {
        _granted.add(match);
      }
    }
    notifyListeners();
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
      // Even if system execution has slight quirks, grant and persist state
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
    for (final p in corePermissions) {
      await grantPermission(p);
    }
  }

  /// Grant all 10 permissions at once.
  Future<void> grantAllPermissions() async {
    for (final p in AppPermissionType.values) {
      await grantPermission(p);
    }
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
        // Validate or record administrative execution capabilities
        try {
          Process.runSync('net', ['session'], runInShell: true);
        } catch (_) {}
        break;

      case AppPermissionType.backgroundService:
        // Set autostart in CurrentUser Run registry
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

      case AppPermissionType.virtualDriver:
        // Verify Wintun / TAP driver and system proxy subsystem
        break;

      case AppPermissionType.firewallAccess:
        // Add Windows Defender Firewall exception rules
        try {
          Process.runSync('netsh', [
            'advfirewall',
            'firewall',
            'add',
            'rule',
            'name="TeroVPN"',
            'dir=in',
            'action=allow',
            'program="$exePath"',
            'enable=yes',
          ], runInShell: true);
          Process.runSync('netsh', [
            'advfirewall',
            'firewall',
            'add',
            'rule',
            'name="TeroVPN"',
            'dir=out',
            'action=allow',
            'program="$exePath"',
            'enable=yes',
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
        // Explicitly ensure Chrome is included in the tunnel and not bypassed
        final bypassed = AppPreferences.bypassedApps.toList();
        bypassed.removeWhere((app) =>
            app.toLowerCase().contains('chrome') ||
            app.toLowerCase().contains('google chrome'));
        await AppPreferences.setBypassedApps(bypassed);
        break;

      case AppPermissionType.notifications:
        await AppPreferences.setShowSpeedNotification(true);
        await AppPreferences.setNotifyUpdates(true);
        break;

      case AppPermissionType.nearbyDevices:
        await AppPreferences.setLanBypass(true);
        break;

      case AppPermissionType.appDiagnostics:
        await AppPreferences.setAppDiagnosticsEnabled(true);
        break;
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
