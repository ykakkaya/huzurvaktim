import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:huzurvakti/providers/clock_provider.dart';
import 'package:huzurvakti/providers/salah_times_provider.dart';
import 'package:huzurvakti/providers/notification_prefs_provider.dart';
import 'package:huzurvakti/models/district_info.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:huzurvakti/utils/project_colors.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import '../models/salah_time.dart';

class PrayerTimesPage extends ConsumerStatefulWidget {
  const PrayerTimesPage({super.key});

  @override
  ConsumerState<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends ConsumerState<PrayerTimesPage> {
  bool _detectingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(salahTimesProvider.notifier);
      // Varsayılan Türkiye listelerini yükle (bottom sheet için)
      await notifier.getAllCountries();
      await notifier.getAllCities(2);
      await notifier.getAllDistricts(539);

      // Kayıtlı konum yoksa otomatik algıla
      final state = ref.read(salahTimesProvider);
      if (state.userDistrictInfo == null) {
        _autoDetectLocation();
      }
    });
  }

  // GPS + Nominatim reverse geocode → ilçe eşleştirme
  Future<void> _autoDetectLocation() async {
    if (!mounted) return;
    setState(() => _detectingLocation = true);

    try {
      // İzin kontrolü
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) setState(() => _detectingLocation = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );

      // Nominatim reverse geocode
      final dio = Dio();
      final resp = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'json',
          'lat': pos.latitude,
          'lon': pos.longitude,
          'accept-language': 'tr',
        },
        options: Options(headers: {'User-Agent': 'HuzurVakti/1.0'}),
      );

      final address = resp.data['address'] as Map<String, dynamic>?;
      if (address == null) return;

      // Türkiye dışındaysa (emülatör, yurt dışı) uyar
      final countryCode = (address['country_code'] ?? '').toString().toLowerCase();
      if (countryCode != 'tr') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Konum Türkiye dışında algılandı. Lütfen konumu manuel seçin.',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              action: SnackBarAction(label: 'Seç', onPressed: showLocationSelector),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        return;
      }

      // Türkiye için adres alanlarını topla (öncelik sırasına göre)
      final provinceName = [
        address['province'], address['state'], address['city'],
      ].firstWhere((v) => v != null && v.toString().isNotEmpty, orElse: () => '')!.toString();

      // İlçe adını temizle (" İlçesi" gibi sonekleri kaldır)
      String rawCounty = [
        address['county'], address['district'], address['city_district'],
        address['town'], address['suburb'],
      ].firstWhere((v) => v != null && v.toString().isNotEmpty, orElse: () => '')!.toString();
      rawCounty = rawCounty
          .replaceAll(RegExp(r'\s*(İlçesi|Ilcesi|District)\s*', caseSensitive: false), '')
          .trim();

      await _matchAndSaveLocation(provinceName, rawCounty);
    } catch (e) {
      debugPrint('Auto location error: $e');
    } finally {
      if (mounted) setState(() => _detectingLocation = false);
    }
  }

  // Şehir ve ilçe ismine göre en iyi eşleşmeyi bul ve kaydet
  Future<void> _matchAndSaveLocation(String provinceName, String countyName) async {
    final notifier = ref.read(salahTimesProvider.notifier);

    await notifier.getAllCities(2);
    final state = ref.read(salahTimesProvider);

    String normalize(String s) => s
        .toLowerCase()
        .replaceAll('ı', 'i').replaceAll('i̇', 'i')
        .replaceAll('ö', 'o').replaceAll('ü', 'u')
        .replaceAll('ş', 's').replaceAll('ğ', 'g')
        .replaceAll('ç', 'c').replaceAll('â', 'a')
        .replaceAll(RegExp(r'[^a-z]'), '');

    // Puan bazlı en iyi eşleşme — 3: tam, 2: birisi diğerinin başında, 1: içerik
    int score(String a, String b) {
      final na = normalize(a), nb = normalize(b);
      if (na.isEmpty || nb.isEmpty) return 0;
      if (na == nb) return 3;
      if (na.startsWith(nb) || nb.startsWith(na)) return 2;
      if (na.contains(nb) || nb.contains(na)) return 1;
      return 0;
    }

    final normProvince = normalize(provinceName);

    // En yüksek puanlı şehri seç
    var bestCityScore = 0;
    var matchedCity = state.cityList.first;
    for (final c in state.cityList) {
      final s = score(c.sehirAdi ?? '', normProvince);
      if (s > bestCityScore) { bestCityScore = s; matchedCity = c; }
    }

    // Şehir eşleşmesi sıfırsa kullanıcı manuel seçsin
    if (bestCityScore == 0) return;

    await notifier.getAllDistricts(matchedCity.sehirId);
    final stateAfter = ref.read(salahTimesProvider);

    final normCounty = normalize(countyName);
    var bestDistScore = 0;
    var matchedDistrict = stateAfter.districtList.first;
    for (final d in stateAfter.districtList) {
      final s = score(d.ilceAdi ?? '', normCounty);
      if (s > bestDistScore) { bestDistScore = s; matchedDistrict = d; }
    }

    // İlçe eşleşmesi yoksa il merkezi ilçeyi (şehir adıyla aynı) bul
    if (bestDistScore == 0) {
      matchedDistrict = stateAfter.districtList.firstWhere(
        (d) => normalize(d.ilceAdi ?? '') == normalize(matchedCity.sehirAdi ?? ''),
        orElse: () => stateAfter.districtList.first,
      );
    }

    notifier.updateSelectedDistrict(matchedDistrict.ilceId);
    await _saveLocation(matchedDistrict.ilceId);
  }

  Future<void> _saveLocation([int? overrideDistrictId]) async {
    final state = ref.read(salahTimesProvider);
    final notifier = ref.read(salahTimesProvider.notifier);
    final districtId = overrideDistrictId ?? state.selectedDistrict;
    final district = await notifier.districtDatabaseHelper.getDistrict(districtId);
    if (district == null) return;
    final city = await notifier.cityDatabaseHelper.getCity(district.sehirId);
    final now = DateTime.now();
    final newInfo = UserDistrictInfo(
      districtNameTr: district.ilceAdi ?? "",
      districtNameEn: district.ilceAdiEn ?? "",
      lastSelectedDistrictId: district.ilceId,
      lastUpdateTime: now,
      willBeUpdated: now.add(const Duration(days: 20)),
      lastSelectedCityId: city?.sehirId ?? 0,
      lastSelectedCountryId: city?.ulkeId ?? 0,
    );
    await notifier.userDiscrictInfoDatabaseHelper.insertOrUpdateDistrictInfo(newInfo);
    final miladi = DateTime(now.year, now.month, now.day);
    await notifier.getSalahTimesForADay(miladi.toString(), newInfo.lastSelectedDistrictId);
    notifier.init();
  }

  String? _activeVakit(SalahTime times) {
    final now = TimeOfDay.now();
    final int nowMin = now.hour * 60 + now.minute;
    int toMin(String? t) {
      if (t == null || t.isEmpty) return 0;
      final parts = t.split(':');
      if (parts.length < 2) return 0;
      return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
    }

    final vakitler = [
      ('imsak', toMin(times.imsak)),
      ('gunes', toMin(times.gunes)),
      ('ogle', toMin(times.ogle)),
      ('ikindi', toMin(times.ikindi)),
      ('aksam', toMin(times.aksam)),
      ('yatsi', toMin(times.yatsi)),
    ];

    String? active;
    for (final v in vakitler) {
      if (nowMin >= v.$2) active = v.$1;
    }
    return active ?? 'yatsi';
  }

  /// Bir sonraki namaz vaktine kalan süreyi hesaplar.
  /// Döner: (vakit adı, "Xsa Ydk Zsn" formatında string)
  (String name, String countdown) _nextVakit(SalahTime times) {
    final now = DateTime.now();
    final nowSec = now.hour * 3600 + now.minute * 60 + now.second;

    int toSec(String? t) {
      if (t == null || t.isEmpty) return 0;
      final parts = t.split(':');
      if (parts.length < 2) return 0;
      return (int.tryParse(parts[0]) ?? 0) * 3600 +
          (int.tryParse(parts[1]) ?? 0) * 60;
    }

    final vakitler = [
      ('İmsak', toSec(times.imsak)),
      ('Güneş', toSec(times.gunes)),
      ('Öğle', toSec(times.ogle)),
      ('İkindi', toSec(times.ikindi)),
      ('Akşam', toSec(times.aksam)),
      ('Yatsı', toSec(times.yatsi)),
    ];

    // İlk gelecek vakti bul
    for (final v in vakitler) {
      if (v.$2 > nowSec) {
        final diff = v.$2 - nowSec;
        return (v.$1, _formatCountdown(diff));
      }
    }

    // Tüm vakitler geçtiyse — yarın sabah imsakına kalan süre
    final imsakSec = toSec(times.imsak);
    final diff = 86400 - nowSec + imsakSec;
    return ('İmsak', _formatCountdown(diff));
  }

  String _formatCountdown(int totalSec) {
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;
    if (h > 0) {
      return '${h}sa ${m.toString().padLeft(2, '0')}dk ${s.toString().padLeft(2, '0')}sn';
    }
    return '${m}dk ${s.toString().padLeft(2, '0')}sn';
  }

  void showLocationSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LocationBottomSheet(
        onSave: (c) async {
          await _saveLocation();
          if (c.mounted) Navigator.pop(c);
        },
        onAutoDetect: () async {
          Navigator.pop(context);
          await _autoDetectLocation();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(salahTimesProvider);
    final currentTime = ref.watch(clockProvider).value ?? '--:--:--';
    final notifPrefs = ref.watch(notificationPrefsProvider);
    final times = state.salahTimes;
    final activeVakit = times != null ? _activeVakit(times) : null;
    final nextVakit = times != null ? _nextVakit(times) : null;

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(state, currentTime, nextVakit),
          if (_detectingLocation)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: ProjectColor.primary)),
                  const SizedBox(width: 10),
                  Text('Konum algılanıyor...',
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ),
          if (times != null) _buildDateRow(times),
          const SizedBox(height: 8),
          if (times == null && !_detectingLocation)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: state.userDistrictInfo == null
                  ? _buildNoLocation()
                  : const CircularProgressIndicator(color: ProjectColor.primary),
            )
          else if (times != null)
            _buildPrayerList(times, activeVakit, notifPrefs),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(SalahTimesState state, String currentTime,
      (String, String)? nextVakit) {
    final topPad = MediaQuery.of(context).padding.top + 16;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0277BD), Color(0xFF0288D1), Color(0xFF039BE5)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30, top: -30,
            child: Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            left: -20, bottom: -20,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPad, 20, 28),
            child: Column(
              children: [
                Text(
                  currentTime,
                  style: GoogleFonts.poppins(
                    fontSize: 42,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                if (nextVakit != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        '${nextVakit.$1}\'e ${nextVakit.$2} kala',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: showLocationSelector,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          state.userDistrictInfo?.districtNameTr ?? 'Konum seçin',
                          style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.expand_more_rounded, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(SalahTime times) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Row(
        children: [
          Expanded(child: _buildDateCard(
              Icons.calendar_today_rounded, 'Miladi', times.miladiTarihUzun ?? '')),
          const SizedBox(width: 12),
          Expanded(child: _buildDateCard(
              Icons.nightlight_round, 'Hicri', times.hicriTarihUzun ?? '')),
        ],
      ),
    );
  }

  Widget _buildDateCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0288D1).withValues(alpha: 0.08),
            blurRadius: 12, offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: ProjectColor.primaryDark),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500])),
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: const Color(0xFF37474F)),
                    maxLines: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerList(
      SalahTime times, String? activeVakit, Map<String, bool> notifPrefs) {
    final prayers = [
      _PrayerItem(key: 'imsak', icon: Icons.brightness_3_rounded,  label: 'prayImsak',  time: times.imsak  ?? '--:--'),
      _PrayerItem(key: 'gunes', icon: Icons.wb_sunny_rounded,       label: 'prayGunes',  time: times.gunes  ?? '--:--'),
      _PrayerItem(key: 'ogle',  icon: Icons.light_mode_rounded,     label: 'prayOgle',   time: times.ogle   ?? '--:--'),
      _PrayerItem(key: 'ikindi',icon: Icons.wb_twilight_rounded,    label: 'prayIkindi', time: times.ikindi ?? '--:--'),
      _PrayerItem(key: 'aksam', icon: Icons.nights_stay_rounded,    label: 'prayAksam',  time: times.aksam  ?? '--:--'),
      _PrayerItem(key: 'yatsi', icon: Icons.bedtime_rounded,        label: 'prayYatsi',  time: times.yatsi  ?? '--:--'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: prayers
            .map((p) => _buildPrayerCard(
                p, p.key == activeVakit, notifPrefs[p.key] ?? true))
            .toList(),
      ),
    );
  }

  Widget _buildPrayerCard(_PrayerItem prayer, bool isActive, bool notifEnabled) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isActive ? ProjectColor.primaryDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? ProjectColor.primaryDark.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: isActive ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.15)
                    : const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(prayer.icon, size: 22,
                  color: isActive ? Colors.white : ProjectColor.primaryDark),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(prayer.label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? Colors.white : const Color(0xFF37474F),
                  )).tr(),
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Şu an',
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500)),
              ),
            Text(
              prayer.time,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : ProjectColor.primaryDark,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 4),
            Transform.scale(
              scale: 0.75,
              child: Switch(
                value: notifEnabled,
                onChanged: (_) {
                  ref
                      .read(notificationPrefsProvider.notifier)
                      .toggle(prayer.key);
                },
                activeThumbColor: isActive ? Colors.white : ProjectColor.primary,
                activeTrackColor: isActive
                    ? Colors.white.withValues(alpha: 0.35)
                    : ProjectColor.primary.withValues(alpha: 0.3),
                inactiveThumbColor: isActive
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.grey[400],
                inactiveTrackColor: isActive
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.grey[200],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoLocation() {
    return Column(
      children: [
        const Icon(Icons.location_off_rounded, size: 64, color: Color(0xFFB0BEC5)),
        const SizedBox(height: 12),
        Text('Konum seçilmedi',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[500])),
        const SizedBox(height: 8),
        Text('GPS izni vererek otomatik algılayabilirsiniz',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400])),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _autoDetectLocation,
              icon: const Icon(Icons.my_location_rounded, size: 18),
              label: const Text('Otomatik Algıla'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ProjectColor.primaryDark,
                side: const BorderSide(color: ProjectColor.primaryDark),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: showLocationSelector,
              icon: const Icon(Icons.list_rounded, size: 18),
              label: const Text('Manuel Seç'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ProjectColor.primaryDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PrayerItem {
  final String key;
  final IconData icon;
  final String label;
  final String time;
  const _PrayerItem(
      {required this.key, required this.icon, required this.label, required this.time});
}

// ── Konum Seçici Bottom Sheet ────────────────────────────────────────────────
class _LocationBottomSheet extends ConsumerStatefulWidget {
  final Future<void> Function(BuildContext) onSave;
  final Future<void> Function() onAutoDetect;

  const _LocationBottomSheet({required this.onSave, required this.onAutoDetect});

  @override
  ConsumerState<_LocationBottomSheet> createState() => _LocationBottomSheetState();
}

class _LocationBottomSheetState extends ConsumerState<_LocationBottomSheet> {
  bool _saving = false;

  Future<void> _onCountryChanged(int countryId) async {
    final notifier = ref.read(salahTimesProvider.notifier);
    await notifier.getAllCities(countryId);
    final state = ref.read(salahTimesProvider);
    if (state.cityList.isNotEmpty) {
      await notifier.getAllDistricts(state.cityList.first.sehirId);
      final s2 = ref.read(salahTimesProvider);
      if (s2.districtList.isNotEmpty) {
        notifier.updateSelectedDistrict(s2.districtList.first.ilceId);
      }
    }
  }

  Future<void> _onCityChanged(int cityId) async {
    final notifier = ref.read(salahTimesProvider.notifier);
    await notifier.getAllDistricts(cityId);
    final state = ref.read(salahTimesProvider);
    if (state.districtList.isNotEmpty) {
      notifier.updateSelectedDistrict(state.districtList.first.ilceId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(salahTimesProvider);
    final notifier = ref.read(salahTimesProvider.notifier);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on_rounded,
                    color: ProjectColor.primaryDark, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Konum Seç',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A237E))),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Otomatik konum butonu
          GestureDetector(
            onTap: widget.onAutoDetect,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.my_location_rounded,
                      color: ProjectColor.primaryDark, size: 18),
                  const SizedBox(width: 8),
                  Text('GPS ile Otomatik Algıla',
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: ProjectColor.primaryDark)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Row(children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('veya manuel seç',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
            ),
            const Expanded(child: Divider()),
          ]),
          const SizedBox(height: 16),

          // Ülke
          _buildDropdownField(
            label: 'Ülke', icon: Icons.flag_rounded,
            isLoading: state.countryList.isEmpty,
            value: state.selectedCountry,
            items: state.countryList
                .map((e) => DropdownMenuItem(value: e.ulkeId, child: Text(e.ulkeAdi ?? "")))
                .toList(),
            onChanged: (v) => _onCountryChanged(v),
          ),
          const SizedBox(height: 12),

          // Şehir
          _buildDropdownField(
            label: 'Şehir', icon: Icons.location_city_rounded,
            isLoading: state.cityList.isEmpty,
            value: state.selectedCity,
            items: state.cityList
                .map((e) => DropdownMenuItem(value: e.sehirId, child: Text(e.sehirAdi ?? "")))
                .toList(),
            onChanged: (v) => _onCityChanged(v),
          ),
          const SizedBox(height: 12),

          // İlçe
          _buildDropdownField(
            label: 'İlçe', icon: Icons.place_rounded,
            isLoading: state.districtList.isEmpty,
            value: state.selectedDistrict,
            items: state.districtList
                .map((e) => DropdownMenuItem(value: e.ilceId, child: Text(e.ilceAdi ?? "")))
                .toList(),
            onChanged: (v) => notifier.updateSelectedDistrict(v),
          ),
          const SizedBox(height: 24),

          // Kaydet
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      await widget.onSave(context);
                      if (mounted) setState(() => _saving = false);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: ProjectColor.primaryDark,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 15),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('prayLocationSelect',
                      style: GoogleFonts.poppins(
                          fontSize: 15, fontWeight: FontWeight.w600)).tr(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required bool isLoading,
    required int value,
    required List<DropdownMenuItem> items,
    required void Function(dynamic) onChanged,
  }) {
    final validValue = items.any((e) => e.value == value) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton(
                    isExpanded: true,
                    value: validValue,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: ProjectColor.primaryDark),
                    items: items,
                    onChanged: onChanged,
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: const Color(0xFF37474F)),
                  ),
                ),
        ),
      ],
    );
  }
}
