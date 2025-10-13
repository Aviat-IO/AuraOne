import 'package:flutter/material.dart';
import '../theme/colors.dart';

class NotebookIcon extends StatelessWidget {
  final bool isLight;

  const NotebookIcon({
    super.key,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = isLight
        ? AuraColors.lightLogoGradient
        : AuraColors.darkLogoGradient;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: isLight
                ? AuraColors.lightPrimary.withValues(alpha: 0.2)
                : AuraColors.darkPrimary.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        size: const Size(24, 24),
        painter: NotebookPainter(),
      ),
    );
  }
}

class NotebookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 1.5;

    final double width = size.width;
    final double height = size.height;

    final double notebookWidth = width * 0.65;
    final double notebookHeight = height * 0.85;
    final double left = (width - notebookWidth) / 2;
    final double top = (height - notebookHeight) / 2;
    final double spineWidth = notebookWidth * 0.12;

    final notebookRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, notebookWidth, notebookHeight),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(notebookRect, paint);

    final spineRect = Rect.fromLTWH(left, top, spineWidth, notebookHeight);
    paint.color = Colors.white.withValues(alpha: 0.7);
    canvas.drawRect(spineRect, paint);

    final lineSpacing = notebookHeight / 5;
    final lineLeft = left + spineWidth + (notebookWidth - spineWidth) * 0.2;
    final lineRight = left + notebookWidth - (notebookWidth - spineWidth) * 0.15;

    for (int i = 1; i <= 3; i++) {
      final y = top + lineSpacing * i;
      final lineLength = i == 3 ? (lineRight - lineLeft) * 0.7 : (lineRight - lineLeft);
      canvas.drawLine(
        Offset(lineLeft, y),
        Offset(lineLeft + lineLength, y),
        strokePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
