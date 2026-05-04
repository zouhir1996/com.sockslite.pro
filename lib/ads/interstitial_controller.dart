import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'admob_config.dart';
import 'admob_sdk.dart';

/// Full-screen interstitial after legal accept (when configured).
class InterstitialController {
  InterstitialController._();
  static final InterstitialController instance = InterstitialController._();

  InterstitialAd? _ad;
  bool _loading = false;

  Future<void> preload() async {
    await AdMobSdk.ensureInitialized();
    if (!AdMobConfig.interstitialActive) {
      return;
    }
    if (_ad != null || _loading) return;
    _loading = true;
    await InterstitialAd.load(
      adUnitId: AdMobConfig.interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _ad = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint(
            '[AdMob] Interstitial load failed: ${error.message} (code ${error.code})',
          );
          _loading = false;
        },
      ),
    );
  }

  /// Shows loaded interstitial then runs [after]. If none ready, runs [after] immediately.
  void showInterstitialOrRun(void Function() after) {
    unawaited(_showInterstitialOrRunAsync(after));
  }

  Future<void> _showInterstitialOrRunAsync(void Function() after) async {
    await AdMobSdk.ensureInitialized();
    if (!AdMobConfig.interstitialActive) {
      after();
      return;
    }
    var ad = _ad;
    if (ad == null) {
      await preload();
      ad = _ad;
    }
    if (ad == null) {
      after();
      return;
    }
    _ad = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        unawaited(preload());
        after();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        unawaited(preload());
        after();
      },
    );
    ad.show();
  }
}
