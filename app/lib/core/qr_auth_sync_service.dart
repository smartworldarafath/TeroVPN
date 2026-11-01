import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'models.dart';

class QrPairingSession {
  final String sessionId;
  final String deviceName;
  final DateTime createdAt;
  bool isAuthorized;
  Account? account;

  QrPairingSession({
    required this.sessionId,
    required this.deviceName,
    required this.createdAt,
    this.isAuthorized = false,
    this.account,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'deviceName': deviceName,
        'createdAt': createdAt.toIso8601String(),
        'isAuthorized': isAuthorized,
        if (account != null) 'account': account!.toJson(),
      };

  factory QrPairingSession.fromJson(Map<String, dynamic> json) => QrPairingSession(
        sessionId: json['sessionId'] as String,
        deviceName: json['deviceName'] as String? ?? 'TeroVPN Desktop',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        isAuthorized: json['isAuthorized'] as bool? ?? false,
        account: json['account'] != null ? Account.fromJson(json['account'] as Map<String, dynamic>) : null,
      );
}

/// Realtime QR-based authorization synchronization service between phone and desktop
class QrAuthSyncService {
  static final Map<String, QrPairingSession> _activeSessions = {};
  static final Map<String, Completer<Account>> _pendingCompleters = {};

  static String generateSessionPayload(String sessionId) {
    return 'terovpn://pair?sid=$sessionId&device=TeroVPN_Desktop&t=${DateTime.now().millisecondsSinceEpoch}';
  }

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
    return session;
  }

  static Future<Account?> waitForAuthorization(String sessionId, {Duration timeout = const Duration(minutes: 5)}) async {
    final completer = _pendingCompleters[sessionId];
    if (completer == null) return null;

    // Check file-based sync in background
    Timer.periodic(const Duration(milliseconds: 600), (timer) async {
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
      return await completer.future.timeout(timeout);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> authorizeSession(String sessionId, Account account) async {
    final session = _activeSessions[sessionId] ??
        QrPairingSession(
          sessionId: sessionId,
          deviceName: 'TeroVPN Desktop',
          createdAt: DateTime.now(),
        );

    session.isAuthorized = true;
    session.account = account;
    _activeSessions[sessionId] = session;

    if (_pendingCompleters.containsKey(sessionId) && !_pendingCompleters[sessionId]!.isCompleted) {
      _pendingCompleters[sessionId]!.complete(account);
    }

    await _saveSessionToFile(session);
    return true;
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
