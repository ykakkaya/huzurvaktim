import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import 'package:huzurvakti/data/salah_time_data.dart';
import 'package:huzurvakti/data/user_district_info_data.dart';
import 'package:huzurvakti/service/notification_service.dart';

const _taskName = 'schedulePrayerNotifications';
const _taskId   = 'prayer_daily_2am';

/// Workmanager arka plan görevi — top-level zorunlu
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, _) async {
    if (taskName != _taskName) return true;

    try {
      WidgetsFlutterBinding.ensureInitialized();

      // Kayıtlı ilçeyi al
      final districtInfoDb = UserDiscrictInfoDatabaseHelper();
      final info = await districtInfoDb.getDistrictInfo();
      if (info == null) return true;

      // Bugünün tarihini DB formatında oluştur
      final now = DateTime.now();
      final todayKey = DateTime(now.year, now.month, now.day).toString();

      // Bugünün vakitlerini DB'den çek
      final salahDb = SalahTimeDatabaseHelper();
      final times = await salahDb.getOne(todayKey, info.lastSelectedDistrictId);
      if (times == null) return true;

      // Bildirimleri zamanla
      await NotificationService.schedulePrayerNotifications(
        imsak:  times.imsak,
        gunes:  times.gunes,
        ogle:   times.ogle,
        ikindi: times.ikindi,
        aksam:  times.aksam,
        yatsi:  times.yatsi,
      );

      // Yarın 02:00 için bir sonraki görevi kayıt et
      BackgroundTask.registerNext();
    } catch (_) {}

    return true;
  });
}

class BackgroundTask {
  /// Uygulama ilk açılışında çağrıl — bir sonraki 02:00'ye göre zamanla
  static Future<void> init() async {
    await Workmanager().initialize(callbackDispatcher);
    registerNext();
  }

  /// Bir sonraki gece yarısından 5 dk sonraya (00:05) kalan süreyi hesapla
  static void registerNext() {
    final now = DateTime.now();
    // Yarının 00:05'i — gece yarısı geçince yeni günün vakitleri zamanlanır
    final nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 5);
    final delay = nextMidnight.difference(now);

    Workmanager().registerOneOffTask(
      _taskId,
      _taskName,
      initialDelay: delay,
      existingWorkPolicy: ExistingWorkPolicy.replace,
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
    );
  }
}
