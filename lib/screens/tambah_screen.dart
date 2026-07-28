// lib/screens/tambah_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/repository.dart';
import '../models/models.dart';
import '../providers/progress_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/animated_checkbox.dart';
import '../widgets/app_card.dart';

class TambahScreen extends StatefulWidget {
  const TambahScreen({super.key});

  @override
  State<TambahScreen> createState() => _TambahScreenState();
}

class _TambahScreenState extends State<TambahScreen> {
  List<SubtestModel> _subtests = [];
  List<ChapterModel> _chapters = [];
  String? _selectedSubtest;
  String? _selectedChapter;
  bool _useNewChapter = false;
  final _topicCtrl    = TextEditingController();
  final _groupCtrl    = TextEditingController();
  final _newChapCtrl  = TextEditingController();
  bool _success = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSubtests();
  }

  Future<void> _loadSubtests() async {
    final subs = await SubtestRepo.getAll();
    if (mounted) setState(() => _subtests = subs);
  }

  Future<void> _loadChapters(String subtestId) async {
    final chs = await ChapterRepo.getBySubtest(subtestId);
    if (mounted) setState(() { _chapters = chs; _selectedChapter = null; });
  }

  Future<void> _submit() async {
    if (_selectedSubtest == null) return;
    if (_topicCtrl.text.trim().isEmpty) return;
    if (!_useNewChapter && _selectedChapter == null) return;
    if (_useNewChapter && _newChapCtrl.text.trim().isEmpty) return;

    setState(() => _loading = true);

    final chapterId = _useNewChapter
        ? 'custom-ch-${DateTime.now().millisecondsSinceEpoch}'
        : _selectedChapter!;
    final chapterName = _useNewChapter
        ? _newChapCtrl.text.trim()
        : _chapters.firstWhere((c) => c.id == _selectedChapter).name;

    await TopicRepo.insertCustom(
      subtestId: _selectedSubtest!,
      chapterId: chapterId,
      chapterName: chapterName,
      topicName: _topicCtrl.text.trim(),
      group: _groupCtrl.text.trim().isEmpty ? null : _groupCtrl.text.trim(),
    );

    // Capture provider before async gap
    if (!mounted) return;
    final prov = context.read<ProgressProvider>();
    await prov.init();

    _topicCtrl.clear();
    _groupCtrl.clear();
    if (mounted) setState(() { _loading = false; _success = true; });
    Future.delayed(const Duration(seconds: 2),
        () => mounted ? setState(() => _success = false) : null);
  }

  @override
  void dispose() {
    _topicCtrl.dispose();
    _groupCtrl.dispose();
    _newChapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 4),
            Text('Tambah Topik', style: Theme.of(context).textTheme.headlineLarge),
            Text('Tambah topik atau target belajar custom',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.border.withValues(alpha: 0.5))),
            const SizedBox(height: 20),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subtest dropdown
                  _label('Pilih Subtes *'),
                  _dropdown(
                    value: _selectedSubtest,
                    items: _subtests.map((s) =>
                        DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                    hint: '— Pilih subtes —',
                    onChanged: (v) {
                      setState(() => _selectedSubtest = v);
                      if (v != null) _loadChapters(v);
                    },
                  ),

                  if (_selectedSubtest != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _label('Bab'),
                        const SizedBox(width: 8),
                        TapScale(
                          onTap: () => setState(() {
                            _useNewChapter = !_useNewChapter;
                            _selectedChapter = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _useNewChapter ? AppColors.blue : Colors.white,
                              borderRadius: AppRadius.pill,
                              border: Border.all(color: AppColors.border, width: 2),
                            ),
                            child: Text(
                              _useNewChapter ? 'Bab Baru ✓' : 'Bab Existing',
                              style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700,
                                color: _useNewChapter ? Colors.white : AppColors.border,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_useNewChapter)
                      _textField(_newChapCtrl, 'Nama bab baru...')
                    else
                      _dropdown(
                        value: _selectedChapter,
                        items: _chapters.map((c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                        hint: '— Pilih bab —',
                        onChanged: (v) => setState(() => _selectedChapter = v),
                      ),
                  ],

                  const SizedBox(height: 16),
                  _label('Nama Topik *'),
                  _textField(_topicCtrl, 'Contoh: Latihan Soal HOTS Aljabar'),

                  const SizedBox(height: 16),
                  _label('Grup (opsional)'),
                  _textField(_groupCtrl, 'Contoh: Latihan Soal'),

                  const SizedBox(height: 20),
                  TapScale(
                    onTap: _loading ? null : _submit,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.amber,
                        borderRadius: AppRadius.pill,
                        border: Border.all(color: AppColors.border, width: 2),
                        boxShadow: AppShadows.card,
                      ),
                      alignment: Alignment.center,
                      child: _loading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2,
                                  color: AppColors.border))
                          : const Text('+ Tambah Topik',
                              style: TextStyle(fontWeight: FontWeight.w800,
                                  fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Success animation
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _success
                  ? AppCard(
                      key: const ValueKey('success'),
                      color: AppColors.lime.withValues(alpha: 0.1),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.lime),
                          const SizedBox(width: 8),
                          const Text('Topik berhasil ditambahkan!',
                              style: TextStyle(fontWeight: FontWeight.w800,
                                  color: AppColors.lime, fontSize: 14)),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 12),
            AppCard(
              small: true,
              color: AppColors.blue.withValues(alpha: 0.05),
              child: const Text(
                'Topik custom akan muncul di halaman subtes terkait. Tidak mengubah materi bawaan.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
  );

  Widget _dropdown({
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: AppRadius.card,
      border: Border.all(color: AppColors.border, width: 2),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        hint: Text(hint, style: const TextStyle(
            color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
        items: items,
        onChanged: onChanged,
        isExpanded: true,
        style: const TextStyle(
            color: AppColors.border, fontWeight: FontWeight.w700,
            fontSize: 13, fontFamily: 'Nunito'),
      ),
    ),
  );

  Widget _textField(TextEditingController ctrl, String hint) => TextField(
    controller: ctrl,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    decoration: InputDecoration(hintText: hint),
  );
}
