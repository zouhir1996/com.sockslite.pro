import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ads/interstitial_controller.dart';
import '../app_messenger.dart';
import '../config/store_metadata.dart';
import 'settings_persistence.dart';

bool get _isAndroid =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Tool rows that open with an interstitial first (when configured).
const Set<String> _interstitialBeforeToolActions = {
  'apn',
  'rede_movel',
  'rotear',
  'speed',
  'bateria',
  'store',
  'contato',
  'telegram',
  'avaliar',
  'instagram',
  'restaurar',
};

Future<void> runToolAction(String id) async {
  if (_interstitialBeforeToolActions.contains(id)) {
    InterstitialController.instance.showInterstitialOrRun(() {
      unawaited(_runToolSafe(id));
    });
    return;
  }
  await _runToolSafe(id);
}

Future<void> _runToolSafe(String id) async {
  try {
    await _runToolActionImpl(id);
  } catch (e, st) {
    debugPrint('runToolAction($id): $e\n$st');
    AppMessenger.show('Could not complete the action. Try again.');
  }
}

Future<void> _runToolActionImpl(String id) async {
  switch (id) {
    case 'apn':
      if (_isAndroid) {
        await AppSettings.openAppSettings(type: AppSettingsType.apn);
      } else {
        await AppSettings.openAppSettings();
        AppMessenger.show(
          'On iOS: Settings → Cellular → Cellular Data Options / Network.',
        );
      }
      break;
    case 'rede_movel':
      if (_isAndroid) {
        await AppSettings.openAppSettings(type: AppSettingsType.wireless);
      } else {
        await AppSettings.openAppSettings();
        AppMessenger.show('Wi‑Fi & cellular are in the system Settings app.');
      }
      break;
    case 'rotear':
      if (_isAndroid) {
        await AppSettings.openAppSettings(type: AppSettingsType.vpn);
      } else {
        await AppSettings.openAppSettings();
        AppMessenger.show(
          'System VPN: Settings → General → VPN & Device Management.',
        );
      }
      break;
    case 'speed':
      await _openExternal(Uri.parse('https://fast.com'));
      break;
    case 'bateria':
      if (_isAndroid) {
        await AppSettings.openAppSettings(
          type: AppSettingsType.batteryOptimization,
        );
      } else {
        await AppSettings.openAppSettings();
        AppMessenger.show('Battery: Settings → Battery.');
      }
      break;
    case 'store':
      await _openExternal(StoreMetadata.storeFrontUriForCurrentPlatform());
      break;
    case 'contato':
      final mail = StoreMetadata.mailtoSupportUri();
      if (await canLaunchUrl(mail)) {
        await launchUrl(mail);
      } else {
        AppMessenger.show(
          'Add a valid supportEmail in StoreMetadata and open this from a '
          'device with email configured.',
        );
      }
      break;
    case 'telegram':
      final tg = StoreMetadata.telegramUri();
      if (tg != null) {
        await _openExternal(tg);
      } else {
        AppMessenger.show(
          'Set telegramUrl in StoreMetadata (e.g. your public channel link).',
        );
      }
      break;
    case 'avaliar':
      await _openExternal(StoreMetadata.storeFrontUriForCurrentPlatform());
      break;
    case 'instagram':
      final ig = StoreMetadata.instagramUri();
      if (ig != null) {
        await _openExternal(ig);
      } else {
        AppMessenger.show(
          'Set instagramUrl in StoreMetadata (your profile or business link).',
        );
      }
      break;
    case 'restaurar':
      await SettingsPersistence.resetAllToggles();
      AppMessenger.show('App preferences restored to defaults.');
      break;
    default:
      AppMessenger.show('Unavailable.');
  }
}

Future<void> _openExternal(Uri uri) async {
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    AppMessenger.show('Could not open the link.');
  }
}
