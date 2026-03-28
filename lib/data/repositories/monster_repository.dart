import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../../domain/entities/monster_entity.dart';

class MonsterRepository {
  final AppDatabase _db;
  MonsterRepository(this._db);

  Future<List<Monster>> getAllMonsters({
    String? search,
    String? monsterClass,
    bool includeMinions = false,
  }) async {
    final query = _db.select(_db.monsters);
    if (!includeMinions) {
      query.where((m) => m.monsterClass.isNotIn(['Minion', 'Herbivore']));
    }
    if (search != null && search.isNotEmpty) {
      query.where((m) => m.name.like('%$search%'));
    }
    if (monsterClass != null && monsterClass.isNotEmpty) {
      query.where((m) => m.monsterClass.equals(monsterClass));
    }
    query.orderBy([(m) => OrderingTerm.asc(m.sortName)]);
    return query.get();
  }

  Future<List<String>> getMonsterClasses() async {
    final query = _db.selectOnly(_db.monsters)
      ..addColumns([_db.monsters.monsterClass])
      ..groupBy([_db.monsters.monsterClass])
      ..where(_db.monsters.monsterClass.isNotIn(['Minion', 'Herbivore']))
      ..orderBy([OrderingTerm.asc(_db.monsters.monsterClass)]);
    final rows = await query.get();
    return rows.map((r) => r.read(_db.monsters.monsterClass)!).toList();
  }

