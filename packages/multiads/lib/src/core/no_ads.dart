import 'package:flutter/material.dart';
import 'ads_base.dart';

class NoAds extends Ads {
  @override
  Future<void> init() async {}
  @override
  Future<void> loadAppOpenAd() async {}
  @override
  void showAdIfAvailableOpenAds() {}
  @override
  Future<void> loadBannerAd(Function? onLoaded, Key key) async {}
  @override
  Widget getBannerAdWidget(Key key) => const SizedBox.shrink();
  @override
  Future<void> disposeBanner(Key key) async {}
  @override
  Future<void> loadInterstitialAd() async {}
  @override
  void showInterstitialAd() {}
  @override
  Future<void> loadRewardAd() async {}
  @override
  void showRewardAd(Function rewarded) {}
  @override
  Future<void> loadNativeAd(
    Function? onLoaded,
    Key key,
    dynamic templateType,
  ) async {}
  @override
  Widget getNativeAdWidget(Key key, double height) => const SizedBox.shrink();
  @override
  Future<void> disposeNative(Key key) async {}
}
