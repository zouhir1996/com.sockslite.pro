import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'admob_config.dart';
import 'admob_sdk.dart';

/// Anchored adaptive banner when [AdMobConfig.bannerActive].
class BannerAdSlot extends StatefulWidget {
  const BannerAdSlot({super.key});

  @override
  State<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends State<BannerAdSlot> {
  BannerAd? _banner;
  AdSize? _size;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (kIsWeb || !AdMobConfig.bannerActive) return;
    await AdMobSdk.ensureInitialized();
    if (!mounted) return;
    final width = MediaQuery.sizeOf(context).width.truncate();
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width,
    );
    if (!mounted || size == null) return;
    final banner = BannerAd(
      adUnitId: AdMobConfig.bannerUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdMob] Banner load failed: ${error.message}');
          ad.dispose();
        },
      ),
    );
    await banner.load();
    if (!mounted) {
      banner.dispose();
      return;
    }
    setState(() {
      _size = size;
      _banner = banner;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !AdMobConfig.bannerActive || _banner == null || _size == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: double.infinity,
      height: _size!.height.toDouble(),
      child: AdWidget(ad: _banner!),
    );
  }
}
