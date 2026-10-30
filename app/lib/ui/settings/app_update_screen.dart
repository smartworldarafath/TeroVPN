import '../components/liquid_glass_card.dart';
import '../components/top_dock_toast.dart';
import '../components/liquid_glass_atmosphere.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../theme/proton_typography.dart';
import '../../theme/theme_manager.dart';
import '../../core/app_preferences.dart';
import '../../core/android_core.dart';
import 'settings_row.dart';

class AppUpdateScreen extends StatefulWidget {
  const AppUpdateScreen({super.key});

  @override
  State<AppUpdateScreen> createState() => _AppUpdateScreenState();
}

class _AppUpdateScreenState extends State<AppUpdateScreen> {
  static const String currentVersion = '1.1.1';

  late bool _autoUpdateWifi;
  late bool _allowUpdateMobile;
  late bool _notifyUpdates;

  bool _isChecking = true;
  bool _updateAvailable = false;
  String? _errorMessage;

  String _latestVersionTag = 'v1.0.8';
  String _latestReleaseName = 'TeroVPN v1.0.8';
  String _releaseDate = 'October 2026';
  List<String> _changelogPoints = [];
  bool _isVersionInfoExpanded = false;
  String? _downloadUrl;
  int _apkSizeBytes = 0;

  // Download state
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  double _downloadSpeedMbps = 0.0;
  int _receivedBytes = 0;
  int _totalBytes = 0;
  String? _downloadedFilePath;
  bool _isInstallReady = false;

  StreamSubscription? _downloadSub;
  http.Client? _httpClient;

  @override
  void initState() {
    super.initState();
    _autoUpdateWifi = AppPreferences.autoUpdateWifi;
    _allowUpdateMobile = AppPreferences.allowUpdateMobile;
    _notifyUpdates = AppPreferences.notifyUpdates;
    _fetchLatestRelease();
  }

  @override
  void dispose() {
    _downloadSub?.cancel();
    _httpClient?.close();
    super.dispose();
  }

  /// Version comparison: returns true if latest is strictly newer than current
  bool _isNewerVersion(String latestTag, String current) {
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

  Future<void> _fetchLatestRelease() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

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
        final tagName = (data['tag_name'] as String?) ?? 'v1.0.7';
        final releaseName = (data['name'] as String?) ?? 'TeroVPN $tagName';
        final publishedAt = (data['published_at'] as String?) ?? '';
        final body = (data['body'] as String?) ?? '';

        // Parse assets for APK
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

        // Parse body into bullet points
        final lines = body
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty && (l.startsWith('-') || l.startsWith('*') || l.startsWith('•')))
            .map((l) => l.replaceFirst(RegExp(r'^[-*•]\s*'), ''))
            .toList();

        final isNewer = _isNewerVersion(tagName, currentVersion);