  Future<MonsterEntity?> getMonsterDetail(int monsterId) async {
    debugPrint('[MonsterRepo] getMonsterDetail($monsterId) START');
    final monster = await (_db.select(_db.monsters)
          ..where((m) => m.id.equals(monsterId)))
        .getSingleOrNull();
    if (monster == null) {
      debugPrint('[MonsterRepo] monster not found');
      return null;
    }
    debugPrint('[MonsterRepo] monster found: ${monster.name}');

    debugPrint('[MonsterRepo] fetching damageRows...');
    final damageRows = await (_db.select(_db.monsterDamage)
          ..where((d) => d.monsterId.equals(monsterId))
          ..orderBy([(d) => OrderingTerm.asc(d.bodyPart)]))
        .get();

    debugPrint('[MonsterRepo] fetching weaknessRows...');
    final weaknessRows = await (_db.select(_db.monsterWeakness)
          ..where((w) => w.monsterId.equals(monsterId)))
        .get();

    debugPrint('[MonsterRepo] fetching rawRewards...');
    final rawRewards = await (_db.select(_db.huntingRewards)
          ..where((hr) => hr.monsterId.equals(monsterId))
          ..orderBy([
            (hr) => OrderingTerm.asc(hr.rank),
            (hr) => OrderingTerm.desc(hr.percentage),
          ]))
        .get();
    debugPrint('[MonsterRepo] rawRewards count: ${rawRewards.length}');
    // Use raw SQL to fetch all item names at once - avoids Drift query conflicts
    final rewardItemMap = <int, String>{};
    if (rawRewards.isNotEmpty) {
      final ids = rawRewards.map((r) => r.itemId).toSet().join(',');
      final itemRows = await _db
          .customSelect(
            'SELECT _id, name FROM items WHERE _id IN ($ids)',
          )
          .get();
      for (final row in itemRows) {
        rewardItemMap[row.read<int>('_id')] = row.read<String>('name');
      }
    }
    debugPrint(
        '[MonsterRepo] rewardItemMap built: ${rewardItemMap.length} items');

    debugPrint('[MonsterRepo] fetching rawHabitats...');
    final rawHabitats = await (_db.select(_db.monsterHabitat)
          ..where((h) => h.monsterId.equals(monsterId)))
        .get();
    debugPrint('[MonsterRepo] rawHabitats count: ${rawHabitats.length}');
    final locationNameMap = <int, String>{};
    if (rawHabitats.isNotEmpty) {
      final locIds = rawHabitats.map((h) => h.locationId).toSet().join(',');
      final locRows = await _db
          .customSelect(
            'SELECT _id, name FROM locations WHERE _id IN ($locIds)',
          )
          .get();
      for (final row in locRows) {
        locationNameMap[row.read<int>('_id')] = row.read<String>('name');
      }
    }
    debugPrint('[MonsterRepo] locationNameMap built');

    debugPrint('[MonsterRepo] fetching ailmentRows...');
    final ailmentRows = await (_db.select(_db.monsterAilment)
          ..where((a) => a.monsterId.equals(monsterId)))
        .get();

    debugPrint('[MonsterRepo] fetching statusRows...');
    final statusRows = await (_db.select(_db.monsterStatus)
          ..where((s) => s.monsterId.equals(monsterId)))
        .get();

    debugPrint('[MonsterRepo] building MonsterEntity...');
    return MonsterEntity(
      id: monster.id,
      name: monster.name,
      monsterClass: monster.monsterClass,
      signatureMove: monster.signatureMove,
      trait: monster.trait,
      iconName: monster.iconName,
      isElderDragon: monster.monsterClass == 'Elder Dragon',
      hitzones: damageRows
          .map((d) => MonsterHitzoneEntity(
                bodyPart: d.bodyPart,
                cut: d.cut,
                impact: d.impact,
                shot: d.shot,
                fire: d.fire,
                water: d.water,
                ice: d.ice,
                thunder: d.thunder,
                dragon: d.dragon,
                ko: d.ko,
              ))
          .toList(),
      weaknesses: weaknessRows
          .map((w) => MonsterWeaknessEntity(
                state: w.state,
                fire: w.fire,
                water: w.water,
                thunder: w.thunder,
                ice: w.ice,
                dragon: w.dragon,
                poison: w.poison,
                paralysis: w.paralysis,
                sleep: w.sleep,
                pitfallTrap: w.pitfallTrap,
                shockTrap: w.shockTrap,
                flashBomb: w.flashBomb,
                sonicBomb: w.sonicBomb,
                dungBomb: w.dungBomb,
                meat: w.meat,
              ))
          .toList(),
      drops: rawRewards
          .map((r) => MonsterDropEntity(
                itemName: rewardItemMap[r.itemId] ?? '?',
                condition: r.condition,
                rank: r.rank,
                stackSize: r.stackSize,
                percentage: r.percentage,
              ))
          .toList(),
      habitats: rawHabitats
          .map((h) => MonsterHabitatEntity(
                locationName: locationNameMap[h.locationId] ?? '?',
                startArea: h.startArea,
                moveArea: h.moveArea,
                restArea: h.restArea,
              ))
          .toList(),
      ailments: ailmentRows.map((a) => a.ailment).toList(),
      statuses: statusRows
          .map((s) => MonsterStatusEntity(
                status: s.status,
                initial: s.initial,
                increase: s.increase,
                max: s.max,
                duration: s.duration,
                damage: s.damage,
              ))
          .toList(),
    );
  }
}

// ── Manual providers (no @riverpod generator) ─────────────────────────────────

typedef MonsterFilter = ({
  String? search,
  String? monsterClass,
  bool includeMinions
});

final monsterRepositoryProvider = Provider<MonsterRepository>((ref) {
  return MonsterRepository(ref.watch(databaseProvider));
});

final monsterListProvider = FutureProvider.family<List<Monster>, MonsterFilter>(
  (ref, filter) async {
    return ref.read(monsterRepositoryProvider).getAllMonsters(
          search: filter.search,
          monsterClass: filter.monsterClass,
          includeMinions: filter.includeMinions,
        );
  },
);

final monsterClassesProvider = FutureProvider<List<String>>((ref) async {
  return ref.read(monsterRepositoryProvider).getMonsterClasses();
});

final monsterDetailProvider = FutureProvider.family<MonsterEntity?, int>(
  (ref, id) async {
    return ref.read(monsterRepositoryProvider).getMonsterDetail(id);
  },
);
