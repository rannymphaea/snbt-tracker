// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/progress_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/ring_progress.dart';
import '../widgets/tree_painter.dart';
import '../widgets/app_card.dart';
import '../widgets/animated_checkbox.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, prov, _) {
        if (prov.isLoading) {
          return const Scaffold(
            backgroundColor: AppColors.cream,
            body: Center(child: CircularProgressIndicator(color: AppColors.blue)),
          );
        }
        return Scaffold(
          backgroundColor: AppColors.cream,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => prov.init(),
              color: AppColors.blue,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildHero(context, prov),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildSubtestGrid(context, prov),
                        const SizedBox(height: 16),
                        _buildStreakCard(prov),
                        const SizedBox(height: 16),
                        _buildChart(prov),
                        const SizedBox(height: 16),
                        _buildTreeSection(prov),
                        const SizedBox(height: 20),
                        const Watermark(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── HERO HEADER (blue card, large progress) ──────────────────────────────
  Widget _buildHero(BuildContext context, ProgressProvider prov) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (_, t, child) =>
          Opacity(opacity: t, child: Transform.translate(offset: Offset(0, 20 * (1 - t)), child: child)),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.blue,
          borderRadius: AppRadius.cardLg,
          border: Border.all(color: AppColors.dark, width: 2.5),
          boxShadow: AppShadows.solidLg,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Halo, pejuang! 👋',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'SNBT 2027',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: AppRadius.pill,
                    ),
                    child: Text(
                      _getDailyQuote(),
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Big progress ring on white bg
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: AppRadius.card,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
              ),
              child: RingProgress(
                progress: prov.totalProgress,
                size: 82,
                strokeWidth: 8,
                color: AppColors.amber,
                fontSize: 15,
                trackColor: Colors.white24,
                textColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDailyQuote() {
    final quotes = [
      'Konsistensi mengalahkan intensitas.',
      'Sedikit demi sedikit, lama-lama jadi bukit.',
      'Setiap langkah kecil = lebih dekat.',
      'Fokus, disiplin, percaya dirimu!',
      'Hari ini lebih baik dari kemarin.',
      'Prosesmu sedang berjalan. Percayalah.',
      'Belajar setiap hari, sekecil apapun.',
    ];
    return quotes[DateTime.now().weekday % quotes.length];
  }

  // ── SUBTEST GRID (colorful cards, not just rings) ────────────────────────
  Widget _buildSubtestGrid(BuildContext context, ProgressProvider prov) {
    final colors  = AppColors.subtestColors;
    final pastels = AppColors.subtestPastel;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: const Interval(0.1, 1.0, curve: Curves.easeOut),
      builder: (_, t, child) => Opacity(opacity: t, child: child),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Subtes'),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 96,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: prov.subtests.length,
            itemBuilder: (_, i) {
              final sub   = prov.subtests[i];
              final color  = colors[i % colors.length];
              final pastel = pastels[i % pastels.length];
              return FutureBuilder<double>(
                future: prov.subtestProgress(sub.id),
                builder: (_, snap) {
                  final prog = snap.data ?? 0;
                  return TapScale(
                    onTap: () => Navigator.pushNamed(context, '/subtes', arguments: sub.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: pastel,
                        borderRadius: AppRadius.card,
                        border: Border.all(color: AppColors.dark, width: 2.5),
                        boxShadow: [AppShadows.solidColor(color, offset: 4)],
                      ),
                      child: Row(
                        children: [
                          RingProgress(
                            progress: prog,
                            size: 50,
                            strokeWidth: 5,
                            color: color,
                            fontSize: 11,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  sub.abbr,
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${(prog * 100).round()}% selesai',
                                  style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.hint,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, size: 16, color: color),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ── STREAK CARD ──────────────────────────────────────────────────────────
  Widget _buildStreakCard(ProgressProvider prov) {
    final streak = prov.streak;
    final color = streak >= 7 ? AppColors.coral
        : streak >= 3 ? AppColors.amber
        : AppColors.lime;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(-20 * (1 - t), 0), child: child),
      ),
      child: AppCard(
        color: color.withValues(alpha: 0.12),
        shadowColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            _StreakIcon(color: color, isHot: streak >= 3),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      AnimatedCount(
                        value: streak,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'hari streak',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.hint,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    streak == 0 ? 'Mulai streak-mu hari ini!'
                        : streak >= 14 ? '🔥 LUAR BIASA! Tak terbendung!'
                        : streak >= 7 ? '🔥 Seminggu full! Hebat!'
                        : streak >= 3 ? 'Pertahankan terus!'
                        : 'Yuk tambah hari ini!',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ACTIVITY CHART ───────────────────────────────────────────────────────
  Widget _buildChart(ProgressProvider prov) {
    final data = prov.last7Days;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      builder: (_, t, child) => Opacity(opacity: t, child: child),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Aktivitas 7 Hari'),
            SizedBox(
              height: 130,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, _) {
                          final i = val.toInt();
                          if (i < 0 || i >= data.length) return const SizedBox();
                          final d = DateTime.parse(data[i].date);
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              DateFormat('E', 'id').format(d),
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.hint,
                              ),
                            ),
                          );
                        },
                        reservedSize: 24,
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.asMap().entries.map((e) =>
                          FlSpot(e.key.toDouble(), e.value.checksCount.toDouble())).toList(),
                      isCurved: true,
                      color: AppColors.blue,
                      barWidth: 3.5,
                      dotData: FlDotData(
                        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                          radius: 5,
                          color: AppColors.blue,
                          strokeColor: AppColors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.blue.withValues(alpha: 0.25),
                            AppColors.blue.withValues(alpha: 0.02),
                          ],
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => AppColors.dark,
                      getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                        '${s.y.toInt()} ✓',
                        const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                      )).toList(),
                    ),
                  ),
                ),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── TREE MASCOT ──────────────────────────────────────────────────────────
  Widget _buildTreeSection(ProgressProvider prov) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      builder: (_, t, child) => Opacity(opacity: t, child: child),
      child: AppCard(
        color: AppColors.lime.withValues(alpha: 0.08),
        shadowColor: AppColors.lime,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SectionHeader(title: '🌳 Pohon Belajarmu'),
            SizedBox(
              height: 160,
              child: TreeMascotWidget(progress: prov.totalProgress),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Streak icon (animated pulsing) ────────────────────────────────────────
class _StreakIcon extends StatefulWidget {
  final Color color;
  final bool isHot;
  const _StreakIcon({required this.color, required this.isHot});

  @override
  State<_StreakIcon> createState() => _StreakIconState();
}

class _StreakIconState extends State<_StreakIcon> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    if (widget.isHot) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(_StreakIcon old) {
    super.didUpdateWidget(old);
    if (widget.isHot && !_ctrl.isAnimating) _ctrl.repeat();
    if (!widget.isHot && _ctrl.isAnimating) _ctrl.stop();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final scale = widget.isHot
            ? 1.0 + 0.1 * (0.5 - ((_ctrl.value - 0.5).abs()))
            : 1.0;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: AppRadius.card,
              border: Border.all(color: AppColors.dark, width: 2.5),
              boxShadow: AppShadows.solidSm,
            ),
            child: const Center(
              child: Text('🔥', style: TextStyle(fontSize: 22)),
            ),
          ),
        );
      },
    );
  }
}
