// lib/screens/dashboard_screen.dart -- Home tab: Tree + XP + Check-in
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/progress_provider.dart';
import '../data/repository.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';
import '../widgets/tree_painter.dart';
import '../widgets/praise_overlay.dart';
import '../services/cloud_sync.dart';
import 'pengaturan_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  // XP state
  UserXp _xp = const UserXp();

  // Check-in form
  List<SubtestModel> _subtests = [];
  List<ChapterModel> _chapters = [];
  List<TopicModel> _topics = [];
  String? _selectedSubtestId;
  String? _selectedChapterId;
  String? _selectedTopicId;
  final _durationCtrl = TextEditingController(text: '30');
  int _todayMinutes = 0;
  int _streak = 0;

  // Animations
  late AnimationController _treeShakeCtrl;
  late Animation<double> _treeShakeAnim;
  late AnimationController _xpPulseCtrl;

  @override
  void initState() {
    super.initState();
    _treeShakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _treeShakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0.04), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.04, end: -0.03), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.03, end: 0.02), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.02, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _treeShakeCtrl, curve: Curves.easeInOut));

    _xpPulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));

    _loadData();
  }

  Future<void> _loadData() async {
    _xp = await XpRepo.get();
    _subtests = await SubtestRepo.getAll();
    _todayMinutes = await CheckinRepo.getTodayMinutes();
    _streak = await ActivityRepo.getStreak();
    if (mounted) setState(() {});
  }

  Future<void> _onSubtestChanged(String? id) async {
    _selectedSubtestId = id;
    _selectedChapterId = null;
    _selectedTopicId = null;
    _chapters = id != null ? await ChapterRepo.getBySubtest(id) : [];
    _topics = [];
    setState(() {});
  }

  Future<void> _onChapterChanged(String? id) async {
    _selectedChapterId = id;
    _selectedTopicId = null;
    _topics = id != null ? await TopicRepo.getByChapter(id) : [];
    setState(() {});
  }

  Future<void> _onStartFocus() async {
    if (_selectedSubtestId == null || _selectedChapterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih bab dan sub-bab terlebih dahulu')),
      );
      return;
    }

    final duration = int.tryParse(_durationCtrl.text) ?? 30;
    if (duration <= 0) return;

    // Save check-in
    final checkin = await CheckinRepo.add(
      subtestId: _selectedSubtestId!,
      chapterId: _selectedChapterId!,
      topicId: _selectedTopicId,
      durationMinutes: duration,
    );

    // Add XP
    _xp = await XpRepo.addFromCheckin(duration);
    _todayMinutes = await CheckinRepo.getTodayMinutes();
    _streak = await ActivityRepo.getStreak();

    // Cloud sync (fire and forget)
    if (checkin != null) CloudSync.pushCheckin(checkin);
    CloudSync.pushXp(_xp);

    // Trigger animations
    _xpPulseCtrl.forward().then((_) => _xpPulseCtrl.reverse());

    // Reset form
    _selectedSubtestId = null;
    _selectedChapterId = null;
    _selectedTopicId = null;
    _chapters = [];
    _topics = [];
    _durationCtrl.text = '30';

    // Reload provider
    if (mounted) {
      context.read<ProgressProvider>().init();
      setState(() {});
    }

    // Show praise overlay
    if (mounted) {
      PraiseOverlay.show(context);
    }
  }

  void _onTreeTap() {
    _treeShakeCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _treeShakeCtrl.dispose();
    _xpPulseCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildTreeCard(),
              const SizedBox(height: 12),
              _buildXpBar(),
              const SizedBox(height: 20),
              _buildCheckinCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
        const Spacer(),
        // Streak badge
        if (_streak > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.15),
              borderRadius: AppRadius.pill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_fire_department, size: 14, color: AppColors.secondary),
                const SizedBox(width: 4),
                Text(
                  '$_streak hari',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PengaturanScreen()),
            );
          },
          child: const Icon(Icons.settings_rounded, color: AppColors.textSecondary, size: 22),
        ),
      ],
    );
  }

  Widget _buildTreeCard() {
    return GestureDetector(
      onTap: _onTreeTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text(
              'Ayo, siram pohonmu hari ini!',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _treeShakeAnim,
              builder: (_, child) => Transform.rotate(
                angle: _treeShakeAnim.value,
                child: child,
              ),
              child: SizedBox(
                height: 180,
                child: CustomPaint(
                  size: const Size(200, 180),
                  painter: TreeMascotPainter(
                    growthLevel: _xp.level.clamp(1, 20).toDouble(),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _statBadge('LV. ${_xp.level}', AppColors.accent),
                  const SizedBox(width: 12),
                  _statBadge('${_xp.totalXp} / ${_xp.xpForNextLevel} XP', AppColors.secondary),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _statBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildXpBar() {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.05)
          .animate(CurvedAnimation(parent: _xpPulseCtrl, curve: Curves.easeOut)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.sm,
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Belajar hari ini: ${(_todayMinutes / 60).toStringAsFixed(1)} jam',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: AppRadius.pill,
              child: LinearProgressIndicator(
                value: _xp.progress.clamp(0, 1),
                minHeight: 8,
                backgroundColor: AppColors.surfaceAlt,
                valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckinCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mulai Sesi Belajar',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 14),

          // Bab dropdown
          _label('PILIH BAB'),
          const SizedBox(height: 6),
          _dropdown<String>(
            hint: '-- Pilih Bab --',
            value: _selectedSubtestId,
            items: _subtests.map((s) => DropdownMenuItem(
              value: s.id, child: Text(s.name),
            )).toList(),
            onChanged: _onSubtestChanged,
          ),
          const SizedBox(height: 12),

          // Sub-bab dropdown (chapters)
          _label('PILIH SUB-BAB'),
          const SizedBox(height: 6),
          _dropdown<String>(
            hint: '-- Pilih Sub-bab --',
            value: _selectedChapterId,
            items: _chapters.map((c) => DropdownMenuItem(
              value: c.id, child: Text(c.name),
            )).toList(),
            onChanged: _onChapterChanged,
          ),
          const SizedBox(height: 12),

          // Topic dropdown (optional, more granular)
          if (_topics.isNotEmpty) ...[
            _label('PILIH TOPIK (OPSIONAL)'),
            const SizedBox(height: 6),
            _dropdown<String>(
              hint: '-- Pilih Topik --',
              value: _selectedTopicId,
              items: _topics.map((t) => DropdownMenuItem(
                value: t.id, child: Text(t.name, overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (v) => setState(() => _selectedTopicId = v),
            ),
            const SizedBox(height: 12),
          ],

          // Duration
          _label('DURASI (MENIT)'),
          const SizedBox(height: 6),
          Row(
            children: [
              ...[15, 30, 45, 60].map((m) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _durationCtrl.text = '$m'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _durationCtrl.text == '$m'
                          ? AppColors.secondary
                          : AppColors.surfaceAlt,
                      borderRadius: AppRadius.pill,
                      border: Border.all(
                        color: _durationCtrl.text == '$m'
                            ? AppColors.secondary
                            : AppColors.border,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '$m',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _durationCtrl.text == '$m'
                            ? AppColors.bg
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              )),
              const SizedBox(width: 4),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _durationCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      hintText: 'Lainnya',
                      hintStyle: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // START FOCUS button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _onStartFocus,
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text('START FOCUS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.pill),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _dropdown<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: TextStyle(
            fontFamily: 'Nunito', fontSize: 13, color: AppColors.textMuted,
          )),
          isExpanded: true,
          dropdownColor: AppColors.surfaceAlt,
          style: const TextStyle(
            fontFamily: 'Nunito', fontSize: 13,
            fontWeight: FontWeight.w600, color: AppColors.textPrimary,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
