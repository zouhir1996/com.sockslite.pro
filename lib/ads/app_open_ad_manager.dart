import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'admob_config.dart';
import 'admob_sdk.dart';

/// Shows an app-open ad when returning from background (not on first resume).
class AppOpenAdManager {
  AppOpenAdManager._();
  static final AppOpenAdManager instance = AppOpenAdManager._();

  AppOpenAd? _ad;
  bool _loading = false;
  DateTime? _lastShown;
  bool _sawPaused = false;
  bool _skippedFirstResume = false;

  Future<void> preload() async {
    await AdMobSdk.ensureInitialized();
    if (!AdMobConfig.appOpenActive) return;
    await _loadInternal();
  }

  Future<void> _loadInternal() async {
    await AdMobSdk.ensureInitialized();
    if (_loading || _ad != null) return;
    _loading = true;
    await AppOpenAd.load(
      adUnitId: AdMobConfig.appOpenUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _ad = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint(
            '[AdMob] App open load failed: ${error.message} (code ${error.code})',
          );
          _loading = false;
        },
      ),
    );
  }

  void handleLifecycle(AppLifecycleState state) {
    if (!AdMobConfig.appOpenActive || !AdMobSdk.isInitialized) return;
    if (state == AppLifecycleState.paused) {
      _sawPaused = true;
    }
    if (state == AppLifecycleState.resumed) {
      if (!_skippedFirstResume) {
        _skippedFirstResume = true;
        return;
      }
      if (!_sawPaused) return;
      _sawPaused = false;
      _maybeShow();
    }
  }

  void _maybeShow() {
    final last = _lastShown;
    if (last != null &&
        DateTime.now().difference(last) < const Duration(minutes: 4)) {
      return;
    }
    final ad = _ad;
    if (ad == null) {
      unawaited(_loadInternal());
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        _lastShown = DateTime.now();
        a.dispose();
        _ad = null;
        unawaited(_loadInternal());
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _ad = null;
        unawaited(_loadInternal());
      },
    );
    ad.show();
  }
}
