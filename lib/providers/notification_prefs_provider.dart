import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:huzurvakti/providers/shared_prefs_provider.dart';
import 'package:huzurvakti/providers/salah_times_provider.dart';
import 'package:huzurvakti/service/notification_service.dart';
import 'package:huzurvakti/data/salah_time_data.dart';

const _prayerKeys = ['imsak', 'gunes', 'ogle', 'ikindi', 'aksam', 'yatsi'];

class NotificationPrefsNotifier extends Notifier<Map<String, bool>> {
  static String _prefKey(String vakit) => 'notify_$vakit';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  Map<String, bool> build() {
    return {
      for (final k in _prayerKeys) k: _prefs.getBool(_prefKey(k)) ?? true,
    };
  }

  Future<void> toggle(String vakit) async {
    final current = state[vakit] ?? true;
    final next = !current;
    await _prefs.setBool(_prefKey(vakit), next);
    state = {...state, vakit: next};

    // Switch değiştiğinde bugün + yarın bildirimlerini yeniden zamanla
    final providerState = ref.read(salahTimesProvider);
    final times = providerState.salahTimes;
    if (times != null) {
      NotificationService.schedulePrayerNotifications(
        imsak: times.imsak,
        gunes: times.gunes,
        ogle: times.ogle,
        ikindi: times.ikindi,
        aksam: times.aksam,
        yatsi: times.yatsi,
        enabledPrayers: state,
      );

      // Yarın için de güncelle
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final db = SalahTimeDatabaseHelper();
      final tomorrowTimes = await db.getOne(
        tomorrow.toString(),
        providerState.selectedDistrict,
      );
      if (tomorrowTimes != null) {
        NotificationService.schedulePrayerNotifications(
          imsak: tomorrowTimes.imsak,
          gunes: tomorrowTimes.gunes,
          ogle: tomorrowTimes.ogle,
          ikindi: tomorrowTimes.ikindi,
          aksam: tomorrowTimes.aksam,
          yatsi: tomorrowTimes.yatsi,
          date: tomorrow,
          enabledPrayers: state,
        );
      }
    }
  }
}

final notificationPrefsProvider =
    NotifierProvider<NotificationPrefsNotifier, Map<String, bool>>(
  NotificationPrefsNotifier.new,
);
