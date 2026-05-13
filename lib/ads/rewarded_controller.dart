import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'admob_config.dart';
import 'admob_sdk.dart';

/// Rewarded placement: runs [whenDone] after the ad closes (or immediately if unavailable).
final class RewardedAdController {
  RewardedAdController._();
  static final RewardedAdController instance = RewardedAdController._();

  RewardedAd? _ad;

  Future<void> preload() async {
    if (kIsWeb) return;
    await AdMobSdk.ensureInitialized();
    if (!AdMobConfig.rewardedActive) return;
    await _load();
  }

  Future<void> _load() async {
    await RewardedAd.load(
      adUnitId: AdMobConfig.rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _ad = ad,
        onAdFailedToLoad: (error) {
          debugPrint('[AdMob] Rewarded load failed: ${error.message}');
          _ad = null;
        },
      ),
    );
  }

  void showRewardedThenRun(void Function() whenDone) {
    unawaited(_showAsync(whenDone));
  }

  Future<void> _showAsync(void Function() whenDone) async {
    if (kIsWeb) {
      whenDone();
      return;
    }
    await AdMobSdk.ensureInitialized();
    if (!AdMobConfig.rewardedActive) {
      whenDone();
      return;
    }
    if (_ad == null) {
      await _load();
    }
    final ad = _ad;
    _ad = null;
    if (ad == null) {
      whenDone();
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        whenDone();
        unawaited(preload());
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        debugPrint('[AdMob] Rewarded show failed: $e');
        a.dispose();
        whenDone();
        unawaited(preload());
      },
    );
    await ad.show(onUserEarnedReward: (_, _) {});
  }
}
