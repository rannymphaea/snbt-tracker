// lib/widgets/praise_overlay.dart -- Motivational pop-up after check-in/tryout
import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class PraiseOverlay extends StatefulWidget {
  final VoidCallback onDismiss;
  final String? customMessage;

  const PraiseOverlay({
    super.key,
    required this.onDismiss,
    this.customMessage,
  });

  static void show(BuildContext context, {String? customMessage}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => PraiseOverlay(
        onDismiss: () => Navigator.of(context).pop(),
        customMessage: customMessage,
      ),
      transitionBuilder: (_, anim, __, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        child: FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  State<PraiseOverlay> createState() => _PraiseOverlayState();
}

class _PraiseOverlayState extends State<PraiseOverlay>
    with TickerProviderStateMixin {
  late AnimationController _particleCtrl;
  late AnimationController _starCtrl;
  late String _message;

  static const _messages = [
    'Mantap! Terus semangat belajarnya!',
    'Keren! Satu langkah lebih dekat ke PTN impian!',
    'Luar biasa! Konsistensimu akan membuahkan hasil!',
    'Bravo! Setiap menit belajar itu berharga!',
    'Hebat! Pohonmu semakin tumbuh!',
    'Kerja keras tidak pernah mengkhianati hasil!',
    'Kamu sedang membangun masa depanmu, terus!',
    'Salut! Disiplinmu luar biasa hari ini!',
  ];

  @override
  void initState() {
    super.initState();
    _message = widget.customMessage ??
        _messages[Random().nextInt(_messages.length)];

    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();
    _starCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _particleCtrl.dispose();
    _starCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: widget.onDismiss,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.card,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated star ring
                AnimatedBuilder(
                  animation: _starCtrl,
                  builder: (_, __) => Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.3 + 0.2 * _starCtrl.value),
                          AppColors.primary.withValues(alpha: 0),
                        ],
                      ),
                    ),
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _particleCtrl,
                        builder: (_, __) => Transform.scale(
                          scale: 0.7 + 0.3 * _particleCtrl.value,
                          child: const Icon(
                            Icons.eco_rounded,
                            size: 44,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // XP gained badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: AppRadius.pill,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'XP diperoleh!',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Main message
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Dismiss hint
                Text(
                  'Ketuk untuk menutup',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),

                // Particle animation (confetti dots)
                const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: _particleCtrl,
                  builder: (_, __) => CustomPaint(
                    size: const Size(double.infinity, 24),
                    painter: _ConfettiPainter(_particleCtrl.value),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final _rng = Random(42);

  _ConfettiPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      AppColors.coral,
    ];
    for (int i = 0; i < 12; i++) {
      final x = size.width * _rng.nextDouble();
      final y = size.height * _rng.nextDouble();
      final r = 3.0 + _rng.nextDouble() * 3;
      final opacity = (1 - progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y + progress * 40), r * progress, paint);
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
