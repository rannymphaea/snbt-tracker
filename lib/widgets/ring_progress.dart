// lib/widgets/ring_progress.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class RingProgress extends StatefulWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color color;
  final Color bgColor;
  final bool showLabel;
  final String? label;
  final double fontSize;
  final Color? trackColor;   // override bgColor (e.g. for dark hero card)
  final Color? textColor;    // override text color

  const RingProgress({
    super.key,
    required this.progress,
    this.size = 120,
    this.strokeWidth = 10,
    this.color = AppColors.amber,
    this.bgColor = const Color(0xFFE8E0D4),
    this.showLabel = true,
    this.label,
    this.fontSize = 22,
    this.trackColor,
    this.textColor,
  });

  @override
  State<RingProgress> createState() => _RingProgressState();
}

class _RingProgressState extends State<RingProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _prevProgress = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = Tween(begin: 0.0, end: widget.progress)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
    _prevProgress = widget.progress;
  }

  @override
  void didUpdateWidget(RingProgress old) {
    super.didUpdateWidget(old);
    if (widget.progress != old.progress) {
      _anim = Tween(begin: _prevProgress, end: widget.progress)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _prevProgress = widget.progress;
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _RingPainter(
            progress: _anim.value,
            strokeWidth: widget.strokeWidth,
            color: widget.color,
            bgColor: widget.trackColor ?? widget.bgColor,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showLabel)
                  Text(
                    '${(_anim.value * 100).round()}%',
                    style: TextStyle(
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.w900,
                      color: widget.textColor ?? AppColors.border,
                      fontFamily: 'Nunito',
                    ),
                  ),
                if (widget.label != null)
                  Text(
                    widget.label!,
                    style: TextStyle(
                      fontSize: widget.fontSize * 0.4,
                      fontWeight: FontWeight.w700,
                      color: AppColors.border.withValues(alpha: 0.6),
                      fontFamily: 'Nunito',
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color, bgColor;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = bgColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);

    if (progress <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

class AnimatedCount extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final String suffix;

  const AnimatedCount({
    super.key,
    required this.value,
    this.style,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (_, v, _) => Text(
        '$v$suffix',
        style: style ?? Theme.of(context).textTheme.displayMedium,
      ),
    );
  }
}