        if (mounted) {
          setState(() {
            _latestVersionTag = tagName;
            _latestReleaseName = releaseName;
            _downloadUrl = apkUrl;
            _apkSizeBytes = apkSize;
            _changelogPoints = lines.isNotEmpty
                ? lines
                : [
                    'MASQUE HTTP/3 & HTTP/2 Dual-Engine Stability Upgrades',
                    'Proton UI & Liquid Glass Next-Gen Design System',
                    'Realtime Download Speed Monitor & Native Package Installer',
                    'Multi-Account Firefox Token Pool Optimization',
                    'Low Latency Gaming & Secure Streaming Routing Improvements',
                  ];
            if (publishedAt.isNotEmpty) {
              try {
                final date = DateTime.parse(publishedAt);
                _releaseDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
              } catch (_) {
                _releaseDate = 'October 2026';
              }
            }
            _updateAvailable = isNewer;
            _isChecking = false;
          });
        }
      } else {
        // Fallback or rate limited
        if (mounted) {
          setState(() {
            _isChecking = false;
            _updateAvailable = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _errorMessage = 'Could not check for updates. Please verify your connection.';
        });
      }
    }
  }

  Future<void> _startDownload() async {
    final url = _downloadUrl ?? 'https://github.com/smartworldarafath/TeroVPN/releases/download/$_latestVersionTag/TeroVPN-Android-$_latestVersionTag.apk';

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadSpeedMbps = 0.0;
      _receivedBytes = 0;
      _totalBytes = _apkSizeBytes;
      _isInstallReady = false;
    });

    try {
      _httpClient = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      request.headers['User-Agent'] = 'TeroVPN-App';

      final response = await _httpClient!.send(request);
      if (response.statusCode >= 400) {
        throw Exception('Download failed with status ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? _apkSizeBytes;
      setState(() => _totalBytes = contentLength > 0 ? contentLength : 48 * 1024 * 1024);

      final tempDir = await getTemporaryDirectory();
      final saveFile = File('${tempDir.path}/TeroVPN_$_latestVersionTag.apk');
      if (await saveFile.exists()) {
        await saveFile.delete();
      }
      final sink = saveFile.openWrite();

      int lastTime = DateTime.now().millisecondsSinceEpoch;
      int lastBytes = 0;

      await for (final chunk in response.stream) {
        if (!mounted || !_isDownloading) break;
        sink.add(chunk);
        _receivedBytes += chunk.length;

        final now = DateTime.now().millisecondsSinceEpoch;
        final elapsedMs = now - lastTime;

        if (elapsedMs >= 350) {
          final deltaBytes = _receivedBytes - lastBytes;
          final dtSec = elapsedMs / 1000.0;
          final bits = deltaBytes * 8.0;
          final currentMbps = (bits / (1000.0 * 1000.0)) / dtSec;

          setState(() {
            _downloadProgress = _totalBytes > 0 ? (_receivedBytes / _totalBytes).clamp(0.0, 1.0) : 0.0;
            _downloadSpeedMbps = _downloadSpeedMbps == 0 ? currentMbps : (_downloadSpeedMbps * 0.35 + currentMbps * 0.65);
          });
          lastTime = now;
          lastBytes = _receivedBytes;
        }
      }

      await sink.flush();
      await sink.close();

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 1.0;
          _isInstallReady = true;
          _downloadedFilePath = saveFile.path;
        });

        // Trigger installation directly upon download complete
        await _triggerInstall();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        TopDockToast.show(
          context,
          title: 'Download Failed',
          message: '$e',
          icon: Icons.error_outline_rounded,
          iconColor: Colors.redAccent,
        );
      }
    }
  }

  Future<void> _triggerInstall() async {
    if (_downloadedFilePath == null) return;
    try {
      final success = await AndroidCore.installApk(_downloadedFilePath!);
      if (!success && mounted) {
        TopDockToast.show(
          context,
          title: 'Installing Update',
          message: 'Installation package launched. Confirm prompt.',
          icon: Icons.system_update_rounded,
        );
      }
    } catch (e) {
      if (mounted) {
        TopDockToast.show(
          context,
          title: 'Install Error',
          message: '$e',
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.orangeAccent,
        );
      }
    }
  }

  void _showBetaDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeManager.instance.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: ThemeManager.instance.cardBorderColor),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6B42FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.science_outlined,
                color: Color(0xFF6B42FF),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Join Beta Program',
              style: ProtonTypography.titleMedium.copyWith(
                fontSize: 18,
                color: ThemeManager.instance.textPrimaryColor,
              ),
            ),
          ],
        ),
        content: Text(
          'This feature is currently under active development and will be available very soon.',
          style: ProtonTypography.bodyMedium.copyWith(
            color: ThemeManager.instance.textSecondaryColor,
            height: 1.4,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B42FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  String _formatMB(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, _) {
        final isLiquid = ThemeManager.instance.isLiquidGlass;
        final isDark = ThemeManager.instance.isDarkMode;

        return LiquidGlassAtmosphere(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'App Update',
              style: ProtonTypography.titleLarge.copyWith(
                fontSize: 22,
                color: ThemeManager.instance.textPrimaryColor,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: ThemeManager.instance.textPrimaryColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: _isChecking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6B42FF)),
                      )
                    : Icon(Icons.refresh_rounded, color: ThemeManager.instance.textSecondaryColor),
                tooltip: 'Check for Updates',
                onPressed: _isChecking || _isDownloading ? null : _fetchLatestRelease,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Stack(
            children: [
              // Background Atmospheric Glow (Dark mode only)
              if (isDark)
                Positioned(
                  top: -40,
                  left: 0,
                  right: 0,
                  height: 300,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.4),
                          radius: 1.1,
                          colors: [
                            isLiquid
                                ? const Color(0xFF7E1C33).withValues(alpha: 0.32)
                                : const Color(0xFFDC3251).withValues(alpha: 0.15),
                            isLiquid
                                ? const Color(0xFF4B237C).withValues(alpha: 0.25)
                                : const Color(0xFF6D4AFF).withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : const Color(0xFFB00020),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // State 1: Checking
                      if (_isChecking)
                        _buildCheckingCard(isLiquid)
                      // State 2: Update Available
                      else if (_updateAvailable)
                        _buildUpdateAvailableCard(isLiquid)
                      // State 3: Up To Date
                      else
                        _buildUpToDateCard(isLiquid),

                      const SizedBox(height: 24),

                      // WHAT'S NEW Section Header with Expand / Collapse
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8, right: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "WHAT'S NEW IN $_latestVersionTag",
                              style: ProtonTypography.labelSmall.copyWith(
                                color: ThemeManager.instance.textSecondaryColor,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _isVersionInfoExpanded = !_isVersionInfoExpanded;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6B42FF).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _isVersionInfoExpanded ? 'Collapse' : 'Expand',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF6B42FF),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      _isVersionInfoExpanded
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      size: 16,
                                      color: const Color(0xFF6B42FF),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      LiquidGlassCard(
                        radius: 20,
                        padding: const EdgeInsets.all(18),
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOutCubic,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...(_isVersionInfoExpanded
                                      ? _changelogPoints
                                      : _changelogPoints.take(4))
                                  .map((point) => _buildBulletPoint(point)),
                              if (!_isVersionInfoExpanded && _changelogPoints.length > 4) ...[
                                const SizedBox(height: 8),
                                Center(
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _isVersionInfoExpanded = true;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '+ ${_changelogPoints.length - 4} more points',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF6B42FF),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            size: 18,
                                            color: Color(0xFF6B42FF),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // PREFERENCES & SETTINGS Section
                      SettingsSectionCard(
                        title: 'PREFERENCES & SETTINGS',
                        children: [
                          SettingsRow(
                            icon: Icons.wifi_rounded,
                            title: 'Auto-update over Wi-Fi',
                            subtitle: 'Automatically download package on Wi-Fi',
                            trailing: Switch(
                              value: _autoUpdateWifi,
                              activeThumbColor: const Color(0xFF6B42FF),
                              onChanged: (val) {
                                setState(() => _autoUpdateWifi = val);
                                AppPreferences.setAutoUpdateWifi(val);
                              },
                            ),
                          ),
                          SettingsRow(
                            icon: Icons.signal_cellular_alt_rounded,
                            title: 'Allow updates over mobile data',
                            subtitle: 'Download updates using cellular network',
                            trailing: Switch(
                              value: _allowUpdateMobile,
                              activeThumbColor: const Color(0xFF6B42FF),
                              onChanged: (val) {
                                setState(() => _allowUpdateMobile = val);
                                AppPreferences.setAllowUpdateMobile(val);
                              },
                            ),
                          ),
                          SettingsRow(
                            icon: Icons.notifications_active_outlined,
                            title: 'Notify me when updates are available',
                            subtitle: 'Push alert for critical security releases',
                            trailing: Switch(
                              value: _notifyUpdates,
                              activeThumbColor: const Color(0xFF6B42FF),
                              onChanged: (val) {
                                setState(() => _notifyUpdates = val);
                                AppPreferences.setNotifyUpdates(val);
                                if (val) {
                                  AndroidCore.askNotifications();
                                }
                              },
                            ),
                          ),
                          SettingsRow(
                            icon: Icons.science_outlined,
                            title: 'Join Beta Program',
                            subtitle: 'Try preview features & early builds',
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6B42FF).withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFF6B42FF).withValues(alpha: 0.4),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: const Text(
                                    'BETA',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF6B42FF),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: ThemeManager.instance.textMutedColor,
                                  size: 20,
                                ),
                              ],
                            ),
                            onTap: _showBetaDialog,
                          ),
                        ],
                      ),

                      // ABOUT UPDATE Section
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'ABOUT UPDATE',
                          style: ProtonTypography.labelSmall.copyWith(
                            color: ThemeManager.instance.textSecondaryColor,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      LiquidGlassCard(
                        radius: 20,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Release channel: Official GitHub Releases',
                              style: ProtonTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: ThemeManager.instance.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Release date: $_releaseDate',
                              style: ProtonTypography.bodySmall.copyWith(
                                color: ThemeManager.instance.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Repository: smartworldarafath/TeroVPN',
                              style: ProtonTypography.bodySmall.copyWith(
                                color: ThemeManager.instance.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  Widget _buildCheckingCard(bool isLiquid) {
    return LiquidGlassCard(
      radius: 20,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF6B42FF)),
          ),
          const SizedBox(width: 16),
          Text(
            'Checking GitHub for newer releases...',
            style: TextStyle(
              color: ThemeManager.instance.textPrimaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpToDateCard(bool isLiquid) {
    return LiquidGlassCard(
      radius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF00C853).withValues(alpha: 0.3)),
                ),
                child: const Center(
                  child: Icon(Icons.verified_rounded, color: Color(0xFF00C853), size: 32),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You are up to date!',
                      style: ProtonTypography.titleMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: ThemeManager.instance.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version $currentVersion (Latest build)',
                      style: ProtonTypography.bodySmall.copyWith(
                        color: const Color(0xFF00C853),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'All security protocols and features are current',
                      style: ProtonTypography.bodySmall.copyWith(
                        color: ThemeManager.instance.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Test download or check update button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _isChecking ? null : _fetchLatestRelease,
              icon: const Icon(Icons.sync_rounded, size: 18),
              label: const Text('Check Again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6B42FF),
                side: const BorderSide(color: Color(0xFF6B42FF), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateAvailableCard(bool isLiquid) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeManager.instance.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6B42FF).withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B42FF).withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B42FF),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6B42FF).withValues(alpha: 0.5),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.shield_rounded, color: Colors.white, size: 34),
                    ),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6B42FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_outward_rounded, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Update Available!',
                      style: ProtonTypography.titleMedium.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: ThemeManager.instance.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_latestReleaseName${_apkSizeBytes > 0 ? " (${_formatMB(_apkSizeBytes)})" : ""}',
                      style: ProtonTypography.bodySmall.copyWith(
                        color: ThemeManager.instance.textPrimaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your current version: $currentVersion',
                      style: ProtonTypography.bodySmall.copyWith(
                        color: ThemeManager.instance.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Download progress or action button
          if (_isDownloading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _downloadProgress > 0 ? _downloadProgress : null,
                minHeight: 8,
                backgroundColor: ThemeManager.instance.dividerColor,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6B42FF)),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_formatMB(_receivedBytes)} / ${_formatMB(_totalBytes)} (${(_downloadProgress * 100).toStringAsFixed(0)}%)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ThemeManager.instance.textPrimaryColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B42FF).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_downloadSpeedMbps.toStringAsFixed(1)} Mbps',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF00E676),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (_isInstallReady) ...[
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _triggerInstall,
                icon: const Icon(Icons.install_mobile_rounded),
                label: const Text('Install Update'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _startDownload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B42FF),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'Download & Install',
                  style: ProtonTypography.labelLarge.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: ThemeManager.instance.textPrimaryColor, fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: ProtonTypography.bodyMedium.copyWith(
                color: ThemeManager.instance.textPrimaryColor,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
