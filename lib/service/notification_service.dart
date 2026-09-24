import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _permissionsRequested = false;

  // Vakit id'leri — her gün aynı id ile üzerine yazılır
  static const _ids = {
    'imsak': 1,
    'gunes': 2,
    'ogle': 3,
    'ikindi': 4,
    'aksam': 5,
    'yatsi': 6,
  };

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  /// Sadece plugin + timezone kurulumu. İzin istemez, açılışta güvenle çağrılır.
  static Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    try {
      final timeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZone.identifier));
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
      settings: const InitializationSettings(android: android, iOS: ios),
    );

    _initialized = true;
  }

  /// Android 13+ standart bildirim izni. Özel sistem ayarlarını açmaz.
  static Future<void> requestNotificationPermission() async {
    if (_permissionsRequested) return;
    _permissionsRequested = true;

    await init();

    try {
      await _android?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('[NotificationService] notification permission: $e');
    }
  }

  /// Exact alarm izni yoksa inexact moda düş — aksi halde zonedSchedule
  /// `exact_alarms_not_permitted` fırlatır (targetSdk 33+ cihazlarda varsayılan).
  static Future<AndroidScheduleMode> _scheduleMode() async {
    try {
      final canExact = await _android?.canScheduleExactNotifications();
      if (canExact == false) return AndroidScheduleMode.inexactAllowWhileIdle;
    } catch (e) {
      debugPrint('[NotificationService] canScheduleExact: $e');
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
    return AndroidScheduleMode.exactAllowWhileIdle;
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

    var scheduleMode = await _scheduleMode();

    for (final entry in vakitler.entries) {
      final key = entry.key;
      final timeStr = entry.value;
      final id = _ids[key]! + idOffset;

      // Switch kapalıysa bildirimi iptal et
      if (enabledPrayers[key] != true) {
        try {
          await _plugin.cancel(id: id);
        } catch (e) {
          debugPrint('[NotificationService] cancel $id: $e');
        }
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
        targetDate.year,
        targetDate.month,
        targetDate.day,
        hour,
        minute,
      );

      // Geçmiş vakit → atla (sadece bugün için kontrol et)
      if (isToday && scheduledTime.isBefore(now)) continue;

      try {
        await _schedule(id, names[key]!, scheduledTime, scheduleMode);
      } catch (e) {
        debugPrint('[NotificationService] schedule $id: $e');
        // Exact alarm izni çalışma anında geri alınmış olabilir → inexact'e düş
        if (scheduleMode == AndroidScheduleMode.exactAllowWhileIdle) {
          scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
          try {
            await _schedule(id, names[key]!, scheduledTime, scheduleMode);
          } catch (e2) {
            debugPrint('[NotificationService] inexact fallback $id: $e2');
          }
        }
      }
    }
  }

  static Future<void> _schedule(
    int id,
    String name,
    tz.TZDateTime when,
    AndroidScheduleMode mode,
  ) {
    return _plugin.zonedSchedule(
      id: id,
      title: '🕌 $name Vakti',
      body: '$name vakti girdi. Hayırlı olsun.',
      scheduledDate: when,
      notificationDetails: NotificationDetails(
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
      androidScheduleMode: mode,
    );
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
