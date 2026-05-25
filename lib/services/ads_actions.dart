import 'package:flutter/widgets.dart';
import 'package:multiads/multiads.dart';

import '../util/global.dart';

/// User has passed splash/legal and may see app-open ads.
bool appOpenGatePassed = false;

DateTime? _appPausedAt;
DateTime? _lastAppOpenAttempt;

/// Minimum time in background before showing an app-open ad on resume.
const Duration minBackgroundForAppOpen = Duration(seconds: 3);

const Duration _appOpenDebounce = Duration(seconds: 1);

void markAppOpenGatePassed() {
  appOpenGatePassed = true;
}

void recordAppBackgrounded() {
  _appPausedAt = DateTime.now();
}

/// After legal accept → home (first entry into the main app this session).
void showAppOpenAfterLegalGate() {
  if (!appOpenGatePassed) return;
  _tryShowAppOpen();
}

/// When returning from background, only if legal gate passed and away long enough.
void showAppOpenOnResumeIfEligible() {
  if (!appOpenGatePassed) return;
  final paused = _appPausedAt;
  if (paused == null) return;
  if (DateTime.now().difference(paused) < minBackgroundForAppOpen) return;
  _appPausedAt = null;
  _tryShowAppOpen();
}

void _tryShowAppOpen() {
  if (!_canShowAppOpen()) return;
  final now = DateTime.now();
  if (_lastAppOpenAttempt != null &&
      now.difference(_lastAppOpenAttempt!) < _appOpenDebounce) {
    return;
  }
  _lastAppOpenAttempt = now;
  gAds.openAdsInstance.showAdIfAvailableOpenAds();
}

bool _canShowAppOpen() => gAdsReady && gAds.hasAppOpen;

bool _canShowInterstitial() => gAdsReady && gAds.hasInterstitials;

bool _canShowRewarded() => gAdsReady && gAds.hasRewarded;

/// Runs [action] after the interstitial closes, or immediately if ads are off.
void runAfterInterstitial(void Function() action) {
  if (!_canShowInterstitial()) {
    action();
    return;
  }
  AdCallbacks.onInterstitialDismissed = action;
  gAds.interInstance.showInterstitialAd();
}

/// Runs [action] after the rewarded ad closes, or immediately if ads are off.
void runAfterRewarded(void Function() action) {
  if (!_canShowRewarded()) {
    action();
    return;
  }
  gAds.rewardInstance.showRewardAd(action);
}

/// Pops [context] after an interstitial closes.
void popAfterInterstitial(BuildContext context, [Object? result]) {
  runAfterInterstitial(() {
    if (context.mounted) Navigator.of(context).pop(result);
  });
}
