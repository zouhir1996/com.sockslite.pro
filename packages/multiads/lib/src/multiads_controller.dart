import 'dart:convert';

import 'constants/networks.dart';
import 'core/ads_base.dart';
import 'core/network_index.dart';
import 'core/no_ads.dart';
import 'core/log.dart';
import 'models/ads_data.dart';
import 'models/multiads_config.dart';
import 'networks/admob/admob_ad.dart';
import 'networks/applovin/applovin_ad.dart';
import 'networks/facebook/facebook_ad.dart';

class MultiAds {
  late final AdsData _adsData;
  late final AdmobAD _admobAD;
  late final ApplovinAD _applovinAD;
  late final FacebookAD _facebookAD;

  final _activeNetworks = <String>{};

  MultiAds(String json, {MultiAdsConfig config = const MultiAdsConfig()}) {
    // Support both { "ads": {...} } and flat { "admob": {...} }
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    final root = decoded.containsKey('ads')
        ? decoded['ads'] as Map<String, dynamic>
        : decoded;

    Log.enabled = config.enableLogs;

    _adsData = AdsData.fromJson(root);
    _admobAD = AdmobAD(_adsData.admobData, config);
    _applovinAD = ApplovinAD(_adsData.applovinData, _adsData.settings);
    _facebookAD = FacebookAD(_adsData.facebookData, config);
    _fillActiveNetworks();
  }

  void _fillActiveNetworks() {
    _adsData.settings.banners.forEach(_activeNetworks.add);
    _adsData.settings.inters.forEach(_activeNetworks.add);
    _adsData.settings.natives.forEach(_activeNetworks.add);
    _adsData.settings.rewards.forEach(_activeNetworks.add);
    if (_adsData.settings.openads.isNotEmpty) {
      _activeNetworks.add(_adsData.settings.openads);
    }
    Log.log("Active networks: $_activeNetworks");
  }

  // ─── Init ────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_activeNetworks.contains(Networks.admob)) {
      await _admobAD.init();
      Log.log("AdMob initialized");
    }
    if (_activeNetworks.contains(Networks.applovin)) {
      await _applovinAD.init();
      Log.log("AppLovin initialized");
    }
    if (_activeNetworks.contains(Networks.facebook)) {
      await _facebookAD.init();
      Log.log("Facebook initialized");
    }
  }

  // ─── Preload ─────────────────────────────────────────────────────────────

  Future<void> loadAds() async {
    for (int i = 0; i < _adsData.settings.inters.length; i++) {
      await interInstance.loadInterstitialAd();
    }
    for (int i = 0; i < _adsData.settings.rewards.length; i++) {
      await rewardInstance.loadRewardAd();
    }
    await openAdsInstance.loadAppOpenAd();
  }

  // ─── Instances ───────────────────────────────────────────────────────────

  Ads get bannerInstance {
    if (_adsData.settings.banners.isEmpty) return NoAds();
    NetworkIndex().incrementBannerIndex(_adsData.settings.banners.length);
    return _resolve(_adsData.settings.banners[NetworkIndex().bannerIndex]);
  }

  Ads get interInstance {
    if (_adsData.settings.inters.isEmpty) return NoAds();
    NetworkIndex().incrementInterIndex(_adsData.settings.inters.length);
    return _resolve(_adsData.settings.inters[NetworkIndex().interIndex]);
  }

  Ads get rewardInstance {
    if (_adsData.settings.rewards.isEmpty) return NoAds();
    NetworkIndex().incrementRewardIndex(_adsData.settings.rewards.length);
    return _resolve(_adsData.settings.rewards[NetworkIndex().rewardIndex]);
  }

  Ads get nativeInstance {
    if (_adsData.settings.natives.isEmpty) return NoAds();
    NetworkIndex().incrementNativeIndex(_adsData.settings.natives.length);
    return _resolve(_adsData.settings.natives[NetworkIndex().nativeIndex]);
  }

  Ads get openAdsInstance {
    if (_adsData.settings.openads.isEmpty) return NoAds();
    return _resolve(_adsData.settings.openads);
  }

  // ─── Resolver — add new networks here only ───────────────────────────────

  Ads _resolve(String network) {
    switch (network) {
      case Networks.admob:
        return _admobAD;
      case Networks.applovin:
        return _applovinAD;
      case Networks.facebook:
        return _facebookAD;
      default:
        Log.log("Unknown network '$network' — falling back to NoAds");
        return NoAds();
    }
  }
}
