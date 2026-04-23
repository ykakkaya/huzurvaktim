import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/salah_time.dart';

class SalahTimeDatabaseHelper {
  Database? _database;

  Future<void> open() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'salah_times_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE salah_times(districtId INTEGER, aksam TEXT, ayinSekliUrl TEXT, greenwichOrtalamaZamani REAL, gunes TEXT, gunesBatis TEXT, gunesDogus TEXT, hicriTarihKisa TEXT, hicriTarihKisaIso8601 TEXT, hicriTarihUzun TEXT, hicriTarihUzunIso8601 TEXT, ikindi TEXT, imsak TEXT, kibleSaati TEXT, miladiTarihKisa TEXT, miladiTarihKisaIso8601 TEXT, miladiTarihUzun TEXT, miladiTarihUzunIso8601 TEXT, ogle TEXT, yatsi TEXT)',
        );
      },
      version: 1,
    );
  }

  Future<void> insertOne(SalahTime salahTime) async {
    if(_database == null) await open();
    await _database!.insert(
      'salah_times',
      salahTime.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertList(List<SalahTime> salahTimes) async {
    if(_database == null) await open();
    final Batch batch = _database!.batch();
    for (final salahTime in salahTimes) {
      batch.insert(
        'salah_times',
        salahTime.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<SalahTime>> getAll() async {
    if(_database == null) await open();
    final List<Map<String, dynamic>> maps = await _database!.query('salah_times');
    return List.generate(maps.length, (i) {
      return SalahTime(
        districtId: maps[i]['districtId'],
        aksam: maps[i]['aksam'],
        ayinSekliUrl: maps[i]['ayinSekliUrl'],
        greenwichOrtalamaZamani: maps[i]['greenwichOrtalamaZamani'],
        gunes: maps[i]['gunes'],
        gunesBatis: maps[i]['gunesBatis'],
        gunesDogus: maps[i]['gunesDogus'],
        hicriTarihKisa: maps[i]['hicriTarihKisa'],
        hicriTarihKisaIso8601: maps[i]['hicriTarihKisaIso8601'],
        hicriTarihUzun: maps[i]['hicriTarihUzun'],
        hicriTarihUzunIso8601: maps[i]['hicriTarihUzunIso8601'],
        ikindi: maps[i]['ikindi'],
        imsak: maps[i]['imsak'],
        kibleSaati: maps[i]['kibleSaati'],
        miladiTarihKisa: DateTime.tryParse(maps[i]['miladiTarihKisa']??""),
        miladiTarihKisaIso8601: maps[i]['miladiTarihKisaIso8601'],
        miladiTarihUzun: maps[i]['miladiTarihUzun'],
        miladiTarihUzunIso8601: DateTime.tryParse(maps[i]['miladiTarihUzunIso8601']??""),
        ogle: maps[i]['ogle'],
        yatsi: maps[i]['yatsi'],
      );
    });
  }

  Future<SalahTime?> getOne(String miladiTarihKisa, int districtId) async {
    if(_database == null) await open();
    final List<Map<String, dynamic>> maps = await _database!.query(
      'salah_times',
      where: 'miladiTarihKisa = ? AND districtId = ?',
      whereArgs: [miladiTarihKisa, districtId],
    );
    if (maps.isEmpty) {
      return null;
    }
    return SalahTime(
      districtId: maps[0]['districtId'],
      aksam: maps[0]['aksam'],
      ayinSekliUrl: maps[0]['ayinSekliUrl'],
      greenwichOrtalamaZamani: maps[0]['greenwichOrtalamaZamani'],
      gunes: maps[0]['gunes'],
      gunesBatis: maps[0]['gunesBatis'],
      gunesDogus: maps[0]['gunesDogus'],
      hicriTarihKisa: maps[0]['hicriTarihKisa'],
      hicriTarihKisaIso8601: maps[0]['hicriTarihKisaIso8601'],
      hicriTarihUzun: maps[0]['hicriTarihUzun'],
      hicriTarihUzunIso8601: maps[0]['hicriTarihUzunIso8601'],
      ikindi: maps[0]['ikindi'],
      imsak: maps[0]['imsak'],
      kibleSaati: maps[0]['kibleSaati'],
      miladiTarihKisa: DateTime.tryParse(maps[0]['miladiTarihKisa']),
      miladiTarihKisaIso8601: maps[0]['miladiTarihKisaIso8601'],
      miladiTarihUzun: maps[0]['miladiTarihUzun'],
      miladiTarihUzunIso8601: DateTime.tryParse(maps[0]['miladiTarihUzunIso8601']),
      ogle: maps[0]['ogle'],
      yatsi: maps[0]['yatsi'],
    );
  }

}
