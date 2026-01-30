import 'package:sqflite/sqflite.dart';
import '../database_service.dart';
import '../models/injection_model.dart';

class InjectionRepository {
  final DatabaseService _dbService;

  InjectionRepository(this._dbService);

  // Injektion speichern
  Future<void> addInjection(InjectionModel injection) async {
    final db = await _dbService.database;
    await db.insert(
      'injections',
      injection.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Injektion löschen (falls man sich vertippt hat)
  Future<void> deleteInjection(String id) async {
    final db = await _dbService.database;
    await db.delete('injections', where: 'id = ?', whereArgs: [id]);
  }

  // Alle Injektionen holen (Neueste zuerst)
  Future<List<InjectionModel>> getAllInjections() async {
    final db = await _dbService.database;
    final maps = await db.query('injections', orderBy: 'timestamp DESC');

    return List.generate(maps.length, (i) {
      return InjectionModel.fromMap(maps[i]);
    });
  }
}
