// lib/screens/pengaturan_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../data/repository.dart';
import '../models/models.dart';
import '../providers/progress_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/animated_checkbox.dart';
import '../widgets/app_card.dart';

class PengaturanScreen extends StatelessWidget {
  const PengaturanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProgressProvider, SettingsProvider>(
      builder: (ctx, prov, settings, _) => Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 4),
              Text('Pengaturan',
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 20),

              _buildSection(context, '🔔 Reminder', [
                _ReminderTile(settings: settings),
              ]),
              const SizedBox(height: 14),

              _buildSection(context, '🔊 Suara', [
                _SwitchTile(
                  label: 'Efek Suara Centang',
                  subtitle: 'Mainkan suara saat centang topik',
                  value: settings.sfxEnabled,
                  onChanged: settings.setSfx,
                ),
              ]),
              const SizedBox(height: 14),

              _buildSection(context, '💾 Data', [
                _ActionTile(
                  icon: Icons.download_rounded,
                  label: 'Export Progres',
                  subtitle: 'Simpan progres sebagai file JSON',
                  color: AppColors.blue,
                  onTap: () => _export(context),
                ),
                _ActionTile(
                  icon: Icons.upload_rounded,
                  label: 'Import Progres',
                  subtitle: 'Pulihkan progres dari file JSON',
                  color: AppColors.green,
                  onTap: () => _import(context, prov),
                ),
                _ActionTile(
                  icon: Icons.delete_outline_rounded,
                  label: 'Reset Semua Progres',
                  subtitle: 'Hapus semua centang dan catatan',
                  color: AppColors.red,
                  onTap: () => _confirmReset(context, prov),
                ),
              ]),
              const SizedBox(height: 20),

              // App info
              AppCard(
                small: true,
                color: AppColors.cream,
                child: Column(
                  children: [
                    const Text('SNBT Study Tracker',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('v1.0.0 · Fully offline · No account needed',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                            color: AppColors.dark.withValues(alpha: 0.5))),
                    const SizedBox(height: 8),
                    Text('made by ran ft envy',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                            color: AppColors.dark.withValues(alpha: 0.25),
                            letterSpacing: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                  color: AppColors.hint)),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }

  Future<void> _export(BuildContext context) async {
    try {
      final allProgress = await ProgressRepo.getAll();
      final activityRows = await ActivityRepo.getLast7Days();
      final data = {
        'version': 1,
        'exported_at': DateTime.now().toIso8601String(),
        'progress': allProgress.map((k, v) => MapEntry(k, {
          'pelajari': v.pelajari,
          'latihan': v.latihan,
          'review': v.review,
          'catatan': v.catatan,
        })),
        'activity_dates': activityRows.where((a) => a.checksCount > 0)
            .map((a) => a.date).toList(),
      };
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

      if (kIsWeb) {
        // For web: show dialog with content
        if (context.mounted) {
          showDialog(context: context, builder: (_) => AlertDialog(
            title: const Text('Export JSON'),
            content: SelectableText(jsonStr, style: const TextStyle(fontSize: 10)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup')),
            ],
          ));
        }
        return;
      }

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Progres SNBT',
        fileName: 'snbt-progress-${DateTime.now().toIso8601String().split('T')[0]}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null) {
        await File(result).writeAsString(jsonStr);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Progres berhasil disimpan!')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _import(BuildContext context, ProgressProvider prov) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final bytes = result.files.first.bytes;
      final path  = result.files.first.path;
      String jsonStr;

      if (bytes != null) {
        jsonStr = utf8.decode(bytes);
      } else if (path != null) {
        jsonStr = await File(path).readAsString();
      } else { return; }

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      // Basic validation
      if (!data.containsKey('progress')) throw Exception('Invalid format');

      final progressMap = data['progress'] as Map<String, dynamic>;
      for (final entry in progressMap.entries) {
        final v = entry.value as Map<String, dynamic>;
        await ProgressRepo.updateCatatan(entry.key, v['catatan'] as String? ?? '');
        if (v['pelajari'] == true) {
          await ProgressRepo.toggle(entry.key, ProgressField.pelajari);
        }
        if (v['latihan'] == true) {
          await ProgressRepo.toggle(entry.key, ProgressField.latihan);
        }
        if (v['review'] == true) {
          await ProgressRepo.toggle(entry.key, ProgressField.review);
        }
      }
      await prov.init();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Progres berhasil diimpor!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error import: $e')));
      }
    }
  }

  Future<void> _confirmReset(BuildContext context, ProgressProvider prov) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.cardLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Reset Semua Progres?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text(
                'Semua centang, catatan, dan riwayat streak akan dihapus. Materi tidak berubah.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.hint,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: TapScale(
                onTap: () => Navigator.pop(context, false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.pill,
                    border: Border.all(color: AppColors.dark, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: const Text('Batal',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              )),
              const SizedBox(width: 12),
              Expanded(child: TapScale(
                onTap: () => Navigator.pop(context, true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: AppRadius.pill,
                    border: Border.all(color: AppColors.dark, width: 2),
                    boxShadow: AppShadows.solidSm,
                  ),
                  alignment: Alignment.center,
                  child: const Text('Reset',
                      style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              )),
            ]),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      await prov.resetAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Progres berhasil direset')));
      }
    }
  }
}

class _SwitchTile extends StatelessWidget {
  final String label, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({required this.label, required this.subtitle,
      required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700)),
            Text(subtitle, style: const TextStyle(
                fontSize: 12, color: AppColors.hint, fontWeight: FontWeight.w600)),
          ],
        )),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.yellow,
          activeTrackColor: AppColors.yellow.withValues(alpha: 0.3),
        ),
      ],
    ),
  );
}

class _ReminderTile extends StatelessWidget {
  final SettingsProvider settings;
  const _ReminderTile({required this.settings});

  @override
  Widget build(BuildContext context) => TapScale(
    onTap: () async {
      final parts = settings.reminderTime.split(':');
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        ),
        helpText: 'Pilih jam pengingat belajar',
        builder: (_, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      );
      if (picked != null) {
        final timeStr =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        await settings.setReminderTime(timeStr);
      }
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Jam Pengingat Belajar',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              Text('Notifikasi harian jam ${settings.reminderTime}',
                  style: const TextStyle(fontSize: 12, color: AppColors.hint,
                      fontWeight: FontWeight.w600)),
            ],
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.yellow,
              borderRadius: AppRadius.pill,
              border: Border.all(color: AppColors.dark, width: 2),
            ),
            child: Text(settings.reminderTime,
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 15)),
          ),
        ],
      ),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label,
      required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => TapScale(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.sm,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700)),
              Text(subtitle, style: const TextStyle(
                  fontSize: 12, color: AppColors.hint, fontWeight: FontWeight.w600)),
            ],
          )),
          Icon(Icons.chevron_right_rounded, color: AppColors.hint),
        ],
      ),
    ),
  );
}
