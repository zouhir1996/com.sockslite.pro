class FacebookData {
  final List<String> bannerIds;
  final List<String> interIds;
  final List<String> nativeIds;
  final List<String> nativeBannerIds;
  final List<String> rewardIds;

  FacebookData.fromJson(Map<String, dynamic> json)
    : bannerIds = List<String>.from(json['bannerIds'] ?? []),
      interIds = List<String>.from(json['interIds'] ?? []),
      nativeIds = List<String>.from(json['nativeIds'] ?? []),
      nativeBannerIds = List<String>.from(json['nativeBannerIds'] ?? []),
      rewardIds = List<String>.from(json['rewardIds'] ?? []);
}
