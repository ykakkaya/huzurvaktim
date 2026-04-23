import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/country.dart';

class CountryDatabaseHelper {
  Database? _database;

  Future<void> open() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'country_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE countries(ulkeAdi TEXT, ulkeAdiEn TEXT, UlkeId INTEGER PRIMARY KEY)',
        );
      },
      version: 1,
    );
  }

  Future<void> insertCountry(Country country) async {
    if(_database == null) await open();
    await _database!.insert(
      'countries',
      country.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Country?> getCountry(String ulkeId) async {
    if(_database == null) await open();
    final List<Map<String, dynamic>> maps = await _database!.query(
      'countries',
      where: 'ulkeId = ?',
      whereArgs: [ulkeId],
    );
    if (maps.isEmpty) {
      return null;
    }
    return Country(
      ulkeAdi: maps[0]['ulkeAdi'],
      ulkeAdiEn: maps[0]['ulkeAdiEn'],
      ulkeId: maps[0]['ulkeId'],
    );
  }

  Future<List<Country>> getAllCountries() async {
    if(_database == null) await open();
    final List<Map<String, dynamic>> maps = await _database!.query('countries');
    return List.generate(maps.length, (i) {
      return Country(
        ulkeAdi: maps[i]['ulkeAdi'],
        ulkeAdiEn: maps[i]['ulkeAdiEn'],
        ulkeId: maps[i]['UlkeId'],
      );
    });
  }

  Future<void> insertCountries(List<Country> countries) async {
    if (_database == null) await open();
    Batch batch = _database!.batch();
    for (Country country in countries) {
      batch.insert(
        'countries',
        country.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteAllCountries() async {
    if (_database == null) await open();
    await _database!.delete('countries');
  }


}
