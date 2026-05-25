/// App-level hooks fired when a full-screen ad finishes (or is skipped).
abstract final class AdCallbacks {
  static void Function()? onInterstitialDismissed;
}
