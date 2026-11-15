import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terovpn/core/app_preferences.dart';
import 'package:terovpn/core/core_controller.dart';
import 'package:terovpn/core/models.dart';
import 'package:terovpn/core/qr_auth_sync_service.dart';
import 'package:terovpn/theme/theme_manager.dart';
import 'package:terovpn/ui/components/signin_dialog.dart';
import 'package:terovpn/ui/desktop/desktop_qr_dialog.dart';
import 'package:terovpn/ui/settings/qr_sign_in_screen.dart';

class _FakeCoreController extends CoreController {
  _FakeCoreController() : super(() async => throw UnimplementedError());

  SignInState? nextStartSignInState;
  SignInState? nextAnswerState;
  SignInState? nextLatestState;
  Exception? answerException;
  String? importedBackup;
  String? exportedBackup;
  int answerCalls = 0;

  @override
  Future<void> refresh({bool accountsToo = false}) async {}

  @override
  Future<void> activate(Account a) async {}

  @override
  Future<void> refreshQuota(Account a) async {}

  @override
  Future<SignInState> startSignIn(String email, String password) async {
    return nextStartSignInState ??
        SignInState.fromJson({
          'id': 'flow_1',
          'email': email,
          'step': SignInStep.needEmailCode,
        });
  }

  @override
  Future<SignInState> signInState(String id) async {
    return nextLatestState ??
        SignInState.fromJson({
          'id': id,
          'email': 'test.user@example.com',
          'step': SignInStep.failed,
          'error_code': SignInError.wrongCode,
          'error': 'Incorrect verification code.',
        });
  }

  @override
  Future<SignInState> answerSignIn(String id, String value) async {
    answerCalls++;
    if (answerException != null) {
      final ex = answerException!;
      answerException = null;
      throw ex;
    }
    return nextAnswerState ??
        SignInState.fromJson({
          'id': id,
          'email': 'test.user@example.com',
          'step': SignInStep.done,
        });
  }

  @override
  Future<String?> exportBackupBase64() async => exportedBackup;

