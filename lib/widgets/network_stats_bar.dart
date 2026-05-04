import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Light pill bar with upload/download totals (display-only).
class NetworkStatsBar extends StatelessWidget {
  const NetworkStatsBar({
    super.key,
    required this.uploadBytes,
    required this.downloadBytes,
  });

  final int uploadBytes;
  final int downloadBytes;

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const u = 1024;
    if (bytes < u) return '$bytes B';
    if (bytes < u * u) {
      final kb = bytes / u;
      return '${kb < 10 ? kb.toStringAsFixed(1) : kb.toStringAsFixed(0)} KB';
    }
    final mb = bytes / (u * u);
    return '${mb < 10 ? mb.toStringAsFixed(2) : mb.toStringAsFixed(1)} MB';
  }

  static const Color _pillBg = Color(0xFFE8E8E8);
  static const Color _orange = Color(0xFFFF9800);
  static const Color _text = Color(0xFF424242);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: BoxDecoration(
        color: _pillBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_upward, color: _orange, size: 20),
              const SizedBox(width: 6),
              Text(
                formatBytes(uploadBytes),
                style: GoogleFonts.nunito(
                  color: _text,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(width: 28),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_downward, color: _orange, size: 20),
              const SizedBox(width: 6),
              Text(
                formatBytes(downloadBytes),
                style: GoogleFonts.nunito(
                  color: _text,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
