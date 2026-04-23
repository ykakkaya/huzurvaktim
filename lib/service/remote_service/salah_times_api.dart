import 'package:dio/dio.dart';
import 'package:huzurvakti/models/country.dart';
import 'package:huzurvakti/models/salah_time.dart';

import '../../models/city.dart';
import '../../models/district.dart';

class SalahTimesApi {
  String baseUrl = "https://ezanvakti.emushaf.net";

  final dio = Dio();

  Future<List<Country>> getAllCountries() async {
    String url = "$baseUrl/ulkeler";

    try {
      final response = await dio.get(url);
      List<dynamic> list = response.data.toList();
      List<Country> responseList = [];
      for (var i in list) {
        responseList.add(Country.fromJson(i));
      }
      return responseList;
    } catch (e) {
      print(e.toString());
      throw Exception(e.toString());
    }
  }

  Future<List<City>> getAllCitiesByCountryId(int countryId) async {
    String url = "$baseUrl/sehirler/$countryId";
    try {
      final response = await dio.get(url);
      List<dynamic> list = response.data.toList();
      List<City> responseList = [];
      for (var i in list) {
        i["ulkeId"] = countryId;
        // print(i);

        responseList.add(City.fromJson(i));
      }
      return responseList;
    } catch (e) {
      print(e.toString());
      throw Exception(e.toString());
    }
  }

  Future<List<District>> getAllDisctrictByCityId(int cityId) async {
    String url = "$baseUrl/ilceler/$cityId";
    try {
      final response = await dio.get(url);
      List<dynamic> list = response.data.toList();
      List<District> responseList = [];
      for (var i in list) {
        i["sehirId"] = cityId;
        //print(i);
        responseList.add(District.fromJson(i));
      }

      return responseList;
    } catch (e) {
      print(e.toString());
      throw Exception(e.toString());
    }
  }

  Future<List<SalahTime>> getAllSalahTimesByDistrictId(int disctrictId) async {
    String url = "$baseUrl/vakitler/$disctrictId";
    try {
      final response = await dio.get(url);
      //print(response.data);
      List<dynamic> list = response.data.toList();

      List<SalahTime> responseList = [];
      for (var i in list) {
        i["districtId"] = disctrictId;
        responseList.add(SalahTime.fromJson(i));
      }

      return responseList;
    } catch (e) {
      print(e.toString());
      throw Exception(e.toString());
    }
  }
}
