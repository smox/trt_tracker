import 'package:sqflite/sqflite.dart';
import 'package:trt_tracker/data/models/lab_result_model.dart';
import '../database_service.dart';

class LabResultRepository {
  final DatabaseService _dbService;

  LabResultRepository(this._dbService);

  Future<void> addLabResult(LabResultModel result) async {
    final db = await _dbService.database;
    await db.insert(
      'lab_results',
      result.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteLabResult(String id) async {
    final db = await _dbService.database;
    await db.delete('lab_results', where: 'id = ?', whereArgs: [id]);
  }

  // Holt NUR die Kalibrierungs-Punkte, sortiert nach Datum
  Future<List<LabResultModel>> getCalibrationPoints() async {
    final db = await _dbService.database;
    final maps = await db.query(
      'lab_results',
      where: 'used_for_calibration = 1',
      orderBy: 'timestamp_drawn ASC', // Wichtig: Chronologisch sortiert!
    );

    return List.generate(maps.length, (i) => LabResultModel.fromMap(maps[i]));
  }

  // Holt alle (für eine Listen-Ansicht, falls wir die später bauen)
  Future<List<LabResultModel>> getAllResults() async {
    final db = await _dbService.database;
    final maps = await db.query('lab_results', orderBy: 'timestamp_drawn DESC');
    return List.generate(maps.length, (i) => LabResultModel.fromMap(maps[i]));
  }
}
