import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

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
    // Sistem timezone'unu kullan — cihazın yerel saatiyle senkron
    final String localTz = DateTime.now().timeZoneName;
    try {
      tz.setLocalLocation(tz.getLocation(localTz));
    } catch (_) {
      // Sistem tz adı tanınmazsa (örn. "GMT+3") offset ile fallback
      final offsetHours = DateTime.now().timeZoneOffset.inHours;
      final fallback = tz.timeZoneDatabase.locations.values.firstWhere(
        (loc) => loc.currentTimeZone.offset == offsetHours * 3600000,
        orElse: () => tz.UTC,
      );
      tz.setLocalLocation(fallback);
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

    _initialized = true;
  }

  /// Bugünün namaz vakitleri için bildirim zamanla.
  /// Geçmiş vakitler atlanır.
  static Future<void> schedulePrayerNotifications({
    required String? imsak,
    required String? gunes,
    required String? ogle,
    required String? ikindi,
    required String? aksam,
    required String? yatsi,
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

    // Önce hepsini iptal et
    await cancelAll();

    final now = tz.TZDateTime.now(tz.local);

    for (final entry in vakitler.entries) {
      final key = entry.key;
      final timeStr = entry.value;
      if (timeStr == null || timeStr.isEmpty) continue;

      final parts = timeStr.split(':');
      if (parts.length < 2) continue;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      var scheduledTime = tz.TZDateTime(
        tz.local,
        now.year, now.month, now.day,
        hour, minute,
      );

      // Geçmiş vakit → atla
      if (scheduledTime.isBefore(now)) continue;

      await _plugin.zonedSchedule(
        _ids[key]!,
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
