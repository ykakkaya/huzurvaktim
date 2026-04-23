import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/district_info.dart';

class UserDiscrictInfoDatabaseHelper {
  Database? _database;

  Future<void> open() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'district_info_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE district_info(lastSelectedDistrictId INTEGER, lastSelectedCityId INTEGER, lastSelectedCountryId INTEGER,  lastUpdateTime TEXT, willBeUpdated TEXT, districtNameTr TEXT, districtNameEn TEXT)',
        );
      },
      version: 1,
    );
  }

  Future<void> insertOrUpdateDistrictInfo(UserDistrictInfo districtInfo) async{
    if(_database==null) await open();
    final existingInfo = await getDistrictInfo();
    if(existingInfo == null) {
      await _insertDistrictInfo(districtInfo);
    }else{
      await _updateDistrictInfo(districtInfo);
    }
  }

  Future<void> _insertDistrictInfo(UserDistrictInfo districtInfo) async {
    if(_database==null) await open();
      await _database!.insert(
        'district_info',
        districtInfo.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  }

  Future<UserDistrictInfo?> getDistrictInfo() async {
    if(_database==null) await open();
    final List<Map<String, dynamic>> maps = await _database!.query('district_info');
    if (maps.isEmpty) {
      return null;
    }
    return UserDistrictInfo(
      districtNameEn: maps[0]['districtNameEn'] ,districtNameTr:  maps[0]['districtNameTr'],
      lastSelectedDistrictId: maps[0]['lastSelectedDistrictId'],
      lastSelectedCountryId: maps[0]['lastSelectedCountryId'],
      lastSelectedCityId: maps[0]['lastSelectedCityId'],
      lastUpdateTime: DateTime.parse(maps[0]['lastUpdateTime']),
      willBeUpdated: DateTime.parse(maps[0]['willBeUpdated']),
    );
  }

  Future<void> _updateDistrictInfo(UserDistrictInfo districtInfo) async {
    if(_database == null) await open();
    await _database!.update(
      'district_info',
      districtInfo.toMap(),
      where: 'lastSelectedDistrictId > ?',
      whereArgs: [-1],
    );
  }

}