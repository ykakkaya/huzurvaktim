import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/district.dart';


class DistrictDatabaseHelper {
  Database? _database;

  Future<void> open() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'district_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE districts(ilceAdi TEXT, ilceAdiEn TEXT, ilceId INTEGER PRIMARY KEY, sehirId INTEGER)',
        );
      },
      version: 1,
    );
  }

  Future<void> insertDistrict(District district) async {
    if(_database == null) await open();
    await _database!.insert(
      'districts',
      district.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<District?> getDistrict(int ilceId) async {
    if(_database == null) await open();
    final List<Map<String, dynamic>> maps = await _database!.query(
      'districts',
      where: 'ilceId = ?',
      whereArgs: [ilceId],
    );
    if (maps.isEmpty) {
      return null;
    }
    return District(
      ilceAdi: maps[0]['ilceAdi'],
      ilceAdiEn: maps[0]['ilceAdiEn'],
      ilceId: maps[0]['ilceId'],
      sehirId: maps[0]['sehirId']
    );
  }

  Future<List<District>> getAllDistrictsByCityId(int cityId) async {
    if (_database == null) await open();
    final List<Map<String, dynamic>> maps = await _database!.query('districts',
        where: 'sehirId = ?', whereArgs: [cityId]);
    return List.generate(maps.length, (i) {
      return District(
        ilceAdi: maps[i]['ilceAdi'],
        ilceAdiEn: maps[i]['ilceAdiEn'],
        ilceId: maps[i]['ilceId'],
        sehirId: maps[i]['sehirId']

      );
    });
  }


  Future<List<District>> getAllDistricts() async {
    if(_database == null) await open();
    final List<Map<String, dynamic>> maps = await _database!.query('districts');
    return List.generate(maps.length, (i) {
      return District(
        ilceAdi: maps[i]['ilceAdi'],
        ilceAdiEn: maps[i]['ilceAdiEn'],
        ilceId: maps[i]['ilceId'],
        sehirId: maps[i]['sehirId']
      );
    });
  }

  Future<void> insertDistricts(List<District> districts) async {
    if (_database == null) await open();
    Batch batch = _database!.batch();
    for (District district in districts) {
      batch.insert(
        'districts',
        district.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteAllDistricts() async {
    if (_database == null) await open();
    await _database!.delete('districts');
  }
}
