import 'package:huzurvakti/models/district.dart';

class UserInfo{
  UserInfo(
      {required this.userDistricts,
        required this.lastSeen,
        required this.userLanguage,
        required this.username});

  String? username;
  String? userLanguage;
  DateTime lastSeen;
  List<District> userDistricts;
}