import 'dart:math' as math;
import 'package:flutter/material.dart';

class CustomChart extends StatelessWidget {
  final List<double> data;
  final bool isLine;
  final double height;

  const CustomChart({
    super.key,
    required this.data,
    this.isLine = true,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: height,
      padding: const EdgeInsets.all(8.0),
      child: CustomPaint(
        size: Size.infinite,
        painter: _ChartPainter(
          data: data,
          isLine: isLine,
          primaryColor: theme.colorScheme.primary,
          secondaryColor: const Color(0xFF22C7D6),
          gridColor: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> data;
  final bool isLine;
  final Color primaryColor;
  final Color secondaryColor;
  final Color gridColor;

  _ChartPainter({
    required this.data,
    required this.isLine,
    required this.primaryColor,
    required this.secondaryColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double maxVal = data.reduce(math.max);
    final double minVal = data.reduce(math.min);
    final double range = maxVal - minVal == 0 ? 1 : maxVal - minVal;

    final int gridRows = 3;
    final double rowHeight = size.height / gridRows;

    // Draw horizontal grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= gridRows; i++) {
      final y = i * rowHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final double widthInterval = size.width / (data.length - 1 == 0 ? 1 : data.length - 1);

    if (isLine) {
      // Draw smooth line chart
      final path = Path();
      final fillPath = Path();

      for (int i = 0; i < data.length; i++) {
        final double x = i * widthInterval;
        final double normalizedY = (data[i] - minVal) / range;
        final double y = size.height - (normalizedY * (size.height - 12) + 6);

        if (i == 0) {
          path.moveTo(x, y);
          fillPath.moveTo(x, size.height);
          fillPath.lineTo(x, y);
        } else {
          path.lineTo(x, y);
          fillPath.lineTo(x, y);
        }

        if (i == data.length - 1) {
          fillPath.lineTo(x, size.height);
          fillPath.close();
        }
      }

      // Draw path gradient fill
      final fillPaint = Paint()
        ..shader = LinearGradient(
          colors: [primaryColor.withValues(alpha: 0.25), primaryColor.withValues(alpha: 0.0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(fillPath, fillPaint);

      // Draw primary path line
      final linePaint = Paint()
        ..color = primaryColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, linePaint);

      // Draw dynamic nodes/dots
      final pointPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill;

      final pointOutline = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      for (int i = 0; i < data.length; i++) {
        final double x = i * widthInterval;
        final double normalizedY = (data[i] - minVal) / range;
        final double y = size.height - (normalizedY * (size.height - 12) + 6);

        canvas.drawCircle(Offset(x, y), 4.5, pointOutline);
        canvas.drawCircle(Offset(x, y), 2.5, pointPaint);
      }
    } else {
      // Draw high-density bar chart
      final double barWidth = (size.width / data.length) * 0.65;
      final double spacing = (size.width / data.length) * 0.35;

      final Paint barPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          colors: [secondaryColor, primaryColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      for (int i = 0; i < data.length; i++) {
        final double normalizedY = (data[i] - minVal) / range;
        final double height = normalizedY * (size.height - 12) + 6;
        final double left = i * (barWidth + spacing) + (spacing / 2);
        final double top = size.height - height;

        final rect = RRect.fromRectAndCorners(
          Rect.fromLTWH(left, top, barWidth, height),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        );

        canvas.drawRRect(rect, barPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) => true;
}
