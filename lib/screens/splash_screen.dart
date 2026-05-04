import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_product_info.dart';
import '../theme/app_colors.dart';
import 'legal_notice_screen.dart';

/// Branded splash matching Sockslite Pro (blue, key icon, PRO badge, loader).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goNext();
  }

  Future<void> _goNext() async {
    await Future<void>.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;
    // Always show legal disclosure on each launch; accept still records consent.
    const Widget next = LegalNoticeScreen();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => next,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBlue,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AppIconTile(),
                  const SizedBox(height: 28),
                  Text(
                    AppProductInfo.name,
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 2),
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.8,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 56),
          ],
        ),
      ),
    );
  }
}

class _AppIconTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: Icon(
              Icons.vpn_key_rounded,
              size: 72,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Text(
              'PRO',
              style: GoogleFonts.nunito(
                color: AppColors.proRed,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
