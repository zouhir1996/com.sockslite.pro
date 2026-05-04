import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'admob_config.dart';
import 'admob_sdk.dart';

/// Fixed-size (320×50) banner; renders nothing when disabled or SDK off.
class BannerAdSlot extends StatefulWidget {
  const BannerAdSlot({super.key});

  @override
  State<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends State<BannerAdSlot> {
  BannerAd? _banner;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (!AdMobConfig.bannerActive) return;
    unawaited(_loadBanner());
  }

  Future<void> _loadBanner() async {
    await AdMobSdk.ensureInitialized();
    if (!mounted || !AdMobConfig.bannerActive) return;
    final banner = BannerAd(
      size: AdSize.banner,
      adUnitId: AdMobConfig.bannerUnitId,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint(
            '[AdMob] Banner load failed: ${error.message} (code ${error.code})',
          );
          ad.dispose();
          if (mounted) setState(() => _banner = null);
        },
      ),
      request: const AdRequest(),
    );
    setState(() => _banner = banner);
    banner.load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _banner;
    if (ad == null || !_loaded) {
      return const SizedBox.shrink();
    }
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
