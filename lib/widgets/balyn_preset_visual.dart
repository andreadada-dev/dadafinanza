import 'dart:math' as math;

import 'package:balyn/l10n/localized_material.dart';

import '../theme/balyn_palette.dart';
import 'ui_helpers.dart';

/// The same icon vocabulary already used for accounts, categories and people.
final presetIconOptions = <IconOption>[
  for (final option in categoryIconOptions) option,
  for (final option in accountIconOptions)
    if (!categoryIconOptions.any((item) => item.key == option.key)) option,
  for (final option in personIconOptions)
    if (!categoryIconOptions.any((item) => item.key == option.key) &&
        !accountIconOptions.any((item) => item.key == option.key))
      option,
];

IconData? presetIconData(String? key) {
  if (key == null) return null;
  for (final option in presetIconOptions) {
    if (option.key == key) return option.icon;
  }
  return null;
}

/// An empty preset slot is always a transparent, dashed circle.
class BalynPresetGlyph extends StatelessWidget {
  const BalynPresetGlyph({
    required this.name,
    required this.iconKey,
    required this.colorValue,
    this.empty = false,
    this.highlighted = false,
    this.dimension = 38,
    super.key,
  });

  final String name;
  final String? iconKey;
  final int colorValue;
  final bool empty;
  final bool highlighted;
  final double dimension;

  @override
  Widget build(BuildContext context) {
    final ink = Color(colorValue);
    final icon = presetIconData(iconKey);
    final letter = name.trim().isNotEmpty
        ? name.trim().characters.first.toUpperCase()
        : '?';
    if (empty) {
      return CustomPaint(
        painter: _DashedCirclePainter(
          color: highlighted ? BalynPalette.accentTextDark : Colors.white70,
        ),
        child: SizedBox.square(
          dimension: dimension,
          child: Icon(
            Icons.add_rounded,
            size: dimension * .46,
            color: Colors.white70,
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: highlighted
            ? BalynPalette.darkSurfaceHigh
            : BalynPalette.darkSurface,
      ),
      child: SizedBox.square(
        dimension: dimension,
        child: Center(
          child: icon == null
              ? Text(
                  letter,
                  style: TextStyle(
                    fontSize: dimension * .48,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                )
              : Icon(icon, size: dimension * .51, color: ink),
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width, size.height) / 2 - 1.5;
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = color;
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (var i = 0; i < 12; i++) {
      canvas.drawArc(rect, i * math.pi / 6, math.pi / 11, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}
