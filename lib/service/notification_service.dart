import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Vakit id'leri — her gün aynı id ile üzerine yazılır
  static const _ids = {
    'imsak': 1,
    'gunes': 2,
    'ogle': 3,
    'ikindi': 4,
    'aksam': 5,
    'yatsi': 6,
  };

  static Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      // Türk kullanıcılar için güvenli fallback
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Android 13+ bildirim izni
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Android 12+ exact alarm izni (SCHEDULE_EXACT_ALARM)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    _initialized = true;
  }

  /// Bugünün namaz vakitleri için bildirim zamanla.
  /// [enabledPrayers]: hangi vakitlerin bildirimi açık olduğunu belirtir.
  /// Geçmiş vakitler atlanır; kapalı vakitler iptal edilir.
  static Future<void> schedulePrayerNotifications({
    required String? imsak,
    required String? gunes,
    required String? ogle,
    required String? ikindi,
    required String? aksam,
    required String? yatsi,
    DateTime? date, // null = bugün
    Map<String, bool> enabledPrayers = const {
      'imsak': true,
      'gunes': true,
      'ogle': true,
      'ikindi': true,
      'aksam': true,
      'yatsi': true,
    },
  }) async {
    await init();

    final vakitler = {
      'imsak': imsak,
      'gunes': gunes,
      'ogle': ogle,
      'ikindi': ikindi,
      'aksam': aksam,
      'yatsi': yatsi,
    };

    final names = {
      'imsak': 'İmsak',
      'gunes': 'Güneş',
      'ogle': 'Öğle',
      'ikindi': 'İkindi',
      'aksam': 'Akşam',
      'yatsi': 'Yatsı',
    };

    final now = tz.TZDateTime.now(tz.local);
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = date ?? today;
    final isToday = targetDate.year == today.year &&
        targetDate.month == today.month &&
        targetDate.day == today.day;
    // Bugün için ID offset 0 (1-6), yarın için offset 10 (11-16)
    final idOffset = isToday ? 0 : 10;

    for (final entry in vakitler.entries) {
      final key = entry.key;
      final timeStr = entry.value;
      final id = _ids[key]! + idOffset;

      // Switch kapalıysa bildirimi iptal et
      if (enabledPrayers[key] != true) {
        await _plugin.cancel(id);
        continue;
      }

      if (timeStr == null || timeStr.isEmpty) continue;

      final parts = timeStr.split(':');
      if (parts.length < 2) continue;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      final scheduledTime = tz.TZDateTime(
        tz.local,
        targetDate.year, targetDate.month, targetDate.day,
        hour, minute,
      );

      // Geçmiş vakit → atla (sadece bugün için kontrol et)
      if (isToday && scheduledTime.isBefore(now)) continue;

      await _plugin.zonedSchedule(
        id,
        '🕌 ${names[key]} Vakti',
        '${names[key]} vakti girdi. Hayırlı olsun.',
        scheduledTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'prayer_times',
            'Namaz Vakitleri',
            channelDescription: 'Namaz vakti bildirimleri',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
