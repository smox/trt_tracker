import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database_service.dart';
import '../data/models/enums.dart';
import '../data/models/user_profile_model.dart';
import '../data/repositories/user_repository.dart';
import '../data/models/injection_model.dart';
import '../data/repositories/injection_repository.dart';
import 'calculator.dart';
import '../data/repositories/lab_result_repository.dart';
import '../data/models/lab_result_model.dart';

// 1. Datenbank-Service Provider
final dbServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// 2. Repository Provider
final userRepoProvider = Provider<UserRepository>((ref) {
  final dbService = ref.watch(dbServiceProvider);
  return UserRepository(dbService);
});

// 3. User Profil Controller & Provider
final userProfileProvider =
    AsyncNotifierProvider<UserProfileController, UserProfileModel>(() {
      return UserProfileController();
    });

class UserProfileController extends AsyncNotifier<UserProfileModel> {
  @override
  Future<UserProfileModel> build() async {
    final repo = ref.watch(userRepoProvider);
    return repo.getUser();
  }

  // Methode zum Speichern (Onboarding)
  Future<void> saveOnboardingData({
    required double weightKg,
    required double kfaPercentage,
    required MassUnit preferredUnit,
    String? name,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(userRepoProvider);
      final currentProfile = await repo.getUser();

      final updatedProfile = currentProfile.copyWith(
        weight: weightKg,
        bodyFatPercentage: kfaPercentage,
        preferredUnit: preferredUnit,
        name: name,
      );

      await repo.updateUserProfile(updatedProfile);
      return updatedProfile;
    });
  }

  // --- NEU: Methode um Einstellungen zu ändern (für SettingsScreen) ---
  Future<void> updateSettings({
    MassUnit? preferredUnit,
    int? startOfWeek,
  }) async {
    // Aktuellen State holen (wir brauchen die ID und die anderen Daten)
    final currentState = state.value;
    if (currentState == null) return;

    // Kopie mit den neuen Werten erstellen
    final updatedProfile = currentState.copyWith(
      preferredUnit: preferredUnit,
      startOfWeek: startOfWeek,
    );

    // In DB speichern
    final repo = ref.read(userRepoProvider);
    await repo.updateUserProfile(updatedProfile);

    // State aktualisieren
    state = AsyncData(updatedProfile);
  }
}

// 4. Injection Repository Provider
final injectionRepoProvider = Provider<InjectionRepository>((ref) {
  final dbService = ref.watch(dbServiceProvider);
  return InjectionRepository(dbService);
});

// 5. Injection List Controller
final injectionListProvider =
    AsyncNotifierProvider<InjectionListController, List<InjectionModel>>(() {
      return InjectionListController();
    });

class InjectionListController extends AsyncNotifier<List<InjectionModel>> {
  @override
  Future<List<InjectionModel>> build() async {
    final repo = ref.watch(injectionRepoProvider);
    return repo.getAllInjections();
  }

  Future<void> addInjection(InjectionModel injection) async {
    final repo = ref.read(injectionRepoProvider);
    await repo.addInjection(injection);
    ref.invalidateSelf();
  }

  Future<void> deleteInjection(String id) async {
    final repo = ref.read(injectionRepoProvider);
    await repo.deleteInjection(id);
    ref.invalidateSelf();
  }
}

// 6. Live Level Provider
final currentLevelProvider = Provider<double>((ref) {
  final userProfile = ref.watch(userProfileProvider).value;
  final injections = ref.watch(injectionListProvider).value;
  final calibrationPoints = ref.watch(calibrationPointsProvider).value;

  if (userProfile == null || injections == null) {
    return 0.0;
  }

  final calculator = TestosteroneCalculator();
  final now = DateTime.now();

  double levelNgMl = calculator.calculateLevelAt(
    targetTime: now,
    injections: injections,
    userProfile: userProfile,
    calibrationPoints: calibrationPoints ?? [],
  );

  return TestosteroneCalculator.convertFromNormalized(
    levelNgMl,
    userProfile.preferredUnit,
  );
});

// 7. Lab Result Repository Provider
final labResultRepoProvider = Provider<LabResultRepository>((ref) {
  final dbService = ref.watch(dbServiceProvider);
  return LabResultRepository(dbService);
});

// 8. Calibration Points Provider
final calibrationPointsProvider =
    AsyncNotifierProvider<CalibrationPointsController, List<LabResultModel>>(
      () {
        return CalibrationPointsController();
      },
    );

class CalibrationPointsController extends AsyncNotifier<List<LabResultModel>> {
  @override
  Future<List<LabResultModel>> build() async {
    final repo = ref.watch(labResultRepoProvider);
    return repo.getCalibrationPoints();
  }

  Future<void> addLabResult({
    required LabResultModel result,
    required List<InjectionModel> currentInjections,
    required UserProfileModel userProfile,
  }) async {
    final repo = ref.read(labResultRepoProvider);

    LabResultModel finalResult = result;

    if (result.usedForCalibration) {
      final calculator = TestosteroneCalculator();

      double rawLevel = calculator.calculateRawLevelAt(
        targetTime: result.dateDrawn,
        injections: currentInjections,
        userProfile: userProfile,
      );

      if (rawLevel < 1.0) rawLevel = 1.0;

      double factor = result.valueNormalized / rawLevel;

      finalResult = LabResultModel(
        id: result.id,
        dateDrawn: result.dateDrawn,
        measuredValueRaw: result.measuredValueRaw,
        unitRaw: result.unitRaw,
        valueNormalized: result.valueNormalized,
        usedForCalibration: true,
        resultingCorrectionFactor: factor,
        createdAt: result.createdAt,
      );
    }

    await repo.addLabResult(finalResult);
    ref.invalidateSelf();
    ref.invalidate(currentLevelProvider);
  }
}
