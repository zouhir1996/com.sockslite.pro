class NetworkIndex {
  static final NetworkIndex _instance = NetworkIndex._internal();
  factory NetworkIndex() => _instance;
  NetworkIndex._internal();

  int bannerIndex = 0;
  int interIndex = 0;
  int rewardIndex = 0;
  int nativeIndex = 0;

  void incrementBannerIndex(int length) {
    if (length == 0) return;
    bannerIndex = (bannerIndex + 1) % length;
  }

  void incrementInterIndex(int length) {
    if (length == 0) return;
    interIndex = (interIndex + 1) % length;
  }

  void incrementRewardIndex(int length) {
    if (length == 0) return;
    rewardIndex = (rewardIndex + 1) % length;
  }

  void incrementNativeIndex(int length) {
    if (length == 0) return;
    nativeIndex = (nativeIndex + 1) % length;
  }
}
