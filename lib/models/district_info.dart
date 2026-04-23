class UserDistrictInfo {
  int lastSelectedCountryId;
  int lastSelectedCityId;
  int lastSelectedDistrictId;
  DateTime lastUpdateTime;
  DateTime willBeUpdated;
  String districtNameTr;
  String districtNameEn;
  UserDistrictInfo(
      {required this.districtNameTr,required this.districtNameEn, required this.lastSelectedDistrictId, required this.lastUpdateTime, required this.willBeUpdated,required this.lastSelectedCityId, required this.lastSelectedCountryId});

  Map<String, dynamic> toMap() {
    return {
      'lastSelectedCountryId': lastSelectedCountryId,
      'lastSelectedCityId': lastSelectedCityId,
      'lastSelectedDistrictId': lastSelectedDistrictId,
      'districtNameTr': districtNameTr,
      'districtNameEn':districtNameEn,
      'lastUpdateTime': lastUpdateTime.toIso8601String(),
      'willBeUpdated': willBeUpdated.toIso8601String(),
    };
  }
}