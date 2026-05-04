import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ads/admob_config.dart';
import '../ads/banner_ad_slot.dart';
import '../ads/interstitial_controller.dart';
import '../ads/rewarded_controller.dart';
import '../app_messenger.dart';
import '../config/app_product_info.dart';
import '../services/settings_persistence.dart';
import '../theme/app_colors.dart';
import '../widgets/ajustes_dialog.dart';
import '../widgets/ferramentas_dialog.dart';
import '../widgets/network_stats_bar.dart';
import '../widgets/registro_dialog.dart';
import '../widgets/selection_card.dart';

/// Main Sockslite Pro UI (dark theme, power ring, cards, custom bottom bar).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

String _formatRemainingConnection(int seconds) {
  final s = seconds.clamp(0, 86400 * 999);
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = s % 60;
  if (h > 0) {
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${sec.toString().padLeft(2, '0')}';
  }
  return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = -1;
  bool _vpnOn = false;
  /// Seconds left on the plan; decrements once per second while UI "connected."
  int _remainingSeconds =
      SettingsPersistence.defaultConnectionRemainingSeconds;
  Timer? _connectionTicker;
  Timer? _statsTicker;
  int _uploadBytes = 0;
  int _downloadBytes = 0;
  String _serverProfile = SettingsPersistence.serverProfileRandom;


  @override
  void initState() {
    super.initState();
    unawaited(_loadVpnState());
    unawaited(_loadServerProfile());
  }

  Future<void> _loadServerProfile() async {
    final profile = await SettingsPersistence.loadServerProfile();
    if (!mounted) return;
    setState(() => _serverProfile = profile);
  }

  @override
  void dispose() {
    _connectionTicker?.cancel();
    _statsTicker?.cancel();
    super.dispose();
  }

  Future<void> _loadVpnState() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _vpnOn = p.getBool('vpn_ui_connected') ?? false;
      _remainingSeconds = p.getInt(
            SettingsPersistence.connectionRemainingSecondsKey,
          ) ??
          SettingsPersistence.defaultConnectionRemainingSeconds;
    });
    _syncConnectionTicker();
    _syncStatsTicker();
  }

  /// UI-only session counters while “connected”; not real interface traffic.
  void _syncStatsTicker() {
    _statsTicker?.cancel();
    _statsTicker = null;
    if (!_vpnOn) {
      if (_uploadBytes != 0 || _downloadBytes != 0) {
        setState(() {
          _uploadBytes = 0;
          _downloadBytes = 0;
        });
      }
      return;
    }
    final rnd = math.Random();
    _statsTicker = Timer.periodic(const Duration(milliseconds: 750), (_) {
      if (!mounted || !_vpnOn) return;
      setState(() {
        _uploadBytes += rnd.nextInt(380) + 40;
        _downloadBytes += rnd.nextInt(1400) + 120;
      });
    });
  }

  Future<void> _persistVpnState(bool on) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('vpn_ui_connected', on);
  }

  Future<void> _persistRemainingSeconds() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(
      SettingsPersistence.connectionRemainingSecondsKey,
      _remainingSeconds,
    );
  }

  void _syncConnectionTicker() {
    _connectionTicker?.cancel();
    _connectionTicker = null;
    if (!_vpnOn || _remainingSeconds <= 0) return;
    _connectionTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _remainingSeconds <= 0) return;
      setState(() {
        _remainingSeconds--;
        unawaited(_persistRemainingSeconds());
        if (_remainingSeconds <= 0) {
          _connectionTicker?.cancel();
          _connectionTicker = null;
        }
      });
    });
  }

  Future<void> _addRemainingTime() async {
    const bonus = 3600; // +1 hour (UI)
    setState(() => _remainingSeconds += bonus);
    await _persistRemainingSeconds();
    if (!mounted) return;
    if (_vpnOn && _connectionTicker == null) {
      _syncConnectionTicker();
    }
    AppMessenger.show('Added 1 hour to remaining connection time (UI).');
  }

  void _clearNavHighlight() {
    if (mounted) setState(() => _navIndex = -1);
  }

  Future<void> _refreshServers() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(
      'last_server_refresh_ms',
      DateTime.now().millisecondsSinceEpoch,
    );
    if (!mounted) return;
    AppMessenger.show('Server list refreshed.');
  }

  Future<void> _runServerRefreshNav() async {
    await _refreshServers();
    _clearNavHighlight();
  }

  void _onNavTap(int index) {
    if (index == 2) {
      RewardedAdController.instance.runAfterRewarded(context, () {
        if (!mounted) return;
        final next = !_vpnOn;
        setState(() => _vpnOn = next);
        unawaited(_persistVpnState(next));
        _syncConnectionTicker();
        _syncStatsTicker();
        AppMessenger.show(
          next
              ? 'On (UI only). Does not create an iOS VPN profile or route traffic.'
              : 'Off (UI).',
        );
      });
      return;
    }

    setState(() => _navIndex = index);
    switch (index) {
      case 0:
        InterstitialController.instance.showInterstitialOrRun(() {
          if (!mounted) return;
          showAjustesDialog(context).whenComplete(_clearNavHighlight);
        });
        break;
      case 1:
        InterstitialController.instance.showInterstitialOrRun(() {
          if (!mounted) return;
          showRegistroDialog(context).whenComplete(_clearNavHighlight);
        });
        break;
      case 3:
        InterstitialController.instance.showInterstitialOrRun(() {
          unawaited(_runServerRefreshNav());
        });
        break;
      case 4:
        InterstitialController.instance.showInterstitialOrRun(() {
          if (!mounted) return;
          showFerramentasDialog(context).whenComplete(_clearNavHighlight);
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBlack,
      // Do not let the scrollable body sit under the bar: it can steal taps
      // from the center "start" (foguete) control on iOS.
      extendBody: false,
      body: Column(
        children: [
          _HeaderBar(
            connectionTimeText:
                '${_formatRemainingConnection(_remainingSeconds)} REMAINING CONNECTION TIME',
            onAdd: () {
              RewardedAdController.instance.runAfterRewarded(context, () {
                if (!mounted) return;
                unawaited(_addRemainingTime());
              });
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _PowerRing(active: _vpnOn, onTap: () => _onNavTap(2)),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: _vpnOn
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 16),
                              NetworkStatsBar(
                                uploadBytes: _uploadBytes,
                                downloadBytes: _downloadBytes,
                              ),
                              const SizedBox(height: 22),
                            ],
                          )
                        : const SizedBox(height: 22),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accentBlue, AppColors.navBlueBottom],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentBlue.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'SOCKSLITE PRO',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardGrey,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _vpnOn ? Icons.link : Icons.link_off,
                              color: _vpnOn
                                  ? AppColors.toggleGreen
                                  : Colors.white54,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _vpnOn
                                    ? 'Session active (UI only — no system VPN)'
                                    : 'Disconnected',
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppProductInfo.connectionRealityShort,
                          style: GoogleFonts.nunito(
                            color: Colors.white54,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  SelectionCard(
                    title: 'RANDOM SERVER',
                    subtitle: 'AUTO PICK',
                    selected: _serverProfile ==
                        SettingsPersistence.serverProfileRandom,
                    onTap: () {
                      RewardedAdController.instance.runAfterRewarded(context, () {
                        if (!mounted) return;
                        unawaited(
                          SettingsPersistence.saveServerProfile(
                            SettingsPersistence.serverProfileRandom,
                          ),
                        );
                        setState(
                          () => _serverProfile =
                              SettingsPersistence.serverProfileRandom,
                        );
                        AppMessenger.show(
                          'Random server will be used on the next connection.',
                        );
                      });
                    },
                    leading: _CircleIcon(
                      color: AppColors.pinkIconBg,
                      child: Icon(Icons.shuffle, color: Colors.white, size: 26),
                    ),
                  ),
                  SelectionCard(
                    title: 'AUTOMATIC',
                    subtitle: 'AUTO PICK',
                    selected:
                        _serverProfile == SettingsPersistence.serverProfileAuto,
                    onTap: () {
                      RewardedAdController.instance.runAfterRewarded(context, () {
                        if (!mounted) return;
                        unawaited(
                          SettingsPersistence.saveServerProfile(
                            SettingsPersistence.serverProfileAuto,
                          ),
                        );
                        setState(
                          () => _serverProfile =
                              SettingsPersistence.serverProfileAuto,
                        );
                        AppMessenger.show(
                          'Automatic mode: protocol chosen by the client.',
                        );
                      });
                    },
                    leading: _SquareIcon(
                      color: AppColors.yellowIconBg,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bolt, color: Colors.white, size: 18),
                          Text(
                            'AUTO',
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 8,
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
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (AdMobConfig.shouldInitializeSdk && AdMobConfig.bannerActive)
            const BannerAdSlot(),
          _BottomDock(
            bottomInset: bottomInset,
            selectedIndex: _navIndex,
            rocketActive: _vpnOn,
            onTap: _onNavTap,
          ),
        ],
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.connectionTimeText,
    required this.onAdd,
  });

  final String connectionTimeText;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 6,
        left: 12,
        right: 12,
        bottom: 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.headerBar,
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white54, width: 2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              connectionTimeText,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Material(
            color: AppColors.accentBlue,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onAdd,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  '+ADD',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PowerRing extends StatelessWidget {
  const _PowerRing({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = math.min(MediaQuery.sizeOf(context).width * 0.42, 200.0);
    final accent = active ? AppColors.toggleGreen : AppColors.accentBlue;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: active ? 0.5 : 0.22),
              blurRadius: active ? 28 : 18,
              spreadRadius: active ? 2 : 0,
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: accent, width: 3),
            color: AppColors.scaffoldBlack,
          ),
          child: Icon(
            Icons.power_settings_new,
            size: size * 0.38,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(child: child),
    );
  }
}

class _SquareIcon extends StatelessWidget {
  const _SquareIcon({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(child: child),
    );
  }
}

class _BottomDock extends StatelessWidget {
  const _BottomDock({
    required this.bottomInset,
    required this.selectedIndex,
    required this.rocketActive,
    required this.onTap,
  });

  final double bottomInset;
  final int selectedIndex;
  final bool rocketActive;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const barHeight = 64.0;
    const fabLift = 38.0;

    return SizedBox(
      height: barHeight + fabLift + bottomInset + 8,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset,
            child: Container(
              height: barHeight,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.navBlueTop, AppColors.navBlueBottom],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 12,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: _NavItem(
                        label: 'SETTINGS',
                        icon: Icons.tune,
                        selected: selectedIndex == 0,
                        onTap: () => onTap(0),
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        label: 'LOG',
                        icon: Icons.integration_instructions_outlined,
                        selected: selectedIndex == 1,
                        onTap: () => onTap(1),
                        badge: 'LOGS',
                      ),
                    ),
                    // Center spacer absorbs taps; same action as rocket (start).
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(2),
                      child: const SizedBox(width: 56, height: 64),
                    ),
                    Expanded(
                      child: _NavItem(
                        label: 'REFRESH',
                        icon: Icons.sync,
                        selected: selectedIndex == 3,
                        onTap: () => onTap(3),
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        label: 'TOOLS',
                        icon: Icons.home_repair_service_outlined,
                        selected: selectedIndex == 4,
                        onTap: () => onTap(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset + barHeight - fabLift,
            child: Center(
              child: Material(
                elevation: 10,
                shape: const CircleBorder(),
                color: rocketActive ? AppColors.toggleGreen : AppColors.fabGrey,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => onTap(2),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: Center(
                      child: Icon(
                        Icons.rocket_launch_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : Colors.white70;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: color, size: 22),
              if (badge != null)
                Positioned(
                  right: -18,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.yellowIconBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge!,
                      style: GoogleFonts.nunito(
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 9,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
