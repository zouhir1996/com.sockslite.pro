import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_messenger.dart';
import '../services/ads_actions.dart';
import '../config/app_product_info.dart';
import '../screens/connection_profiles_screen.dart';
import '../screens/sockslite_guide_screen.dart';
import '../services/settings_persistence.dart';
import '../theme/app_colors.dart';
import '../util/push_after_dialog.dart';

bool _isValidIpv4(String s) {
  final parts = s.split('.');
  if (parts.length != 4) return false;
  for (final p in parts) {
    final n = int.tryParse(p);
    if (n == null || n < 0 || n > 255) return false;
  }
  return true;
}

/// Comma-separated IPv4; empty string is valid (use system default).
bool _validateDnsCsv(String raw) {
  for (final part in raw.split(',')) {
    final ip = part.trim();
    if (ip.isEmpty) continue;
    if (!_isValidIpv4(ip)) return false;
  }
  return true;
}

String _dnsSubtitleFromStored(String stored) {
  final t = stored.trim();
  if (t.isEmpty) return 'System default — tap to edit';
  if (t.length <= 40) return t;
  return '${t.substring(0, 37)}…';
}

/// Short lines for the (i) button — all local preferences only.
const Map<String, String> _settingHelp = {
  'FORWARD UDP':
      'Prefer UDP forwarding when your connection profile supports it. Saved on this device.',
  'SSH COMPRESSION':
      'Prefer SSH compression when supported. Does not change server behavior by itself.',
  'TUN HEV-SOCKS5':
      'UI preference for HEV/SOCKS-style tunnel options in your profile.',
  'TCP DELAY': 'TCP tuning preference stored locally for your session preset.',
  'IPV6 ROUTES':
      'Whether to prefer IPv6 routes in the client preset (local only).',
  'WAKELOCK': 'Keep the screen awake during an active in-app session.',
  'HIDE LOG': 'Show fewer lines in the Log screen.',
  'CLEAR LOG': 'Prefer an empty log view until new entries are generated.',
  'DARK MODE': 'Use this app’s dark styling.',
  'SPEED METER': 'Show speed indicators where the UI provides them.',
  'LIMIT THREADS': 'Reduce parallel worker threads in supported modes.',
  'DNS':
      'Optional IPv4 DNS servers for your saved profile. Stored on device only.',
  'PINGER': 'Enable periodic reachability checks when connected (UI session).',
};

