import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  Color palette — warm antiquarian tones
// ─────────────────────────────────────────────
class BookTheme {
  static const Color inkDeep     = Color(0xFF1C1A14); // near-black ink
  static const Color parchment   = Color(0xFFF5EDD6); // aged page
  static const Color amber       = Color(0xFFD4A853); // gilded accent
  static const Color sepia       = Color(0xFF8B6543); // warm sepia
  static const Color dustRose    = Color(0xFFB87A6A); // faded rose chapter mark
  static const Color sage        = Color(0xFF7A9478); // muted sage bookmark
}

// ─────────────────────────────────────────────
//  Widget
// ─────────────────────────────────────────────
class BookBackgroundShape extends StatelessWidget {
  const BookBackgroundShape({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: BookBackgroundPainter(),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Painter
// ─────────────────────────────────────────────
class BookBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── 1. OPEN BOOK silhouette (centred, large, ghost) ──────────────
    _drawOpenBook(canvas, w / 2, h * 0.42, w * 0.82, h * 0.52);

    // ── 2. STACKED BOOKS (bottom-left corner) ────────────────────────
    _drawStackedBooks(canvas, w * 0.08, h * 0.78, w * 0.22, h * 0.18);

    // ── 3. QUILL & INK (top-right) ───────────────────────────────────
    _drawQuill(canvas, w * 0.80, h * 0.12, w * 0.14);

    // ── 4. BOOKMARK RIBBONS ──────────────────────────────────────────
    _drawBookmark(canvas, w * 0.62, 0, BookTheme.sage,   h * 0.18);
    _drawBookmark(canvas, w * 0.70, 0, BookTheme.dustRose, h * 0.13);

    // ── 5. SCATTERED TEXT LINES (lorem ipsum style) ──────────────────
    _drawTextLines(canvas, w * 0.05, h * 0.05, w * 0.38, h * 0.28);
    _drawTextLines(canvas, w * 0.55, h * 0.60, w * 0.40, h * 0.22);

    // ── 6. DECORATIVE CORNER FLOURISH (top-left) ─────────────────────
    _drawCornerFlourish(canvas, 0, 0, w * 0.28);

    // ── 7. FLOATING SPARKLE DOTS (ink splatter) ──────────────────────
    _drawInkSplatter(canvas, size);

    // ── 8. CIRCULAR CHAPTER SEAL ─────────────────────────────────────
    _drawChapterSeal(canvas, w * 0.14, h * 0.38, w * 0.09);
  }

  // ── Open Book ─────────────────────────────────────────────────────
  void _drawOpenBook(Canvas c, double cx, double cy, double bw, double bh) {
    final half  = bw / 2;
    final top   = cy - bh / 2;
    final bot   = cy + bh / 2;
    final curve = bh * 0.08;

    final fillPaint = Paint()
      ..color = BookTheme.parchment.withValues(alpha: 0.10);
    final strokePaint = Paint()
      ..color = BookTheme.amber.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final spinePaint = Paint()
      ..color = BookTheme.sepia.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Left page
    final leftPage = Path()
      ..moveTo(cx, top + curve)
      ..quadraticBezierTo(cx - half * 0.15, cy, cx, bot - curve)
      ..lineTo(cx - half + 12, bot)
      ..quadraticBezierTo(cx - half, bot - 6, cx - half, bot - 16)
      ..lineTo(cx - half, top + 16)
      ..quadraticBezierTo(cx - half, top + 6, cx - half + 12, top)
      ..close();
    c.drawPath(leftPage, fillPaint);
    c.drawPath(leftPage, strokePaint);

    // Right page
    final rightPage = Path()
      ..moveTo(cx, top + curve)
      ..quadraticBezierTo(cx + half * 0.15, cy, cx, bot - curve)
      ..lineTo(cx + half - 12, bot)
      ..quadraticBezierTo(cx + half, bot - 6, cx + half, bot - 16)
      ..lineTo(cx + half, top + 16)
      ..quadraticBezierTo(cx + half, top + 6, cx + half - 12, top)
      ..close();
    c.drawPath(rightPage, fillPaint);
    c.drawPath(rightPage, strokePaint);

    // Spine curve
    final spine = Path()
      ..moveTo(cx, top + curve)
      ..quadraticBezierTo(cx, cy + bh * 0.06, cx, bot - curve);
    c.drawPath(spine, spinePaint);

    // Inner page lines (left)
    _drawPageLines(c, cx - half + 20, top + bh * 0.20, half - 32, bh * 0.60, 6,
        BookTheme.sepia.withValues(alpha: 0.12));

    // Inner page lines (right)
    _drawPageLines(c, cx + 12, top + bh * 0.20, half - 32, bh * 0.60, 6,
        BookTheme.sepia.withValues(alpha: 0.12));
  }

  void _drawPageLines(
      Canvas c, double x, double y, double w, double h, int count, Color col) {
    final p = Paint()
      ..color = col
      ..strokeWidth = 1.0;
    final step = h / (count + 1);
    for (int i = 1; i <= count; i++) {
      final lw = i == count ? w * 0.55 : w * (0.80 + math.Random(i).nextDouble() * 0.20);
      c.drawLine(Offset(x, y + step * i), Offset(x + lw, y + step * i), p);
    }
  }

  // ── Stacked Books ────────────────────────────────────────────────
  void _drawStackedBooks(Canvas c, double x, double y, double w, double totalH) {
    final colors = [
      BookTheme.sepia.withValues(alpha: 0.25),
      BookTheme.dustRose.withValues(alpha: 0.22),
      BookTheme.sage.withValues(alpha: 0.20),
    ];
    final heights = [totalH * 0.38, totalH * 0.32, totalH * 0.30];
    final strokes = Paint()
      ..color = Colors.white.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    double curY = y + totalH;
    for (int i = 0; i < 3; i++) {
      final bh = heights[i];
      final bx = x + (i.isOdd ? w * 0.04 : 0);
      final bw = w - (i.isEven ? 0 : w * 0.04);
      final rect = RRect.fromLTRBR(bx, curY - bh, bx + bw, curY, const Radius.circular(3));
      c.drawRRect(rect, Paint()..color = colors[i]);
      c.drawRRect(rect, strokes);
      // Spine line
      c.drawLine(Offset(bx + 10, curY - bh + 4), Offset(bx + 10, curY - 4),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.15)
            ..strokeWidth = 1.5);
      curY -= bh + 2;
    }
  }

