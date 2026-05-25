import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_product_info.dart';
import '../services/ads_actions.dart';
import '../services/vpn_settings_launcher.dart';
import '../theme/app_colors.dart';

/// Sockslite Pro reference: VPN & proxy literacy (educational only; no tunnel).
class SocksliteGuideScreen extends StatelessWidget {
  const SocksliteGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        popAfterInterstitial(context, result);
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBlack,
        appBar: AppBar(
          backgroundColor: AppColors.headerBar,
          foregroundColor: Colors.white,
          title: Text(
            'Sockslite guide',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppProductInfo.name,
                style: GoogleFonts.fredoka(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Reference for VPN and proxy concepts. This app does not create '
                'a VPN tunnel by itself; use system or third-party clients where '
                'you configure a real VPN.',
                style: GoogleFonts.nunito(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              _GuideSection(
                title: 'What a VPN does on iOS',
                body: [
                  'A VPN (Virtual Private Network) profile tells iOS to send some '
                      'or all of your device traffic through a remote server using '
                      'an encrypted tunnel, according to the profile your provider gives you.',
                  'On iPhone and iPad, VPN is managed under Settings → General → '
                      'VPN & Device Management → VPN. You add configurations from a '
                      'trusted app or MDM, or manually if your organization allows it.',
                  '${AppProductInfo.name} can help you understand and organize '
                      'details, but it does not install a Network Extension or route '
                      'traffic unless you use a separate VPN product that does.',
                ],
              ),
              _OpenVpnSettingsButton(
                label: 'Open Settings (VPN path on iOS)',
                onPressed: () {
                  runAfterInterstitial(() => openSystemVpnRelatedSettings());
                },
              ),
              const SizedBox(height: 24),
              _GuideSection(
                title: 'VPN vs SOCKS / HTTP proxy',
                body: [
                  'A system VPN on iOS typically tunnels IP traffic for apps that '
                      'respect the VPN (exceptions exist). The server endpoint and '
                      'protocol (for example IKEv2, IPsec) are defined in the VPN profile.',
                  'A SOCKS or HTTP proxy is usually an address and port your app or '
                      'tool uses to forward specific traffic. Many desktop apps support '
                      'proxy settings separately from the OS VPN.',
                  'SOCKS often carries TCP (and sometimes UDP, depending on client and '
                      'version) at a higher layer; an HTTP proxy is oriented to web traffic. '
                      'Neither is automatically the same as a full-device VPN profile.',
                  'Use the values you save in Saved profiles in whichever VPN or '
                      'proxy client supports that protocol—this app only stores them locally.',
                ],
              ),
              _OpenVpnSettingsButton(
                label: 'Open system settings',
                onPressed: () {
                  runAfterInterstitial(() => openSystemVpnRelatedSettings());
                },
              ),
              const SizedBox(height: 24),
              _GuideSection(
                title: 'What “split tunneling” means',
                body: [
                  'Split tunneling means only some traffic goes through the VPN (or '
                      'a chosen interface) while other traffic uses the normal network path.',
                  'Whether you can use split tunneling on iOS depends on the VPN '
                      'technology and the profile your provider supplies; it is not '
                      'something this app toggles on its own.',
                  'If your goal is “only work apps on VPN,” you often need a provider '
                      'that supports per-app or route-based rules on the platform you use.',
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardGrey,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  'Security tip: only enter hosts, ports, and notes you are '
                  'comfortable storing on this device. Profiles are not encrypted '
                  'beyond normal device storage; treat them like written notes.',
                  style: GoogleFonts.nunito(
                    color: Colors.white60,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({required this.title, required this.body});

  final String title;
  final List<String> body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.nunito(
            color: AppColors.accentBlue,
            fontWeight: FontWeight.w800,
            fontSize: 16,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 10),
        for (final p in body) ...[
          Text(
            p,
            style: GoogleFonts.nunito(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _OpenVpnSettingsButton extends StatelessWidget {
  const _OpenVpnSettingsButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.settings_outlined, size: 20),
      label: Text(
        label,
        style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 13),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.toggleTileBg,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
