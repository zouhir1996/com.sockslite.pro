class ApplovinData {
  final String sdkKey;
  final String bannerId;
  final String openAdsId;
  final String interId;
  final String nativeId;
  final String rewardId;

  ApplovinData.fromJson(Map<String, dynamic> json)
    : sdkKey = json['sdk_key'] ?? "",
      bannerId = json['bannerId'] ?? "",
      openAdsId = json['openAdsIds'] ?? "",
      interId = json['interId'] ?? "",
      nativeId = json['nativeId'] ?? "",
      rewardId = json['rewardId'] ?? "";
}