  // ── Quill ────────────────────────────────────────────────────────
  void _drawQuill(Canvas c, double tipX, double tipY, double length) {
    final angle = math.pi * 0.72; // slant
    final endX = tipX + math.cos(angle) * length;
    final endY = tipY - math.sin(angle) * length;

    final shaftPaint = Paint()
      ..color = BookTheme.amber.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    // Shaft
    c.drawLine(Offset(tipX, tipY), Offset(endX, endY), shaftPaint);

    // Barbs (right side)
    final barbCount = 8;
    for (int i = 1; i <= barbCount; i++) {
      final t = i / (barbCount + 1);
      final bx = tipX + (endX - tipX) * t;
      final by = tipY + (endY - tipY) * t;
      final barbLen = length * 0.10 * (i < barbCount * 0.5 ? t + 0.3 : 1.2 - t);
      final perpAngle = angle - math.pi / 2;
      c.drawLine(
        Offset(bx, by),
        Offset(bx + math.cos(perpAngle) * barbLen, by - math.sin(perpAngle) * barbLen),
        Paint()
          ..color = BookTheme.amber.withValues(alpha: 0.22)
          ..strokeWidth = 0.9,
      );
      c.drawLine(
        Offset(bx, by),
        Offset(bx - math.cos(perpAngle) * barbLen, by + math.sin(perpAngle) * barbLen),
        Paint()
          ..color = BookTheme.amber.withValues(alpha: 0.18)
          ..strokeWidth = 0.9,
      );
    }

    // Nib tip
    final nibPath = Path()
      ..moveTo(tipX, tipY)
      ..lineTo(tipX + 6, tipY - 8)
      ..lineTo(tipX - 4, tipY - 12)
      ..close();
    c.drawPath(nibPath,
        Paint()..color = BookTheme.inkDeep.withValues(alpha: 0.25));
  }

  // ── Bookmark ─────────────────────────────────────────────────────
  void _drawBookmark(Canvas c, double x, double y, Color col, double len) {
    const w = 14.0;
    final path = Path()
      ..moveTo(x, y)
      ..lineTo(x + w, y)
      ..lineTo(x + w, y + len)
      ..lineTo(x + w / 2, y + len - 10)
      ..lineTo(x, y + len)
      ..close();
    c.drawPath(path, Paint()..color = col.withValues(alpha: 0.30));
    c.drawPath(
        path,
        Paint()
          ..color = col.withValues(alpha: 0.40)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8);
  }

