import 'package:flutter/foundation.dart';

import 'app_product_info.dart';

/// Publisher-only values for App Store submission and in-app links.
///
/// Before release, set at minimum:
/// - [appleAppId] — numeric App ID from App Store Connect (for rate/open links).
/// - [privacyPolicyUrl] — public HTTPS URL (must match App Store Connect).
/// - [supportEmail] — working mailbox shown to users and in review notes.
///
/// [termsOfUseUrl], [telegramUrl], and [instagramUrl] are optional; empty hides
/// or downgrades related actions to a clear message.
abstract final class StoreMetadata {
  static const String appleAppId = '';

  /// Public privacy policy page (HTTPS).
  static const String privacyPolicyUrl =
      'https://sites.google.com/view/sockslite-pro/home';

  /// Terms of use / EULA (HTTPS).
  static const String termsOfUseUrl = '';

  /// Shown in mailto and support flows (replace with your live Gmail if different).
  static const String supportEmail = 'sockslitepro@gmail.com';

  static const String telegramUrl = 'https://web.telegram.org';
  static const String instagramUrl = 'https://www.instagram.com';

  static Uri? _parseHttpUrl(String value) {
    if (value.isEmpty) return null;
    final u = Uri.tryParse(value);
    if (u == null || !u.hasScheme || u.host.isEmpty) return null;
    if (u.scheme != 'https' && u.scheme != 'http') return null;
    return u;
  }

  static Uri? privacyPolicyUri() => _parseHttpUrl(privacyPolicyUrl);
  static Uri? termsOfUseUri() => _parseHttpUrl(termsOfUseUrl);
  static Uri? telegramUri() => _parseHttpUrl(telegramUrl);
  static Uri? instagramUri() => _parseHttpUrl(instagramUrl);

  static Uri iosStoreListingUri() {
    if (appleAppId.isEmpty) {
      return Uri.parse('https://apps.apple.com');
    }
    return Uri.parse('https://apps.apple.com/app/id$appleAppId');
  }

  static Uri androidStoreFrontUri() =>
      Uri.parse('https://play.google.com/store');

  static Uri storeFrontUriForCurrentPlatform() {
    final android =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return android ? androidStoreFrontUri() : iosStoreListingUri();
  }

  static Uri mailtoSupportUri() {
    final q = Uri.encodeComponent('${AppProductInfo.name} support');
    return Uri.parse('mailto:$supportEmail?subject=$q');
  }
}
