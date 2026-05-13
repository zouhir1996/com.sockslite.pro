import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../ads/interstitial_controller.dart';
import '../ads/rewarded_controller.dart';
import '../screens/connection_profiles_screen.dart';
import '../screens/sockslite_guide_screen.dart';
import '../services/tool_actions.dart';
import '../theme/app_colors.dart';
import '../util/push_after_dialog.dart';
import 'privacy_policy_dialog.dart';

Future<void> showFerramentasDialog(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Tools',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const _FerramentasBody();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

class _Tool {
  const _Tool(this.id, this.label, this.icon, this.color);
  final String id;
  final String label;
  final IconData icon;
  final Color color;
}

class _FerramentasBody extends StatelessWidget {
  const _FerramentasBody();

  /// Platform-appropriate store label on iOS vs Android.
  static List<_Tool> _tools() {
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final lojaLabel = isAndroid ? 'GOOGLE PLAY' : 'APP STORE';
    final list = <_Tool>[
      const _Tool('apn', 'APN', Icons.sim_card, Color(0xFF90CAF9)),
      const _Tool(
        'rede_movel',
        'MOBILE NETWORK',
        Icons.signal_cellular_alt,
        Color(0xFF81C784),
      ),
      const _Tool('rotear', 'ROUTE', Icons.cloud_outlined, Color(0xFF64B5F6)),
      const _Tool(
        'sockslite_guide',
        'SOCKSLITE GUIDE',
        Icons.menu_book_outlined,
        Color(0xFF4FC3F7),
      ),
      const _Tool(
        'saved_profiles',
        'SAVED PROFILES',
        Icons.folder_special_outlined,
        Color(0xFFAED581),
      ),
      const _Tool('speed', 'SPEED TEST', Icons.speed, Color(0xFFFFB74D)),
      const _Tool(
        'bateria',
        'BATTERY',
        Icons.battery_charging_full,
        Color(0xFFFFF176),
      ),
      _Tool('store', lojaLabel, Icons.play_arrow_rounded, Color(0xFF64B5F6)),
      const _Tool(
        'contato',
        'CONTACT',
        Icons.email_outlined,
        Color(0xFF42A5F5),
      ),
      const _Tool('telegram', 'TELEGRAM', Icons.send, Color(0xFF29B6F6)),
      const _Tool(
        'avaliar',
        'RATE APP',
        Icons.thumb_up_alt_outlined,
        Color(0xFFFFB74D),
      ),
      const _Tool(
        'instagram',
        'INSTAGRAM',
        Icons.camera_alt_outlined,
        Color(0xFFE040FB),
      ),
      const _Tool(
        'restaurar',
        'RESTORE',
        Icons.cleaning_services_outlined,
        Color(0xFFB0BEC5),
      ),
      const _Tool(
        'privacy',
        'PRIVACY',
        Icons.privacy_tip_outlined,
        Color(0xFFFFEE58),
      ),
    ];
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final tools = _tools();
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.sizeOf(context).width * 0.92,
          height: math.min(640, MediaQuery.sizeOf(context).height * 0.72),
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF757575), Color(0xFF424242)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'TOOLS',
                        style: GoogleFonts.fredoka(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        InterstitialController.instance.showInterstitialOrRun(() {
                          Navigator.of(context).pop();
                        });
                      },
                      icon: const Icon(
                        Icons.close,
                        color: Colors.redAccent,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 2.4,
                        ),
                    itemCount: tools.length,
                    itemBuilder: (_, i) {
                      final t = tools[i];
                      return _ToolTile(tool: t);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({required this.tool});

  final _Tool tool;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.toggleTileBg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          if (tool.id == 'privacy') {
            if (context.mounted) showPrivacyPolicyDialog(context);
            return;
          }
          if (tool.id == 'sockslite_guide') {
            RewardedAdController.instance.showRewardedThenRun(() {
              pushAfterClosingDialog(context, const SocksliteGuideScreen());
            });
            return;
          }
          if (tool.id == 'saved_profiles') {
            RewardedAdController.instance.showRewardedThenRun(() {
              pushAfterClosingDialog(
                context,
                const ConnectionProfilesScreen(),
              );
            });
            return;
          }
          unawaited(runToolAction(tool.id));
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.toggleTileBorder, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(tool.icon, color: tool.color, size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tool.label,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
