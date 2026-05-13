import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'admob_config.dart';
import 'admob_sdk.dart';

/// App open: cold-start attempt after first frames + show after pause→resume.
final class AppOpenAdManager {
  AppOpenAdManager._();
  static final AppOpenAdManager instance = AppOpenAdManager._();

  AppOpenAd? _ad;
  DateTime? _lastShown;
  bool _sawPaused = false;
  bool _scheduledColdStart = false;

  /// After splash (~2.6s) + route fade (~0.4s) so the first window is stable for full-screen ads.
  static const Duration _coldStartDelay = Duration(milliseconds: 3300);

  Future<void> preload() async {
    if (kIsWeb) return;
    await AdMobSdk.ensureInitialized();
    if (!AdMobConfig.appOpenActive) return;
    await AppOpenAd.load(
      adUnitId: AdMobConfig.appOpenUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) => _ad = ad,
        onAdFailedToLoad: (error) {
          debugPrint('[AdMob] App open load failed: ${error.message}');
          _ad = null;
        },
      ),
    );
  }

  /// Call once from [MaterialApp] after first frame — first foreground has no prior `paused` event.
  void scheduleColdStartShow() {
    if (kIsWeb || !AdMobConfig.appOpenActive || _scheduledColdStart) return;
    _scheduledColdStart = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(_coldStartDelay, () {
        _tryShow(respectCooldown: false);
      });
    });
  }

  void handleLifecycle(AppLifecycleState state) {
    if (kIsWeb) return;
    // Only `paused` means the app left the foreground. `inactive` also fires on
    // iOS during launch, control center, etc.; treating it as background makes
    // the first `resumed` call `_tryShow` too early and clears the preloaded ad.
    if (state == AppLifecycleState.paused) {
      _sawPaused = true;
      return;
    }
    if (state != AppLifecycleState.resumed) return;
    if (!_sawPaused) return;
    _tryShow(respectCooldown: true);
  }

  void _tryShow({required bool respectCooldown}) {
    if (!AdMobConfig.appOpenActive || !AdMobSdk.isInitialized) return;
    if (respectCooldown) {
      final last = _lastShown;
      if (last != null &&
          DateTime.now().difference(last) < const Duration(minutes: 4)) {
        return;
      }
    }
    final ad = _ad;
    _ad = null;
    if (ad == null) {
      unawaited(preload());
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _lastShown = DateTime.now();
        unawaited(preload());
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        debugPrint('[AdMob] App open show failed: $e');
        a.dispose();
        unawaited(preload());
      },
    );
    ad.show();
  }
}