Future<void> showAjustesDialog(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Settings',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const _AjustesBody();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

class _AjustesBody extends StatefulWidget {
  const _AjustesBody();

  @override
  State<_AjustesBody> createState() => _AjustesBodyState();
}

class _AjustesBodyState extends State<_AjustesBody> {
  final Map<String, bool> _toggles = {
    'FORWARD UDP': true,
    'SSH COMPRESSION': false,
    'TUN HEV-SOCKS5': true,
    'TCP DELAY': false,
    'IPV6 ROUTES': false,
    'WAKELOCK': true,
    'HIDE LOG': false,
    'CLEAR LOG': false,
    'DARK MODE': true,
    'SPEED METER': false,
    'LIMIT THREADS': false,
    'PINGER': false,
  };

  String _dnsSubtitle = _dnsSubtitleFromStored('');

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _hydrate() async {
    final loaded = await SettingsPersistence.loadAllForLabels(_toggles.keys);
    final dns = await SettingsPersistence.loadCustomDns();
    if (!mounted) return;
    setState(() {
      for (final e in loaded.entries) {
        _toggles[e.key] = e.value;
      }
      _dnsSubtitle = _dnsSubtitleFromStored(dns);
    });
  }

  Future<void> _setToggle(String label, bool value) async {
    setState(() => _toggles[label] = value);
    await SettingsPersistence.saveLabel(label, value);
  }

  Future<void> _redefinir() async {
    await SettingsPersistence.resetAllToggles();
    if (!mounted) return;
    setState(() {
      for (final label in _toggles.keys) {
        final slug = SettingsPersistence.labelToSlug[label];
        if (slug != null) {
          _toggles[label] = SettingsPersistence.defaults[slug] ?? false;
        }
      }
      _dnsSubtitle = _dnsSubtitleFromStored('');
    });
    AppMessenger.show('Settings and custom DNS restored to defaults.');
  }

  Future<void> _openDnsEditor() async {
    final initial = await SettingsPersistence.loadCustomDns();
    if (!mounted) return;
    final controller = TextEditingController(text: initial);
    try {
      final result = await showDialog<String?>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.cardGrey,
          title: Text(
            'Custom DNS',
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter IPv4 addresses separated by commas, or leave empty to '
                  'use the system default. Values are stored on this device only '
                  'and do not change iOS system DNS without a full VPN profile.',
                  style: GoogleFonts.nunito(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  style: GoogleFonts.nunito(color: Colors.white),
                  maxLength: 200,
                  maxLines: 2,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'e.g. 1.1.1.1, 8.8.8.8',
                    hintStyle: GoogleFonts.nunito(color: Colors.white38),
                    filled: true,
                    fillColor: AppColors.toggleTileBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.toggleTileBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.accentBlue),
                    ),
                  ),
                  keyboardType: TextInputType.text,
                  autocorrect: false,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => popAfterInterstitial(ctx, null),
              child: Text(
                'Cancel',
                style: GoogleFonts.nunito(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                final t = controller.text;
                if (!_validateDnsCsv(t)) {
                  AppMessenger.show(
                    'Use valid IPv4 addresses, separated by commas (e.g. 1.1.1.1, 8.8.8.8).',
                  );
                  return;
                }
                Navigator.of(ctx).pop(t.trim());
              },
              child: Text(
                'Save',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
      if (result == null || !mounted) return;
      await SettingsPersistence.saveCustomDns(result);
      if (!mounted) return;
      setState(() {
        _dnsSubtitle = _dnsSubtitleFromStored(result.isEmpty ? '' : result);
      });
      AppMessenger.show('Custom DNS saved on this device.');
    } finally {
      controller.dispose();
    }
  }

  void _showHelp(String label) {
    final text = _settingHelp[label];
    if (text == null) return;
    AppMessenger.show(text);
  }

  @override
  Widget build(BuildContext context) {
    const labelsLeft = [
      'FORWARD UDP',
      'TUN HEV-SOCKS5',
      'IPV6 ROUTES',
      'HIDE LOG',
      'DARK MODE',
      'LIMIT THREADS',
    ];
    const labelsRight = [
      'SSH COMPRESSION',
      'TCP DELAY',
      'WAKELOCK',
      'CLEAR LOG',
      'SPEED METER',
      'DNS',
    ];

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.sizeOf(context).width * 0.94,
          height: math.min(720, MediaQuery.sizeOf(context).height * 0.86),
          constraints: const BoxConstraints(maxWidth: 440),
          decoration: BoxDecoration(
            color: AppColors.modalGrey.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black45, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 4, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'SETTINGS',
                        style: GoogleFonts.fredoka(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
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
              const Divider(height: 1, color: Colors.black26),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          AppProductInfo.settingsReality,
                          style: GoogleFonts.nunito(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ),
                      _HubLinkCard(
                        icon: Icons.menu_book_outlined,
                        title: 'Sockslite guide',
                        subtitle: 'VPN & proxy reference (no tunnel)',
                        onTap: () {
                          runAfterRewarded(() {
                            if (!context.mounted) return;
                            pushAfterClosingDialog(
                              context,
                              const SocksliteGuideScreen(),
                            );
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _HubLinkCard(
                        icon: Icons.folder_special_outlined,
                        title: 'Saved connection profiles',
                        subtitle: 'For your VPN or proxy client (local only)',
                        onTap: () {
                          runAfterInterstitial(() {
                            if (!context.mounted) return;
                            pushAfterClosingDialog(
                              context,
                              const ConnectionProfilesScreen(),
                            );
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: labelsLeft
                                  .map(
                                    (l) => _ToggleRow(
                                      label: l,
                                      value: _toggles[l] ?? false,
                                      isDns: false,
                                      onHelp: () => _showHelp(l),
                                      onChanged: (v) => _setToggle(l, v),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              children: labelsRight
                                  .map(
                                    (l) => l == 'DNS'
                                        ? _ToggleRow(
                                            label: l,
                                            value: false,
                                            isDns: true,
                                            dnsSubtitle: _dnsSubtitle,
                                            onHelp: () => _showHelp('DNS'),
                                            onDnsTap: () =>
                                                unawaited(_openDnsEditor()),
                                            onChanged: (_) {},
                                          )
                                        : _ToggleRow(
                                            label: l,
                                            value: _toggles[l] ?? false,
                                            isDns: false,
                                            onHelp: () => _showHelp(l),
                                            onChanged: (v) => _setToggle(l, v),
                                          ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _ToggleRow(
                        label: 'PINGER',
                        value: _toggles['PINGER'] ?? false,
                        isDns: false,
                        onHelp: () => _showHelp('PINGER'),
                        onChanged: (v) => _setToggle('PINGER', v),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: Material(
                          color: AppColors.toggleTileBg,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              runAfterRewarded(() {
                                if (!mounted) return;
                                unawaited(_redefinir());
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.toggleTileBorder,
                                ),
                              ),
                              child: Text(
                                'RESET',
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _HubLinkCard extends StatelessWidget {
  const _HubLinkCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.toggleTileBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.toggleTileBorder),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.accentBlue, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.nunito(
                        color: Colors.white60,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.isDns = false,
    this.dnsSubtitle,
    this.onDnsTap,
    this.onHelp,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDns;
  final String? dnsSubtitle;
  final VoidCallback? onDnsTap;
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    final core = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.toggleTileBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.toggleTileBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onHelp ?? () {},
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.lightBlueAccent.shade100,
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    softWrap: true,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5,
                      height: 1.15,
                    ),
                  ),
                  if (isDns && dnsSubtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      dnsSubtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        color: Colors.white54,
                        fontWeight: FontWeight.w600,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isDns)
              Icon(Icons.chevron_right, color: Colors.white54, size: 22)
            else
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: AppColors.toggleGreen,
                activeTrackColor: AppColors.toggleGreen.withValues(alpha: 0.45),
                inactiveThumbColor: Colors.grey.shade400,
                inactiveTrackColor: Colors.grey.shade800,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        ),
      ),
    );

    if (isDns && onDnsTap != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => onDnsTap!(),
        child: core,
      );
    }
    return core;
  }
}
