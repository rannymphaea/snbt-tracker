// lib/services/notification_service.dart -- Local notifications for daily reminder
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(settings,
        onDidReceiveNotificationResponse: (_) {});

    _initialized = true;
  }

  // Schedule daily reminder at HH:mm every day
  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) return;
    try {
      await _plugin.cancelAll();

      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      // If already passed today, schedule for tomorrow
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        0,
        'Waktunya Belajar!',
        'Jangan lupa check-in hari ini. Pohonmu menunggumu.',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'snbt_daily',
            'Pengingat Belajar Harian',
            channelDescription: 'Notifikasi harian pengingat belajar SNBT',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('NotificationService: scheduled daily at $hour:$minute');
    } catch (e) {
      debugPrint('NotificationService: $e');
    }
  }

  static Future<void> scheduleWeeklyTryoutReminder() async {
    if (kIsWeb) return;
    try {
      final now = tz.TZDateTime.now(tz.local);
      // Every Sunday at 09:00
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9, 0);
      while (scheduled.weekday != DateTime.sunday) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        1,
        'Cek Skor Tryout!',
        'Sudah ada tryout minggu ini? Catat skormu sekarang.',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'snbt_tryout',
            'Pengingat Tryout Mingguan',
            channelDescription: 'Pengingat mingguan untuk mencatat skor tryout',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('NotificationService weekly: $e');
    }
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
