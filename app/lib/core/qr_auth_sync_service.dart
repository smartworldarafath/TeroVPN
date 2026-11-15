import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'models.dart';
import 'app_preferences.dart';

class QrPairingSession {
  final String sessionId;
  final String deviceName;
  final DateTime createdAt;
  final String secretKey;
  String localIp;
  int localPort;
  bool isAuthorized;
  Account? account;
  String? password;
  String? backupB64;

  QrPairingSession({
    required this.sessionId,
    required this.deviceName,
    required this.createdAt,
    required this.secretKey,
    this.localIp = '127.0.0.1',
    this.localPort = 0,
    this.isAuthorized = false,
    this.account,
    this.password,
    this.backupB64,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'deviceName': deviceName,
        'createdAt': createdAt.toIso8601String(),
        'secretKey': secretKey,
        'localIp': localIp,
        'localPort': localPort,
        'isAuthorized': isAuthorized,
        if (account != null) 'account': account!.toJson(),
        if (password != null) 'password': password,
        if (backupB64 != null) 'backupB64': backupB64,
      };

  factory QrPairingSession.fromJson(Map<String, dynamic> json) => QrPairingSession(
        sessionId: json['sessionId'] as String,
        deviceName: json['deviceName'] as String? ?? 'TeroVPN Device',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        secretKey: json['secretKey'] as String? ?? '',
        localIp: json['localIp'] as String? ?? '127.0.0.1',
        localPort: json['localPort'] as int? ?? 0,
        isAuthorized: json['isAuthorized'] as bool? ?? false,
        account: json['account'] != null ? Account.fromJson(json['account'] as Map<String, dynamic>) : null,
        password: json['password'] as String?,
        backupB64: json['backupB64'] as String?,
      );
}

/// Realtime Cross-Device QR Authorization Synchronization Service with AES-256 E2EE
/// Supports direct zero-config local LAN HTTP server (<20ms response) +
/// Global cloud relay streaming (ntfy.sh) across mobile networks, tablets, desktop, and Chrome Extension.
class QrAuthSyncService {
  static final Map<String, QrPairingSession> _activeSessions = {};
  static final Map<String, QrPairingSession> _completedSessions = {};
  static QrPairingSession? getSession(String sessionId) =>
      _activeSessions[sessionId] ?? _completedSessions[sessionId];
  static final Map<String, Completer<Account?>> _pendingCompleters = {};
  static final Map<String, HttpServer> _activeServers = {};
  static final Map<String, Timer> _activePollTimers = {};
  static final Map<String, http.Client> _activeStreamClients = {};

  static String generateSecureSecretKey() {
    final rng = Random.secure();
    final bytes = Uint8List.fromList(List<int>.generate(32, (_) => rng.nextInt(256)));
    return base64UrlEncode(bytes);
  }

  static String generateSessionId(String secretKey) {
    final hash = sha256.convert(utf8.encode(secretKey)).toString().substring(0, 16);
    final rand = 100000 + Random.secure().nextInt(900000);
    return 'tero_${hash}_$rand';
  }

  static Map<String, dynamic> encryptPayload(String plainJson, String secretKey) {
    final keyBytes = base64Url.decode(base64Url.normalize(secretKey));
    final encKey = enc.Key(keyBytes);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(encKey, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainJson, iv: iv);
    final hmac = Hmac(sha256, keyBytes).convert(encrypted.bytes).toString();

    return {
      'e2ee': true,
      'cipher': encrypted.base64,
      'iv': iv.base64,
      'mac': hmac,
    };
  }

