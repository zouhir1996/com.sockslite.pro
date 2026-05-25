import 'package:flutter/material.dart';

abstract class Ads {
  bool isInterShowed = false;

  Future<void> init();

  // App Open
  Future<void> loadAppOpenAd();
  void showAdIfAvailableOpenAds();

  // Banner
  Future<void> loadBannerAd(Function? onLoaded, Key key);
  Widget getBannerAdWidget(Key key);
  Future<void> disposeBanner(Key key);

  // Interstitial
  Future<void> loadInterstitialAd();
  void showInterstitialAd();

  // Reward
  Future<void> loadRewardAd();
  void showRewardAd(Function rewarded);

  // Native
  // templateType is dynamic — AdMob passes TemplateType, others ignore it
  Future<void> loadNativeAd(Function? onLoaded, Key key, dynamic templateType);
  Widget getNativeAdWidget(Key key, double height);
  Future<void> disposeNative(Key key);
}
