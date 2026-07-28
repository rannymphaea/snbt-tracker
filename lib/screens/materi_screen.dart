// lib/screens/materi_screen.dart -- Study tab: manage 7 subtests, chapters, topics
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/progress_provider.dart';
import '../data/repository.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';

class MateriScreen extends StatefulWidget {
  const MateriScreen({super.key});

  @override
  State<MateriScreen> createState() => _MateriScreenState();
}

class _MateriScreenState extends State<MateriScreen> {
  List<SubtestModel> _subtests = [];
  final Set<String> _expanded = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _subtests = await SubtestRepo.getAll();
    _loading = false;
    if (mounted) setState(() {});
  }

  Color _colorFromHex(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                'SNBT TRACKER',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.accent,
                  letterSpacing: 1,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                'Materi Belajar',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            // Subtest list
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _subtests.length,
                      itemBuilder: (_, i) => _buildSubtestCard(_subtests[i], i),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtestCard(SubtestModel subtest, int index) {
    final color = _colorFromHex(subtest.color);
    final isExpanded = _expanded.contains(subtest.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: AppRadius.card,
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          children: [
            // Header row
            InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expanded.remove(subtest.id);
                  } else {
                    _expanded.add(subtest.id);
                  }
                });
              },
              borderRadius: AppRadius.card,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Color dot
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: AppRadius.sm,
                      ),
                      child: Center(
                        child: Text(
                          subtest.abbr,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subtest.name,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                          FutureBuilder<double>(
                            future: context.read<ProgressProvider>().subtestProgress(subtest.id),
                            builder: (_, snap) {
                              final pct = ((snap.data ?? 0) * 100).round();
                              return Text(
                                '$pct% selesai',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: isExpanded ? 0.5 : 0,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: color,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Expanded chapters
            if (isExpanded)
              _ChapterList(subtestId: subtest.id, color: color, onChanged: _load),
          ],
        ),
      ),
    );
  }
}

class _ChapterList extends StatefulWidget {
  final String subtestId;
  final Color color;
  final VoidCallback onChanged;

  const _ChapterList({required this.subtestId, required this.color, required this.onChanged});

  @override
  State<_ChapterList> createState() => _ChapterListState();
}

class _ChapterListState extends State<_ChapterList> {
  List<ChapterModel> _chapters = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _chapters = await ChapterRepo.getBySubtest(widget.subtestId);
    _loading = false;
    if (mounted) setState(() {});
  }

  Future<void> _addChapter() async {
    final name = await _showInputDialog('Tambah Bab Baru', 'Nama bab');
    if (name == null || name.trim().isEmpty) return;
    final id = 'ch-custom-${DateTime.now().millisecondsSinceEpoch}';
    await ChapterRepo.insert(ChapterModel(
      id: id,
      subtestId: widget.subtestId,
      name: name.trim(),
      sortOrder: _chapters.length,
    ));
    await _load();
    widget.onChanged();
  }

  Future<void> _editChapter(ChapterModel ch) async {
    final name = await _showInputDialog('Edit Bab', 'Nama bab', initial: ch.name);
    if (name == null || name.trim().isEmpty) return;
    await ChapterRepo.update(ch.id, name.trim());
    await _load();
    widget.onChanged();
  }

  Future<void> _deleteChapter(ChapterModel ch) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Bab'),
        content: Text('Hapus "${ch.name}" dan semua topik di dalamnya?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Hapus', style: TextStyle(color: AppColors.coral)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ChapterRepo.delete(ch.id);
    await _load();
    widget.onChanged();
  }

  Future<String?> _showInputDialog(String title, String label, {String? initial}) {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(labelText: label),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return Column(
      children: [
        const Divider(height: 1, color: AppColors.border),
        ..._chapters.map((ch) => _buildChapterTile(ch)),
        // Add button
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
          child: GestureDetector(
            onTap: _addChapter,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.08),
                borderRadius: AppRadius.sm,
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 16, color: widget.color),
                  const SizedBox(width: 6),
                  Text(
                    'Tambah Bab',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: widget.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChapterTile(ChapterModel ch) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/subtes', arguments: ch.subtestId);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  ch.name,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _editChapter(ch),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.edit_rounded, size: 16, color: AppColors.textMuted),
            ),
          ),
          GestureDetector(
            onTap: () => _deleteChapter(ch),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.coral),
            ),
          ),
        ],
      ),
    );
  }
}
