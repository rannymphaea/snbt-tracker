import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../data/repository.dart';
import '../models/models.dart';
import '../providers/progress_provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../utils/app_theme.dart';
import '../widgets/animated_checkbox.dart';
import '../widgets/app_card.dart';

class PengaturanScreen extends StatelessWidget {
  const PengaturanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProgressProvider, SettingsProvider>(
      builder: (ctx, prov, settings, _) => Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 4),
              Text('Pengaturan',
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 20),

              _buildSection(context, 'Reminder', [
                _ReminderTile(settings: settings),
              ]),
              const SizedBox(height: 14),

              _buildSection(context, 'Suara', [
                _SwitchTile(
                  label: 'Efek Suara Centang',
                  subtitle: 'Mainkan suara saat centang topik',
                  value: settings.sfxEnabled,
                  onChanged: settings.setSfx,
                ),
              ]),
              const SizedBox(height: 14),

              _buildSection(context, 'Data', [
                _ActionTile(
                  icon: Icons.download_rounded,
                  label: 'Export Progres',
                  subtitle: 'Simpan progres sebagai file JSON',
                  color: AppColors.accent,
                  onTap: () => _export(context),
                ),
                _ActionTile(
                  icon: Icons.upload_rounded,
                  label: 'Import Progres',
                  subtitle: 'Pulihkan progres dari file JSON',
                  color: AppColors.primary,
                  onTap: () => _import(context, prov),
                ),
                _ActionTile(
                  icon: Icons.delete_outline_rounded,
                  label: 'Reset Semua Progres',
                  subtitle: 'Hapus semua centang dan catatan',
                  color: AppColors.coral,
                  onTap: () => _confirmReset(context, prov),
                ),
              ]),
              const SizedBox(height: 14),

              _buildSection(context, 'Akun', [
                _ActionTile(
                  icon: Icons.logout_rounded,
                  label: 'Keluar',
                  subtitle: 'Logout dari akun Firebase',
                  color: AppColors.coral,
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Keluar'),
                        content: const Text('Yakin ingin keluar dari akun?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Keluar',
                                style: TextStyle(color: AppColors.coral)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      await context.read<app_auth.AuthProvider>().logout();
                    }
                  },
                ),
              ]),
              const SizedBox(height: 20),

              // App info
              AppCard(
                small: true,
                color: AppColors.surface,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset('assets/icon.png', width: 64, height: 64, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 10),
                    const Text('SNBT Study Tracker',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('v2.0 · Offline-first · Firebase Auth',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                            color: AppColors.border.withValues(alpha: 0.5))),
                    const SizedBox(height: 10),
                    const Watermark(),
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
                  color: AppColors.textMuted)),
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
      final fileName = 'snbt-progress-${DateTime.now().toIso8601String().split('T')[0]}.json';

      if (kIsWeb) {
        if (context.mounted) {
          showDialog(context: context, builder: (_) => AlertDialog(
            title: const Text('Export JSON'),
            content: SelectableText(jsonStr, style: const TextStyle(fontSize: 10)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
            ],
          ));
        }
        return;
      }

      // Write to Documents directory (accessible on Android + Windows)
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(jsonStr);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Disimpan ke:\n${file.path}'),
            duration: const Duration(seconds: 6),
          ),
        );
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
      if (kIsWeb) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Import tidak didukung di browser.')));
        }
        return;
      }

      // Read the most recent exported file from Documents
      final dir = await getApplicationDocumentsDirectory();
      final files = dir.listSync()
          .whereType<File>()
          .where((f) => f.path.contains('snbt-progress') && f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path)); // newest first

      if (files.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada file export ditemukan di Documents.')));
        }
        return;
      }

      final jsonStr = await files.first.readAsString();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (!data.containsKey('progress')) throw Exception('Format tidak valid');

      final progressMap = data['progress'] as Map<String, dynamic>;
      for (final entry in progressMap.entries) {
        final v = entry.value as Map<String, dynamic>;
        await ProgressRepo.updateCatatan(entry.key, v['catatan'] as String? ?? '');
        if ((v['pelajari'] as int? ?? 0) == 1) {
          await ProgressRepo.toggle(entry.key, ProgressField.pelajari);
        }
        if ((v['latihan'] as int? ?? 0) == 1) {
          await ProgressRepo.toggle(entry.key, ProgressField.latihan);
        }
        if ((v['review'] as int? ?? 0) == 1) {
          await ProgressRepo.toggle(entry.key, ProgressField.review);
        }
      }
      await prov.init();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Diimpor dari: ${files.first.path.split(Platform.pathSeparator).last}')));
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
                style: TextStyle(fontSize: 13, color: AppColors.textMuted,
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
                    border: Border.all(color: AppColors.border, width: 2),
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
                    color: AppColors.coral,
                    borderRadius: AppRadius.pill,
                    border: Border.all(color: AppColors.border, width: 2),
                    boxShadow: AppShadows.card,
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
                fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          ],
        )),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.amber,
          activeTrackColor: AppColors.amber.withValues(alpha: 0.3),
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
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted,
                      fontWeight: FontWeight.w600)),
            ],
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.amber,
              borderRadius: AppRadius.pill,
              border: Border.all(color: AppColors.border, width: 2),
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
                  fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
            ],
          )),
          Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    ),
  );
}
