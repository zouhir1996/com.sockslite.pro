import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';

import '../ads/interstitial_controller.dart';
import '../app_messenger.dart';

bool get _isAndroid =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Opens system settings where the user can reach VPN configuration.
Future<void> openSystemVpnRelatedSettings() async {
  InterstitialController.instance.showInterstitialOrRun(() {
    unawaited(_openSystemVpnRelatedSettingsBody());
  });
}

Future<void> _openSystemVpnRelatedSettingsBody() async {
  if (_isAndroid) {
    await AppSettings.openAppSettings(type: AppSettingsType.vpn);
  } else {
    await AppSettings.openAppSettings();
    AppMessenger.show(
      'On iOS: Settings → General → VPN & Device Management → VPN.',
    );
  }
}
