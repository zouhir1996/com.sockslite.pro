import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'admob_config.dart';

abstract final class AdMobSdk {
  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    if (kIsWeb) return;
    if (!AdMobConfig.shouldInitializeSdk) return;
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  static bool get isInitialized => _initialized;
}
