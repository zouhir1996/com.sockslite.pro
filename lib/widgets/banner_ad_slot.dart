import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../util/global.dart';

/// Bottom banner using [gAds.bannerInstance] from multiads.
class BannerAdSlot extends StatefulWidget {
  const BannerAdSlot({super.key});

  @override
  State<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends State<BannerAdSlot> {
  final Key _bannerKey = UniqueKey();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb || !gAdsReady) return;
    unawaited(
      gAds.bannerInstance.loadBannerAd(() {
        if (mounted) setState(() => _ready = true);
      }, _bannerKey),
    );
  }

  @override
  void dispose() {
    if (gAdsReady) {
      unawaited(gAds.bannerInstance.disposeBanner(_bannerKey));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !gAdsReady || !_ready) {
      return const SizedBox.shrink();
    }
    return gAds.bannerInstance.getBannerAdWidget(_bannerKey);
  }
}
