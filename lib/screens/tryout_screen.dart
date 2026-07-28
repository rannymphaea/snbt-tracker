// lib/screens/tryout_screen.dart -- Tryout tab: target PTN + input skor + riwayat
import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';

class TryoutScreen extends StatefulWidget {
  const TryoutScreen({super.key});

  @override
  State<TryoutScreen> createState() => _TryoutScreenState();
}

class _TryoutScreenState extends State<TryoutScreen> {
  TargetPtn? _target;
  List<TryoutScore> _scores = [];
  bool _loading = true;
  bool _showForm = false;

  // Form fields
  final _nameCtrl = TextEditingController();
  final _scoreExpectedCtrl = TextEditingController();
  final _scoreMaxCtrl = TextEditingController(text: '1000');
  final _notesCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _target = await TargetPtnRepo.get();
    _scores = await TryoutScoreRepo.getAll();
    _loading = false;
    if (mounted) setState(() {});
  }

  Future<void> _saveScore() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nama tryout')),
      );
      return;
    }
    final expected = int.tryParse(_scoreExpectedCtrl.text);
    final max = int.tryParse(_scoreMaxCtrl.text) ?? 1000;

    await TryoutScoreRepo.add(TryoutScore(
      id: '',
      name: name,
      date: _selectedDate.toIso8601String().split('T')[0],
      scoreExpected: expected,
      scoreMax: max,
      notes: _notesCtrl.text.trim(),
    ));

    _nameCtrl.clear();
    _scoreExpectedCtrl.clear();
    _scoreMaxCtrl.text = '1000';
    _notesCtrl.clear();
    _selectedDate = DateTime.now();
    _showForm = false;
    await _load();
  }

  Future<void> _deleteScore(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Tryout'),
        content: const Text('Hapus catatan tryout ini?'),
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
      await TryoutScoreRepo.delete(int.tryParse(id) ?? 0);
      await _load();
    }
  }

  Future<void> _editTarget() async {
    final uniCtrl = TextEditingController(text: _target?.university ?? '');
    final majCtrl = TextEditingController(text: _target?.major ?? '');
    final pgCtrl = TextEditingController(
        text: _target?.passingGrade?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Target PTN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: uniCtrl,
              decoration: const InputDecoration(labelText: 'Universitas'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: majCtrl,
              decoration: const InputDecoration(labelText: 'Jurusan'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: pgCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Passing Grade (skor)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              if (uniCtrl.text.trim().isEmpty || majCtrl.text.trim().isEmpty) return;
              await TargetPtnRepo.set(TargetPtn(
                university: uniCtrl.text.trim(),
                major: majCtrl.text.trim(),
                passingGrade: int.tryParse(pgCtrl.text),
              ));
              if (mounted) Navigator.pop(context);
              await _load();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _scoreExpectedCtrl.dispose();
    _scoreMaxCtrl.dispose();
    _notesCtrl.dispose();
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
                    // Header
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
                      'Tryout',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Target PTN card
                    _buildTargetCard(),
                    const SizedBox(height: 16),

                    // Input form toggle
                    GestureDetector(
                      onTap: () => setState(() => _showForm = !_showForm),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.08),
                          borderRadius: AppRadius.card,
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.add_circle_outline_rounded,
                                color: AppColors.secondary, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Input Skor Tryout Baru',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.secondary,
                              ),
                            ),
                            const Spacer(),
                            AnimatedRotation(
                              duration: const Duration(milliseconds: 200),
                              turns: _showForm ? 0.5 : 0,
                              child: Icon(Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.secondary, size: 22),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Input form
                    if (_showForm) ...[
                      const SizedBox(height: 8),
                      _buildInputForm(),
                    ],

                    const SizedBox(height: 20),

                    // Riwayat
                    Row(
                      children: [
                        Text(
                          'Riwayat Tryout',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: AppRadius.pill,
                          ),
                          child: Text(
                            '${_scores.length}',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_scores.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            'Belum ada catatan tryout',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 14,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      )
                    else
                      ..._buildScoreList(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTargetCard() {
    return GestureDetector(
      onTap: _editTarget,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F2A2A),
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.teal.withValues(alpha: 0.4), width: 1),
        ),
        child: _target == null
            ? Row(
                children: [
                  Icon(Icons.add_circle_outline_rounded, color: AppColors.teal, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Tambahkan Target PTN',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.teal,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_target!.major} - ${_target!.university}',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Estimasi Aman (Passing Grade)',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_target!.passingGrade != null) ...[
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_target!.passingGrade}',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'SKOR / ESTIMASI',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.teal,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(width: 8),
                  const Icon(Icons.edit_rounded, color: AppColors.textMuted, size: 16),
                ],
              ),
      ),
    );
  }

  Widget _buildInputForm() {
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
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nama Tryout'),
          ),
          const SizedBox(height: 10),
          // Date picker
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2024),
                lastDate: DateTime(2028),
              );
              if (d != null) setState(() => _selectedDate = d);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: AppRadius.sm,
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded,
                      size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _scoreExpectedCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Skor Kamu'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _scoreMaxCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Skor Maksimal'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Catatan (opsional)',
              hintText: 'Contoh: Tryout Nasional 1',
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _saveScore,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('SIMPAN SKOR TRYOUT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.bg,
                textStyle: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.pill),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildScoreList() {
    return _scores.asMap().entries.map((entry) {
      final i = entry.key;
      final s = entry.value;
      final prev = i < _scores.length - 1 ? _scores[i + 1] : null;
      final delta = prev != null && s.scoreExpected != null && prev.scoreExpected != null
          ? s.scoreExpected! - prev.scoreExpected!
          : null;

      final score = s.scoreExpected ?? 0;
      final max = s.scoreMax > 0 ? s.scoreMax : 1000;
      final ratio = score / max;

      Color cardColor;
      if (ratio >= 0.75) {
        cardColor = AppColors.primary;
      } else if (ratio >= 0.55) {
        cardColor = AppColors.secondary;
      } else {
        cardColor = AppColors.coral;
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor.withValues(alpha: 0.08),
            borderRadius: AppRadius.card,
            border: Border.all(color: cardColor.withValues(alpha: 0.25), width: 1),
          ),
          child: Row(
            children: [
              // Delta badge
              if (delta != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: delta >= 0 ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.coral.withValues(alpha: 0.15),
                    borderRadius: AppRadius.pill,
                  ),
                  child: Text(
                    '${delta >= 0 ? '+' : ''}$delta PTS',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: delta >= 0 ? AppColors.primary : AppColors.coral,
                    ),
                  ),
                ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      s.date,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${s.scoreExpected ?? '-'}',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: cardColor,
                    ),
                  ),
                  Text(
                    '/ ${s.scoreMax}',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _deleteScore(s.id),
                child: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.textMuted, size: 18),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
