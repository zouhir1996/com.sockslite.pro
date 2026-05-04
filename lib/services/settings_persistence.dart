import 'package:shared_preferences/shared_preferences.dart';

/// Persist VPN-style toggles and reset (RESET / RESTORE).
final class SettingsPersistence {
  SettingsPersistence._();

  static const _prefix = 'toggle.';

  static const Map<String, bool> defaults = {
    'encaminhar_udp': true,
    'compressao_ssh': false,
    'tun_hev_socks5': true,
    'tcp_delay': false,
    'rotas_ipv6': false,
    'wakelock': true,
    'ocultar_log': false,
    'limpar_log': false,
    'modo_noturno': true,
    'velocimetro': false,
    'limitar_threads': false,
    'pinger': false,
  };

  /// English UI label → storage slug (unchanged for existing prefs).
  static const Map<String, String> labelToSlug = {
    'FORWARD UDP': 'encaminhar_udp',
    'SSH COMPRESSION': 'compressao_ssh',
    'TUN HEV-SOCKS5': 'tun_hev_socks5',
    'TCP DELAY': 'tcp_delay',
    'IPV6 ROUTES': 'rotas_ipv6',
    'WAKELOCK': 'wakelock',
    'HIDE LOG': 'ocultar_log',
    'CLEAR LOG': 'limpar_log',
    'DARK MODE': 'modo_noturno',
    'SPEED METER': 'velocimetro',
    'LIMIT THREADS': 'limitar_threads',
    'PINGER': 'pinger',
  };

  static Future<bool?> loadSlug(String slug) async {
    final p = await SharedPreferences.getInstance();
    final key = '$_prefix$slug';
    if (!p.containsKey(key)) return null;
    return p.getBool(key);
  }

  static Future<void> saveSlug(String slug, bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('$_prefix$slug', value);
  }

  static Future<void> saveLabel(String label, bool value) async {
    final slug = labelToSlug[label];
    if (slug == null) return;
    await saveSlug(slug, value);
  }

  static Future<Map<String, bool>> loadAllForLabels(
    Iterable<String> labels,
  ) async {
    final p = await SharedPreferences.getInstance();
    final out = <String, bool>{};
    for (final label in labels) {
      final slug = labelToSlug[label];
      if (slug == null) continue;
      final key = '$_prefix$slug';
      out[label] = p.containsKey(key)
          ? (p.getBool(key) ?? false)
          : (defaults[slug] ?? false);
    }
    return out;
  }

  static Future<void> resetAllToggles() async {
    final p = await SharedPreferences.getInstance();
    for (final e in defaults.entries) {
      await p.setBool('$_prefix${e.key}', e.value);
    }
    await p.remove(_customDnsKey);
  }

  /// Optional comma-separated IPv4 list for UI / future profiles (device-local).
  static const String _customDnsKey = 'connection.custom_dns';

  static Future<String> loadCustomDns() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_customDnsKey) ?? '';
  }

  static Future<void> saveCustomDns(String csv) async {
    final p = await SharedPreferences.getInstance();
    final t = csv.trim();
    if (t.isEmpty) {
      await p.remove(_customDnsKey);
    } else {
      await p.setString(_customDnsKey, t);
    }
  }

  static const String _serverProfileKey = 'connection.server_profile';
  static const String serverProfileRandom = 'random';
  static const String serverProfileAuto = 'auto';

  static Future<void> saveServerProfile(String profile) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_serverProfileKey, profile);
  }

  static Future<String> loadServerProfile() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_serverProfileKey) ?? serverProfileRandom;
  }

  /// Same key as home “remaining connection time” (seconds).
  static const String connectionRemainingSecondsKey =
      'connection_remaining_seconds';

  static const int defaultConnectionRemainingSeconds = 86400;

  static Future<void> addConnectionRemainingSeconds(int delta) async {
    if (delta <= 0) return;
    final p = await SharedPreferences.getInstance();
    final cur =
        p.getInt(connectionRemainingSecondsKey) ??
            defaultConnectionRemainingSeconds;
    await p.setInt(connectionRemainingSecondsKey, cur + delta);
  }
}
