import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huzurvakti/data/district_data.dart';
import 'package:huzurvakti/service/notification_service.dart';
import 'package:huzurvakti/providers/notification_prefs_provider.dart';
import 'package:huzurvakti/data/salah_time_data.dart';
import 'package:huzurvakti/models/country.dart';
import 'package:huzurvakti/models/district.dart';
import 'package:huzurvakti/models/district_info.dart';
import '../service/remote_service/salah_times_api.dart';
import '../data/city_data.dart';
import '../data/country_data.dart';
import '../data/user_district_info_data.dart';
import '../models/city.dart';
import '../models/salah_time.dart';

class SalahTimesState {
  final List<Country> countryList;
  final List<City> cityList;
  final List<District> districtList;
  final SalahTime? salahTimes;
  final UserDistrictInfo? userDistrictInfo;
  final int selectedCountry;
  final int selectedCity;
  final int selectedDistrict;

  SalahTimesState({
    this.countryList = const [],
    this.cityList = const [],
    this.districtList = const [],
    this.salahTimes,
    this.userDistrictInfo,
    this.selectedCountry = 2,
    this.selectedCity = 539,
    this.selectedDistrict = 3851,
  });

  SalahTimesState copyWith({
    List<Country>? countryList,
    List<City>? cityList,
    List<District>? districtList,
    SalahTime? salahTimes,
    UserDistrictInfo? userDistrictInfo,
    int? selectedCountry,
    int? selectedCity,
    int? selectedDistrict,
  }) {
    return SalahTimesState(
      countryList: countryList ?? this.countryList,
      cityList: cityList ?? this.cityList,
      districtList: districtList ?? this.districtList,
      salahTimes: salahTimes ?? this.salahTimes,
      userDistrictInfo: userDistrictInfo ?? this.userDistrictInfo,
      selectedCountry: selectedCountry ?? this.selectedCountry,
      selectedCity: selectedCity ?? this.selectedCity,
      selectedDistrict: selectedDistrict ?? this.selectedDistrict,
    );
  }
}

class SalahTimesNotifier extends Notifier<SalahTimesState> {
  final api = SalahTimesApi();
  final countryDatabaseHelper = CountryDatabaseHelper();
  final cityDatabaseHelper = CityDatabaseHelper();
  final districtDatabaseHelper = DistrictDatabaseHelper();
  final userDiscrictInfoDatabaseHelper = UserDiscrictInfoDatabaseHelper();
  final salahTimeDatabaseHelper = SalahTimeDatabaseHelper();

  @override
  SalahTimesState build() {
    init();
    return SalahTimesState();
  }

  Future<void> init() async {
    var now = DateTime.now();
    DateTime miladi = DateTime(now.year, now.month, now.day);
    final districtInfo = await userDiscrictInfoDatabaseHelper.getDistrictInfo();
    state = state.copyWith(userDistrictInfo: districtInfo);

    if (districtInfo != null) {
      await getSalahTimesForADay(miladi.toString(), districtInfo.lastSelectedDistrictId);
    }
  }

  Future<void> getAllCountries() async {
    var countries = await countryDatabaseHelper.getAllCountries();
    if (countries.isEmpty) {
      var apiCountries = await api.getAllCountries();
      await countryDatabaseHelper.insertCountries(apiCountries);
      countries = await countryDatabaseHelper.getAllCountries();
    }
    state = state.copyWith(countryList: countries);
  }

  Future<void> getAllCities(int countryId) async {
    var cities = await cityDatabaseHelper.getAllCitiesByCountryId(countryId);
    if (cities.isEmpty) {
      var apiCities = await api.getAllCitiesByCountryId(countryId);
      await cityDatabaseHelper.insertCities(apiCities);
      cities = await cityDatabaseHelper.getAllCitiesByCountryId(countryId);
    }
    state = state.copyWith(cityList: cities, selectedCountry: countryId);
  }

  Future<void> getAllDistricts(int cityId) async {
    var districts = await districtDatabaseHelper.getAllDistrictsByCityId(cityId);
    if (districts.isEmpty) {
      var apiDistricts = await api.getAllDisctrictByCityId(cityId);
      await districtDatabaseHelper.insertDistricts(apiDistricts);
      districts = await districtDatabaseHelper.getAllDistrictsByCityId(cityId);
    }
    state = state.copyWith(districtList: districts, selectedCity: cityId);
  }

  Future<void> getSalahTimesForADay(String miladi, int districtId) async {
    var times = await salahTimeDatabaseHelper.getOne(miladi, districtId);
    if (times == null) {
      var apiTimes = await api.getAllSalahTimesByDistrictId(districtId);
      await salahTimeDatabaseHelper.insertList(apiTimes);
      times = await salahTimeDatabaseHelper.getOne(miladi, districtId);
    }
    state = state.copyWith(salahTimes: times, selectedDistrict: districtId);

    // Bugünün vakitleri yüklendiyse bildirimleri zamanla
    if (times != null) {
      final now = DateTime.now();
      final isToday = times.miladiTarihKisa != null &&
          times.miladiTarihKisa!.year == now.year &&
          times.miladiTarihKisa!.month == now.month &&
          times.miladiTarihKisa!.day == now.day;
      if (isToday) {
        final enabledPrayers = ref.read(notificationPrefsProvider);
        NotificationService.schedulePrayerNotifications(
          imsak: times.imsak,
          gunes: times.gunes,
          ogle: times.ogle,
          ikindi: times.ikindi,
          aksam: times.aksam,
          yatsi: times.yatsi,
          enabledPrayers: enabledPrayers,
        );

        // Yarının vakitlerini de zamanla (workmanager çalışmazsa yedek)
        final tomorrow = DateTime(now.year, now.month, now.day + 1);
        final tomorrowTimes = await salahTimeDatabaseHelper.getOne(
          tomorrow.toString(),
          districtId,
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
            enabledPrayers: enabledPrayers,
          );
        }
      }
    }
  }
  
  void updateSelectedDistrict(int districtId) {
    state = state.copyWith(selectedDistrict: districtId);
  }
}

final salahTimesProvider = NotifierProvider<SalahTimesNotifier, SalahTimesState>(SalahTimesNotifier.new);
