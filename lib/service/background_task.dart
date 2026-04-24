import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:huzurvakti/data/salah_time_data.dart';
import 'package:huzurvakti/data/user_district_info_data.dart';
import 'package:huzurvakti/service/notification_service.dart';
import 'package:huzurvakti/service/remote_service/salah_times_api.dart';

const _taskName = 'schedulePrayerNotifications';
const _taskId   = 'prayer_daily_2am';

const _prayerKeys = ['imsak', 'gunes', 'ogle', 'ikindi', 'aksam', 'yatsi'];

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
      var times = await salahDb.getOne(todayKey, info.lastSelectedDistrictId);

      // DB'de yoksa API'den çek (ay sonu geçişi vb. durumlar için)
      if (times == null) {
        try {
          final api = SalahTimesApi();
          final apiTimes = await api.getAllSalahTimesByDistrictId(
            info.lastSelectedDistrictId,
          );
          await salahDb.insertList(apiTimes);
          times = await salahDb.getOne(todayKey, info.lastSelectedDistrictId);
        } catch (e) {
          debugPrint('[BackgroundTask] API fetch failed: $e');
        }
      }

      if (times == null) return true;

      // SharedPreferences'tan switch durumlarını oku
      final prefs = await SharedPreferences.getInstance();
      final enabledPrayers = {
        for (final k in _prayerKeys) k: prefs.getBool('notify_$k') ?? true,
      };

      // Bildirimleri zamanla
      await NotificationService.schedulePrayerNotifications(
        imsak:  times.imsak,
        gunes:  times.gunes,
        ogle:   times.ogle,
        ikindi: times.ikindi,
        aksam:  times.aksam,
        yatsi:  times.yatsi,
        enabledPrayers: enabledPrayers,
      );
    } catch (e, stackTrace) {
      debugPrint('[BackgroundTask] ERROR: $e');
      debugPrint('[BackgroundTask] $stackTrace');
    } finally {
      // Zincir asla kırılmasın — hata olsa bile yarın için kayıt et
      BackgroundTask.registerNext();
    }

    return true;
  });
}

class BackgroundTask {
  /// Uygulama ilk açılışında çağrıl
  static Future<void> init() async {
    await Workmanager().initialize(callbackDispatcher);
    registerNext();
  }

  /// Bir sonraki gece 00:05'e kalan süreyi hesapla ve kayıt et
  static void registerNext() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 5);
    final delay = nextMidnight.difference(now);

    Workmanager().registerOneOffTask(
      _taskId,
      _taskName,
      initialDelay: delay,
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 5),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
    );
  }
}
