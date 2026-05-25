class Log {
  static bool enabled = true;

  static void log(String message) {
    if (enabled) print("[MultiAds] $message");
  }
}
