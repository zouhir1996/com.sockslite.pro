import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ads/interstitial_controller.dart';
import '../app_messenger.dart';
import '../config/app_product_info.dart';
import '../config/store_metadata.dart';
import '../theme/app_colors.dart';

/// In-app privacy summary. Host the definitive policy at [StoreMetadata.privacyPolicyUrl].
void showPrivacyPolicyDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.cardGrey,
      title: Text(
        'Privacy',
        style: GoogleFonts.nunito(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'What this app does',
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppProductInfo.connectionRealityShort,
              style: GoogleFonts.nunito(
                color: Colors.white70,
                height: 1.45,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Data on your device',
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We store preferences and session-related UI state locally '
              '(SharedPreferences). No account is required for this build. '
              'We do not run third-party analytics in this client unless you add them.',
              style: GoogleFonts.nunito(
                color: Colors.white70,
                height: 1.45,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'When you share',
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'If you export or share the log, that content leaves the device under '
              'your control. Email and web links open in other apps or the browser.',
              style: GoogleFonts.nunito(
                color: Colors.white70,
                height: 1.45,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'App Store',
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your listing’s Privacy Nutrition Labels and the privacy policy URL '
              'in App Store Connect must match what you actually collect. Update '
              'this screen and your hosted policy before submission.',
              style: GoogleFonts.nunito(
                color: Colors.white70,
                height: 1.45,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (StoreMetadata.privacyPolicyUri() != null)
          TextButton(
            onPressed: () async {
              final uri = StoreMetadata.privacyPolicyUri();
              if (uri == null) return;
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                if (ctx.mounted) {
                  AppMessenger.show('Could not open the privacy policy URL.');
                }
              }
            },
            child: Text(
              'Full policy',
              style: GoogleFonts.nunito(
                color: AppColors.accentBlue,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        TextButton(
          onPressed: () {
            InterstitialController.instance.showInterstitialOrRun(() {
              Navigator.of(ctx).pop();
            });
          },
          child: Text(
            'OK',
            style: GoogleFonts.nunito(
              color: AppColors.accentBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}
