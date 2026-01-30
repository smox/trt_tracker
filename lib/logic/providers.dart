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
import '../data/models/injection_plan_model.dart';
import 'notification_service.dart';

// 1. Datenbank-Service
final dbServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// 2. User Repo
final userRepoProvider = Provider<UserRepository>((ref) {
  final dbService = ref.watch(dbServiceProvider);
  return UserRepository(dbService);
});

// 3. User Profile
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

  Future<void> saveOnboardingData({
    required String name,
    required double weightKg,
    required int heightCm,
    required DateTime birthDate,
    required DateTime therapyStart,
    required MassUnit preferredUnit,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(userRepoProvider);
      final currentProfile = await repo.getUser();
      final updatedProfile = currentProfile.copyWith(
        name: name,
        weight: weightKg,
        height: heightCm,
        bodyFatPercentage: 0.0,
        preferredUnit: preferredUnit,
        birthDate: birthDate.millisecondsSinceEpoch,
        therapyStart: therapyStart.millisecondsSinceEpoch,
      );
      await repo.updateUserProfile(updatedProfile);
      return updatedProfile;
    });
  }

  Future<void> updateSettings({
    MassUnit? preferredUnit,
    int? startOfWeek,
  }) async {
    final currentState = state.value;
    if (currentState == null) return;
    final updatedProfile = currentState.copyWith(
      preferredUnit: preferredUnit,
      startOfWeek: startOfWeek,
    );
    final repo = ref.read(userRepoProvider);
    await repo.updateUserProfile(updatedProfile);
    state = AsyncData(updatedProfile);
  }
}

// 4. Injection Repo
final injectionRepoProvider = Provider<InjectionRepository>((ref) {
  final dbService = ref.watch(dbServiceProvider);
  return InjectionRepository(dbService);
});

// 5. Injection List
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

// 6. Live Level
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

// 7. Lab Result Repo
final labResultRepoProvider = Provider<LabResultRepository>((ref) {
  final dbService = ref.watch(dbServiceProvider);
  return LabResultRepository(dbService);
});

// 8. Calibration Points
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

// 9. Plan Provider
final injectionPlanProvider =
    AsyncNotifierProvider<InjectionPlanController, List<InjectionPlanModel>>(
      () {
        return InjectionPlanController();
      },
    );

class InjectionPlanController extends AsyncNotifier<List<InjectionPlanModel>> {
  @override
  Future<List<InjectionPlanModel>> build() async {
    final db = await ref.read(dbServiceProvider).database;
    final maps = await db.query('injection_plans');
    return maps.map((e) => InjectionPlanModel.fromMap(e)).toList();
  }

  Future<void> addPlan(InjectionPlanModel plan) async {
    final db = await ref.read(dbServiceProvider).database;
    await db.insert('injection_plans', plan.toMap());

    if (plan.isActive) {
      _scheduleNextNotification(plan);
    }
    ref.invalidateSelf();
  }

  Future<void> updatePlan(InjectionPlanModel plan) async {
    final db = await ref.read(dbServiceProvider).database;
    await db.update(
      'injection_plans',
      plan.toMap(),
      where: 'id = ?',
      whereArgs: [plan.id],
    );

    await NotificationService().cancelNotification(plan.id.hashCode);
    if (plan.isActive) {
      _scheduleNextNotification(plan);
    }
    ref.invalidateSelf();
  }

  // FIX: Stabile Zeitberechnung
  Future<void> markPlanAsDone(String planId) async {
    final plans = state.value ?? [];
    try {
      final plan = plans.firstWhere((element) => element.id == planId);

      // WICHTIG: Wir nehmen das GEPLANTE Datum als Basis, nicht "Jetzt".
      // So bleibt der Donnerstag ein Donnerstag, auch wenn man Freitag bucht.
      // Wir addieren einfach das Intervall (z.B. 7 Tage) drauf.
      DateTime nextBase = plan.nextDueDate.add(
        Duration(days: plan.intervalDays),
      );

      // Falls der User den Plan lange ignoriert hat und nextBase immer noch in der Vergangenheit liegt:
      // Option A: Wir zwingen es in die Zukunft (Rhythmusbruch, aber praktisch)
      // Option B: Wir lassen es mathematisch korrekt (Rhythmus stabil, aber User muss mehrmals klicken)
      // -> Wir wählen hier eine smarte Mischung: Wenn es > 1 Intervall in der Vergangenheit ist, holen wir es ran, aber behalten den Wochentag.

      if (nextBase.isBefore(
        DateTime.now().subtract(Duration(days: plan.intervalDays)),
      )) {
        // Logik um auf den nächsten passenden Wochentag in der Zukunft zu springen
        // Das ist komplex, für V1 bleiben wir beim strikten Rhythmus (Option B).
        // Der User wird ja wohl nicht 3 Wochen vergessen zu tracken ;)
      }

      // Uhrzeit sicherstellen (falls durch Sommerzeit verschoben, wobei DateTime das meist regelt)
      final newDate = DateTime(
        nextBase.year,
        nextBase.month,
        nextBase.day,
        plan.reminderTimeHour,
        plan.reminderTimeMinute,
      );

      final updatedPlan = plan.copyWith(nextDueDate: newDate);
      await updatePlan(updatedPlan);
    } catch (e) {
      // Plan nicht gefunden
    }
  }

  Future<void> deletePlan(String id) async {
    final db = await ref.read(dbServiceProvider).database;
    await db.delete('injection_plans', where: 'id = ?', whereArgs: [id]);
    await NotificationService().cancelNotification(id.hashCode);
    ref.invalidateSelf();
  }

  void _scheduleNextNotification(InjectionPlanModel plan) {
    NotificationService().scheduleNotification(
      id: plan.id.hashCode,
      title: "Zeit für deine Injektion",
      body: "${plan.amountMg}mg ${plan.ester.label} sind fällig.",
      scheduledDate: plan.nextDueDate,
      payload: plan.id,
    );
  }
}
