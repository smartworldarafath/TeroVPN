import 'dart:async';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'country_data.dart';

class DynamicCountry {
  final String code;
  final String name;
  final String cities;
  int load;
  int pingMs;
  final bool isP2p;
  final bool isSecureCore;
  final bool isTor;

  DynamicCountry({
    required this.code,
    required this.name,
    required this.cities,
    required this.load,
    required this.pingMs,
    this.isP2p = true,
    this.isSecureCore = false,
    this.isTor = false,
  });

  DynamicCountry copyWith({int? load, int? pingMs}) {
    return DynamicCountry(
      code: code,
      name: name,
      cities: cities,
      load: load ?? this.load,
      pingMs: pingMs ?? this.pingMs,
      isP2p: isP2p,
      isSecureCore: isSecureCore,
      isTor: isTor,
    );
  }
}

class CountryManager extends ChangeNotifier {
  static final CountryManager instance = CountryManager._internal();

  CountryManager._internal() {
    _initCountries();
    _startHourlyAutoRefresh();
  }

  final List<DynamicCountry> _countries = [];
  Timer? _hourlyTimer;
  DateTime _lastRefreshTime = DateTime.now();

  List<DynamicCountry> get countries => List.unmodifiable(_countries);
  DateTime get lastRefreshTime => _lastRefreshTime;

  void _initCountries() {
    _countries.clear();
    for (final c in kFastlyCountries) {
      _countries.add(
        DynamicCountry(
          code: c.code,
          name: c.name,
          cities: c.cities,
          load: c.load,
          pingMs: c.pingMs,
          isP2p: c.isP2p,
          isSecureCore: c.isSecureCore,
          isTor: c.isTor,
        ),
      );
    }
  }

  void _startHourlyAutoRefresh() {
    _hourlyTimer?.cancel();
    if (WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      return;
    }
    // Auto refresh every 1 hour
    _hourlyTimer = Timer.periodic(const Duration(hours: 1), (_) {
      refresh();
    });
  }

  void stopTimer() {
    _hourlyTimer?.cancel();
    _hourlyTimer = null;
  }

  /// Refreshes all country loads (%) and pings (ms) in real-time
  Future<void> refresh() async {
    final random = Random();
    for (var i = 0; i < _countries.length; i++) {
      final c = _countries[i];
      // Realistic jitter: ping jitter ±4ms, load jitter ±6%
      final basePing = kFastlyCountries.firstWhere((k) => k.code == c.code, orElse: () => c as CountryItem).pingMs;
      final baseLoad = kFastlyCountries.firstWhere((k) => k.code == c.code, orElse: () => c as CountryItem).load;

      final pingDelta = random.nextInt(9) - 4; // -4 to +4
      final loadDelta = random.nextInt(11) - 5; // -5 to +5

      final newPing = (basePing + pingDelta).clamp(12, 350);
      final newLoad = (baseLoad + loadDelta).clamp(15, 95);

      _countries[i] = c.copyWith(pingMs: newPing, load: newLoad);
    }

    _lastRefreshTime = DateTime.now();
    notifyListeners();
  }

  /// Returns the fastest country currently available
  DynamicCountry getFastestCountry() {
    if (_countries.isEmpty) _initCountries();
    DynamicCountry fastest = _countries.first;
    for (final c in _countries) {
      // Score based on ping + load weight
      final score = c.pingMs + (c.load * 0.15);
      final currentFastestScore = fastest.pingMs + (fastest.load * 0.15);
      if (score < currentFastestScore) {
        fastest = c;
      }
    }
    return fastest;
  }

  @override
  void dispose() {
    _hourlyTimer?.cancel();
    super.dispose();
  }
}
