import 'package:flutter/foundation.dart';

/// Ad **unit** IDs for banner, rewarded, interstitial, and app open are loaded
/// only from a remote JSON URL (see [AdMobRemoteLoader]); nothing is bundled here.
///
/// Native **application** IDs stay in `AndroidManifest.xml` and `Info.plist`
/// (required by the Mobile Ads SDK).
abstract final class AdMobConfig {
  static String _appOpen = '';
  static String _banner = '';
  static String _rewarded = '';
  static String _interstitial = '';

  /// Called after a successful remote fetch for the current OS.
  static void applyFromRemote({
    dynamic appOpen,
    dynamic banner,
    dynamic rewarded,
    dynamic interstitial,
  }) {
    _appOpen = _coerceUnitId(appOpen);
    _banner = _coerceUnitId(banner);
    _rewarded = _coerceUnitId(rewarded);
    _interstitial = _coerceUnitId(interstitial);
  }

  static String _coerceUnitId(dynamic v) {
    final raw = _parseRaw(v);
    if (raw == null) return '';
    if (!_looksLikeAdMobUnitId(raw)) {
      debugPrint('[AdMob] Ignoring invalid or non-AdMob unit value.');
      return '';
    }
    return raw;
  }

  /// `null`, `""`, `"0"`, or JSON number `0` → disabled (no ad for that slot).
  static String? _parseRaw(dynamic v) {
    if (v == null) return null;
    if (v is num && v == 0) return null;
    final s = v.toString().trim();
    if (s.isEmpty || s == '0') return null;
    return s;
  }

  static bool _looksLikeAdMobUnitId(String id) {
    return id.startsWith('ca-app-pub-') &&
        id.contains('/') &&
        !id.contains(' ') &&
        !id.toUpperCase().contains('YOUR_');
  }

  static bool get shouldInitializeSdk =>
      bannerActive || rewardedActive || interstitialActive || appOpenActive;

  static String get bannerUnitId => _banner;
  static String get rewardedUnitId => _rewarded;
  static String get interstitialUnitId => _interstitial;
  static String get appOpenUnitId => _appOpen;

  static bool get bannerActive => _banner.isNotEmpty;
  static bool get rewardedActive => _rewarded.isNotEmpty;
  static bool get interstitialActive => _interstitial.isNotEmpty;
  static bool get appOpenActive => _appOpen.isNotEmpty;
}