  static Map<String, dynamic>? decryptPayload(Map<String, dynamic> envelope, String secretKey) {
    try {
      final keyBytes = base64Url.decode(base64Url.normalize(secretKey));
      final cipherBase64 = envelope['cipher'] as String;
      final ivBase64 = envelope['iv'] as String;
      final receivedMac = envelope['mac'] as String? ?? '';

      final encrypted = enc.Encrypted.fromBase64(cipherBase64);
      final computedMac = Hmac(sha256, keyBytes).convert(encrypted.bytes).toString();
      if (computedMac != receivedMac) {
        return null;
      }

      final encKey = enc.Key(keyBytes);
      final iv = enc.IV.fromBase64(ivBase64);
      final encrypter = enc.Encrypter(enc.AES(encKey, mode: enc.AESMode.cbc));
      final plainText = encrypter.decrypt(encrypted, iv: iv);
      return jsonDecode(plainText) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Resolves the device's primary Wi-Fi / LAN IPv4 address, prioritizing wlan/en/eth over tun/rmnet.
  static Future<String> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      String? fallbackCandidate;
      for (final interface in interfaces) {
        final name = interface.name.toLowerCase();
        final isVirtualOrCell = name.contains('tun') ||
            name.contains('tap') ||
            name.contains('rmnet') ||
            name.contains('ccmni') ||
            name.contains('pdp') ||
            name.contains('dummy');
        final isWifiOrLan = name.contains('wlan') ||
            name.contains('wifi') ||
            name.contains('wi-fi') ||
            name.contains('eth') ||
            name.contains('en') ||
            name.contains('ap');

        for (final addr in interface.addresses) {
          final ip = addr.address;
          if (addr.isLoopback || ip.startsWith('169.254.') || ip.startsWith('127.')) {
            continue;
          }
          if (isWifiOrLan && (ip.startsWith('192.168.') || ip.startsWith('10.') || ip.startsWith('172.'))) {
            return ip;
          }
          if (!isVirtualOrCell && ip.startsWith('192.168.')) {
            return ip;
          }
          if (!isVirtualOrCell) {
            fallbackCandidate ??= ip;
          }
        }
      }
      if (fallbackCandidate != null) return fallbackCandidate;
    } catch (_) {}
    return '127.0.0.1';
  }

  /// Formats a complete, universal URI containing pairing tokens, local LAN IP/port, and relay topic
  static String generateSessionPayload(
    String sessionId, {
    String? localIp,
    int? port,
    String? secretKey,
  }) {
    final key = secretKey ?? _activeSessions[sessionId]?.secretKey ?? '';
    final keyParam = key.isNotEmpty ? '&k=$key' : '';
    final ipParam = (localIp != null && localIp.isNotEmpty && localIp != '127.0.0.1')
        ? '&ip=$localIp'
        : '';
    final portParam = (port != null && port > 0) ? '&port=$port' : '';
    return 'terovpn://pair?sid=$sessionId$keyParam$ipParam$portParam&relay=ntfy.sh';
  }

  static Account _buildSyncedAccount(
    Map<String, dynamic> decryptedPayload, {
    required String email,
    required String name,
    required String password,
    required String token,
  }) {
    if (decryptedPayload['account'] is Map) {
      final map = Map<String, dynamic>.from(decryptedPayload['account'] as Map);
      map['email'] = email.isNotEmpty ? email : (map['email'] ?? '');
      map['name'] = name.isNotEmpty ? name : (map['name'] ?? '');
      map['active'] = true;
      map['enabled'] = true;
      map['status'] = AccountStatus.ready;
      if (password.isNotEmpty) {
        map['password'] = password;
        map['has_password'] = true;
      }
      if (token.isNotEmpty) {
        map['reason_detail'] = token;
      }
      return Account.fromJson(map);
    }
    return Account(
      id: 'sync_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      name: name,
      active: true,
      enabled: true,
      status: AccountStatus.ready,
      password: password,
      reasonDetail: token,
    );
  }

  static void _attachLanHandler(HttpServer server, String defaultSessionId) {
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
          final sid = data['sessionId'] as String? ?? request.uri.queryParameters['sid'] ?? defaultSessionId;
          final activeSession = _activeSessions[sid] ?? _activeSessions[defaultSessionId];

          Map<String, dynamic> decryptedPayload;
          if (data['e2ee'] == true && data['cipher'] != null) {
            if (activeSession == null || activeSession.secretKey.isEmpty) {
              request.response.statusCode = HttpStatus.unauthorized;
              request.response.write(jsonEncode({'error': 'Unauthorized session'}));
              await request.response.close();
              return;
            }
            final decrypted = decryptPayload(data, activeSession.secretKey);
            if (decrypted == null) {
              request.response.statusCode = HttpStatus.unauthorized;
              request.response.write(jsonEncode({'error': 'Invalid MAC or decryption failure'}));
              await request.response.close();
              return;
            }
            decryptedPayload = decrypted;
          } else {
            decryptedPayload = data;
          }

          final rawAccount = decryptedPayload['account'] is Map
              ? Map<String, dynamic>.from(decryptedPayload['account'] as Map)
              : null;
          final email = (decryptedPayload['email'] as String? ?? rawAccount?['email'] as String? ?? '').trim();
          if (email.isEmpty) {
            request.response.statusCode = HttpStatus.badRequest;
            request.response.write(jsonEncode({'error': 'Missing email'}));
            await request.response.close();
            return;
          }

          String password = decryptedPayload['password'] as String? ?? rawAccount?['password'] as String? ?? '';
          if (password.isEmpty) {
            password = AppPreferences.getSavedAccountPassword(email) ?? '';
          }
          final token = decryptedPayload['token'] as String? ?? rawAccount?['reason_detail'] as String? ?? 'auth_qr_pair';
          final backupB64 = decryptedPayload['backup_b64'] as String?;
          final name = decryptedPayload['name'] as String? ??
              rawAccount?['name'] as String? ??
              (email.contains('@') ? email.split('@').first : 'User');

          final account = _buildSyncedAccount(
            decryptedPayload,
            email: email,
            name: name,
            password: password,
            token: token,
          );

          await authorizeSession(
            sid,
            account,
            password: password,
            backupB64: backupB64,
          );

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
  }

