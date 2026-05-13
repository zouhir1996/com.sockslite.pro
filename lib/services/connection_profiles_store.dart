import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_product_info.dart';
import '../models/saved_connection_profile.dart';

/// Device-local JSON list of [SavedConnectionProfile] (not a VPN tunnel).
final class ConnectionProfilesStore {
  ConnectionProfilesStore._();

  static const _prefsKey = 'connection_profiles.v1';

  static Future<List<SavedConnectionProfile>> loadAll() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final out = <SavedConnectionProfile>[];
      for (final e in decoded) {
        final row = SavedConnectionProfile.tryFromJson(e);
        if (row != null) out.add(row);
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAll(List<SavedConnectionProfile> list) async {
    final p = await SharedPreferences.getInstance();
    final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
    await p.setString(_prefsKey, encoded);
  }

  static List<String> _detailLines(SavedConnectionProfile e) => [
    'Label: ${e.label}',
    'Protocol / type: ${e.protocolNote.isEmpty ? '—' : e.protocolNote}',
    'Host: ${e.host.isEmpty ? '—' : e.host}',
    'Port: ${e.port ?? '—'}',
    'Notes: ${e.notes.isEmpty ? '—' : e.notes}',
  ];

  static String exportProfileText(SavedConnectionProfile e) {
    return [
      '${AppProductInfo.name} — connection profile',
      'For use in your VPN or proxy client (this app does not create a tunnel).',
      '',
      ..._detailLines(e),
    ].join('\n');
  }

  static String exportAllText(List<SavedConnectionProfile> list) {
    if (list.isEmpty) {
      return '${AppProductInfo.name} — no saved profiles.';
    }
    final buf = StringBuffer()
      ..writeln('${AppProductInfo.name} — saved connection profiles')
      ..writeln(
        'Reference only; use in your VPN or proxy client as applicable.',
      )
      ..writeln();
    for (var i = 0; i < list.length; i++) {
      buf.writeln('--- Profile ${i + 1} ---');
      for (final line in _detailLines(list[i])) {
        buf.writeln(line);
      }
      buf.writeln();
    }
    return buf.toString();
  }
}
