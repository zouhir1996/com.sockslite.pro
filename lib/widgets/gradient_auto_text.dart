import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Teal / blue‑green gradient "AUTO" label from the reference UI.
class GradientAutoText extends StatelessWidget {
  const GradientAutoText({super.key, this.fontSize = 18});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFF00BCD4), Color(0xFF00C853)],
      ).createShader(bounds),
      child: Text(
        'AUTO',
        style: GoogleFonts.nunito(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
