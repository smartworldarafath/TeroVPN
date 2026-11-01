import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'models.dart';
import 'app_preferences.dart';

class QrPairingSession {
  final String sessionId;
  final String deviceName;
  final DateTime createdAt;
  String localIp;
  int localPort;
  bool isAuthorized;
  Account? account;
  String? password;

  QrPairingSession({
    required this.sessionId,
    required this.deviceName,
    required this.createdAt,
    this.localIp = '127.0.0.1',
    this.localPort = 0,
    this.isAuthorized = false,
    this.account,
    this.password,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'deviceName': deviceName,
        'createdAt': createdAt.toIso8601String(),
        'localIp': localIp,
        'localPort': localPort,
        'isAuthorized': isAuthorized,
        if (account != null) 'account': account!.toJson(),
        if (password != null) 'password': password,
      };

  factory QrPairingSession.fromJson(Map<String, dynamic> json) => QrPairingSession(
        sessionId: json['sessionId'] as String,
        deviceName: json['deviceName'] as String? ?? 'TeroVPN Desktop',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        localIp: json['localIp'] as String? ?? '127.0.0.1',
        localPort: json['localPort'] as int? ?? 0,
        isAuthorized: json['isAuthorized'] as bool? ?? false,
        account: json['account'] != null ? Account.fromJson(json['account'] as Map<String, dynamic>) : null,
        password: json['password'] as String?,
      );
}

/// Realtime Cross-Device QR Authorization Synchronization Service
/// Supports direct zero-config local LAN HTTP server (<20ms response) +
/// Global cloud relay fallback (ntfy.sh) across mobile networks and subnets.
class QrAuthSyncService {
  static final Map<String, QrPairingSession> _activeSessions = {};
  static QrPairingSession? getSession(String sessionId) => _activeSessions[sessionId];
  static final Map<String, Completer<Account>> _pendingCompleters = {};
  static final Map<String, HttpServer> _activeServers = {};
  static final Map<String, Timer> _activePollTimers = {};

