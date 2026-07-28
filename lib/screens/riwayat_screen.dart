// lib/screens/riwayat_screen.dart -- History tab: charts, tabel 7 hari, kalender, breakdown
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/repository.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';
import 'dart:math' as math;

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen>
    with TickerProviderStateMixin {
  // Period toggle: 0=week, 1=month, 2=year
  int _periodIndex = 0;

  List<MapEntry<String, int>> _dailyData = [];
  Map<String, int> _subtestMinutes = {};
  List<TryoutScore> _tryouts = [];
  List<DailyCheckin> _checkins7Days = [];
  List<SubtestModel> _subtests = [];

  bool _loading = true;

  // Animation
  late AnimationController _barAnimCtrl;
  late Animation<double> _barAnim;

  final _periods = ['Minggu Ini', 'Bulan Ini', 'Tahun Ini'];

  @override
  void initState() {
    super.initState();
    _barAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _barAnim =
        CurvedAnimation(parent: _barAnimCtrl, curve: Curves.elasticOut);
    _load();
  }

  Future<void> _load() async {
    int days;
    switch (_periodIndex) {
      case 1:
        days = 30;
        break;
      case 2:
        days = 365;
        break;
      default:
        days = 7;
    }

    _dailyData = await CheckinRepo.getDailyTotals(days);
    _subtestMinutes = await CheckinRepo.getMinutesPerSubtest();
    _tryouts = await TryoutScoreRepo.getAll();
    _subtests = await SubtestRepo.getAll();

    // Last 7 days check-ins
    final all = await CheckinRepo.getAll();
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    _checkins7Days = all
        .where((c) => DateTime.parse(c.date).isAfter(cutoff))
        .toList();

    _loading = false;
    if (mounted) {
      setState(() {});
      _barAnimCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _barAnimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildFocusTodayCard(),
                    const SizedBox(height: 16),
                    _buildStudyTimeChart(),
                    const SizedBox(height: 16),
                    _buildTable7Days(),
                    const SizedBox(height: 16),
                    _buildSubtestBreakdown(),
                    const SizedBox(height: 16),
                    if (_tryouts.isNotEmpty) _buildTryoutChart(),
                    const SizedBox(height: 16),
                    _buildCalendar(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SNBT TRACKER',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.accent,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'History & Stats',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Lacak perjalanan belajarmu. Konsistensimu menentukan hasilmu.',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildFocusTodayCard() {
    final todayData = _dailyData.isNotEmpty ? _dailyData.last : null;
    final todayMinutes = todayData?.value ?? 0;
    final hours = todayMinutes / 60;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Focus Today',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${hours.toStringAsFixed(1)}h',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'TOTAL hari ini',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          _buildAverageStat(),
        ],
      ),
    );
  }

  Widget _buildAverageStat() {
    // Compute averages
    int days;
    switch (_periodIndex) {
      case 1: days = 30; break;
      case 2: days = 365; break;
      default: days = 7;
    }
    final total = _dailyData.fold(0, (s, e) => s + e.value);
    final avgMin = days > 0 ? total / days : 0;
    final avgHours = avgMin / 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Rata-rata / hari',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
        Text(
          '${avgHours.toStringAsFixed(1)}h',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.textSecondary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: AppRadius.pill,
          ),
          child: Text(
            _periods[_periodIndex],
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudyTimeChart() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Waktu Belajar Harian',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              // Period toggle
              ...List.generate(3, (i) {
                final active = i == _periodIndex;
                return GestureDetector(
                  onTap: () async {
                    setState(() => _periodIndex = i);
                    await _load();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: active ? AppColors.secondary : AppColors.surfaceAlt,
                      borderRadius: AppRadius.pill,
                    ),
                    child: Text(
                      ['M', 'B', 'T'][i],
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: active ? AppColors.bg : AppColors.textMuted,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _barAnim,
            builder: (_, __) {
              if (_dailyData.isEmpty) {
                return const Center(
                  child: Text('Belum ada data',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                );
              }
              final maxVal = _dailyData.fold(1, (m, e) => math.max(m, e.value));

              // Show limited bars based on period
              final displayData = _periodIndex == 0
                  ? _dailyData
                  : _periodIndex == 1
                      ? _dailyData.where((e) {
                          final d = DateTime.parse(e.key);
                          return DateTime.now().difference(d).inDays <= 30;
                        }).toList()
                      : _dailyData;

              return SizedBox(
                height: 160,
                child: BarChart(
                  BarChartData(
                    maxY: (maxVal * 1.2).toDouble(),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: AppColors.border,
                        strokeWidth: 0.5,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: _periodIndex == 0,
                          getTitlesWidget: (val, meta) {
                            if (val.toInt() >= displayData.length) return const SizedBox();
                            final d = DateTime.parse(displayData[val.toInt()].key);
                            final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                days[d.weekday - 1],
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 9,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            );
                          },
                          reservedSize: 18,
                        ),
                      ),
                    ),
                    barGroups: displayData.asMap().entries.map((entry) {
                      final i = entry.key;
                      final minutes = entry.value.value;
                      final animated = minutes * _barAnim.value;
                      final isToday = i == displayData.length - 1;

                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: animated.toDouble(),
                            width: _periodIndex == 0 ? 28 : 6,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: isToday
                                  ? [AppColors.secondary, AppColors.secondary.withValues(alpha: 0.7)]
                                  : [AppColors.accent.withValues(alpha: 0.8), AppColors.accent],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AppColors.surfaceAlt,
                        getTooltipItem: (group, _, rod, __) {
                          if (group.x >= displayData.length) return null;
                          final date = displayData[group.x].key;
                          final min = displayData[group.x].value;
                          final h = (min / 60).toStringAsFixed(1);
                          return BarTooltipItem(
                            '$date\n${h}j',
                            const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 500),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTable7Days() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Text(
              'Aktivitas 7 Hari Terakhir',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          // Table header
          Container(
            color: AppColors.surfaceAlt,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                _th('Tanggal', flex: 3),
                _th('Durasi', flex: 2),
                _th('Sesi', flex: 2),
                _th('Sub-bab', flex: 3),
              ],
            ),
          ),
          // Rows: group by date
          ..._buildTableRows(),
        ],
      ),
    );
  }

  Widget _th(String label, {int flex = 1}) => Expanded(
        flex: flex,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted,
          ),
        ),
      );

  List<Widget> _buildTableRows() {
    // Group check-ins by date
    final grouped = <String, List<DailyCheckin>>{};
    for (final c in _checkins7Days) {
      grouped.putIfAbsent(c.date, () => []).add(c);
    }

    if (grouped.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('Belum ada aktivitas',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ),
        )
      ];
    }

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return sortedDates.map((date) {
      final items = grouped[date]!;
      final totalMin = items.fold(0, (s, c) => s + c.durationMinutes);
      final h = (totalMin / 60).toStringAsFixed(1);
      final sesiCount = items.length;

      // Find unique chapter names from this date
      final chapterNames = items
          .map((c) => c.chapterId)
          .toSet()
          .take(2)
          .join(', ');

      final d = DateTime.parse(date);
      final dateLabel = '${d.day}/${d.month}';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                dateLabel,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${h}j',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '$sesiCount x',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                chapterNames.isEmpty ? '-' : chapterNames,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildSubtestBreakdown() {
    if (_subtestMinutes.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Durasi per Subtes',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ..._subtests.map((s) {
            final min = _subtestMinutes[s.id] ?? 0;
            if (min == 0) return const SizedBox();
            final h = (min / 60).toStringAsFixed(1);
            final total = _subtestMinutes.values.fold(1, (a, b) => a + b);
            final ratio = min / total;
            final color = Color(int.parse(s.color.replaceFirst('#', '0xFF')));

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 18,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: AppRadius.xs,
                        ),
                        child: Center(
                          child: Text(
                            s.abbr,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.name,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${h}j',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AnimatedBuilder(
                    animation: _barAnim,
                    builder: (_, __) => ClipRRect(
                      borderRadius: AppRadius.pill,
                      child: LinearProgressIndicator(
                        value: (ratio * _barAnim.value).clamp(0, 1),
                        minHeight: 5,
                        backgroundColor: AppColors.surfaceAlt,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTryoutChart() {
    final sorted = _tryouts.reversed.toList();
    if (sorted.length < 2) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tren Skor Tryout',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: AnimatedBuilder(
              animation: _barAnim,
              builder: (_, __) {
                final scores = sorted
                    .where((s) => s.scoreExpected != null)
                    .toList();
                if (scores.isEmpty) return const SizedBox();

                return LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) =>
                          FlLine(color: AppColors.border, strokeWidth: 0.5),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, _) {
                            final i = val.toInt();
                            if (i < 0 || i >= scores.length) return const SizedBox();
                            return Text(
                              'TO${i + 1}',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 8,
                                color: AppColors.textMuted,
                              ),
                            );
                          },
                          reservedSize: 16,
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: scores.asMap().entries.map((e) =>
                            FlSpot(e.key.toDouble(),
                                e.value.scoreExpected!.toDouble() * _barAnim.value)).toList(),
                        isCurved: true,
                        curveSmoothness: 0.35,
                        color: AppColors.primary,
                        barWidth: 2.5,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                            radius: 4,
                            color: AppColors.primary,
                            strokeColor: AppColors.bg,
                            strokeWidth: 2,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.primary.withValues(alpha: 0.3),
                              AppColors.primary.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    // Get active dates from check-ins
    final activeDates = _checkins7Days.map((c) => c.date).toSet();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kalender Aktivitas',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          // Day labels
          Row(
            children: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),
          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: daysInMonth + (firstDay.weekday - 1),
            itemBuilder: (_, index) {
              final offset = firstDay.weekday - 1;
              if (index < offset) return const SizedBox();

              final day = index - offset + 1;
              final dateStr =
                  '${now.year}-${now.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
              final isActive = activeDates.contains(dateStr);
              final isToday = day == now.day;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary
                      : isToday
                          ? AppColors.surfaceAlt
                          : Colors.transparent,
                  borderRadius: AppRadius.xs,
                  border: isToday && !isActive
                      ? Border.all(color: AppColors.secondary, width: 1)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 10,
                      fontWeight: isActive || isToday ? FontWeight.w800 : FontWeight.w500,
                      color: isActive
                          ? AppColors.bg
                          : isToday
                              ? AppColors.secondary
                              : AppColors.textMuted,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(width: 10, height: 10,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: AppRadius.xs)),
              const SizedBox(width: 4),
              Text('Ada sesi belajar', style: TextStyle(
                fontFamily: 'Nunito', fontSize: 10, color: AppColors.textMuted)),
              const SizedBox(width: 12),
              Container(width: 10, height: 10,
                  decoration: BoxDecoration(
                      border: Border.all(color: AppColors.secondary, width: 1),
                      borderRadius: AppRadius.xs)),
              const SizedBox(width: 4),
              Text('Hari ini', style: TextStyle(
                fontFamily: 'Nunito', fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
