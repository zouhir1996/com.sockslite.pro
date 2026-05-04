import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// AdMob **ad unit** ids are loaded only from this Google Drive file (share: **Anyone with the link**):
/// https://drive.google.com/file/d/1zJx37z8TDwetDWQUilCB9AB6jWOohjx2/view?usp=share_link
///
/// No other URL, dart-define, or bundled asset is used for units.
///
/// **Behavior**
/// - Each of **appOpen**, **banner**, **rewarded**, **interstitial** may be set to a real AdMob unit
///   (`ca-app-pub-…/…`) or to **`0`** / **empty** / omitted → that format is **off**; the rest of the app
///   runs normally without it.
/// - If **all four** are off (or the file cannot be read), the Mobile Ads SDK is **not** initialized and
///   no ads are shown.
///
/// **Formats** (plain text from Drive):
///
/// **JSON** — shorthand keys apply to **both** platforms unless `android*` / `ios*` are set:
/// ```json
/// { "appOpen": "ca-app-pub-…/…", "banner": "0", "rewarded": "", "interstitial": "…" }
/// ```
///
/// **Line-based** — `key=value` per line, `#` comments:
/// ```
/// androidAppOpen=0
/// iosAppOpen=ca-app-pub-…/…
/// ```
///
/// **App ID** (`ca-app-pub-…~…`) stays only in native `Info.plist` / `AndroidManifest.xml`.
abstract final class AdMobConfig {
  /// Same file as the view link above; direct download endpoint.
  static const String _driveConfigUrl =
      'https://drive.google.com/uc?export=download&id=1zJx37z8TDwetDWQUilCB9AB6jWOohjx2';

  static final Map<String, String> _kv = {};
  static Future<void>? _loadFuture;

  /// Call once after binding, before [AdMobBootstrap.warmUp].
  static Future<void> ensureLoaded() {
    _loadFuture ??= _loadOnce();
    return _loadFuture!;
  }

  static Future<void> _loadOnce() async {
    String? body;
    try {
      final res = await http
          .get(Uri.parse(_driveConfigUrl))
          .timeout(const Duration(seconds: 25));
      if (res.statusCode == 200 && res.body.trim().isNotEmpty) {
        body = res.body;
      } else {
        debugPrint(
          '[AdMob] Drive file returned HTTP ${res.statusCode}; ads disabled.',
        );
      }
    } catch (e, st) {
      debugPrint('[AdMob] Drive download failed; ads disabled. $e\n$st');
    }
    if (body != null && body.trim().isNotEmpty) {
      _applyParsedConfig(body);
      if (shouldInitializeSdk) {
        debugPrint(
          '[AdMob] Drive config: appOpen=$appOpenActive banner=$bannerActive '
          'rewarded=$rewardedActive interstitial=$interstitialActive.',
        );
      } else {
        debugPrint(
          '[AdMob] Drive config loaded; all slots off (0/empty) or invalid — '
          'no ads, app continues normally.',
        );
      }
    } else {
      debugPrint(
        '[AdMob] No Drive config body; ads off. Check sharing (Anyone with link).',
      );
    }
  }

  /// JSON (`{` … `}`) or line-based `key=value`.
  static void _applyParsedConfig(String body) {
    final t = body.trimLeft();
    if (t.startsWith('{')) {
      _parseJsonAdMobConfig(body);
    } else {
      _parseKeyValueBody(body);
    }
  }

  /// Quoted string value: `"key":"value"`.
  static String? _jsonQuoted(String text, String key) {
    final m = RegExp('"${RegExp.escape(key)}"\\s*:\\s*"([^"]*)"').firstMatch(text);
    return m?.group(1)?.trim();
  }

  /// JSON `"key": 0` (unquoted zero → off).
  static bool _jsonUnquotedZero(String text, String key) =>
      RegExp('"${RegExp.escape(key)}"\\s*:\\s*0\\b').hasMatch(text);

