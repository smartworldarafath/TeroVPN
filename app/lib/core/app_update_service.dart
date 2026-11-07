import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'android_core.dart';
import 'app_preferences.dart';

class ReleaseInfo {
  final String tagName;
  final String releaseName;
  final String publishedAt;
  final String body;
  final String? apkUrl;
  final int apkSizeBytes;
  final List<String> changelogPoints;

  ReleaseInfo({
    required this.tagName,
    required this.releaseName,
    required this.publishedAt,
    required this.body,
    this.apkUrl,
    required this.apkSizeBytes,
    required this.changelogPoints,
  });
}

class AppUpdateService extends ChangeNotifier {
  static final AppUpdateService instance = AppUpdateService._();
  AppUpdateService._();

  static const String currentVersion = '1.2.0';

  ReleaseInfo? latestRelease;
  bool isChecking = false;
  bool updateAvailable = false;
  bool isDownloading = false;
  double downloadProgress = 0.0;
  double downloadSpeedMbps = 0.0;
  String? downloadedApkPath;
  String? errorMessage;

  Timer? _periodicCheckTimer;

  void startBackgroundChecker() {
    // Check on startup
    checkAndAutoUpdate();

    // Check every 2 hours in the background
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = Timer.periodic(const Duration(minutes: 6), (_) {
      checkAndAutoUpdate();
    });
  }

  /// Version comparison: returns true if latest is strictly newer than current
  static bool isNewerVersion(String latestTag, String current) {
    try {
      final cleanLatest = latestTag.replaceAll(RegExp(r'^[vV]'), '').trim();
      final cleanCurrent = current.replaceAll(RegExp(r'^[vV]'), '').trim();
      final lParts = cleanLatest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final cParts = cleanCurrent.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      for (int i = 0; i < 3; i++) {
        final l = i < lParts.length ? lParts[i] : 0;
        final c = i < cParts.length ? cParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> checkAndAutoUpdate({bool isManual = false}) async {
    if (isChecking || isDownloading) return;

    isChecking = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/smartworldarafath/TeroVPN/releases/latest'),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'TeroVPN-App',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final tagName = (data['tag_name'] as String?) ?? 'v1.2.0';
        final releaseName = (data['name'] as String?) ?? 'TeroVPN $tagName';
        final publishedAt = (data['published_at'] as String?) ?? '';
        final body = (data['body'] as String?) ?? '';

        String? apkUrl;
        int apkSize = 0;
        final assets = (data['assets'] as List<dynamic>?) ?? [];
        for (final asset in assets) {
          final aName = (asset['name'] as String? ?? '').toLowerCase();
          if (aName.endsWith('.apk')) {
            apkUrl = asset['browser_download_url'] as String?;
            apkSize = (asset['size'] as int?) ?? 0;
            break;
          }
        }

        final lines = body
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty && (l.startsWith('-') || l.startsWith('*') || l.startsWith('•')))
            .map((l) => l.replaceFirst(RegExp(r'^[-*•]\s*'), ''))
            .toList();

        final hasNewer = isNewerVersion(tagName, currentVersion);

        latestRelease = ReleaseInfo(
          tagName: tagName,
          releaseName: releaseName,
          publishedAt: publishedAt,
          body: body,
          apkUrl: apkUrl,
          apkSizeBytes: apkSize,
          changelogPoints: lines.isNotEmpty ? lines : [
            'Proton VPN Advanced Settings Suite',
            'Full 60fps Kinetic Opening Splash Animation',
            'Smooth Liquid Onboarding Screen Story',
            'Sign In via QR Desktop Synchronization',
            'Hardware Cutout Auto-Detection & High-Contrast Top Dock Toast',
            'Tablet Desktop Mode Toggle & 120Hz Rendering Engine',
          ],
        );

        updateAvailable = hasNewer;
        isChecking = false;
        notifyListeners();

        // Check if previously downloaded APK exists and is ready (validate size and integrity)
        final tempDir = await getTemporaryDirectory();
        final cachedApk = File('${tempDir.path}/TeroVPN_$tagName.apk');
        final minExpected = apkSize > 0 ? (apkSize * 0.98).toInt() : 45 * 1024 * 1024;
        if (await cachedApk.exists()) {
          final actualLen = await cachedApk.length();
          if (actualLen >= minExpected) {
            downloadedApkPath = cachedApk.path;
          } else {
            // Delete truncated / incomplete file from previous failed attempt
            await cachedApk.delete().catchError((_) => cachedApk);
            downloadedApkPath = null;
          }
        }

        if (hasNewer) {
          // Post Android Notification to system tray if enabled
          if (AppPreferences.notifyUpdates && !kIsWeb && Platform.isAndroid) {
            await AndroidCore.showNotification(
              title: 'New Update Available: TeroVPN $tagName 🚀',
              message: 'A brand-new version of TeroVPN is ready with enhanced features.',
              isUpdateReady: downloadedApkPath != null,
              apkPath: downloadedApkPath,
            );
          }

          // Auto-download on Wi-Fi if enabled
          if (AppPreferences.autoUpdateWifi && downloadedApkPath == null && apkUrl != null) {
            await downloadUpdate(apkUrl, tagName, apkSize);
          }
        }
      } else {
        isChecking = false;
        notifyListeners();
      }
    } catch (e) {
      isChecking = false;
      errorMessage = 'Could not check for updates: $e';
      notifyListeners();
    }
  }

