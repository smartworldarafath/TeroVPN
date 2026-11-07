import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terovpn/core/app_preferences.dart';
import 'package:terovpn/core/app_update_service.dart';
import 'package:terovpn/core/models.dart';
import 'package:terovpn/core/qr_auth_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
  });

  group('v1.2.0 Security Hardening Tests (Issue #1)', () {
    test('AppPreferences encrypts passwords with AES-256 and never writes plaintext', () async {
      const email = 'dummy.security.test@example.com';
      const plaintextPass = 'DUMMY_STRONG_PASSWORD_SECURE_99#';

      await AppPreferences.setSavedAccountPassword(email, plaintextPass);

      // Verify returned value is decrypted plaintext
      final retrieved = AppPreferences.getSavedAccountPassword(email);
      expect(retrieved, plaintextPass);

      // Verify underlying storage is encrypted with enc:v1 prefix
      final prefs = await SharedPreferences.getInstance();
      final storedRaw = prefs.getString('saved_auth_password_${email.toLowerCase()}');
      expect(storedRaw, isNotNull);
      expect(storedRaw!.startsWith('enc:v1:'), isTrue);
      expect(storedRaw.contains(plaintextPass), isFalse);

      // Verify legacy plaintext key was purged
      expect(prefs.containsKey('pwd_${email.toLowerCase()}'), isFalse);
    });

    test('AppPreferences can transparently read legacy plaintext passwords', () async {
      const legacyEmail = 'legacy.user@example.com';
      const legacyPass = 'DUMMY_LEGACY_PASS_123';
      SharedPreferences.setMockInitialValues({
        'pwd_${legacyEmail.toLowerCase()}': legacyPass,
      });
      await AppPreferences.init();

      final retrieved = AppPreferences.getSavedAccountPassword(legacyEmail);
      expect(retrieved, legacyPass);
    });

    test('QrAuthSyncService E2EE payload encryption and decryption with AES-256 & HMAC-SHA256', () {
      final secretKey = QrAuthSyncService.generateSecureSecretKey();
      expect(secretKey.isNotEmpty, isTrue);

      final plainMap = {
        'email': 'dummy.user@example.com',
        'password': 'DUMMY_MOCK_SECRET_PASS_456',
        'token': 'auth_test_token',
      };
      final plainJson = jsonEncode(plainMap);

      // Encrypt
      final envelope = QrAuthSyncService.encryptPayload(plainJson, secretKey);
      expect(envelope['e2ee'], isTrue);
      expect(envelope['cipher'], isNotNull);
      expect(envelope['iv'], isNotNull);
      expect(envelope['mac'], isNotNull);
      expect(envelope['cipher'].toString().contains('DUMMY_MOCK_SECRET_PASS_456'), isFalse);

      // Decrypt with correct key
      final decrypted = QrAuthSyncService.decryptPayload(envelope, secretKey);
      expect(decrypted, isNotNull);
      expect(decrypted!['email'], 'dummy.user@example.com');
      expect(decrypted['password'], 'DUMMY_MOCK_SECRET_PASS_456');

      // Decrypt with invalid key fails
      final wrongKey = QrAuthSyncService.generateSecureSecretKey();
      final failedDecryption = QrAuthSyncService.decryptPayload(envelope, wrongKey);
      expect(failedDecryption, isNull);

      // Tampered cipher fails MAC validation
      final tamperedEnvelope = Map<String, dynamic>.from(envelope);
      tamperedEnvelope['cipher'] = 'dGFtcGVyZWQ=';
      expect(QrAuthSyncService.decryptPayload(tamperedEnvelope, secretKey), isNull);
    });

    test('AndroidManifest.xml enforce allowBackup=false and removes QUERY_ALL_PACKAGES', () {
      final manifestFile = File('android/app/src/main/AndroidManifest.xml');
      expect(manifestFile.existsSync(), isTrue);
      final manifest = manifestFile.readAsStringSync();

      expect(manifest.contains('android:allowBackup="false"'), isTrue);
      expect(manifest.contains('android.permission.QUERY_ALL_PACKAGES'), isFalse);
      expect(manifest.contains('<queries>'), isTrue);
      expect(manifest.contains('android.intent.action.MAIN'), isTrue);
    });

    test('Backup rules exclude sharedpref from extraction and cloud backup', () {
      final backupRules = File('android/app/src/main/res/xml/backup_rules.xml').readAsStringSync();
      expect(backupRules.contains('<exclude domain="sharedpref" path="."'), isTrue);

      final dataExtraction = File('android/app/src/main/res/xml/data_extraction_rules.xml').readAsStringSync();
      expect(dataExtraction.contains('<exclude domain="sharedpref" path="."'), isTrue);
    });

    test('Desktop CI workflow includes SHA256 integrity verification for all binaries', () {
      final workflow = File('../.github/workflows/desktop.yml').readAsStringSync();
      expect(workflow.contains('77BF4CC7BD6D57C7F4B8EE228F15AE09748DAD4F3E6841D21ED57E3ABF49A157'), isTrue);
      expect(workflow.contains('5f3cbfb1aa19c6659e53ddba52015092f85e5f799012ad174ee494c00b74d66d'), isTrue);
      expect(workflow.contains('1cc7ce4a10c1f1a69b6a454fb738b95a29cccded40a041cf8b1305d68b165266'), isTrue);
    });
  });

  group('v1.2.0 Mozilla Sign In Flow Tests (Issue #2)', () {
    test('SignInStep supports needEmailLink and secondary verification steps', () {
      expect(SignInStep.needEmailLink, 'need_email_link');
      expect(SignInStep.needUnblockCode, 'need_unblock_code');
      expect(SignInStep.needTotp, 'need_totp');
      expect(SignInStep.needCaptcha, 'need_captcha');
    });

    test('SignInState correctly identifies steps requiring user keyboard input', () {
      final emailCodeState = SignInState.fromJson({'id': '1', 'step': 'need_email_code'});
      expect(emailCodeState.needsAnswer, isTrue);

      final unblockCodeState = SignInState.fromJson({'id': '2', 'step': 'need_unblock_code'});
      expect(unblockCodeState.needsAnswer, isTrue);

      final totpState = SignInState.fromJson({'id': '3', 'step': 'need_totp'});
      expect(totpState.needsAnswer, isTrue);

      final captchaState = SignInState.fromJson({'id': '4', 'step': 'need_captcha'});
      expect(captchaState.needsAnswer, isTrue);

      final emailLinkState = SignInState.fromJson({'id': '5', 'step': 'need_email_link'});
      expect(emailLinkState.needsAnswer, isFalse);
      expect(emailLinkState.finished, isFalse);
    });

    test('SignInError maps all Mozilla failure codes', () {
      expect(SignInError.unblockCodeRejected, 'unblock_code_rejected');
      expect(SignInError.tooManyCodes, 'too_many_codes');
      expect(SignInError.timedOut, 'timed_out');
      expect(SignInError.wrongPassword, 'wrong_password');
      expect(SignInError.wrongCode, 'wrong_code');
    });
  });

  group('v1.2.0 Phone-to-Phone and Tablet QR Sync Tests', () {
    test('QR pairing session encodes secret key and local network endpoints in URI', () async {
      final session = await QrAuthSyncService.createSessionAsync(deviceName: 'TeroVPN Mobile');
      expect(session.secretKey.isNotEmpty, isTrue);
      expect(session.localPort, greaterThan(0));

      final uriString = QrAuthSyncService.generateSessionPayload(
        session.sessionId,
        localIp: session.localIp,
        port: session.localPort,
        secretKey: session.secretKey,
      );

      final uri = Uri.parse(uriString);
      expect(uri.scheme, 'terovpn');
      expect(uri.host, 'pair');
      expect(uri.queryParameters['sid'], session.sessionId);
      expect(uri.queryParameters['k'], session.secretKey);
      expect(uri.queryParameters['port'], session.localPort.toString());

      QrAuthSyncService.cancelSession(session.sessionId);
    });

    test('Cross-device round-trip authorization delivers credentials and persists them', () async {
      // 1. Tablet displays QR
      final tabletSession = await QrAuthSyncService.createSessionAsync(deviceName: 'TeroVPN Tablet');
      final waitFuture = QrAuthSyncService.waitForAuthorization(
        tabletSession.sessionId,
        timeout: const Duration(seconds: 5),
      );

      // 2. Phone scans QR code
      final uri = Uri.parse(QrAuthSyncService.generateSessionPayload(
        tabletSession.sessionId,
        localIp: tabletSession.localIp,
        port: tabletSession.localPort,
        secretKey: tabletSession.secretKey,
      ));

      final phoneAccount = Account(
        id: 'acc_phone_1',
        email: 'tablet.sync.user@example.com',
        name: 'Phone User',
        password: 'DUMMY_MOCK_PASSWORD_SYNC_99',
      );

      // 3. Phone authorizes session with secret key
      final authorized = await QrAuthSyncService.authorizeRemoteSession(
        sessionId: uri.queryParameters['sid']!,
        account: phoneAccount,
        password: 'DUMMY_MOCK_PASSWORD_SYNC_99',
        ip: uri.queryParameters['ip'],
        port: int.tryParse(uri.queryParameters['port'] ?? '0'),
        secretKey: uri.queryParameters['k'],
      );
      expect(authorized, isTrue);

      // 4. Tablet receives authorization
      final received = await waitFuture;
      expect(received, isNotNull);
      expect(received!.email, 'tablet.sync.user@example.com');
      expect(received.password, 'DUMMY_MOCK_PASSWORD_SYNC_99');

      // 5. Tablet persists account and encrypted password
      await AppPreferences.setSavedActiveAccount(received.toJson());
      await AppPreferences.setSavedAccountPassword(received.email, received.password!);

      expect(AppPreferences.savedActiveAccount, isNotNull);
      expect(AppPreferences.savedActiveAccount!['email'], 'tablet.sync.user@example.com');
      expect(AppPreferences.getSavedAccountPassword('tablet.sync.user@example.com'), 'DUMMY_MOCK_PASSWORD_SYNC_99');

      QrAuthSyncService.cancelSession(tabletSession.sessionId);
    });
  });

  group('v1.2.0 Version Bumping Consistency Tests', () {
    test('All configuration and code references report v1.2.0', () {
      expect(AppUpdateService.currentVersion, '1.2.0');

      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec.contains('version: 1.2.0+20'), isTrue);

      final iss = File('../windows/installer/terovpn_setup.iss').readAsStringSync();
      expect(iss.contains('MyAppVersion "1.2.0"'), isTrue);
      expect(iss.contains('TeroVPN-v1.2.0-Windows-Setup'), isTrue);

      final workflow = File('../.github/workflows/desktop.yml').readAsStringSync();
      expect(workflow.contains('APP_VERSION=1.2.0'), isTrue);
      expect(workflow.contains('TeroVPN-v1.2.0-Windows-x64'), isTrue);
    });
  });
}