  /// Creates and binds a new pairing session with an ephemeral LAN HTTP server and cloud relay
  static Future<QrPairingSession> createSessionAsync({
    String deviceName = 'TeroVPN Desktop',
  }) async {
    final secretKey = generateSecureSecretKey();
    final sessionId = generateSessionId(secretKey);
    String localIp = '127.0.0.1';
    int localPort = 0;

    final session = QrPairingSession(
      sessionId: sessionId,
      deviceName: deviceName,
      createdAt: DateTime.now(),
      secretKey: secretKey,
    );

    _activeSessions[sessionId] = session;
    _pendingCompleters[sessionId] = Completer<Account?>();

    try {
      localIp = await getLocalIpAddress();
      final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
      localPort = server.port;
      session.localIp = localIp;
      session.localPort = localPort;
      _activeServers[sessionId] = server;
      _attachLanHandler(server, sessionId);
    } catch (_) {}

    _saveSessionToFile(session);
    return session;
  }

  /// Synchronous helper that binds the LAN server in background and invokes [onServerBound] when ready.
  static QrPairingSession createSession({
    String deviceName = 'TeroVPN Desktop',
    void Function()? onServerBound,
  }) {
    final secretKey = generateSecureSecretKey();
    final sessionId = generateSessionId(secretKey);
    final session = QrPairingSession(
      sessionId: sessionId,
      deviceName: deviceName,
      createdAt: DateTime.now(),
      secretKey: secretKey,
    );
    _activeSessions[sessionId] = session;
    _pendingCompleters[sessionId] = Completer<Account?>();
    _saveSessionToFile(session);

    HttpServer.bind(InternetAddress.anyIPv4, 0).then((server) async {
      _activeServers[sessionId] = server;
      session.localPort = server.port;
      final resolvedIp = await getLocalIpAddress();
      session.localIp = resolvedIp;
      _saveSessionToFile(session);
      _attachLanHandler(server, sessionId);
      onServerBound?.call();
    }).catchError((_) {});

    return session;
  }

