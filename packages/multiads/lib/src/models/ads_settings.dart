class AdsSettings {
  final String openads;
  final List<String> banners;
  final List<String> inters;
  final List<String> natives;
  final List<String> rewards;

  AdsSettings.fromJson(Map<String, dynamic> json)
    : openads = json['openads'] ?? "",
      banners = List<String>.from(json['banners'] ?? []),
      inters = List<String>.from(json['inters'] ?? []),
      natives = List<String>.from(json['natives'] ?? []),
      rewards = List<String>.from(json['rewards'] ?? []);
}
