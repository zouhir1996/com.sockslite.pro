import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_messenger.dart';
import '../services/ads_actions.dart';
import '../config/app_product_info.dart';
import '../theme/app_colors.dart';

Future<void> showRegistroDialog(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Log',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const _RegistroBody();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

class _LogLine {
  const _LogLine(this.text, this.color);
  final String text;
  final Color color;
}

String _logTime12h() {
  final n = DateTime.now();
  final hour24 = n.hour;
  final h = hour24 == 0
      ? 12
      : (hour24 > 12 ? hour24 - 12 : hour24);
  final m = n.minute.toString().padLeft(2, '0');
  final ap = hour24 < 12 ? 'AM' : 'PM';
  return '$h:$m $ap';
}

String _platformLogLabel() {
  if (kIsWeb) return 'WEB';
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'IPHONE, iOS',
    TargetPlatform.android => 'ANDROID',
    _ => 'DEVICE',
  };
}

class _RegistroBody extends StatefulWidget {
  const _RegistroBody();

  @override
  State<_RegistroBody> createState() => _RegistroBodyState();
}

class _RegistroBodyState extends State<_RegistroBody> {
  late List<_LogLine> _lines;
  PackageInfo? _packageInfo;

  List<_LogLine> _buildLines({
    required bool limpar,
    required bool ocultar,
  }) {
    if (limpar) {
      return const [
        _LogLine(
          '[—] CLEAR LOG enabled: history is not kept for this view.',
          AppColors.logGreen,
        ),
      ];
    }
    final ts = _logTime12h();
    final plat = _platformLogLabel();
    final head = '[$ts] RUNNING ON $plat — ${AppProductInfo.name}';
    if (ocultar) {
      return [
        _LogLine(head, Colors.white),
        const _LogLine(
          '[—] HIDE LOG enabled: remaining entries omitted.',
          Colors.white54,
        ),
      ];
    }
    final ver = _packageInfo != null
        ? '[$ts] APP VERSION: ${_packageInfo!.version} '
            '(${_packageInfo!.buildNumber}) — RELEASE'
        : '[$ts] APP VERSION: …';
    return [
      _LogLine(head, Colors.white),
      _LogLine(ver, Colors.white),
      _LogLine('[$ts] SERVERS UPDATED', AppColors.logGreen),
    ];
  }

  @override
  void initState() {
    super.initState();
    _lines = _buildLines(limpar: false, ocultar: false);
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    final pkg = await PackageInfo.fromPlatform();
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _packageInfo = pkg;
      final limpar = p.getBool('toggle.limpar_log') ?? false;
      final ocultar = p.getBool('toggle.ocultar_log') ?? false;
      _lines = _buildLines(limpar: limpar, ocultar: ocultar);
    });
  }

  String get _textBlock => _lines.map((e) => e.text).join('\n');

  Future<void> _share() async {
    if (_lines.isEmpty) {
      AppMessenger.show('Nothing to share.');
      return;
    }
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: _textBlock,
          subject: '${AppProductInfo.name} — Log',
        ),
      );
    } catch (_) {
      if (!mounted) return;
      AppMessenger.show('Could not open the system share sheet.');
    }
  }

  Future<void> _copy() async {
    if (_lines.isEmpty) {
      AppMessenger.show('Nothing to copy.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: _textBlock));
    if (!mounted) return;
    AppMessenger.show('Copied to clipboard.');
  }

  void _delete() {
    setState(() {
      _lines = [
        const _LogLine(
          '[—] LOG CLEARED BY USER',
          AppColors.logGreen,
        ),
      ];
    });
    AppMessenger.show('Log cleared.');
  }

  @override
  Widget build(BuildContext context) {
    final mono = GoogleFonts.robotoMono(fontSize: 12, height: 1.45);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.sizeOf(context).width * 0.92,
          height: math.min(520, MediaQuery.sizeOf(context).height * 0.58),
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: AppColors.cardGrey,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.06,
                  child: Center(
                    child: Icon(
                      Icons.power_settings_new,
                      size: 180,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 6, 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _share,
                          icon: const Icon(
                            Icons.share_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        IconButton(
                          onPressed: _copy,
                          icon: const Icon(
                            Icons.copy_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        IconButton(
                          onPressed: _delete,
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'LOG',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => popAfterInterstitial(context),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.redAccent,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Colors.white12),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(14),
                      itemCount: _lines.length,
                      separatorBuilder: (_, _) =>
                          const Divider(color: Colors.white10, height: 20),
                      itemBuilder: (_, i) {
                        final e = _lines[i];
                        return Text(
                          e.text,
                          style: mono.copyWith(color: e.color),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