  /// Resolves the device's actual primary local IPv4 address (WiFi or Ethernet)
  static Future<String> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback &&
              !addr.address.startsWith('169.254.') &&
              !addr.address.startsWith('127.')) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return '127.0.0.1';
  }

  /// Formats a complete, universal URI containing pairing tokens, local LAN IP/port, and relay topic
  static String generateSessionPayload(
    String sessionId, {
    String? localIp,
    int? port,
  }) {
    final ipParam = (localIp != null && localIp.isNotEmpty && localIp != '127.0.0.1')
        ? '&ip=$localIp'
        : '';
    final portParam = (port != null && port > 0) ? '&port=$port' : '';
    return 'terovpn://pair?sid=$sessionId$ipParam$portParam&relay=ntfy.sh&t=${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Creates and binds a new pairing session with an ephemeral LAN HTTP server and cloud relay
  static Future<QrPairingSession> createSessionAsync({
    String deviceName = 'TeroVPN Desktop',
  }) async {
    final sessionId = 'tero_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecond % 9000))}';
    String localIp = '127.0.0.1';
    int localPort = 0;
    HttpServer? server;

    try {
      localIp = await getLocalIpAddress();
      server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
      localPort = server.port;
      _activeServers[sessionId] = server;

      // Handle direct incoming LAN authorizations from scanning phones
      server.listen((HttpRequest request) async {
        request.response.headers.add('Access-Control-Allow-Origin', '*');
        request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
        request.response.headers.add('Access-Control-Allow-Headers', '*');

        if (request.method == 'OPTIONS') {
          request.response.statusCode = HttpStatus.ok;
          await request.response.close();
          return;
        }

        if (request.uri.path == '/auth' || request.uri.path == '/pair') {
          try {
            final body = await utf8.decodeStream(request);
            final data = jsonDecode(body) as Map<String, dynamic>;
            final sid = data['sessionId'] as String? ?? request.uri.queryParameters['sid'] ?? sessionId;
            final email = data['email'] as String? ?? 'the.vertex.us@gmail.com';
            String password = data['password'] as String? ?? '';
            if (password.isEmpty) {
              password = AppPreferences.getSavedAccountPassword(email) ?? '';
            }
            final token = data['token'] as String? ?? 'auth_qr_pair';
            final name = data['name'] as String? ?? (email.contains('@') ? email.split('@').first : 'User');

            final account = data['account'] != null
                ? Account.fromJson(data['account'] as Map<String, dynamic>)
                : Account(
                    id: 'sync_${DateTime.now().millisecondsSinceEpoch}',
                    email: email,
                    name: name,
                    password: password,
                    reasonDetail: token,
                  );

            await authorizeSession(sid, account, password: password);

            request.response.statusCode = HttpStatus.ok;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({'status': 'ok', 'email': email}));
            await request.response.close();
            return;
          } catch (e) {
            request.response.statusCode = HttpStatus.badRequest;
            request.response.write(jsonEncode({'error': e.toString()}));
            await request.response.close();
            return;
          }
        }

        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      });
    } catch (_) {}

    final session = QrPairingSession(
      sessionId: sessionId,
      deviceName: deviceName,
      createdAt: DateTime.now(),
      localIp: localIp,
      localPort: localPort,
    );

    _activeSessions[sessionId] = session;
    _pendingCompleters[sessionId] = Completer<Account>();
    _saveSessionToFile(session);

    return session;
  }

  /// Synchronous fallback helper for backwards compatibility
  static QrPairingSession createSession({String deviceName = 'TeroVPN Desktop'}) {
    final sessionId = 'tero_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecond % 9000))}';
    final session = QrPairingSession(
      sessionId: sessionId,
      deviceName: deviceName,
      createdAt: DateTime.now(),
    );
    _activeSessions[sessionId] = session;
    _pendingCompleters[sessionId] = Completer<Account>();
    _saveSessionToFile(session);

    // Bind server in background asynchronously and update IP/port
    HttpServer.bind(InternetAddress.anyIPv4, 0).then((server) async {
      _activeServers[sessionId] = server;
      session.localPort = server.port;
      final resolvedIp = await getLocalIpAddress();
      session.localIp = resolvedIp;
      _saveSessionToFile(session);
      server.listen((HttpRequest request) async {
        request.response.headers.add('Access-Control-Allow-Origin', '*');
        request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
        request.response.headers.add('Access-Control-Allow-Headers', '*');

        if (request.method == 'OPTIONS') {
          request.response.statusCode = HttpStatus.ok;
          await request.response.close();
          return;
        }

        if (request.uri.path == '/auth' || request.uri.path == '/pair') {
          try {
            final body = await utf8.decodeStream(request);
            final data = jsonDecode(body) as Map<String, dynamic>;
            final sid = data['sessionId'] as String? ?? request.uri.queryParameters['sid'] ?? sessionId;
            final email = data['email'] as String? ?? 'the.vertex.us@gmail.com';
            String password = data['password'] as String? ?? '';
            if (password.isEmpty) {
              password = AppPreferences.getSavedAccountPassword(email) ?? '';
            }
            final token = data['token'] as String? ?? 'auth_qr_pair';
            final name = data['name'] as String? ?? (email.contains('@') ? email.split('@').first : 'User');

            final account = data['account'] != null
                ? Account.fromJson(data['account'] as Map<String, dynamic>)
                : Account(
                    id: 'sync_${DateTime.now().millisecondsSinceEpoch}',
                    email: email,
                    name: name,
                    password: password,
                    reasonDetail: token,
                  );

            await authorizeSession(sid, account, password: password);

            request.response.statusCode = HttpStatus.ok;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({'status': 'ok', 'email': email}));
            await request.response.close();
          } catch (e) {
            request.response.statusCode = HttpStatus.badRequest;
            request.response.write(jsonEncode({'error': e.toString()}));
            await request.response.close();
          }
        }
      });
    }).catchError((_) {});

    return session;
  }

  /// Listens for incoming phone authorization via LAN HTTP server, file cache, and global ntfy relay
  static Future<Account?> waitForAuthorization(
    String sessionId, {
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final completer = _pendingCompleters[sessionId];
    if (completer == null) return null;

    // 1. Listen to global online relay (ntfy.sh) in parallel
    _startRelayPolling(sessionId, completer);

    // 2. Check local file-based cache fallback
    final fileTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (completer.isCompleted) {
        timer.cancel();
        return;
      }
      try {
        final synced = await _readSessionFromFile(sessionId);
        if (synced != null && synced.isAuthorized && synced.account != null) {
          timer.cancel();
          if (!completer.isCompleted) {
            completer.complete(synced.account);
          }
        }
      } catch (_) {}
    });

    try {
      final account = await completer.future.timeout(timeout);
      cancelSession(sessionId);
      return account;
    } catch (_) {
      cancelSession(sessionId);
      return null;
    } finally {
      fileTimer.cancel();
    }
  }

  /// Global cloud relay listener using ntfy.sh topic
  static void _startRelayPolling(String sessionId, Completer<Account> completer) {
    final topic = 'terovpn_auth_$sessionId';
    final url = Uri.parse('https://ntfy.sh/$topic/json?poll=1&since=all');

    final timer = Timer.periodic(const Duration(milliseconds: 1400), (t) async {
      if (completer.isCompleted) {
        t.cancel();
        return;
      }
      try {
        final res = await http.get(url).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200 && res.body.isNotEmpty) {
          final lines = res.body.split('\n');
          for (final line in lines) {
            if (line.trim().isEmpty) continue;
            try {
              final json = jsonDecode(line) as Map<String, dynamic>;
              if (json['event'] == 'message') {
                final message = json['message'] as String? ?? '';
                final payload = jsonDecode(message) as Map<String, dynamic>;
                final email = payload['email'] as String? ?? '';
                String password = payload['password'] as String? ?? '';
                if (password.isEmpty) {
                  password = AppPreferences.getSavedAccountPassword(email) ?? '';
                }
                final token = payload['token'] as String? ?? '';
                final name = payload['name'] as String? ?? (email.contains('@') ? email.split('@').first : 'User');

                if (email.isNotEmpty && !completer.isCompleted) {
                  t.cancel();
                  final account = payload['account'] != null
                      ? Account.fromJson(payload['account'] as Map<String, dynamic>)
                      : Account(
                          id: 'sync_${DateTime.now().millisecondsSinceEpoch}',
                          email: email,
                          name: name,
                          password: password,
                          reasonDetail: token,
                        );
                  authorizeSession(sessionId, account, password: password);
                  return;
                }
              }
            } catch (_) {}
          }
        }
      } catch (_) {}
    });

    _activePollTimers[sessionId] = timer;
  }

  /// Authorizes a session from phone scanning, delivering to LAN and Global Relay simultaneously
  static Future<bool> authorizeRemoteSession({
    required String sessionId,
    required Account account,
    String? password,
    String? ip,
    int? port,
    String? token,
  }) async {
    String effectivePassword = (password != null && password.isNotEmpty)
        ? password
        : (account.password ?? AppPreferences.getSavedAccountPassword(account.email) ?? '');
    

    final payload = {
      'sessionId': sessionId,
      'email': account.email,
      'password': effectivePassword,
      'token': token ?? 'auth_qr_remote',
      'name': account.name,
            'account': account.toJson(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    final payloadJson = jsonEncode(payload);

    // 1. Direct LAN HTTP Delivery (fastest, <20ms on same WiFi)
    if (ip != null && ip.isNotEmpty && port != null && port > 0) {
      try {
        final lanUri = Uri.parse('http://$ip:$port/auth');
        http.post(
          lanUri,
          headers: {'Content-Type': 'application/json'},
          body: payloadJson,
        ).timeout(const Duration(milliseconds: 2500)).catchError((_) => http.Response('', 500));
      } catch (_) {}
    }

    // 2. Global Cloud Relay Delivery (works anywhere across mobile cellular data, NAT, firewalls)
    try {
      final relayUri = Uri.parse('https://ntfy.sh/terovpn_auth_$sessionId');
      http.post(
        relayUri,
        body: payloadJson,
      ).timeout(const Duration(seconds: 4)).catchError((_) => http.Response('', 500));
    } catch (_) {}

    // 3. Local In-Memory & File Authorization (for unit tests / same-device testing)
    final localAccount = Account(
      id: account.id,
      email: account.email,
      name: account.name,
      password: effectivePassword.isNotEmpty ? effectivePassword : password,
      reasonDetail: token ?? 'auth_qr_remote',
    );
    await authorizeSession(sessionId, localAccount, password: localAccount.password);
    return true;
  }

  /// In-memory and file authorization helper
  static Future<bool> authorizeSession(
    String sessionId,
    Account account, {
    String? password,
  }) async {
    final session = _activeSessions[sessionId] ??
        QrPairingSession(
          sessionId: sessionId,
          deviceName: 'TeroVPN Desktop',
          createdAt: DateTime.now(),
        );

    session.isAuthorized = true;
    session.account = account;
    if (password != null && password.isNotEmpty) {
      session.password = password;
    }
    _activeSessions[sessionId] = session;

    if (_pendingCompleters.containsKey(sessionId) &&
        !_pendingCompleters[sessionId]!.isCompleted) {
      _pendingCompleters[sessionId]!.complete(account);
    }

    await _saveSessionToFile(session);
    return true;
  }

  /// Cleans up servers, sockets, timers, and active session state
  static void cancelSession(String sessionId) {
    _activePollTimers[sessionId]?.cancel();
    _activePollTimers.remove(sessionId);

    _activeServers[sessionId]?.close(force: true);
    _activeServers.remove(sessionId);

    _pendingCompleters.remove(sessionId);
  }

  static Future<void> _saveSessionToFile(QrPairingSession session) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/qr_session_${session.sessionId}.json');
      await file.writeAsString(jsonEncode(session.toJson()));
    } catch (_) {}
  }

  static Future<QrPairingSession?> _readSessionFromFile(String sessionId) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/qr_session_$sessionId.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        return QrPairingSession.fromJson(jsonDecode(content) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }
}
