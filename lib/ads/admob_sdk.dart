import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'admob_config.dart';

/// Single place for `MobileAds.instance.initialize()` (avoids circular imports).
abstract final class AdMobSdk {
  static bool _initialized = false;
  static Future<void>? _pending;

  static bool get isInitialized => _initialized;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    if (!AdMobConfig.shouldInitializeSdk) return;
    _pending ??= () async {
      await MobileAds.instance.initialize();
      _initialized = true;
    }();
    await _pending;
  }
}
