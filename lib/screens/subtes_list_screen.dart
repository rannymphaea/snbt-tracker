// lib/screens/subtes_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/progress_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/animated_checkbox.dart';
import '../widgets/app_card.dart';
import '../screens/subtes_screen.dart';

class SubtesListScreen extends StatelessWidget {
  const SubtesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, prov, _) => Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 4),
              Text('Subtes SNBT',
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 4),
              Text('Pilih subtes untuk mulai belajar',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark.withValues(alpha: 0.5))),
              const SizedBox(height: 16),
              ...prov.subtests.asMap().entries.map((entry) {
                final i = entry.key;
                final sub = entry.value;
                final color = Color(
                    int.parse(sub.color.replaceFirst('#', '0xFF')));
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 250 + i * 80),
                  curve: Curves.easeOut,
                  builder: (_, t, child) => Opacity(
                    opacity: t,
                    child: Transform.translate(
                        offset: Offset(0, 20 * (1 - t)), child: child),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TapScale(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SubtesScreen(subtestId: sub.id),
                        ),
                      ),
                      child: AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: AppRadius.sm,
                                border: Border.all(color: color, width: 2),
                              ),
                              child: Center(
                                child: Text(sub.abbr,
                                    style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(sub.name,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800),
                                      maxLines: 2),
                                  const SizedBox(height: 6),
                                  FutureBuilder<double>(
                                    future: prov.subtestProgress(sub.id),
                                    builder: (_, snap) {
                                      final prog = snap.data ?? 0;
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('${(prog * 100).round()}% selesai',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: color)),
                                          const SizedBox(height: 4),
                                          ClipRRect(
                                            borderRadius: AppRadius.pill,
                                            child: LinearProgressIndicator(
                                              value: prog,
                                              backgroundColor:
                                                  color.withValues(alpha: 0.1),
                                              color: color,
                                              minHeight: 6,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right_rounded,
                                color: AppColors.hint),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 72),
            ],
          ),
        ),
      ),
    );
  }
}
