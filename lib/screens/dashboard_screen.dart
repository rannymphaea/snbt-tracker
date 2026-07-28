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
            body: Center(child: CircularProgressIndicator(color: AppColors.yellow)),
          );
        }
        return Scaffold(
          backgroundColor: AppColors.cream,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => prov.init(),
              color: AppColors.yellow,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  _buildHeader(context, prov),
                  const SizedBox(height: 16),
                  _buildTreeSection(context, prov),
                  const SizedBox(height: 16),
                  _buildSubtestRings(context, prov),
                  const SizedBox(height: 16),
                  _buildStreakCard(prov),
                  const SizedBox(height: 16),
                  _buildChart(prov),
                  const SizedBox(height: 20),
                  const Watermark(),
                  const SizedBox(height: 72), // nav bar space
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ProgressProvider prov) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 20 * (1 - t)), child: child),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SNBT 2027 📚',
                    style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 2),
                Text(_getDailyQuote(),
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: AppColors.dark.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          RingProgress(
            progress: prov.totalProgress,
            size: 72,
            strokeWidth: 7,
            color: AppColors.yellow,
            fontSize: 14,
          ),
        ],
      ),
    );
  }

  String _getDailyQuote() {
    final quotes = [
      'Konsistensi mengalahkan intensitas.',
      'Sedikit demi sedikit, lama-lama jadi bukit.',
      'Setiap langkah kecil membawamu lebih dekat.',
      'Fokus, disiplin, percaya dirimu sendiri.',
      'Hari ini lebih baik dari kemarin.',
      'Prosesmu sedang berjalan. Percayalah.',
      'Belajar setiap hari, sekecil apapun.',
    ];
    return quotes[DateTime.now().weekday % quotes.length];
  }

  Widget _buildTreeSection(BuildContext context, ProgressProvider prov) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      builder: (_, t, child) => Opacity(opacity: t, child: child),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 180,
          child: TreeMascotWidget(progress: prov.totalProgress),
        ),
      ),
    );
  }

  Widget _buildSubtestRings(BuildContext context, ProgressProvider prov) {
    final colors = AppColors.subtestColors;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      builder: (_, t, child) => Opacity(opacity: t, child: child),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Progress per Subtes',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisExtent: 90,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: prov.subtests.length,
              itemBuilder: (_, i) {
                final sub = prov.subtests[i];
                final color = colors[i % colors.length];
                return FutureBuilder<double>(
                  future: prov.subtestProgress(sub.id),
                  builder: (_, snap) {
                    final prog = snap.data ?? 0;
                    return TapScale(
                      onTap: () => Navigator.pushNamed(
                          context, '/subtes', arguments: sub.id),
                      child: Column(
                        children: [
                          RingProgress(
                            progress: prog,
                            size: 58,
                            strokeWidth: 6,
                            color: color,
                            fontSize: 12,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sub.abbr,
                            style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(ProgressProvider prov) {
    final streak = prov.streak;
    final color = streak >= 7 ? AppColors.coral
        : streak >= 3 ? AppColors.yellow
        : AppColors.green;
    final isHot = streak >= 3;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(-20 * (1 - t), 0), child: child),
      ),
      child: AppCard(
        small: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _StreakIcon(color: color, isHot: isHot),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AnimatedCount(value: streak,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900,
                              color: AppColors.dark)),
                      const SizedBox(width: 4),
                      const Text(' hari streak',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: AppColors.hint)),
                    ],
                  ),
                  Text(
                    streak == 0 ? 'Mulai streak-mu hari ini!'
                        : streak >= 14 ? '🔥 LUAR BIASA! Tak terbendung!'
                        : streak >= 7 ? '🔥 Seminggu full! Hebat!'
                        : streak >= 3 ? 'Pertahankan terus!'
                        : 'Yuk tambah hari ini!',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.hint),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(ProgressProvider prov) {
    final data = prov.last7Days;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      builder: (_, t, child) => Opacity(opacity: t, child: child),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tren 7 Hari Terakhir',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
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
                          final label = DateFormat('E', 'id').format(d);
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(label,
                                style: const TextStyle(fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.hint)),
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
                      color: AppColors.yellow,
                      barWidth: 3,
                      dotData: FlDotData(
                        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.yellow,
                          strokeColor: AppColors.dark,
                          strokeWidth: 2,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.yellow.withValues(alpha: 0.35),
                            AppColors.yellow.withValues(alpha: 0.02),
                          ],
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                        '${s.y.toInt()} ✓',
                        const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                      )).toList(),
                    ),
                  ),
                ),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
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
            ? 1.0 + 0.08 * (0.5 - ((_ctrl.value - 0.5).abs()))
            : 1.0;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: AppRadius.sm,
              border: Border.all(color: AppColors.dark, width: 2),
            ),
            child: const Center(
              child: Text('🔥', style: TextStyle(fontSize: 20)),
            ),
          ),
        );
      },
    );
  }
}

