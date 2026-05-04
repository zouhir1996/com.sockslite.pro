import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ads/rewarded_controller.dart';
import '../app_messenger.dart';
import '../config/app_product_info.dart';
import '../config/store_metadata.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';

/// First-run legal conduct screen (scrollable card + decline / accept).
class LegalNoticeScreen extends StatelessWidget {
  const LegalNoticeScreen({super.key});

  Future<void> _accept(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('legal_accepted', true);
    if (!context.mounted) return;
    RewardedAdController.instance.runAfterRewarded(context, () {
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      );
    });
  }

  Future<void> _openIfPresent(BuildContext context, Uri? uri) async {
    if (uri == null) {
      AppMessenger.show('Add the URL in app configuration before release.');
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        AppMessenger.show('Could not open the link.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.fredoka(
      fontWeight: FontWeight.w700,
      fontSize: 16,
      color: Colors.white,
      height: 1.35,
    );
    final subHeaderStyle = GoogleFonts.fredoka(
      fontWeight: FontWeight.w700,
      fontSize: 14,
      color: Colors.white,
      height: 1.35,
    );
    final bodyStyle = GoogleFonts.fredoka(
      fontWeight: FontWeight.w600,
      fontSize: 12.5,
      color: Colors.white,
      height: 1.45,
    );
    final mutedStyle = GoogleFonts.fredoka(
      fontWeight: FontWeight.w600,
      fontSize: 12,
      color: Colors.white70,
      height: 1.45,
    );

    final termsUri = StoreMetadata.termsOfUseUri();
    final privacyUri = StoreMetadata.privacyPolicyUri();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBlack,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.modalBorder,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.modalBorder.withValues(alpha: 0.25),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'REQUIRED LEGAL CONDUCT',
                          style: titleStyle,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'LEGAL USE DISCLOSURE',
                          style: subHeaderStyle,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'The app is still under development and will be '
                          'more powerful soon.',
                          style: mutedStyle,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'This app is intended for lawful everyday privacy, '
                          'personal network awareness, connection organization, '
                          'public Wi-Fi safety, and session monitoring.',
                          style: bodyStyle,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Users must use this app only in compliance with '
                          'applicable laws, platform rules, service provider '
                          'terms, and any agreements that apply to their network '
                          'or online activity.',
                          style: bodyStyle,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'DO NOT CONFUSE PRIVACY WITH IMPUNITY.',
                          style: bodyStyle,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Any illegal, harmful, abusive, or unauthorized '
                          'activity is strictly prohibited.',
                          style: bodyStyle,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'SERIOUS CRIMINAL ACTIVITY, INCLUDING CHILD '
                          'EXPLOITATION, TERRORISM, DRUG TRAFFICKING, FRAUD, '
                          'UNAUTHORIZED ACCESS, CYBER ATTACKS, HARASSMENT, OR '
                          'ANY OTHER ILLEGAL ACTIVITY, IS NOT ACCEPTABLE.',
                          style: bodyStyle,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Users remain fully responsible for their actions '
                          'and may be held accountable by competent authorities '
                          'where applicable.',
                          style: bodyStyle,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'The company may cooperate with law enforcement, '
                          'regulators, platform providers, or other authorized '
                          'parties when required or permitted by law.',
                          style: bodyStyle,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'By using this app, you agree to use it responsibly, '
                          'legally, and in accordance with all applicable rules '
                          'and obligations.',
                          style: bodyStyle,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'IF YOU USE THIS APP LAWFULLY AND RESPONSIBLY, YOU '
                          'HAVE NOTHING TO WORRY ABOUT.',
                          style: bodyStyle,
                        ),
                        if (termsUri != null || privacyUri != null) ...[
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.start,
                            children: [
                              if (termsUri != null)
                                OutlinedButton(
                                  onPressed: () => unawaited(
                                    _openIfPresent(context, termsUri),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white38),
                                  ),
                                  child: Text(
                                    'Terms of use',
                                    style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              if (privacyUri != null)
                                OutlinedButton(
                                  onPressed: () => unawaited(
                                    _openIfPresent(context, privacyUri),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white38),
                                  ),
                                  child: Text(
                                    'Privacy policy',
                                    style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _FootButton(
                      label: 'I DECLINE',
                      color: const Color(0xFF58181F),
                      onPressed: () {
                        AppMessenger.show(
                          'You must accept the terms above to use '
                          '${AppProductInfo.name}. You can leave the app using '
                          'the system app switcher.',
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FootButton(
                      label: 'I ACCEPT THE TERMS',
                      color: const Color(0xFF1E5622),
                      onPressed: () => _accept(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FootButton extends StatelessWidget {
  const _FootButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