  // ── Text Lines (simulated body copy) ────────────────────────────
  void _drawTextLines(Canvas c, double x, double y, double w, double h, ) {
    final p = Paint()
      ..color = BookTheme.parchment.withValues(alpha: 0.13)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    final lineCount = (h / 11).floor();
    final rng = math.Random(42);
    for (int i = 0; i < lineCount; i++) {
      final lw = w * (0.60 + rng.nextDouble() * 0.38);
      c.drawLine(Offset(x, y + i * 11.0), Offset(x + lw, y + i * 11.0), p);
    }
    // Drop cap hint
    final capPaint = Paint()
      ..color = BookTheme.amber.withValues(alpha: 0.22);
    c.drawRect(Rect.fromLTWH(x, y, 18, 22), capPaint);
  }

  // ── Corner Flourish (ornate vine) ───────────────────────────────
  void _drawCornerFlourish(Canvas c, double x, double y, double size) {
    final p = Paint()
      ..color = BookTheme.amber.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    // Main arcs
    for (int i = 0; i < 4; i++) {
      final r = size * (0.18 + i * 0.20);
      c.drawArc(
        Rect.fromLTWH(x - r * 0.1, y - r * 0.1, r * 1.5, r * 1.5),
        0,
        math.pi / 2,
        false,
        p,
      );
    }

    // Small leaf-dots along outer arc
    final outerR = size * 0.78;
    for (int i = 0; i <= 5; i++) {
      final angle = (math.pi / 2) * i / 5;
      final lx = x + math.cos(angle) * outerR;
      final ly = y + math.sin(angle) * outerR;
      c.drawCircle(Offset(lx, ly), 3.0,
          Paint()..color = BookTheme.amber.withValues(alpha: 0.25));
    }

    // Diagonal rule
    c.drawLine(
      Offset(x + size * 0.06, y + size * 0.06),
      Offset(x + size * 0.36, y + size * 0.36),
      Paint()
        ..color = BookTheme.sepia.withValues(alpha: 0.18)
        ..strokeWidth = 0.8,
    );
  }

  // ── Ink Splatter Dots ───────────────────────────────────────────
  void _drawInkSplatter(Canvas c, Size size) {
    final rng = math.Random(7);
    final positions = [
      Offset(size.width * 0.45, size.height * 0.08),
      Offset(size.width * 0.88, size.height * 0.35),
      Offset(size.width * 0.30, size.height * 0.70),
      Offset(size.width * 0.75, size.height * 0.85),
      Offset(size.width * 0.15, size.height * 0.55),
      Offset(size.width * 0.55, size.height * 0.48),
      Offset(size.width * 0.92, size.height * 0.62),
    ];
    for (final pos in positions) {
      final r = 2.0 + rng.nextDouble() * 4.0;
      c.drawCircle(
        pos,
        r,
        Paint()..color = BookTheme.amber.withValues(alpha: 0.18 + rng.nextDouble() * 0.14),
      );
      // tiny satellite splat
      c.drawCircle(
        pos.translate(r * 1.8, -r * 1.2),
        r * 0.35,
        Paint()..color = BookTheme.amber.withValues(alpha: 0.12),
      );
    }
  }

  // ── Chapter Seal ────────────────────────────────────────────────
  void _drawChapterSeal(Canvas c, double cx, double cy, double r) {
    // Outer ring
    c.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = BookTheme.amber.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    // Inner ring
    c.drawCircle(
      Offset(cx, cy),
      r * 0.72,
      Paint()
        ..color = BookTheme.amber.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );
    // 8-point star
    final starPaint = Paint()
      ..color = BookTheme.amber.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (int i = 0; i < 8; i++) {
      final a = (math.pi * 2 / 8) * i - math.pi / 2;
      c.drawLine(
        Offset(cx + math.cos(a) * r * 0.28, cy + math.sin(a) * r * 0.28),
        Offset(cx + math.cos(a) * r * 0.65, cy + math.sin(a) * r * 0.65),
        starPaint,
      );
    }
    // Centre dot
    c.drawCircle(
      Offset(cx, cy),
      r * 0.14,
      Paint()..color = BookTheme.amber.withValues(alpha: 0.28),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}