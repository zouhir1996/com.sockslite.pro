import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../app_messenger.dart';
import '../services/ads_actions.dart';
import '../config/app_product_info.dart';
import '../models/saved_connection_profile.dart';
import '../services/connection_profiles_store.dart';
import '../theme/app_colors.dart';

/// Local-only named endpoints for use in another VPN or proxy client.
class ConnectionProfilesScreen extends StatefulWidget {
  const ConnectionProfilesScreen({super.key});

  @override
  State<ConnectionProfilesScreen> createState() =>
      _ConnectionProfilesScreenState();
}

class _ConnectionProfilesScreenState extends State<ConnectionProfilesScreen> {
  List<SavedConnectionProfile> _profiles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  Future<void> _reload() async {
    final list = await ConnectionProfilesStore.loadAll();
    if (!mounted) return;
    setState(() {
      _profiles = list;
      _loading = false;
    });
  }

  Future<void> _persist(List<SavedConnectionProfile> next) async {
    await ConnectionProfilesStore.saveAll(next);
    if (!mounted) return;
    setState(() => _profiles = next);
  }

  Future<void> _shareAll() async {
    if (_profiles.isEmpty) {
      AppMessenger.show('No profiles to share.');
      return;
    }
    final text = ConnectionProfilesStore.exportAllText(_profiles);
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: '${AppProductInfo.name} — profiles',
        ),
      );
    } catch (_) {
      if (!mounted) return;
      AppMessenger.show('Could not open the system share sheet.');
    }
  }

  Future<void> _shareOne(SavedConnectionProfile e) async {
    final text = ConnectionProfilesStore.exportProfileText(e);
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: '${AppProductInfo.name} — ${e.label}',
        ),
      );
    } catch (_) {
      if (!mounted) return;
      AppMessenger.show('Could not open the system share sheet.');
    }
  }

  Future<void> _openAddProfile() async {
    if (!mounted) return;
    runAfterInterstitial(() {
      if (!mounted) return;
      unawaited(_openEditor());
    });
  }

  Future<void> _openEditor({SavedConnectionProfile? existing}) async {
    final result = await showDialog<SavedConnectionProfile>(
      context: context,
      builder: (ctx) => _ProfileEditorDialog(existing: existing),
    );
    if (result == null || !mounted) return;
    final next = List<SavedConnectionProfile>.from(_profiles);
    final i = next.indexWhere((e) => e.id == result.id);
    if (i >= 0) {
      next[i] = result;
    } else {
      next.add(result);
    }
    await _persist(next);
    AppMessenger.show('Profile saved on this device.');
  }

  Future<void> _confirmDelete(SavedConnectionProfile e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardGrey,
        title: Text(
          'Delete profile?',
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          '“${e.label}” will be removed from this device.',
          style: GoogleFonts.nunito(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final next = _profiles.where((p) => p.id != e.id).toList();
    await _persist(next);
    AppMessenger.show('Profile deleted.');
  }

  String _subtitle(SavedConnectionProfile e) {
    final hostPort = [
      if (e.host.isNotEmpty) e.host,
      if (e.port != null) ':${e.port}',
    ].join();
    final proto = e.protocolNote.trim();
    if (hostPort.isEmpty && proto.isEmpty) return 'Tap to edit · share as text';
    if (proto.isEmpty) return hostPort;
    if (hostPort.isEmpty) return proto;
    return '$hostPort · $proto';
  }

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
            'Saved profiles',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          actions: [
            IconButton(
              tooltip: 'Share all as text',
              onPressed: _profiles.isEmpty ? null : () => unawaited(_shareAll()),
              icon: const Icon(Icons.ios_share_outlined),
            ),
          ],
        ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accentBlue),
            )
          : _profiles.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_special_outlined,
                      size: 56,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No saved profiles yet',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Add labels, hosts, ports, and notes you use in your VPN '
                      'or proxy client. Nothing here creates a tunnel—local reference only.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        color: Colors.white60,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: () => unawaited(_openAddProfile()),
                      icon: const Icon(Icons.add, size: 22),
                      label: Text(
                        'Add profile',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
              itemCount: _profiles.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final e = _profiles[i];
                return Material(
                  color: AppColors.cardGrey,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => unawaited(_openEditor(existing: e)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.description_outlined,
                            color: AppColors.accentBlue,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.label,
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _subtitle(e),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.nunito(
                                    color: Colors.white60,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white54,
                            ),
                            color: AppColors.cardGrey,
                            onSelected: (v) {
                              switch (v) {
                                case 'share':
                                  unawaited(_shareOne(e));
                                  break;
                                case 'delete':
                                  unawaited(_confirmDelete(e));
                                  break;
                              }
                            },
                            itemBuilder: (ctx) => [
                              PopupMenuItem(
                                value: 'share',
                                child: Text(
                                  'Share as text',
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  'Delete',
                                  style: GoogleFonts.nunito(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: _profiles.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => unawaited(_openAddProfile()),
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text(
                'Add',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
              ),
            ),
    ),
    );
  }
}

class _ProfileEditorDialog extends StatefulWidget {
  const _ProfileEditorDialog({this.existing});

  final SavedConnectionProfile? existing;

  @override
  State<_ProfileEditorDialog> createState() => _ProfileEditorDialogState();
}

class _ProfileEditorDialogState extends State<_ProfileEditorDialog> {
  late final TextEditingController _label;
  late final TextEditingController _protocol;
  late final TextEditingController _host;
  late final TextEditingController _port;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _label = TextEditingController(text: e?.label ?? '');
    _protocol = TextEditingController(text: e?.protocolNote ?? '');
    _host = TextEditingController(text: e?.host ?? '');
    _port = TextEditingController(
      text: (e != null && e.port != null) ? '${e.port}' : '',
    );
    _notes = TextEditingController(text: e?.notes ?? '');
  }

  @override
  void dispose() {
    _label.dispose();
    _protocol.dispose();
    _host.dispose();
    _port.dispose();
    _notes.dispose();
    super.dispose();
  }

  InputDecoration _dec(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.nunito(color: Colors.white38),
      filled: true,
      fillColor: AppColors.toggleTileBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.toggleTileBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.accentBlue),
      ),
    );
  }

  void _save() {
    final label = _label.text.trim();
    if (label.isEmpty) {
      AppMessenger.show('Enter a label for this profile.');
      return;
    }
    final portRaw = _port.text.trim();
    int? port;
    if (portRaw.isNotEmpty) {
      port = int.tryParse(portRaw);
      if (port == null || port < 1 || port > 65535) {
        AppMessenger.show('Port must be a number between 1 and 65535, or empty.');
        return;
      }
    }
    final id = widget.existing?.id ??
        '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(0xFFFFFF)}';
    Navigator.of(context).pop(
      SavedConnectionProfile(
        id: id,
        label: label,
        protocolNote: _protocol.text.trim(),
        host: _host.text.trim(),
        port: port,
        notes: _notes.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardGrey,
      title: Text(
        widget.existing == null ? 'New profile' : 'Edit profile',
        style: GoogleFonts.nunito(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Stored only on this device. Use these values in your VPN or proxy client.',
              style: GoogleFonts.nunito(
                color: Colors.white60,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _label,
              style: GoogleFonts.nunito(color: Colors.white),
              decoration: _dec('Label (required) e.g. Office Wi‑Fi'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _protocol,
              style: GoogleFonts.nunito(color: Colors.white),
              decoration: _dec('Protocol / type e.g. IKEv2, SOCKS5'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _host,
              style: GoogleFonts.nunito(color: Colors.white),
              decoration: _dec('Host or hostname'),
              autocorrect: false,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _port,
              style: GoogleFonts.nunito(color: Colors.white),
              decoration: _dec('Port (optional)'),
              keyboardType: TextInputType.number,
              autocorrect: false,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notes,
              style: GoogleFonts.nunito(color: Colors.white),
              maxLines: 3,
              maxLength: 500,
              decoration: _dec('Notes e.g. streaming region').copyWith(
                counterText: '',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => popAfterInterstitial(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.nunito(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(
            'Save',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
