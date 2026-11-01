import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/foundation.dart';

typedef _InternetSetOptionNative = Int32 Function(
  IntPtr hInternet,
  Uint32 dwOption,
  Pointer<Void> lpBuffer,
  Uint32 dwBufferLength,
);
typedef _InternetSetOptionDart = int Function(
  int hInternet,
  int dwOption,
  Pointer<Void> lpBuffer,
  int dwBufferLength,
);

/// Multi-platform Desktop System Proxy Service for Windows, macOS, and Linux.
///
/// Ensures all web browsers (Chrome, Edge, Firefox, Brave, Safari) and OS applications
/// route their HTTP/HTTPS/SOCKS traffic directly through the local TeroVPN core proxy
/// (default 127.0.0.1:10810) so the public IP matches the selected VPN country.
class DesktopSystemProxyService {
  DesktopSystemProxyService._();
  static final DesktopSystemProxyService instance = DesktopSystemProxyService._();

  bool _isEnabled = false;
  bool get isEnabled => _isEnabled;

  static const String bypassList =
      'localhost;127.*;10.*;172.16.*;172.17.*;172.18.*;172.19.*;172.20.*;172.21.*;172.22.*;172.23.*;172.24.*;172.25.*;172.26.*;172.27.*;172.28.*;172.29.*;172.30.*;172.31.*;192.168.*;<local>';

