import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class PrayerNotificationService {
  PrayerNotificationService._();
  static final PrayerNotificationService instance = PrayerNotificationService._();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try { tz.setLocalLocation(tz.getLocation('Africa/Cairo')); } catch (_) {}
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings);
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    _initialized = true;
  }

  Future<void> scheduleDailyPrayerTimes(Map<String, String> timings) async {
    await initialize();
    const prayers = <String, int>{
      'الفجر': 101, 'الظهر': 102, 'العصر': 103,
      'المغرب': 104, 'العشاء': 105,
    };
    for (final entry in prayers.entries) {
      final raw = timings[entry.key];
      if (raw == null) continue;
      final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(raw.trim());
      if (match == null) continue;
      final hour = int.tryParse(match.group(1)!);
      final minute = int.tryParse(match.group(2)!);
      if (hour == null || minute == null || hour > 23 || minute > 59) continue;
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (!scheduled.isAfter(now)) scheduled = scheduled.add(const Duration(days: 1));
      await _plugin.zonedSchedule(
        entry.value,
        'حان وقت صلاة ${entry.key}',
        'تذكير بموعد الصلاة — فخري قرآن',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'fakhri_prayer_times', 'مواقيت الصلاة',
            channelDescription: 'تنبيهات يومية لمواقيت الصلاة',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelPrayerTimes() async {
    await initialize();
    for (var id = 101; id <= 105; id++) { await _plugin.cancel(id); }
  }
}