  /// Listens for incoming phone authorization via LAN HTTP server, file cache, and live ntfy.sh stream
  static Future<Account?> waitForAuthorization(
    String sessionId, {
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final completer = _pendingCompleters.putIfAbsent(sessionId, () => Completer<Account?>());
    if (completer.isCompleted) {
      return completer.future;
    }

    // 1. Listen to global online relay (ntfy.sh live stream + fallback poll) in parallel
    _startRelayStreamAndPolling(sessionId, completer);

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
          final current = _activeSessions[sessionId];
          if (current != null) {
            current.isAuthorized = true;
            current.account = synced.account;
            if (synced.password != null && synced.password!.isNotEmpty) {
              current.password = synced.password;
            }
            if (synced.backupB64 != null && synced.backupB64!.isNotEmpty) {
              current.backupB64 = synced.backupB64;
            }
          } else {
            _activeSessions[sessionId] = synced;
          }
          if (!completer.isCompleted) {
            completer.complete(synced.account);
          }
        }
      } catch (_) {}
    });

    try {
      final account = await completer.future.timeout(timeout);
      final doneSession = _activeSessions[sessionId];
      if (doneSession != null) {
        _completedSessions[sessionId] = doneSession;
      }
      cancelSession(sessionId);
      return account;
    } catch (_) {
      cancelSession(sessionId);
      return null;
    } finally {
      fileTimer.cancel();
    }
  }

  static void _processIncomingRelayLine(
    String line,
    String sessionId,
    Completer<Account?> completer,
  ) {
    if (line.trim().isEmpty || completer.isCompleted) return;
    try {
      final json = jsonDecode(line) as Map<String, dynamic>;
      if (json['event'] != 'message') return;
      final message = json['message'] as String? ?? '';
      if (message.isEmpty) return;
      final payload = jsonDecode(message) as Map<String, dynamic>;

      final session = _activeSessions[sessionId];
      Map<String, dynamic> decryptedPayload;
      if (payload['e2ee'] == true && payload['cipher'] != null) {
        if (session == null || session.secretKey.isEmpty) return;
        final decrypted = decryptPayload(payload, session.secretKey);
        if (decrypted == null) return;
        decryptedPayload = decrypted;
      } else {
        decryptedPayload = payload;
      }

      final rawAccount = decryptedPayload['account'] is Map
          ? Map<String, dynamic>.from(decryptedPayload['account'] as Map)
          : null;
      final email = (decryptedPayload['email'] as String? ?? rawAccount?['email'] as String? ?? '').trim();
      if (email.isEmpty || completer.isCompleted) return;

      String password = decryptedPayload['password'] as String? ?? rawAccount?['password'] as String? ?? '';
      if (password.isEmpty) {
        password = AppPreferences.getSavedAccountPassword(email) ?? '';
      }
      final token = decryptedPayload['token'] as String? ?? rawAccount?['reason_detail'] as String? ?? 'auth_qr_remote';
      final backupB64 = decryptedPayload['backup_b64'] as String?;
      final name = decryptedPayload['name'] as String? ??
          rawAccount?['name'] as String? ??
          (email.contains('@') ? email.split('@').first : 'User');

      final account = _buildSyncedAccount(
        decryptedPayload,
        email: email,
        name: name,
        password: password,
        token: token,
      );
      authorizeSession(
        sessionId,
        account,
        password: password,
        backupB64: backupB64,
      );
    } catch (_) {}
  }

  /// Opens a persistent real-time HTTP NDJSON stream to ntfy.sh (which delivers messages in <100ms)
  /// and automatically reconnects if dropped.
  static void _startRelayStreamAndPolling(String sessionId, Completer<Account?> completer) {
    final topic = 'terovpn_auth_$sessionId';

    Future<void> connectStream() async {
      while (!completer.isCompleted && _pendingCompleters.containsKey(sessionId)) {
        final client = http.Client();
        _activeStreamClients[sessionId]?.close();
        _activeStreamClients[sessionId] = client;
        try {
          final req = http.Request('GET', Uri.parse('https://ntfy.sh/$topic/json'));
          req.headers['Cache-Control'] = 'no-cache';
          final streamedRes = await client.send(req).timeout(const Duration(seconds: 15));
          if (streamedRes.statusCode == 200) {
            await for (final line in streamedRes.stream
                .transform(utf8.decoder)
                .transform(const LineSplitter())) {
              if (completer.isCompleted || !_pendingCompleters.containsKey(sessionId)) {
                break;
              }
              _processIncomingRelayLine(line, sessionId, completer);
            }
          }
        } catch (_) {} finally {
          client.close();
        }
        if (!completer.isCompleted && _pendingCompleters.containsKey(sessionId)) {
          await Future.delayed(const Duration(milliseconds: 900));
        }
      }
    }

    unawaited(connectStream());
  }

  /// Authorizes a session from phone scanning, delivering to LAN and Global Relay simultaneously with AES-256 E2EE
  static Future<bool> authorizeRemoteSession({
    required String sessionId,
    required Account account,
    String? password,
    String? ip,
    int? port,
    String? token,
    String? secretKey,
    String? backupB64,
  }) async {
    final String effectivePassword = (password != null && password.isNotEmpty)
        ? password
        : (account.password ?? AppPreferences.getSavedAccountPassword(account.email) ?? '');

    final syncedAccount = Account(
      id: account.id.isNotEmpty ? account.id : 'sync_${DateTime.now().millisecondsSinceEpoch}',
      email: account.email,
      name: account.name.isNotEmpty
          ? account.name
          : (account.email.contains('@') ? account.email.split('@').first : 'User'),
      active: true,
      enabled: true,
      status: AccountStatus.ready,
      password: effectivePassword,
      reasonDetail: token ?? (account.reasonDetail.isNotEmpty ? account.reasonDetail : 'auth_qr_remote'),
    );

    final compactPayload = <String, dynamic>{
      'sessionId': sessionId,
      'email': syncedAccount.email,
      'password': effectivePassword,
      'token': syncedAccount.reasonDetail,
      'name': syncedAccount.name,
      'account': syncedAccount.toJson(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    final fullPayload = <String, dynamic>{
      ...compactPayload,
      if (backupB64 != null && backupB64.isNotEmpty) 'backup_b64': backupB64,
    };

    // E2EE encryption if secretKey is available
    final keyToUse = (secretKey != null && secretKey.isNotEmpty)
        ? secretKey
        : _activeSessions[sessionId]?.secretKey;

    String encodeEnvelope(Map<String, dynamic> payload) {
      final rawJson = jsonEncode(payload);
      if (keyToUse != null && keyToUse.isNotEmpty) {
        final envelope = encryptPayload(rawJson, keyToUse);
        envelope['sessionId'] = sessionId;
        envelope['timestamp'] = DateTime.now().millisecondsSinceEpoch;
        return jsonEncode(envelope);
      }
      return rawJson;
    }

    final outgoingJson = encodeEnvelope(fullPayload);
    final relayBody = utf8.encode(outgoingJson).length <= 3900
        ? outgoingJson
        : encodeEnvelope(compactPayload);

    final deliveries = <Future<void>>[];

    // 1. Direct LAN HTTP Delivery (fastest, <20ms on same WiFi; no 4KB body limit)
    if (ip != null && ip.isNotEmpty && ip != '127.0.0.1' && port != null && port > 0) {
      deliveries.add(() async {
        try {
          final lanUri = Uri.parse('http://$ip:$port/auth');
          await http
              .post(
                lanUri,
                headers: {'Content-Type': 'application/json'},
                body: outgoingJson,
              )
              .timeout(const Duration(milliseconds: 2200));
        } catch (_) {}
      }());
    }

    // 2. Global Cloud Relay Delivery (works across mobile data, NAT, tablets, desktop, and Chrome Extension)
    deliveries.add(() async {
      final relayUri = Uri.parse('https://ntfy.sh/terovpn_auth_$sessionId');
      try {
        await http
            .post(
              relayUri,
              headers: {'Content-Type': 'text/plain; charset=utf-8'},
              body: relayBody,
            )
            .timeout(const Duration(seconds: 4));
      } catch (_) {}
      // Send a second follow-up burst 600ms later so any reconnecting stream catches it reliably
      unawaited(Future.delayed(const Duration(milliseconds: 600), () async {
        try {
          await http
              .post(
                relayUri,
                headers: {'Content-Type': 'text/plain; charset=utf-8'},
                body: relayBody,
              )
              .timeout(const Duration(seconds: 3));
        } catch (_) {}
      }));
    }());

    // 3. Local In-Memory & File Authorization (for unit tests / same-device testing)
    deliveries.add(
      authorizeSession(
        sessionId,
        syncedAccount,
        password: effectivePassword,
        backupB64: backupB64,
      ),
    );

    await Future.wait(deliveries);
    return true;
  }

  /// In-memory and file authorization helper
  static Future<bool> authorizeSession(
    String sessionId,
    Account account, {
    String? password,
    String? backupB64,
  }) async {
    final session = _activeSessions[sessionId] ??
        QrPairingSession(
          sessionId: sessionId,
          deviceName: 'TeroVPN Device',
          createdAt: DateTime.now(),
          secretKey: generateSecureSecretKey(),
        );

    session.isAuthorized = true;
    session.account = account;
    if (password != null && password.isNotEmpty) {
      session.password = password;
    }
    if (backupB64 != null && backupB64.isNotEmpty) {
      session.backupB64 = backupB64;
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

    _activeStreamClients[sessionId]?.close();
    _activeStreamClients.remove(sessionId);

    _activeServers[sessionId]?.close(force: true);
    _activeServers.remove(sessionId);

    final pending = _pendingCompleters.remove(sessionId);
    if (pending != null && !pending.isCompleted) {
      pending.complete(null);
    }
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
