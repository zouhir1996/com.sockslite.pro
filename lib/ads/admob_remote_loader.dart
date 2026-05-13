import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'admob_config.dart';

/// Turns `https://drive.google.com/file/d/<id>/view?...` into a direct download
/// URL so a GET returns file bytes (small JSON files usually work).
Uri _normalizeDriveFileUrl(Uri u) {
  final host = u.host.toLowerCase();
  if (host != 'drive.google.com' && host != 'docs.google.com') return u;
  final m = RegExp(r'/file/d/([a-zA-Z0-9_-]+)').firstMatch(u.path);
  if (m == null) return u;
  return Uri.https('drive.google.com', '/uc', {
    'export': 'download',
    'id': m.group(1)!,
  });
}

String _stripBom(String body) {
  if (body.isEmpty) return body;
  if (body.codeUnitAt(0) == 0xFEFF) return body.substring(1);
  return body;
}

/// Loads AdMob **unit** IDs from a JSON document at build-time URL
/// `--dart-define=ADMOB_UNITS_JSON_URL=https://.../units.json`.
///
/// Google Drive **view** pages return HTML; this loader rewrites
/// `/file/d/<id>/view` to `uc?export=download&id=<id>` when possible.
/// If you still get parse errors, host the JSON on a raw URL (GitHub raw, S3).
///
/// Expected shape (only the block for the running OS is required):
/// ```json
/// {
///   "android": {
///     "appOpen": "ca-app-pub-xxx/yyy",
///     "banner": "ca-app-pub-xxx/yyy",
///     "rewarded": "ca-app-pub-xxx/yyy",
///     "interstitial": "ca-app-pub-xxx/yyy"
///   },
///   "ios": {
///     "appOpen": "ca-app-pub-xxx/yyy",
///     "banner": "ca-app-pub-xxx/yyy",
///     "rewarded": "ca-app-pub-xxx/yyy",
///     "interstitial": "ca-app-pub-xxx/yyy"
///   }
/// }
/// ```
///
/// Use `"0"` or `0` for any slot you want disabled. Alternate key `app_open`
/// is accepted instead of `appOpen`.
final class AdMobRemoteLoader {
  AdMobRemoteLoader._();
  static final AdMobRemoteLoader instance = AdMobRemoteLoader._();

  static const String _urlFromDefine = String.fromEnvironment(
    'ADMOB_UNITS_JSON_URL',
    defaultValue: '',
  );

  Future<void> load() async {
    if (kIsWeb) return;
    final url = _urlFromDefine.trim();
    if (url.isEmpty) {
      debugPrint(
        '[AdMob] No ADMOB_UNITS_JSON_URL; unit IDs unset — ads disabled.',
      );
      return;
    }
    Uri uri;
    try {
      uri = Uri.parse(url);
    } catch (_) {
      debugPrint('[AdMob] ADMOB_UNITS_JSON_URL is not a valid URL.');
      return;
    }
    if (!uri.hasScheme || (uri.scheme != 'https' && uri.scheme != 'http')) {
      debugPrint('[AdMob] ADMOB_UNITS_JSON_URL must be http or https.');
      return;
    }
    final fetchUri = _normalizeDriveFileUrl(uri);
    if (fetchUri != uri) {
      debugPrint('[AdMob] Using Drive direct download URL for unit JSON.');
    }
    try {
      final res = await http
          .get(fetchUri)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        debugPrint(
          '[AdMob] Remote units request failed: HTTP ${res.statusCode}.',
        );
        return;
      }
      final body = _stripBom(res.body.trim());
      if (body.startsWith('<!DOCTYPE') ||
          body.startsWith('<html') ||
          body.startsWith('<HTML')) {
        debugPrint(
          '[AdMob] Response looks like HTML, not JSON (set Drive file to '
          'Anyone with the link, or host JSON on a raw HTTPS URL).',
        );
        return;
      }
      final dynamic decoded;
      try {
        decoded = jsonDecode(body);
      } on FormatException catch (e) {
        debugPrint('[AdMob] JSON parse error: $e');
        debugPrint(
          '[AdMob] Fix JSON (e.g. comma between "ios" and "android" objects). '
          'Preview: ${body.length > 160 ? '${body.substring(0, 160)}…' : body}',
        );
        return;
      }
      if (decoded is! Map) {
        debugPrint('[AdMob] Remote units JSON must be an object.');
        return;
      }
      final map = Map<String, dynamic>.from(
        decoded.map((k, v) => MapEntry(k.toString(), v)),
      );
      final platformKey = defaultTargetPlatform == TargetPlatform.android
          ? 'android'
          : 'ios';
      final plat = map[platformKey];
      if (plat is! Map) {
        debugPrint(
          '[AdMob] Remote JSON missing "$platformKey" object — ads disabled.',
        );
        return;
      }
      final p = Map<String, dynamic>.from(
        plat.map((k, v) => MapEntry(k.toString(), v)),
      );
      AdMobConfig.applyFromRemote(
        appOpen: p['appOpen'] ?? p['app_open'],
        banner: p['banner'],
        rewarded: p['rewarded'],
        interstitial: p['interstitial'],
      );
    } catch (e, st) {
      debugPrint('[AdMob] Remote units load failed: $e');
      debugPrint('$st');
    }
  }
}