  /// Initializes the service. If the app previously exited unexpectedly while
  /// proxy was enabled, this ensures the system is in a clean direct state.
  Future<void> init({bool isVpnAlreadyActive = false}) async {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) return;
    if (!isVpnAlreadyActive) {
      await disableProxy();
    }
  }

  /// Enables system-wide proxy routing through [host]:[port].
  Future<bool> enableProxy({String host = '127.0.0.1', int port = 10810}) async {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) return false;

    try {
      if (Platform.isWindows) {
        await _enableWindowsProxy(host, port);
      } else if (Platform.isMacOS) {
        await _enableMacOSProxy(host, port);
      } else if (Platform.isLinux) {
        await _enableLinuxProxy(host, port);
      }
      _isEnabled = true;
      return true;
    } catch (e) {
      debugPrint('DesktopSystemProxyService.enableProxy error: $e');
      return false;
    }
  }

  /// Disables system-wide proxy routing, reverting OS to direct connection.
  Future<bool> disableProxy() async {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) return false;

    try {
      if (Platform.isWindows) {
        await _disableWindowsProxy();
      } else if (Platform.isMacOS) {
        await _disableMacOSProxy();
      } else if (Platform.isLinux) {
        await _disableLinuxProxy();
      }
      _isEnabled = false;
      return true;
    } catch (e) {
      debugPrint('DesktopSystemProxyService.disableProxy error: $e');
      return false;
    }
  }

  /// Refreshes Windows WinINet options so running browsers (Chrome, Edge, etc.)
  /// detect the proxy change immediately without requiring a browser restart.
  static void _refreshWindowsWinINet() {
    if (!Platform.isWindows) return;
    try {
      final wininet = DynamicLibrary.open('wininet.dll');
      final setOption = wininet.lookupFunction<
          _InternetSetOptionNative,
          _InternetSetOptionDart>('InternetSetOptionW');

      // INTERNET_OPTION_SETTINGS_CHANGED = 39
      // INTERNET_OPTION_REFRESH = 37
      setOption(0, 39, nullptr, 0);
      setOption(0, 37, nullptr, 0);
    } catch (e) {
      debugPrint('WinINet refresh error: $e');
    }
  }

  static Future<void> _enableWindowsProxy(String host, int port) async {
    try {
      final proxyString = 'http=$host:$port;https=$host:$port;socks=$host:$port';
      const regPath = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings';

      Process.runSync('reg', [
        'add',
        regPath,
        '/v',
        'ProxyEnable',
        '/t',
        'REG_DWORD',
        '/d',
        '1',
        '/f',
      ]);

      Process.runSync('reg', [
        'add',
        regPath,
        '/v',
        'ProxyServer',
        '/t',
        'REG_SZ',
        '/d',
        proxyString,
        '/f',
      ]);

      Process.runSync('reg', [
        'add',
        regPath,
        '/v',
        'ProxyOverride',
        '/t',
        'REG_SZ',
        '/d',
        bypassList,
        '/f',
      ]);

      _refreshWindowsWinINet();
    } catch (e) {
      debugPrint('Windows enable proxy error: $e');
    }
  }

  static Future<void> _disableWindowsProxy() async {
    try {
      const regPath = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings';

      Process.runSync('reg', [
        'add',
        regPath,
        '/v',
        'ProxyEnable',
        '/t',
        'REG_DWORD',
        '/d',
        '0',
        '/f',
      ]);

      Process.runSync('reg', [
        'add',
        regPath,
        '/v',
        'ProxyServer',
        '/t',
        'REG_SZ',
        '/d',
        '',
        '/f',
      ]);

      _refreshWindowsWinINet();
    } catch (e) {
      debugPrint('Windows disable proxy error: $e');
    }
  }

  static Future<void> _enableMacOSProxy(String host, int port) async {
    try {
      final res = await Process.run('networksetup', ['-listallnetworkservices']);
      final lines = res.stdout.toString().split('\n');
      for (final raw in lines) {
        final service = raw.trim();
        if (service.isEmpty || service.startsWith('*') || service.contains('An asterisk')) continue;
        await Process.run('networksetup', ['-setwebproxy', service, host, '$port']);
        await Process.run('networksetup', ['-setsecurewebproxy', service, host, '$port']);
        await Process.run('networksetup', ['-setsocksfirewallproxy', service, host, '$port']);
        await Process.run('networksetup', ['-setwebproxystate', service, 'on']);
        await Process.run('networksetup', ['-setsecurewebproxystate', service, 'on']);
        await Process.run('networksetup', ['-setsocksfirewallproxystate', service, 'on']);
      }
    } catch (e) {
      debugPrint('macOS enable proxy error: $e');
    }
  }

  static Future<void> _disableMacOSProxy() async {
    try {
      final res = await Process.run('networksetup', ['-listallnetworkservices']);
      final lines = res.stdout.toString().split('\n');
      for (final raw in lines) {
        final service = raw.trim();
        if (service.isEmpty || service.startsWith('*') || service.contains('An asterisk')) continue;
        await Process.run('networksetup', ['-setwebproxystate', service, 'off']);
        await Process.run('networksetup', ['-setsecurewebproxystate', service, 'off']);
        await Process.run('networksetup', ['-setsocksfirewallproxystate', service, 'off']);
      }
    } catch (e) {
      debugPrint('macOS disable proxy error: $e');
    }
  }

  static Future<void> _enableLinuxProxy(String host, int port) async {
    try {
      await Process.run('gsettings', ['set', 'org.gnome.system.proxy', 'mode', 'manual']);
      await Process.run('gsettings', ['set', 'org.gnome.system.proxy.http', 'host', host]);
      await Process.run('gsettings', ['set', 'org.gnome.system.proxy.http', 'port', '$port']);
      await Process.run('gsettings', ['set', 'org.gnome.system.proxy.https', 'host', host]);
      await Process.run('gsettings', ['set', 'org.gnome.system.proxy.https', 'port', '$port']);
      await Process.run('gsettings', ['set', 'org.gnome.system.proxy.socks', 'host', host]);
      await Process.run('gsettings', ['set', 'org.gnome.system.proxy.socks', 'port', '$port']);
    } catch (e) {
      debugPrint('Linux enable proxy error: $e');
    }
  }

  static Future<void> _disableLinuxProxy() async {
    try {
      await Process.run('gsettings', ['set', 'org.gnome.system.proxy', 'mode', 'none']);
    } catch (e) {
      debugPrint('Linux disable proxy error: $e');
    }
  }

  /// Queries public IP address (for testing or verification).
  Future<String?> checkCurrentPublicIp() async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final req = await client.getUrl(Uri.parse('https://api.ipify.org'));
      final res = await req.close();
      if (res.statusCode == 200) {
        return (await res.transform(utf8.decoder).join()).trim();
      }
    } catch (_) {}
    return null;
  }
}
