import 'package:sqflite/sqflite.dart';
import '../database_service.dart';
import '../models/injection_model.dart';

class InjectionRepository {
  final DatabaseService _dbService;

  InjectionRepository(this._dbService);

  // Alle Injektionen laden
  Future<List<InjectionModel>> getAllInjections() async {
    final db = await _dbService.database;
    final maps = await db.query('injections', orderBy: 'timestamp DESC');

    return maps.map((e) => InjectionModel.fromMap(e)).toList();
  }

  // Injektion hinzufügen oder updaten
  Future<void> addInjection(InjectionModel injection) async {
    final db = await _dbService.database;

    // Wir nutzen db.insert mit ConflictAlgorithm.replace
    // Das nutzt automatisch die toMap() Methode vom Model -> keine falschen Spaltennamen mehr!
    await db.insert(
      'injections',
      injection.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Injektion löschen
  Future<void> deleteInjection(String id) async {
    final db = await _dbService.database;
    await db.delete('injections', where: 'id = ?', whereArgs: [id]);
  }
}
