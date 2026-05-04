import 'admob_config.dart';
import 'admob_sdk.dart';
import 'app_open_ad_manager.dart';
import 'interstitial_controller.dart';
import 'rewarded_controller.dart';

/// First app start: initialize SDK + preload active formats.
abstract final class AdMobBootstrap {
  static Future<void> warmUp() async {
    await AdMobSdk.ensureInitialized();
    if (!AdMobSdk.isInitialized) return;
    if (AdMobConfig.interstitialActive) {
      await InterstitialController.instance.preload();
    }
    if (AdMobConfig.appOpenActive) {
      await AppOpenAdManager.instance.preload();
    }
    if (AdMobConfig.rewardedActive) {
      await RewardedAdController.instance.preload();
    }
  }
}
