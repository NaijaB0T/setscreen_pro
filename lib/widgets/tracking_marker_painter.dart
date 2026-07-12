import 'package:flutter/material.dart';

class TrackingMarkerPainter extends CustomPainter {
  final String style;
  final Color color;

  TrackingMarkerPainter({
    required this.style,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 2;

    switch (style) {
      case 'crosshair':
        // Plus inside a circle
        canvas.drawCircle(Offset(centerX, centerY), radius - 2, paint);
        // Vertical line
        canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), paint);
        // Horizontal line
        canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), paint);
        break;

      case 'x':
        // X inside a thin square
        final rect = Rect.fromLTWH(0, 0, size.width, size.height);
        canvas.drawRect(rect, paint);
        // Diagonal 1
        canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), paint);
        // Diagonal 2
        canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), paint);
        break;

      case 'circle':
        // Concentric target circles
        canvas.drawCircle(Offset(centerX, centerY), radius - 2, paint);
        canvas.drawCircle(Offset(centerX, centerY), radius / 2, paint);
        canvas.drawCircle(Offset(centerX, centerY), 3, paint..style = PaintingStyle.fill);
        break;

      case 'vfxTriangle':
      default:
        // Triangle with a central crosshair inside a square
        final rect = Rect.fromLTWH(0, 0, size.width, size.height);
        canvas.drawRect(rect, paint);
        
        // Triangle path
        final path = Path()
          ..moveTo(centerX, 4)
          ..lineTo(size.width - 4, size.height - 4)
          ..lineTo(4, size.height - 4)
          ..close();
        canvas.drawPath(path, paint);

        // Center crosshair (located at the center of the square)
        const crossSize = 8.0;
        canvas.drawLine(Offset(centerX, centerY - crossSize), Offset(centerX, centerY + crossSize), paint);
        canvas.drawLine(Offset(centerX - crossSize, centerY), Offset(centerX + crossSize, centerY), paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant TrackingMarkerPainter oldDelegate) {
    return oldDelegate.style != style || oldDelegate.color != color;
  }
}
