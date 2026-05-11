import 'dart:async';
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'database.dart';
import 'daos.dart';

part 'daos_extra.g.dart';

class GoalDao {
  GoalDao(this._db);
  final AppDatabase _db;

  Future<List<Goal>> getAll() => _db.select(_db.goals).get();

  Future<Goal?> getById(String id) =>
      (_db.select(_db.goals)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<String> insert(Insertable<Goal> goal) async {
    final row = await _db.into(_db.goals).insertReturning(goal);
    return row.id;
  }

  Future<bool> update(Insertable<Goal> goal) async {
    return await _db.update(_db.goals).replace(goal);
  }

  Future<int> delete(String id) =>
      (_db.delete(_db.goals)..where((t) => t.id.equals(id))).go();
  Future<int> clearAll() => _db.delete(_db.goals).go();
}

class NotificationDao {
  NotificationDao(this._db);
  final AppDatabase _db;

  Future<List<Notification>> getUnread() =>
      (_db.select(_db.notifications)..where((t) => t.readAt.isNull())).get();

  Future<List<Notification>> getByType(String type) =>
      (_db.select(_db.notifications)..where((t) => t.type.equals(type))).get();

  Future<Notification?> getById(String id) => (_db.select(
    _db.notifications,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Notification>> getAllNotifications() =>
      _db.select(_db.notifications).get();

  Future<String> insertNotification({
    required String type,
    required String title,
    required String body,
    String? payloadJson,
  }) async {
    final notification = NotificationsCompanion.insert(
      type: type,
      title: title,
      body: body,
      payloadJson: Value(payloadJson),
    );
    final row = await _db.into(_db.notifications).insertReturning(notification);
    return row.id;
  }

  Future<bool> markAsRead(String id) async {
    final update = _db.update(_db.notifications)..where((t) => t.id.equals(id));
    return await update.write(
          NotificationsCompanion(readAt: Value(DateTime.now())),
        ) >
        0;
  }

  Future<int> markAllAsRead() async {
    return await (_db.update(_db.notifications)
          ..where((t) => t.readAt.isNull()))
        .write(NotificationsCompanion(readAt: Value(DateTime.now())));
  }

  Future<int> deleteNotification(String id) =>
      (_db.delete(_db.notifications)..where((t) => t.id.equals(id))).go();

  Future<int> clearAllNotifications() => _db.delete(_db.notifications).go();
}

class SettingDao {
  SettingDao(this._db);
  final AppDatabase _db;

  Future<String?> getValue(String key) async {
    final setting = await (_db.select(
      _db.settings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return setting?.value;
  }

  Future<void> setValue(String key, String value) async {
    await _db
        .into(_db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion(key: Value(key), value: Value(value)),
        );
  }

  Future<bool> delete(String key) async {
    return await (_db.delete(
          _db.settings,
        )..where((t) => t.key.equals(key))).go() >
        0;
  }
}

class SystematicPlanDao {
  SystematicPlanDao(this._db);
  final AppDatabase _db;

  Future<List<SystematicPlan>> getAll() =>
      _db.select(_db.systematicPlans).get();

  Future<List<SystematicPlan>> getByHoldingId(String holdingId) => (_db.select(
    _db.systematicPlans,
  )..where((t) => t.holdingId.equals(holdingId))).get();

  Future<List<SystematicPlan>> getActivePlans() => (_db.select(
    _db.systematicPlans,
  )..where((t) => t.status.equals('active'))).get();

  Stream<List<SystematicPlan>> watchActivePlans() => (_db.select(
    _db.systematicPlans,
  )..where((t) => t.status.equals('active'))).watch();

  Stream<List<SystematicPlan>> watchByHoldingId(String holdingId) =>
      (_db.select(
        _db.systematicPlans,
      )..where((t) => t.holdingId.equals(holdingId))).watch();

  Future<SystematicPlan?> getById(String id) => (_db.select(
    _db.systematicPlans,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<String> insert(Insertable<SystematicPlan> plan) async {
    final row = await _db.into(_db.systematicPlans).insertReturning(plan);
    return row.id;
  }

  Future<bool> update(Insertable<SystematicPlan> plan) async {
    return await _db.update(_db.systematicPlans).replace(plan);
  }

  Future<bool> updateLastExecutedAt(String id, DateTime date) async {
    return await (_db.update(_db.systematicPlans)
              ..where((t) => t.id.equals(id)))
            .write(SystematicPlansCompanion(lastExecutedAt: Value(date))) >
        0;
  }

  Future<bool> pausePlan(String id) async {
    return await (_db.update(_db.systematicPlans)
              ..where((t) => t.id.equals(id)))
            .write(const SystematicPlansCompanion(status: Value('paused'))) >
        0;
  }

  Future<bool> resumePlan(String id) async {
    return await (_db.update(_db.systematicPlans)
              ..where((t) => t.id.equals(id)))
            .write(const SystematicPlansCompanion(status: Value('active'))) >
        0;
  }

  Future<bool> cancelPlan(String id) async {
    return await (_db.update(_db.systematicPlans)
              ..where((t) => t.id.equals(id)))
            .write(const SystematicPlansCompanion(status: Value('cancelled'))) >
        0;
  }

  Future<bool> completePlan(String id) async {
    return await (_db.update(_db.systematicPlans)
              ..where((t) => t.id.equals(id)))
            .write(const SystematicPlansCompanion(status: Value('completed'))) >
        0;
  }

  Future<int> delete(String id) =>
      (_db.delete(_db.systematicPlans)..where((t) => t.id.equals(id))).go();

  Future<int> clearAll() => _db.delete(_db.systematicPlans).go();
}

class FundamentalSnapshotDao {
  FundamentalSnapshotDao(this._db);
  final AppDatabase _db;

  Future<FundamentalSnapshot?> getLatest(String instrumentId) =>
      (_db.select(_db.fundamentalSnapshots)
            ..where((t) => t.instrumentId.equals(instrumentId))
            ..orderBy([
              (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
            ]))
          .getSingleOrNull();

  Future<void> insertOrUpdate(Insertable<FundamentalSnapshot> snapshot) async {
    await _db.into(_db.fundamentalSnapshots).insertOnConflictUpdate(snapshot);
  }

  Future<int> clearAll() => _db.delete(_db.fundamentalSnapshots).go();
}

@riverpod
GoalDao goalDao(Ref ref) => GoalDao(ref.watch(appDatabaseProvider));

@riverpod
NotificationDao notificationDao(Ref ref) =>
    NotificationDao(ref.watch(appDatabaseProvider));

@riverpod
SettingDao settingDao(Ref ref) => SettingDao(ref.watch(appDatabaseProvider));

@riverpod
SystematicPlanDao systematicPlanDao(Ref ref) =>
    SystematicPlanDao(ref.watch(appDatabaseProvider));

@riverpod
FundamentalSnapshotDao fundamentalSnapshotDao(Ref ref) =>
    FundamentalSnapshotDao(ref.watch(appDatabaseProvider));
