// lib/widgets/animated_checkbox.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/progress_provider.dart';
import '../utils/app_theme.dart';

class AnimatedCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;
  final Color color;

  const AnimatedCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.color = AppColors.green,
  });

  @override
  State<AnimatedCheckbox> createState() => _AnimatedCheckboxState();
}

class _AnimatedCheckboxState extends State<AnimatedCheckbox>
    with TickerProviderStateMixin {
  late AnimationController _checkCtrl;
  late AnimationController _particleCtrl;
  late Animation<double> _checkAnim;
  final _player = AudioPlayer();
  final _rng = Random();
  List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _checkAnim =
        CurvedAnimation(parent: _checkCtrl, curve: Curves.easeOut);
    if (widget.value) _checkCtrl.value = 1.0;
  }

  @override
  void didUpdateWidget(AnimatedCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _checkCtrl.forward();
      } else {
        _checkCtrl.reverse();
      }
    }
  }

  void _handleTap() async {
    final newVal = !widget.value;
    widget.onChanged(newVal);
    if (newVal) {
      _spawnParticles();
      if (mounted) {
        final sfxOn = context.read<SettingsProvider>().sfxEnabled;
        if (sfxOn) {
          try {
            await _player.play(AssetSource('sfx/check.wav'), volume: 0.6);
          } catch (_) {}
        }
      }
    }
  }

  void _spawnParticles() {
    _particles = List.generate(
        5,
        (i) => _Particle(
              dx: (_rng.nextDouble() - 0.5) * 36,
              dy: -(_rng.nextDouble() * 20 + 10),
              color: [
                AppColors.yellow,
                AppColors.coral,
                AppColors.blue,
                AppColors.green,
                AppColors.purple,
              ][i % 5],
              size: 4 + _rng.nextDouble() * 4,
            ));
    _particleCtrl
      ..reset()
      ..forward();
    setState(() {});
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _particleCtrl.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: widget.value ? widget.color : Colors.white,
                      borderRadius: AppRadius.sm,
                      border: Border.all(
                        color: widget.value
                            ? widget.color
                            : const Color(0xFFD4C9B8),
                        width: 2,
                      ),
                    ),
                    child: AnimatedBuilder(
                      animation: _checkAnim,
                      builder: (_, __x) => CustomPaint(
                        painter: _CheckPainter(_checkAnim.value),
                      ),
                    ),
                  ),
                  if (_particles.isNotEmpty)
                    AnimatedBuilder(
                      animation: _particleCtrl,
                      builder: (_, __x) => Stack(
                        clipBehavior: Clip.none,
                        children: _particles.map((p) {
                          final t = _particleCtrl.value;
                          return Positioned(
                            left: 13 + p.dx * t,
                            top: 13 + p.dy * t,
                            child: Opacity(
                              opacity: (1 - t).clamp(0.0, 1.0),
                              child: Transform.scale(
                                scale: t < 0.3 ? t / 0.3 : 1.0,
                                child: Container(
                                  width: p.size,
                                  height: p.size,
                                  decoration: BoxDecoration(
                                    color: p.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: widget.value ? widget.color : AppColors.hint,
            ),
            child: Text(widget.label),
          ),
        ],
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  _CheckPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.5)
      ..lineTo(size.width * 0.42, size.height * 0.72)
      ..lineTo(size.width * 0.8, size.height * 0.28);
    final metrics = path.computeMetrics().first;
    final extracted = metrics.extractPath(0, metrics.length * progress);
    canvas.drawPath(extracted, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}

class _Particle {
  final double dx, dy, size;
  final Color color;
  _Particle(
      {required this.dx,
      required this.dy,
      required this.size,
      required this.color});
}

// ─── TapScale ────────────────────────────────────────────────────────────────
class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  const TapScale(
      {super.key, required this.child, this.onTap, this.scale = 0.92});

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _anim = Tween(begin: 1.0, end: widget.scale)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) => _ctrl.reverse(),
        onTapCancel: () => _ctrl.reverse(),
        child: ScaleTransition(scale: _anim, child: widget.child),
      );
}

