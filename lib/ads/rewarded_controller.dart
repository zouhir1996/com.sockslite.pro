import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../app_messenger.dart';
import 'admob_config.dart';
import 'admob_sdk.dart';

/// Rewarded placement (Tools → optional tile when configured).
class RewardedAdController {
  RewardedAdController._();
  static final RewardedAdController instance = RewardedAdController._();

  RewardedAd? _ad;
  bool _loading = false;

  /// Runs [whenDone] after rewarded closes (or immediately if ads off / not loaded).
  void runAfterRewarded(BuildContext context, VoidCallback whenDone) {
    unawaited(_runAfterRewardedAsync(context, whenDone));
  }

  Future<void> _runAfterRewardedAsync(
    BuildContext context,
    VoidCallback whenDone,
  ) async {
    await AdMobSdk.ensureInitialized();
    if (!AdMobConfig.rewardedActive) {
      whenDone();
      return;
    }
    if (_ad == null) {
      await preload();
    }
    if (!context.mounted) return;
    final ad = _ad;
    if (ad == null) {
      whenDone();
      return;
    }
    _ad = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        unawaited(preload());
        if (context.mounted) whenDone();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        unawaited(preload());
        if (context.mounted) whenDone();
      },
    );
    unawaited(
      ad.show(
        onUserEarnedReward: (rewardedAd, item) {},
      ),
    );
  }

  Future<void> preload() async {
    await AdMobSdk.ensureInitialized();
    if (!AdMobConfig.rewardedActive) return;
    if (_ad != null || _loading) return;
    _loading = true;
    await RewardedAd.load(
      adUnitId: AdMobConfig.rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _ad = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint(
            '[AdMob] Rewarded load failed: ${error.message} (code ${error.code})',
          );
          _loading = false;
        },
      ),
    );
  }

  /// Loads (if needed) and shows a rewarded ad. [onUserEarnedReward] only if user completes.
  Future<void> show(
    BuildContext context, {
    required void Function() onUserEarnedReward,
  }) async {
    await AdMobSdk.ensureInitialized();
    if (!AdMobConfig.rewardedActive) {
      AppMessenger.show('Rewarded ads are not configured.');
      return;
    }
    if (_ad == null && !_loading) {
      await preload();
    }
    if (!context.mounted) return;
    final ad = _ad;
    if (ad == null) {
      AppMessenger.show('Ad is not ready yet. Try again in a moment.');
      unawaited(preload());
      return;
    }
    _ad = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        unawaited(preload());
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        unawaited(preload());
      },
    );
    await ad.show(
      onUserEarnedReward: (ad, reward) {
        if (context.mounted) {
          onUserEarnedReward();
        }
      },
    );
  }
}
