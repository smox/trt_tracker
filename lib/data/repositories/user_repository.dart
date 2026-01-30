import 'package:sqflite/sqflite.dart';
import '../database_service.dart';
import '../models/user_profile_model.dart';

class UserRepository {
  final DatabaseService _dbService;

  UserRepository(this._dbService);

  // Holt den User (wir wissen, ID ist immer 1)
  Future<UserProfileModel> getUser() async {
    final db = await _dbService.database;
    final maps = await db.query(
      'user_profile',
      where: 'id = ?',
      whereArgs: [1],
    );

    if (maps.isNotEmpty) {
      return UserProfileModel.fromMap(maps.first);
    } else {
      // Sollte theoretisch nicht passieren, da wir beim DB Create einen anlegen
      throw Exception('User profile not found in DB');
    }
  }

  // Aktualisiert die Stammdaten beim Onboarding
  Future<void> updateUserProfile(UserProfileModel user) async {
    final db = await _dbService.database;
    await db.update(
      'user_profile',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }
}
