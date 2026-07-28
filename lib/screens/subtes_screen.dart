// lib/screens/subtes_screen.dart -- Detail screen: chapters + topics with progress
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

  Future<void> _addTopic() async {
    // Pick chapter first
    if (_chapters.isEmpty) return;
    ChapterModel? selectedChapter;
    final nameCtrl = TextEditingController();
    final groupCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: const Text('Tambah Topik Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ChapterModel>(
                decoration: const InputDecoration(labelText: 'Bab'),
                items: _chapters.map((c) => DropdownMenuItem(
                  value: c, child: Text(c.name, overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (v) => setDs(() => selectedChapter = v),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: groupCtrl,
                decoration: const InputDecoration(labelText: 'Grup (opsional)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nama Topik'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            TextButton(
              onPressed: () async {
                if (selectedChapter == null || nameCtrl.text.trim().isEmpty) return;
                final nav = Navigator.of(ctx);
                await TopicRepo.insertCustom(
                  subtestId: widget.subtestId,
                  chapterId: selectedChapter!.id,
                  chapterName: selectedChapter!.name,
                  topicName: nameCtrl.text.trim(),
                  group: groupCtrl.text.trim().isEmpty ? null : groupCtrl.text.trim(),
                );
                nav.pop();
                await _load();
              },
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sub = _subtest;
    final color = sub != null
        ? Color(int.parse(sub.color.replaceFirst('#', '0xFF')))
        : AppColors.accent;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sub?.name ?? 'Detail Materi',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
        actions: [
          // Add topic button
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.textSecondary),
            onPressed: _addTopic,
            tooltip: 'Tambah Topik',
          ),
          // Progress ring
          if (sub != null)
            Consumer<ProgressProvider>(
              builder: (_, prov, __) => FutureBuilder<double>(
                future: prov.subtestProgress(widget.subtestId),
                builder: (_, snap) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: RingProgress(
                    progress: snap.data ?? 0,
                    size: 38,
                    strokeWidth: 3.5,
                    color: color,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _chapters.isEmpty
              ? Center(
                  child: Text(
                    'Belum ada bab.\nTambahkan dari tab Study.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: _chapters.length,
                  itemBuilder: (_, i) =>
                      _ChapterTile(chapter: _chapters[i], color: color, index: i, onChanged: _load),
                ),
    );
  }
}

class _ChapterTile extends StatefulWidget {
  final ChapterModel chapter;
  final Color color;
  final int index;
  final VoidCallback onChanged;

  const _ChapterTile({
    required this.chapter,
    required this.color,
    required this.index,
    required this.onChanged,
  });

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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final ch = widget.chapter;
    final allIds = ch.topics.map((t) => t.id).toList();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 250 + widget.index * 50),
      curve: Curves.easeOut,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 12 * (1 - t)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: _toggle,
              borderRadius: AppRadius.card,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 36,
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
                          Text(
                            ch.name,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Consumer<ProgressProvider>(
                            builder: (_, prov, __) {
                              final done = allIds.fold(
                                0, (s, id) => s + (prov.progress[id]?.completedCount ?? 0));
                              final total = allIds.length * 3;
                              final pct = total == 0 ? 0 : (done / total * 100).round();
                              return Row(
                                children: [
                                  Text(
                                    '${allIds.length} topik',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: AppRadius.pill,
                                      child: LinearProgressIndicator(
                                        value: total == 0 ? 0 : done / total,
                                        backgroundColor: AppColors.surfaceAlt,
                                        valueColor: AlwaysStoppedAnimation(widget.color),
                                        minHeight: 4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$pct%',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: widget.color,
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
                      turns: Tween(begin: 0.0, end: 0.5).animate(_anim),
                      child: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textMuted, size: 22),
                    ),
                  ],
                ),
              ),
            ),
            SizeTransition(
              sizeFactor: _anim,
              child: Column(
                children: [
                  const Divider(height: 1, color: AppColors.border),
                  ..._buildGroupedTopics(ch.topics, widget.color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroupedTopics(List<TopicModel> topics, Color color) {
    final groups = <String, List<TopicModel>>{};
    for (final t in topics) {
      final g = t.groupName ?? 'Umum';
      groups.putIfAbsent(g, () => []).add(t);
    }
    final widgets = <Widget>[];
    for (final entry in groups.entries) {
      widgets.add(Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        child: Text(
          entry.key.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted,
            letterSpacing: 1.2,
          ),
        ),
      ));
      for (final t in entry.value) {
        widgets.add(_TopicRow(topic: t, color: color, onDeleted: widget.onChanged));
      }
    }
    return widgets;
  }
}

class _TopicRow extends StatefulWidget {
  final TopicModel topic;
  final Color color;
  final VoidCallback onDeleted;
  const _TopicRow({required this.topic, required this.color, required this.onDeleted});

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

  Future<void> _deleteTopic() async {
    if (!widget.topic.isCustom) return; // only delete custom topics
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Topik'),
        content: Text('Hapus topik "${widget.topic.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Hapus', style: TextStyle(color: AppColors.coral)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await TopicRepo.delete(widget.topic.id);
      widget.onDeleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (ctx, prov, _) {
        final p = prov.progress[widget.topic.id] ??
            ProgressModel(topicId: widget.topic.id);

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.topic.name,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  // Notes button
                  GestureDetector(
                    onTap: () => setState(() => _showNotes = !_showNotes),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: (_showNotes || p.catatan.isNotEmpty)
                            ? AppColors.secondary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: AppRadius.sm,
                        border: Border.all(
                          color: (_showNotes || p.catatan.isNotEmpty)
                              ? AppColors.secondary
                              : AppColors.border,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.edit_note_rounded,
                        size: 16,
                        color: (_showNotes || p.catatan.isNotEmpty)
                            ? AppColors.secondary
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                  // Delete (only for custom topics)
                  if (widget.topic.isCustom) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: _deleteTopic,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.delete_outline_rounded,
                            size: 16, color: AppColors.coral),
                      ),
                    ),
                  ],
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
                        widget.topic.id, ProgressField.pelajari),
                  ),
                  const SizedBox(width: 8),
                  AnimatedCheckbox(
                    value: p.latihan,
                    label: 'Latihan',
                    color: AppColors.secondary,
                    onChanged: (_) => prov.toggleProgress(
                        widget.topic.id, ProgressField.latihan),
                  ),
                  const SizedBox(width: 8),
                  AnimatedCheckbox(
                    value: p.review,
                    label: 'Review',
                    color: AppColors.coral,
                    onChanged: (_) => prov.toggleProgress(
                        widget.topic.id, ProgressField.review),
                  ),
                ],
              ),
              if (_showNotes) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: TextEditingController(text: p.catatan)
                    ..selection = TextSelection.collapsed(offset: p.catatan.length),
                  maxLines: 2,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Tulis catatan di sini...',
                    isDense: true,
                    contentPadding: EdgeInsets.all(10),
                  ),
                  onChanged: (val) {
                    _debounce?.cancel();
                    _debounce = Timer(
                      const Duration(milliseconds: 500),
                      () => prov.updateCatatan(widget.topic.id, val),
                    );
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