  static String? _jsonSlot(String text, String key) {
    if (_jsonUnquotedZero(text, key)) return '0';
    return _jsonQuoted(text, key);
  }

  /// Fills [_kv] from JSON. Shared keys map to both Android and iOS when per-platform missing.
  static void _parseJsonAdMobConfig(String text) {
    _kv.clear();
    void put(String normalizedKey, String? value) {
      final v = value?.trim();
      if (v == null || _inactive(v)) return;
      _kv[normalizedKey] = v;
    }

    final appOpen = _jsonSlot(text, 'appOpen');
    put('androidappopen', _jsonSlot(text, 'androidAppOpen') ?? appOpen);
    put('iosappopen', _jsonSlot(text, 'iosAppOpen') ?? appOpen);

    final banner = _jsonSlot(text, 'banner');
    put('androidbanner', _jsonSlot(text, 'androidBanner') ?? banner);
    put('iosbanner', _jsonSlot(text, 'iosBanner') ?? banner);

    final rewarded = _jsonSlot(text, 'rewarded');
    put('androidrewarded', _jsonSlot(text, 'androidRewarded') ?? rewarded);
    put('iosrewarded', _jsonSlot(text, 'iosRewarded') ?? rewarded);

    final interstitial = _jsonSlot(text, 'interstitial');
    put(
      'androidinterstitial',
      _jsonSlot(text, 'androidInterstitial') ?? interstitial,
    );
    put('iosinterstitial', _jsonSlot(text, 'iosInterstitial') ?? interstitial);
  }

  static void _parseKeyValueBody(String text) {
    _kv.clear();
    for (final line in text.split(RegExp(r'\r?\n'))) {
      final t = line.trim();
      if (t.isEmpty || t.startsWith('#')) continue;
      final idx = t.indexOf('=');
      if (idx <= 0) continue;
      final keyRaw = t.substring(0, idx).trim();
      final val = t.substring(idx + 1).trim();
      if (_inactive(val)) continue;
      final nk = _normalizeKey(keyRaw);
      if (nk.isEmpty) continue;
      _kv[nk] = val;
    }
  }

  static String _normalizeKey(String key) =>
      key.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');

  static String _value(String normalizedKey) =>
      (_kv[normalizedKey] ?? '').trim();

  static bool _inactive(String raw) {
    final s = raw.trim();
    return s.isEmpty || s == '0';
  }

  static bool _looksLikeAdMobId(String raw) {
    final s = raw.trim();
    return s.startsWith('ca-app-pub-');
  }

  static bool _unitUsable(String raw) =>
      !_inactive(raw) && _looksLikeAdMobId(raw) && raw.contains('/');

  static bool get _onIos =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get _onAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static String _unitForPlatform(String androidKey, String iosKey) {
    if (kIsWeb) return '';
    final raw = _onIos ? _value(iosKey) : (_onAndroid ? _value(androidKey) : '');
    return _unitUsable(raw) ? raw : '0';
  }

  static String get appOpenUnitId =>
      _unitForPlatform('androidappopen', 'iosappopen');

  static String get bannerUnitId =>
      _unitForPlatform('androidbanner', 'iosbanner');

  static String get rewardedUnitId =>
      _unitForPlatform('androidrewarded', 'iosrewarded');

  static String get interstitialUnitId =>
      _unitForPlatform('androidinterstitial', 'iosinterstitial');

  static bool get shouldInitializeSdk {
    if (kIsWeb) return false;
    if (!(_onIos || _onAndroid)) return false;
    return appOpenActive ||
        bannerActive ||
        rewardedActive ||
        interstitialActive;
  }

  static bool get appOpenActive => _unitUsable(appOpenUnitId);
  static bool get bannerActive => _unitUsable(bannerUnitId);
  static bool get rewardedActive => _unitUsable(rewardedUnitId);
  static bool get interstitialActive => _unitUsable(interstitialUnitId);
}
