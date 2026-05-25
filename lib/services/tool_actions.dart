import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_messenger.dart';
import '../config/store_metadata.dart';
import 'settings_persistence.dart';
import 'vpn_settings_launcher.dart';

bool get _isAndroid =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

Future<void> runToolAction(String id) async {
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
      await _openApn();
      break;
    case 'rede_movel':
      await _openRedeMovel();
      break;
    case 'rotear':
      await openSystemVpnRelatedSettings();
      break;
    case 'speed':
      await _openExternal(Uri.parse('https://fast.com'));
      break;
    case 'bateria':
      await _openBateria();
      break;
    case 'store':
      await _openExternal(StoreMetadata.storeFrontUriForCurrentPlatform());
      break;
    case 'contato':
      final site = StoreMetadata.supportUri();
      if (site != null) {
        await _openExternal(site);
        break;
      }
      final mail = StoreMetadata.mailtoSupportUri();
      if (await canLaunchUrl(mail)) {
        await launchUrl(mail);
      } else {
        AppMessenger.show(
          'Add supportUrl or a valid supportEmail in StoreMetadata.',
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

Future<void> _openApn() async {
  if (_isAndroid) {
    await AppSettings.openAppSettings(type: AppSettingsType.apn);
  } else {
    await AppSettings.openAppSettings();
    AppMessenger.show(
      'On iOS: Settings → Cellular → Cellular Data Options / Network.',
    );
  }
}

Future<void> _openRedeMovel() async {
  if (_isAndroid) {
    await AppSettings.openAppSettings(type: AppSettingsType.wireless);
  } else {
    await AppSettings.openAppSettings();
    AppMessenger.show('Wi‑Fi & cellular are in the system Settings app.');
  }
}

Future<void> _openBateria() async {
  if (_isAndroid) {
    await AppSettings.openAppSettings(
      type: AppSettingsType.batteryOptimization,
    );
  } else {
    await AppSettings.openAppSettings();
    AppMessenger.show('Battery: Settings → Battery.');
  }
}

Future<void> _openExternal(Uri uri) async {
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    AppMessenger.show('Could not open the link.');
  }
}
