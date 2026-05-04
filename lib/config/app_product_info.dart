/// Product copy used for App Store–aligned disclosure (what the app actually does).
///
/// The in-app “connect” / “session” experience is a **local UI and preferences**
/// layer. A full iOS VPN (traffic routing) requires a Network Extension, server
/// infrastructure, and entitlements—out of scope for this client unless you add them.
abstract final class AppProductInfo {
  static const String name = 'Sockslite Pro';

  /// Shown on the home screen and in settings.
  static const String connectionRealityShort =
      'Session and "connect" are in-app only.';

  /// Short summary aligned with the first-run legal screen (for reuse elsewhere).
  static const String legalProductParagraph =
      'The app is under development. Use it only for lawful privacy, network '
      'awareness, and session monitoring, in compliance with applicable laws and '
      'agreements.';

  static const String settingsReality =
      'These switches save preferences on this device for your next session. '
      'They do not modify iOS system VPN, carrier APN, or routing by themselves.';
}
