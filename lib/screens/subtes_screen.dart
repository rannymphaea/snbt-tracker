// lib/screens/subtes_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/repository.dart';
import '../models/models.dart';
import '../providers/progress_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/animated_checkbox.dart';
import '../widgets/ring_progress.dart';

class SubtesScreen extends StatefulWidget {
  final String subtestId;
  const SubtesScreen({super.key, required this.subtestId});

  @override
  State<SubtesScreen> createState() => _SubtesScreenState();
}

class _SubtesScreenState extends State<SubtesScreen> {
  List<ChapterModel> _chapters = [];
  SubtestModel? _subtest;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prov = context.read<ProgressProvider>();
    final sub = await SubtestRepo.getById(widget.subtestId);
    final chapters = await prov.getChaptersWithTopics(widget.subtestId);
    if (mounted) {
      setState(() {
        _subtest = sub;
        _chapters = chapters;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = _subtest;
    final color = sub != null
        ? Color(int.parse(sub.color.replaceFirst('#', '0xFF')))
        : AppColors.blue;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: TapScale(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_rounded, color: AppColors.dark),
        ),
        title: Text(sub?.name ?? 'Subtes',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        actions: [
          if (sub != null)
            Consumer<ProgressProvider>(
              builder: (_, prov, __) => FutureBuilder<double>(
                future: prov.subtestProgress(widget.subtestId),
                builder: (_, snap) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: RingProgress(
                    progress: snap.data ?? 0,
                    size: 42,
                    strokeWidth: 4,
                    color: color,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.yellow))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _chapters.length + 1,
              itemBuilder: (_, i) {
                if (i == _chapters.length) return const SizedBox(height: 80);
                return _ChapterTile(
                    chapter: _chapters[i], color: color, index: i);
              },
            ),
    );
  }
}

class _ChapterTile extends StatefulWidget {
  final ChapterModel chapter;
  final Color color;
  final int index;
  const _ChapterTile(
      {required this.chapter, required this.color, required this.index});

  @override
  State<_ChapterTile> createState() => _ChapterTileState();
}

class _ChapterTileState extends State<_ChapterTile>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ch = widget.chapter;
    final allIds = ch.topics.map((t) => t.id).toList();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + widget.index * 60),
      curve: Curves.easeOut,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
            offset: Offset(-16 * (1 - t), 0), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.dark, width: 2),
          boxShadow: AppShadows.solidSm,
        ),
        child: Column(
          children: [
            TapScale(
              onTap: _toggle,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: widget.color,
                        borderRadius: AppRadius.pill,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ch.name,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Consumer<ProgressProvider>(
                            builder: (_, prov, __) {
                              final done = allIds.fold(
                                  0,
                                  (s, id) =>
                                      s +
                                      (prov.progress[id]?.completedCount ??
                                          0));
                              final total = allIds.length * 3;
                              final pct = total == 0
                                  ? 0
                                  : (done / total * 100).round();
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      '${allIds.length} topik · $pct%',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.hint)),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: AppRadius.pill,
                                    child: LinearProgressIndicator(
                                      value: total == 0
                                          ? 0
                                          : done / total,
                                      backgroundColor:
                                          const Color(0xFFEEEEEE),
                                      color: widget.color,
                                      minHeight: 5,
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
                    RotationTransition(
                      turns:
                          Tween(begin: 0.0, end: 0.5).animate(_anim),
                      child: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: AppColors.hint),
                    ),
                  ],
                ),
              ),
            ),
            SizeTransition(
              sizeFactor: _anim,
              child: Column(
                children:
                    _buildGroupedTopics(ch.topics, widget.color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroupedTopics(
      List<TopicModel> topics, Color color) {
    final groups = <String, List<TopicModel>>{};
    for (final t in topics) {
      final g = t.groupName ?? 'Lainnya';
      groups.putIfAbsent(g, () => []).add(t);
    }
    final widgets = <Widget>[];
    widgets.add(
        const Divider(height: 1, color: Color(0xFFF0EDE8)));
    for (final entry in groups.entries) {
      widgets.add(Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        child: Text(entry.key.toUpperCase(),
            style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppColors.hint,
                letterSpacing: 1.2)),
      ));
      for (final t in entry.value) {
        widgets.add(_TopicRow(topic: t, color: color));
      }
    }
    return widgets;
  }
}

class _TopicRow extends StatefulWidget {
  final TopicModel topic;
  final Color color;
  const _TopicRow({required this.topic, required this.color});

  @override
  State<_TopicRow> createState() => _TopicRowState();
}

class _TopicRowState extends State<_TopicRow> {
  bool _showNotes = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (ctx, prov, _) {
        final p = prov.progress[widget.topic.id] ??
            ProgressModel(topicId: widget.topic.id);

        return Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: const BoxDecoration(
            border: Border(
                bottom:
                    BorderSide(color: Color(0xFFF0EDE8))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(widget.topic.name,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ),
                  TapScale(
                    onTap: () => setState(
                        () => _showNotes = !_showNotes),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _showNotes ||
                                p.catatan.isNotEmpty
                            ? AppColors.yellow
                                .withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: AppRadius.sm,
                        border: Border.all(
                          color: _showNotes ||
                                  p.catatan.isNotEmpty
                              ? AppColors.yellow
                              : const Color(0xFFDDDDDD),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                          Icons.edit_note_rounded,
                          size: 16,
                          color: _showNotes ||
                                  p.catatan.isNotEmpty
                              ? AppColors.dark
                              : AppColors.hint),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  AnimatedCheckbox(
                    value: p.pelajari,
                    label: 'Pelajari',
                    color: widget.color,
                    onChanged: (_) => prov.toggleProgress(
                        widget.topic.id,
                        ProgressField.pelajari),
                  ),
                  const SizedBox(width: 8),
                  AnimatedCheckbox(
                    value: p.latihan,
                    label: 'Latihan',
                    color: AppColors.yellow,
                    onChanged: (_) => prov.toggleProgress(
                        widget.topic.id,
                        ProgressField.latihan),
                  ),
                  const SizedBox(width: 8),
                  AnimatedCheckbox(
                    value: p.review,
                    label: 'Review',
                    color: AppColors.coral,
                    onChanged: (_) => prov.toggleProgress(
                        widget.topic.id,
                        ProgressField.review),
                  ),
                ],
              ),
              if (_showNotes) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: TextEditingController(
                      text: p.catatan)
                    ..selection = TextSelection.collapsed(
                        offset: p.catatan.length),
                  maxLines: 2,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    hintText: 'Tulis catatan di sini...',
                    isDense: true,
                    contentPadding: EdgeInsets.all(10),
                  ),
                  onChanged: (val) {
                    _debounce?.cancel();
                    _debounce = Timer(
                        const Duration(milliseconds: 500),
                        () => prov.updateCatatan(
                            widget.topic.id, val));
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

