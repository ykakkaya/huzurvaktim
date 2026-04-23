import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/city.dart';

class CityDatabaseHelper {
  Database? _database;

  Future<void> open() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'city_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE cities(sehirAdi TEXT, sehirAdiEn TEXT, sehirId INTEGER PRIMARY KEY, ulkeId INTEGER)',
        );
      },
      version: 1,
    );
  }

  Future<void> insertCity(City city) async {
    if(_database == null) await open();
    await _database!.insert(
      'cities',
      city.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }


  Future<City?> getCity(int sehirId) async {
    if(_database == null) await open();
    final List<Map<String, dynamic>> maps = await _database!.query(
      'cities',
      where: 'sehirId = ?',
      whereArgs: [sehirId],
    );
    if (maps.isEmpty) {
      return null;
    }
    return City(
      sehirAdi: maps[0]['sehirAdi'],
      sehirAdiEn: maps[0]['sehirAdiEn'],
      sehirId: maps[0]['sehirId'], ulkeId: maps[0]['ulkeId'],
    );
  }

  Future<List<City>> getAllCities() async {
    if(_database == null) await open();
    final List<Map<String, dynamic>> maps = await _database!.query('cities');
    return List.generate(maps.length, (i) {
      return City(
        ulkeId: maps[0]['ulkeId'],
        sehirAdi: maps[i]['sehirAdi'],
        sehirAdiEn: maps[i]['sehirAdiEn'],
        sehirId: maps[i]['sehirId'],
      );
    });
  }

  Future<List<City>> getAllCitiesByCountryId(int ulkeId) async {
    if (_database == null) await open();
    final List<Map<String, dynamic>> maps = await _database!.query('cities',
        where: 'ulkeId = ?', whereArgs: [ulkeId]);
    return List.generate(maps.length, (i) {
      return City(
        ulkeId: maps[i]['ulkeId'],
        sehirAdi: maps[i]['sehirAdi'],
        sehirAdiEn: maps[i]['sehirAdiEn'],
        sehirId: maps[i]['sehirId'],
      );
    });
  }


  Future<void> insertCities(List<City> cities) async {
    if (_database == null) await open();
    Batch batch = _database!.batch();
    for (City city in cities) {
      batch.insert(
        'cities',
        city.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteAllCities() async {
    if (_database == null) await open();
    await _database!.delete('cities');
  }
}