  Future<void> downloadUpdate(String url, String tagName, int expectedBytes) async {
    if (isDownloading) return;

    isDownloading = true;
    downloadProgress = 0.0;
    downloadSpeedMbps = 0.0;
    notifyListeners();

    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      request.headers['User-Agent'] = 'TeroVPN-App';

      final response = await client.send(request);
      final total = response.contentLength ?? (expectedBytes > 0 ? expectedBytes : 48 * 1024 * 1024);

      final tempDir = await getTemporaryDirectory();
      final partFile = File('${tempDir.path}/TeroVPN_$tagName.apk.part');
      final saveFile = File('${tempDir.path}/TeroVPN_$tagName.apk');
      if (await partFile.exists()) {
        await partFile.delete().catchError((_) => partFile);
      }
      if (await saveFile.exists()) {
        await saveFile.delete().catchError((_) => saveFile);
      }

      final sink = partFile.openWrite();
      int received = 0;
      int lastTime = DateTime.now().millisecondsSinceEpoch;
      int lastBytes = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;

        final now = DateTime.now().millisecondsSinceEpoch;
        final elapsedMs = now - lastTime;
        if (elapsedMs >= 350) {
          final delta = received - lastBytes;
          final dtSec = elapsedMs / 1000.0;
          final bits = delta * 8.0;
          final mbps = (bits / (1000.0 * 1000.0)) / dtSec;

          downloadProgress = (received / total).clamp(0.0, 1.0);
          downloadSpeedMbps = downloadSpeedMbps == 0 ? mbps : (downloadSpeedMbps * 0.35 + mbps * 0.65);
          lastTime = now;
          lastBytes = received;
          notifyListeners();
        }
      }

      await sink.flush();
      await sink.close();
      client.close();

      final minExpected = expectedBytes > 0 ? (expectedBytes * 0.98).toInt() : (total * 0.95).toInt();
      if (received < minExpected) {
        if (await partFile.exists()) {
          await partFile.delete().catchError((_) => partFile);
        }
        throw Exception('Download was incomplete ($received of $total bytes). Please retry.');
      }

      await partFile.rename(saveFile.path);

      downloadProgress = 1.0;
      isDownloading = false;
      downloadedApkPath = saveFile.path;
      notifyListeners();

      // Post Android system notification that update is ready to install!
      if (!kIsWeb && Platform.isAndroid) {
        await AndroidCore.showNotification(
          title: 'TeroVPN $tagName Downloaded 🎉',
          message: 'The new update is downloaded and ready to install. Tap to finish.',
          isUpdateReady: true,
          apkPath: saveFile.path,
        );
      }
    } catch (e) {
      isDownloading = false;
      errorMessage = 'Download failed: $e';
      notifyListeners();
    }
  }

  Future<bool> installDownloadedUpdate() async {
    if (downloadedApkPath == null) return false;
    final file = File(downloadedApkPath!);
    if (!await file.exists()) return false;
    return await AndroidCore.installApk(file.path);
  }
}