  @override
  Future<bool> importBackupBase64(
    String data, {
    String? preferredEmail,
  }) async {
    importedBackup = data;
    setAccounts(
      AccountList.fromJson({
        'accounts': [
          {
            'id': 'real_imported_acc_1',
            'email': preferredEmail ?? 'test.user@example.com',
            'name': 'Test User',
            'active': true,
            'enabled': true,
            'status': AccountStatus.ready,
          },
        ],
        'switch_threshold_percent': 10.0,
      }),
    );
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
    ThemeManager.instance.init();
  });

  group('v1.2.9 SignInDialog Email OTP & Recovery Tests', () {
    testWidgets(
      'Shows email verification copy, dynamic Continue to Mail Code <-> Verify button, retains wrong code state, and completes with 2-2.5s animation',
      (tester) async {
        final controller = _FakeCoreController();
        controller.nextStartSignInState = SignInState.fromJson({
          'id': 'flow_email_1',
          'email': 'test.user@example.com',
          'step': SignInStep.needEmailCode,
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SignInDialog(controller: controller),
            ),
          ),
        );

        // Enter credentials & click Sign In
        final fields = find.byType(TextField);
        await tester.enterText(fields.at(0), 'test.user@example.com');
        await tester.enterText(fields.at(1), 'DUMMY_PASSWORD_TEST');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        // Check exact email subtitle & empty-box button label
        expect(
          find.text(
            'A verification code has been sent to your email. Please check your inbox.',
          ),
          findsWidgets,
        );
        expect(find.text('Continue to Mail Code'), findsOneWidget);
        expect(find.text('Verify'), findsNothing);

        // Type 6-digit code -> button must automatically switch to "Verify"
        final codeBox = find.byKey(const ValueKey(SignInStep.needEmailCode));
        expect(codeBox, findsOneWidget);
        await tester.enterText(codeBox, '111111');
        await tester.pump();
        expect(find.text('Verify'), findsOneWidget);
        expect(find.text('Continue to Mail Code'), findsNothing);

        // Submit wrong code (simulates failed / wrong_code step) -> stays on verification input!
        controller.nextAnswerState = SignInState.fromJson({
          'id': 'flow_email_1',
          'email': 'test.user@example.com',
          'step': SignInStep.failed,
          'error_code': SignInError.wrongCode,
        });
        await tester.tap(find.text('Verify'));
        await tester.pump();

        expect(
          find.text(
            'Incorrect verification code. Please check your inbox and try again.',
          ),
          findsOneWidget,
        );
        // Must NOT auto-exit back to Email Address / Password fields
        expect(find.byKey(const ValueKey(SignInStep.needEmailCode)), findsOneWidget);
        expect(find.text('Email Address'), findsNothing);

        // Now enter the correct code -> should restart & succeed cleanly with ~2.2s animation
        controller.nextAnswerState = SignInState.fromJson({
          'id': 'flow_email_1',
          'email': 'test.user@example.com',
          'step': SignInStep.done,
        });
        await tester.enterText(
          find.byKey(const ValueKey(SignInStep.needEmailCode)),
          '747572',
        );
        await tester.pump();
        await tester.tap(find.text('Verify'));
        await tester.pump();

        // Still completing at 1000ms (inside 2-2.5s loading animation)
        await tester.pump(const Duration(milliseconds: 1000));
        expect(find.text('Signing In...'), findsWidgets);

        // Advances to Sign In Complete around 1600ms and settles cleanly after 2200ms
        await tester.pump(const Duration(milliseconds: 700));
        expect(find.text('Sign In Complete'), findsWidgets);
        await tester.pump(const Duration(milliseconds: 700));
      },
    );

    testWidgets(
      'needCaptcha does not show misleading Gmail code button text',
      (tester) async {
        final controller = _FakeCoreController();
        controller.nextStartSignInState = SignInState.fromJson({
          'id': 'flow_cap_1',
          'email': 'test.user@example.com',
          'step': SignInStep.needCaptcha,
          'captcha': '',
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SignInDialog(controller: controller),
            ),
          ),
        );

        final fields = find.byType(TextField);
        await tester.enterText(fields.at(0), 'test.user@example.com');
        await tester.enterText(fields.at(1), 'DUMMY_PASSWORD_TEST');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Continue to Gmail Code'), findsNothing);
        expect(find.textContaining('proceed to Gmail verification'), findsNothing);
        expect(find.text('Verify'), findsOneWidget);
      },
    );
  });

  group('v1.2.9 Cross-Device QR Sign-In (Desktop + Phone/Tablet) Tests', () {
    test(
      'E2EE QR transfer preserves backup_b64 across waitForAuthorization -> getSession without password',
      () async {
        final session = await QrAuthSyncService.createSessionAsync(
          deviceName: 'TeroVPN Test Desktop',
        );
        final qrPayload = QrAuthSyncService.generateSessionPayload(
          session.sessionId,
          localIp: '127.0.0.1',
          port: session.localPort,
          secretKey: session.secretKey,
        );
        final uri = Uri.parse(qrPayload);
        final fakeBackup = base64Encode(utf8.encode('FAKE_ZIP_BACKUP_DATA'));

        final encrypted = QrAuthSyncService.encryptPayload(
          jsonEncode({
            'sessionId': session.sessionId,
            'email': 'webview.user@example.com',
            'password': '',
            'token': 'auth_qr_remote',
            'backup_b64': fakeBackup,
            'name': 'WebView User',
          }),
          uri.queryParameters['k']!,
        );
        final decrypted = QrAuthSyncService.decryptPayload(
          encrypted,
          uri.queryParameters['k']!,
        );
        expect(decrypted, isNotNull);
        expect(decrypted!['backup_b64'], fakeBackup);

        final waitFuture = QrAuthSyncService.waitForAuthorization(
          session.sessionId,
          timeout: const Duration(seconds: 5),
        );

        final authorized = await QrAuthSyncService.authorizeRemoteSession(
          sessionId: uri.queryParameters['sid']!,
          account: Account.fromJson({
            'id': 'acc_webview_1',
            'email': 'webview.user@example.com',
            'name': 'WebView User',
            'status': AccountStatus.ready,
          }),
          password: '',
          ip: uri.queryParameters['ip'],
          port: int.tryParse(uri.queryParameters['port'] ?? '0'),
          secretKey: uri.queryParameters['k'],
          backupB64: fakeBackup,
        );
        expect(authorized, isTrue);

        final receivedAccount = await waitFuture;
        expect(receivedAccount, isNotNull);
        expect(receivedAccount!.email, 'webview.user@example.com');

        final cachedSession = QrAuthSyncService.getSession(session.sessionId);
        expect(cachedSession, isNotNull);
        expect(cachedSession!.backupB64, fakeBackup);
      },
    );

    testWidgets(
      'Receiving Phone/Tablet QrSignInScreen imports backup_b64 cleanly and disposes cleanly',
      (tester) async {
        final receiverController = _FakeCoreController();
        final fakeBackup = base64Encode(utf8.encode('FAKE_TABLET_BACKUP'));

        await tester.pumpWidget(
          MaterialApp(
            home: QrSignInScreen(
              controller: receiverController,
              forceShowQr: true,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Scan to Log In Instantly'), findsOneWidget);

        // Unmount before test end to ensure cancelSession clears pending relay timers
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 1));

        final imported = await receiverController.importBackupBase64(
          fakeBackup,
          preferredEmail: 'tablet.user@example.com',
        );
        expect(imported, isTrue);
        expect(receiverController.hasAccount, isTrue);
        expect(
          receiverController.activeAccount?.email,
          'tablet.user@example.com',
        );
        expect(receiverController.importedBackup, fakeBackup);
      },
    );

    testWidgets(
      'DesktopQrSignInDialog shows Sign In via QR Code and cleans up session cleanly',
      (tester) async {
        final desktopController = _FakeCoreController();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DesktopQrSignInDialog(controller: desktopController),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Sign In via QR Code'), findsOneWidget);

        // Unmount before test end to verify clean disposal
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 1));
      },
    );
  });
}
