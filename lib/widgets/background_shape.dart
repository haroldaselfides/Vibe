import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BackgroundShape extends StatelessWidget {
  const BackgroundShape({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Center(
        child: SizedBox(
          width: 320,
          height: 320,
          child: CustomPaint(
            painter: SpeechBubblePainter(),
          ),
        ),
      ),
    );
  }
}

class SpeechBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // ── Paint styles ──
    final fillA = Paint()
      ..color = AppTheme.wabiCream.withValues(alpha: 0.25);

    final fillB = Paint()
      ..color = AppTheme.wabiSand.withValues(alpha: 0.20);


    final fillC = Paint()
      ..color = AppTheme.wabiSand.withValues(alpha: 0.15);

    final stroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final strokeFaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // ── Helper: draw a rounded speech bubble ──
    // [x, y] = top-left of bubble rect, [w, h] = size,
    // tailSide: 'left' | 'right' | 'bottom' | 'none'
    void drawBubble(
      Canvas c,
      double x,
      double y,
      double w,
      double h,
      double r,
      String tailSide,
      Paint fill,
      Paint str,
    ) {
      final rect = RRect.fromLTRBR(x, y, x + w, y + h, Radius.circular(r));
      c.drawRRect(rect, fill);
      c.drawRRect(rect, str);

      if (tailSide == 'bottom-left') {
        final tail = Path()
          ..moveTo(x + r, y + h)
          ..lineTo(x + r * 0.2, y + h + 18)
          ..lineTo(x + r * 2, y + h)
          ..close();
        c.drawPath(tail, fill);
        c.drawPath(tail, str);
      } else if (tailSide == 'bottom-right') {
        final tail = Path()
          ..moveTo(x + w - r * 2, y + h)
          ..lineTo(x + w - r * 0.2, y + h + 18)
          ..lineTo(x + w - r, y + h)
          ..close();
        c.drawPath(tail, fill);
        c.drawPath(tail, str);
      } else if (tailSide == 'left-bottom') {
        final tail = Path()
          ..moveTo(x, y + h - r * 2)
          ..lineTo(x - 18, y + h - r * 0.5)
          ..lineTo(x, y + h - r)
          ..close();
        c.drawPath(tail, fill);
        c.drawPath(tail, str);
      }
    }

    // ── Helper: draw wave lines inside a bubble ──
    void drawWaves(Canvas c, double x, double y, double w, double h, Paint p) {
      final waveCount = 3;
      final spacing = h * 0.22;
      final startY = y + h * 0.30;
      final margin = w * 0.12;
      for (int i = 0; i < waveCount; i++) {
        final wy = startY + i * spacing;
        final ww = i == waveCount - 1 ? w * 0.55 : w - margin * 2;
        final path = Path();
        final segW = ww / 4;
        path.moveTo(x + margin, wy);
        for (int s = 0; s < 4; s++) {
          final sx = x + margin + s * segW;
          final cp1x = sx + segW * 0.25;
          final cp2x = sx + segW * 0.75;
          final amp = (i == 0 ? 4.0 : 3.0) * (s % 2 == 0 ? 1 : -1);
          path.cubicTo(cp1x, wy - amp, cp2x, wy + amp, sx + segW, wy);
        }
        c.drawPath(path, p);
      }
    }

    // ══════════════════════════════════════════════
    // BUBBLE 1 — large, top-center, tail bottom-left
    // ══════════════════════════════════════════════
    final b1x = cx - 115.0;
    final b1y = cy - 130.0;
    const b1w = 170.0;
    const b1h = 110.0;
    drawBubble(canvas, b1x, b1y, b1w, b1h, 22, 'bottom-left', fillA, stroke);
    drawWaves(
      canvas,
      b1x,
      b1y,
      b1w,
      b1h,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    // ══════════════════════════════════════════════
    // BUBBLE 2 — medium, right-center, tail bottom-right
    // ══════════════════════════════════════════════
    final b2x = cx + 10.0;
    final b2y = cy - 80.0;
    const b2w = 130.0;
    const b2h = 85.0;
    drawBubble(canvas, b2x, b2y, b2w, b2h, 18, 'bottom-right', fillB, stroke);
    drawWaves(
      canvas,
      b2x,
      b2y,
      b2w,
      b2h,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );

    // ══════════════════════════════════════════════
    // BUBBLE 3 — small round, left-mid, tail left-bottom
    // ══════════════════════════════════════════════
    final b3x = cx - 140.0;
    final b3y = cy - 10.0;
    const b3w = 105.0;
    const b3h = 68.0;
    drawBubble(canvas, b3x, b3y, b3w, b3h, 16, 'left-bottom', fillB, strokeFaint);
    drawWaves(
      canvas,
      b3x,
      b3y,
      b3w,
      b3h,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round,
    );

    // ══════════════════════════════════════════════
    // BUBBLE 4 — tiny dot bubble (typing indicator style)
    // ══════════════════════════════════════════════
    final b4x = cx + 60.0;
    final b4y = cy + 30.0;
    const b4w = 80.0;
    const b4h = 48.0;
    drawBubble(canvas, b4x, b4y, b4w, b4h, 24, 'none', fillC, strokeFaint);
    // Three dots inside
    final dotY = b4y + b4h / 2;
    final dotSpacing = b4w / 4;
    for (int d = 0; d < 3; d++) {
      canvas.drawCircle(
        Offset(b4x + dotSpacing * (d + 1), dotY),
        3.5,
        Paint()..color = Colors.white.withValues(alpha: 0.50),
      );
    }

    // ══════════════════════════════════════════════
    // FLOATING DOTS — decorative small circles
    // ══════════════════════════════════════════════
    final dots = [
      [cx - 60.0, cy + 70.0, 5.0],
      [cx + 50.0, cy - 110.0, 4.0],
      [cx - 130.0, cy - 60.0, 3.5],
      [cx + 140.0, cy - 20.0, 6.0],
      [cx + 20.0, cy + 85.0, 3.0],
    ];
    for (final d in dots) {
      canvas.drawCircle(
        Offset(d[0], d[1]),
        d[2],
        Paint()..color = Colors.white.withValues(alpha: 0.35),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}