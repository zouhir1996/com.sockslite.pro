class AdsSettings {
  final String openads;
  final List<String> banners;
  final List<String> inters;
  final List<String> natives;
  final List<String> rewards;

  AdsSettings.fromJson(Map<String, dynamic> json)
    : openads = _parseOpenAds(json['openads']),
      banners = _parseNetworkList(json['banners']),
      inters = _parseNetworkList(json['inters']),
      natives = _parseNetworkList(json['natives']),
      rewards = _parseNetworkList(json['rewards']);

  /// `false`, empty list, or missing → disabled.
  static List<String> _parseNetworkList(dynamic value) {
    if (value == false || value == null) return [];
    if (value is bool) return value ? [] : [];
    if (value is String) return value.isEmpty ? [] : [value];
    if (value is List) {
      return value
          .where((e) => e != false && e != null)
          .map((e) => e.toString())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  static String _parseOpenAds(dynamic value) {
    if (value == false || value == null) return '';
    if (value is bool) return '';
    if (value is String) return value;
    return '';
  }
}
