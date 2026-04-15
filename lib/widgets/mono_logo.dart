import 'package:flutter/material.dart';

class MonoLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const MonoLogo({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    final logoColor = color ?? Theme.of(context).colorScheme.primary;
    
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MonoLogoPainter(color: logoColor),
      ),
    );
  }
}

class _MonoLogoPainter extends CustomPainter {
  final Color color;

  _MonoLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer thick ring
    final outerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.15;
    
    canvas.drawCircle(center, radius - (outerPaint.strokeWidth / 2), outerPaint);

    // Inner offset dot
    final innerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    // The dot is slightly offset to the right and down center relative to the ring center, based on the image
    final dotRadius = size.width * 0.3;
    final dotCenter = Offset(
      center.dx + (size.width * 0.1),
      center.dy + (size.width * 0.05),
    );
    
    canvas.drawCircle(dotCenter, dotRadius, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
