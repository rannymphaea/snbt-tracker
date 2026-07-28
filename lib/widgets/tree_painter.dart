// lib/widgets/tree_painter.dart — 6-stage procedural tree via CustomPainter
import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class TreePainter extends CustomPainter {
  final int stage;
  final double leafAnim;
  TreePainter({required this.stage, this.leafAnim = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final ground = size.height * 0.85;
    final rng = _FakeRng(42);

    _drawGround(canvas, size, ground);
    _drawTrunk(canvas, cx, ground, stage);
    if (stage >= 1) _drawCrown(canvas, cx, ground, stage, rng);
    if (stage >= 3 && leafAnim > 0) {
      _drawLeafBurst(canvas, cx, ground, leafAnim, rng);
    }
    if (stage == 5) _drawFruit(canvas, cx, ground);
    _drawFaceOrSparkles(canvas, cx, ground, stage);
  }

  void _drawGround(Canvas canvas, Size size, double ground) {
    final paint = Paint()
      ..color = const Color(0xFFE8DFD0)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, ground + 8),
        width: size.width * 0.7,
        height: 18,
      ),
      paint,
    );
  }

  void _drawTrunk(Canvas canvas, double cx, double ground, int stage) {
    final heights = [18.0, 28.0, 40.0, 52.0, 62.0, 70.0];
    final widths = [5.0, 7.0, 9.0, 11.0, 12.0, 14.0];
    final h = heights[stage.clamp(0, 5)];
    final w = widths[stage.clamp(0, 5)];
    final paint = Paint()
      ..color = const Color(0xFF8B5E3C)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(cx - w / 2, ground)
      ..lineTo(cx - w * 0.3, ground - h)
      ..lineTo(cx + w * 0.3, ground - h)
      ..lineTo(cx + w / 2, ground)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawCrown(
      Canvas canvas, double cx, double ground, int stage, _FakeRng rng) {
    final trunkHeights = [0, 28.0, 40.0, 52.0, 62.0, 70.0];
    final trunkH = trunkHeights[stage.clamp(0, 5)];
    final crownCy = ground - trunkH;

    final colors = [
      const Color(0xFF3BA55C),
      const Color(0xFF43A047),
      const Color(0xFF2E7D32),
      const Color(0xFF4CAF50),
      const Color(0xFF66BB6A),
    ];

    switch (stage) {
      case 1:
        _drawLeaf(canvas, Offset(cx - 8, crownCy - 5), 10, -0.5, colors[0]);
        _drawLeaf(canvas, Offset(cx + 8, crownCy - 5), 10, 0.5, colors[1]);
      case 2:
        _drawBlob(canvas, Offset(cx, crownCy - 10), 18, colors[0]);
      case 3:
        _drawBlob(canvas, Offset(cx, crownCy - 20), 26, colors[0]);
        _drawBlob(canvas, Offset(cx - 14, crownCy - 10), 18, colors[1]);
        _drawBlob(canvas, Offset(cx + 14, crownCy - 10), 18, colors[2]);
      case 4:
        _drawBlob(canvas, Offset(cx, crownCy - 30), 34, colors[0]);
        _drawBlob(canvas, Offset(cx - 18, crownCy - 18), 24, colors[1]);
        _drawBlob(canvas, Offset(cx + 18, crownCy - 18), 24, colors[2]);
        _drawBlob(canvas, Offset(cx - 8, crownCy - 10), 16, colors[3]);
        _drawBlob(canvas, Offset(cx + 8, crownCy - 10), 16, colors[4]);
      case 5:
        _drawBlob(canvas, Offset(cx, crownCy - 38), 40, colors[0]);
        _drawBlob(canvas, Offset(cx - 22, crownCy - 24), 30, colors[1]);
        _drawBlob(canvas, Offset(cx + 22, crownCy - 24), 30, colors[2]);
        _drawBlob(canvas, Offset(cx - 10, crownCy - 16), 22, colors[3]);
        _drawBlob(canvas, Offset(cx + 10, crownCy - 16), 22, colors[4]);
        _drawBlob(canvas, Offset(cx, crownCy - 10), 18, colors[0]);
    }
  }

  void _drawBlob(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(center, radius, Paint()..color = color);
  }

  void _drawLeaf(
      Canvas canvas, Offset pos, double size, double angle, Color color) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size * 0.5, -size * 0.4, size, 0)
      ..quadraticBezierTo(size * 0.5, size * 0.4, 0, 0);
    canvas.drawPath(path, Paint()..color = color);
    canvas.restore();
  }

  void _drawLeafBurst(
      Canvas canvas, double cx, double ground, double t, _FakeRng rng) {
    const trunkH = 62.0;
    final crownCy = ground - trunkH - 20;
    for (int i = 0; i < 5; i++) {
      final angle = (i / 5) * 2 * pi;
      final r = 20 + rng.next() * 15;
      final x = cx + cos(angle) * r * t;
      final y = crownCy + sin(angle) * r * 0.6 * t - 15 * t;
      final opacity = (1 - t).clamp(0.0, 1.0);
      final color = [
        const Color(0xFF66BB6A),
        const Color(0xFF81C784),
        const Color(0xFFA5D6A7),
        const Color(0xFF4CAF50),
        const Color(0xFF2E7D32),
      ][i % 5]
          .withValues(alpha: opacity);
      _drawLeaf(canvas, Offset(x, y), 8 + rng.next() * 4,
          angle + pi / 4 * t, color);
    }
  }

  void _drawFruit(Canvas canvas, double cx, double ground) {
    final positions = [
      Offset(cx - 16, ground - 88),
      Offset(cx + 18, ground - 82),
      Offset(cx - 6, ground - 78),
      Offset(cx + 8, ground - 95),
    ];
    for (final p in positions) {
      canvas.drawCircle(p, 5, Paint()..color = AppColors.coral);
      canvas.drawCircle(
          p,
          5,
          Paint()
            ..color = AppColors.border.withValues(alpha: 0.15)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
    }
  }

  void _drawFaceOrSparkles(
      Canvas canvas, double cx, double ground, int stage) {
    if (stage == 0) {
      final center = Offset(cx, ground - 25);
      final paint = Paint()..color = AppColors.border;
      canvas.drawCircle(Offset(cx - 3, center.dy - 2), 1.5, paint);
      canvas.drawCircle(Offset(cx + 3, center.dy - 2), 1.5, paint);
      final smilePath = Path()
        ..moveTo(cx - 3, center.dy + 3)
        ..quadraticBezierTo(cx, center.dy + 6, cx + 3, center.dy + 3);
      canvas.drawPath(
          smilePath,
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round);
    } else if (stage >= 4) {
      final positions = [
        Offset(cx - 40, ground - 90),
        Offset(cx + 42, ground - 85),
        Offset(cx, ground - 115),
      ];
      for (final p in positions) {
        _drawSparkle(canvas, p, AppColors.amber);
      }
    }
  }

  void _drawSparkle(Canvas canvas, Offset c, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 4; i++) {
      final angle = (i / 4) * 2 * pi;
      canvas.drawLine(
        Offset(c.dx + cos(angle) * 2, c.dy + sin(angle) * 2),
        Offset(c.dx + cos(angle) * 7, c.dy + sin(angle) * 7),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(TreePainter old) =>
      old.stage != stage || old.leafAnim != leafAnim;
}

class TreeMascotWidget extends StatefulWidget {
  final double progress;
  const TreeMascotWidget({super.key, required this.progress});

  @override
  State<TreeMascotWidget> createState() => _TreeMascotWidgetState();
}

class _TreeMascotWidgetState extends State<TreeMascotWidget>
    with TickerProviderStateMixin {
  late int _stage;
  late AnimationController _leafCtrl;

  @override
  void initState() {
    super.initState();
    _stage = _getStage(widget.progress);
    _leafCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
  }

  int _getStage(double p) {
    if (p >= 0.84) return 5;
    if (p >= 0.67) return 4;
    if (p >= 0.50) return 3;
    if (p >= 0.33) return 2;
    if (p >= 0.16) return 1;
    return 0;
  }

  @override
  void didUpdateWidget(TreeMascotWidget old) {
    super.didUpdateWidget(old);
    final newStage = _getStage(widget.progress);
    if (newStage != _stage) {
      setState(() => _stage = newStage);
    } else if (widget.progress != old.progress) {
      _leafCtrl.reset();
      _leafCtrl.forward();
    }
  }

  @override
  void dispose() {
    _leafCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _leafCtrl.reset();
        _leafCtrl.forward();
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween(begin: 0.85, end: 1.0).animate(anim),
            child: child,
          ),
        ),
        child: AnimatedBuilder(
          key: ValueKey(_stage),
          animation: _leafCtrl,
          builder: (_, _) => CustomPaint(
            painter: TreePainter(
              stage: _stage,
              leafAnim: _leafCtrl.value,
            ),
          ),
        ),
      ),
    );
  }
}

class _FakeRng {
  int _seed;
  _FakeRng(this._seed);
  double next() {
    _seed = (_seed * 1664525 + 1013904223) & 0xFFFFFFFF;
    return (_seed & 0xFFFF) / 0xFFFF;
  }
}

/// Alias used by dashboard: maps growthLevel (1-20) -> stage (0-5)
class TreeMascotPainter extends CustomPainter {
  final double growthLevel;
  TreeMascotPainter({required this.growthLevel});

  @override
  void paint(Canvas canvas, Size size) {
    final stage = ((growthLevel / 4).clamp(0, 5)).round();
    TreePainter(stage: stage, leafAnim: 0.8).paint(canvas, size);
  }

  @override
  bool shouldRepaint(TreeMascotPainter old) => old.growthLevel != growthLevel;
}

