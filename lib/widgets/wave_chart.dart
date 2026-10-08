import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reproduit le graphique vu dans les maquettes : fond quadrillé de points
/// (avec quelques '+' décoratifs), une courbe verte lissée et un remplissage
/// dégradé sous la courbe. Deux étiquettes optionnelles (min/max) peuvent
/// être affichées en haut à gauche, comme "50°C" / "30°C".
class WaveChart extends StatelessWidget {
  final List<double> values;
  final double minValue;
  final double maxValue;
  final String? topLabel;
  final String? bottomLabel;
  final double height;

  const WaveChart({
    super.key,
    required this.values,
    required this.minValue,
    required this.maxValue,
    this.topLabel,
    this.bottomLabel,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _WaveChartPainter(
                values: values,
                minValue: minValue,
                maxValue: maxValue,
              ),
            ),
          ),
          if (topLabel != null)
            Positioned(
              top: 6,
              left: 6,
              child: _badge(topLabel!),
            ),
          if (bottomLabel != null)
            Positioned(
              bottom: 6,
              left: 6,
              child: _badge(bottomLabel!),
            ),
        ],
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.pillDark,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _WaveChartPainter extends CustomPainter {
  final List<double> values;
  final double minValue;
  final double maxValue;

  _WaveChartPainter({
    required this.values,
    required this.minValue,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintGrid(canvas, size);
    if (values.length < 2) return;
    _paintCurve(canvas, size);
  }

  void _paintGrid(Canvas canvas, Size size) {
    final dotPaint = Paint()..color = AppColors.gridDot.withValues(alpha: 0.55);
    const spacing = 14.0;
    final cols = (size.width / spacing).floor();
    final rows = (size.height / spacing).floor();

    for (var r = 0; r <= rows; r++) {
      for (var c = 0; c <= cols; c++) {
        final dx = c * spacing;
        final dy = r * spacing;
        final isPlus = (r + c) % 5 == 0;
        if (isPlus) {
          canvas.drawLine(Offset(dx - 3, dy), Offset(dx + 3, dy), dotPaint..strokeWidth = 1.2);
          canvas.drawLine(Offset(dx, dy - 3), Offset(dx, dy + 3), dotPaint..strokeWidth = 1.2);
        } else {
          canvas.drawCircle(Offset(dx, dy), 1.1, dotPaint);
        }
      }
    }
  }

  void _paintCurve(Canvas canvas, Size size) {
    final range = (maxValue - minValue).abs() < 0.001 ? 1.0 : (maxValue - minValue);
    final points = <Offset>[];
    final stepX = size.width / (values.length - 1);

    for (var i = 0; i < values.length; i++) {
      final normalized = ((values[i] - minValue) / range).clamp(0.0, 1.0);
      final x = i * stepX;
      final y = size.height - normalized * size.height * 0.85 - size.height * 0.05;
      points.add(Offset(x, y));
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      linePath.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    linePath.lineTo(points.last.dx, points.last.dy);

    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.accentGreen.withValues(alpha: 0.35), AppColors.accentGreen.withValues(alpha: 0.02)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = AppColors.accentGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _WaveChartPainter oldDelegate) {
    return !_doubleListEquals(oldDelegate.values, values) ||
        oldDelegate.minValue != minValue ||
        oldDelegate.maxValue != maxValue;
  }
}

bool _doubleListEquals(List<double> a, List<double> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Génère une valeur initiale d'historique pour amorcer les courbes avant
/// la première vraie mesure.
List<double> seedHistory(double around, {int length = 24, double spread = 4}) {
  final rnd = Random();
  return List.generate(length, (_) => around + (rnd.nextDouble() - 0.5) * spread);
}
