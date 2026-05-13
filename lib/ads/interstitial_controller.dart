import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'admob_config.dart';
import 'admob_sdk.dart';

/// Full-screen interstitial before sensitive navigation or system UI.
final class InterstitialController {
  InterstitialController._();
  static final InterstitialController instance = InterstitialController._();

  InterstitialAd? _ad;

  Future<void> preload() async {
    if (kIsWeb) return;
    await AdMobSdk.ensureInitialized();
    if (!AdMobConfig.interstitialActive) return;
    await InterstitialAd.load(
      adUnitId: AdMobConfig.interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _ad = ad,
        onAdFailedToLoad: (error) {
          debugPrint('[AdMob] Interstitial load failed: ${error.message}');
          _ad = null;
        },
      ),
    );
  }

  void showInterstitialOrRun(void Function() after) {
    unawaited(_showAsync(after));
  }

  Future<void> _showAsync(void Function() after) async {
    if (kIsWeb) {
      after();
      return;
    }
    await AdMobSdk.ensureInitialized();
    if (!AdMobConfig.interstitialActive) {
      after();
      return;
    }
    final ad = _ad;
    _ad = null;
    if (ad == null) {
      after();
      unawaited(preload());
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        after();
        unawaited(preload());
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        debugPrint('[AdMob] Interstitial show failed: $e');
        a.dispose();
        after();
        unawaited(preload());
      },
    );
    ad.show();
  }
}
