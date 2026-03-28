import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../../domain/entities/other_entities.dart';

class ArmorRepository {
  final AppDatabase _db;
  ArmorRepository(this._db);

  Future<List<ArmorListItem>> getArmorList({
    String? search,
    String? slot,
    String? hunterType,
  }) async {
    final a = _db.armor;
    final i = _db.items;
    final query = _db.select(a).join([innerJoin(i, i.id.equalsExp(a.id))]);
    if (search != null && search.isNotEmpty) {
      query.where(i.name.like('%$search%'));
    }
    if (slot != null && slot.isNotEmpty) {
      query.where(a.slot.equals(slot));
    }
    if (hunterType != null && hunterType.isNotEmpty && hunterType != 'Both') {
      query.where(a.hunterType.isIn([hunterType, 'Both']));
    }
    query.orderBy([OrderingTerm.asc(i.name)]);
    final rows = await query.get();
    return rows.map((r) => ArmorListItem(
      id: r.readTable(a).id,
      name: r.readTable(i).name,
      slot: r.readTable(a).slot,
      defense: r.readTable(a).defense,
      maxDefense: r.readTable(a).maxDefense,
      rarity: r.readTable(i).rarity,
      hunterType: r.readTable(a).hunterType,
      gender: r.readTable(a).gender,
      numSlots: r.readTable(a).numSlots ?? 0,
    )).toList();
  }

  Future<ArmorEntity?> getArmorDetail(int armorId) async {
    final a = _db.armor;
    final i = _db.items;
    final row = await (_db.select(a).join([innerJoin(i, i.id.equalsExp(a.id))])
          ..where(a.id.equals(armorId)))
        .getSingleOrNull();
    if (row == null) return null;

    final armor = row.readTable(a);
    final item = row.readTable(i);

    // Raw SQL for skill points - avoids Drift async issues
    final skillRows = await _db.customSelect(
      '''SELECT st.name as tree_name, its.point_value
         FROM item_to_skill_tree its
         JOIN skill_trees st ON st._id = its.skill_tree_id
         WHERE its.item_id = $armorId''',
    ).get();

    // Raw SQL for materials
    final matRows = await _db.customSelect(
      '''SELECT i.name, c.quantity
         FROM components c JOIN items i ON i._id = c.component_item_id
         WHERE c.created_item_id = $armorId
         AND c.type IN ('Create', 'Create A', 'Create B')''',
    ).get();

    return ArmorEntity(
      id: armor.id,
      name: item.name,
      slot: armor.slot,
      defense: armor.defense,
      maxDefense: armor.maxDefense ?? armor.defense,
      fireRes: armor.fireRes,
      waterRes: armor.waterRes,
      thunderRes: armor.thunderRes,
      iceRes: armor.iceRes,
      dragonRes: armor.dragonRes,
      numSlots: armor.numSlots ?? 0,
      rarity: item.rarity,
      hunterType: armor.hunterType,
      gender: armor.gender,
      description: item.description,
      skillPoints: skillRows.map((r) => ArmorSkillPoint(
        skillTreeName: r.read<String>('tree_name'),
        points: r.read<int>('point_value'),
      )).toList(),
      materials: matRows.map((r) => ArmorMaterialEntity(
        itemName: r.read<String>('name'),
        quantity: r.read<int>('quantity'),
      )).toList(),
    );
  }
}

// ── Manual providers ──────────────────────────────────────────────────────────

typedef ArmorFilter = ({String? search, String? slot, String? hunterType});

final armorRepositoryProvider = Provider<ArmorRepository>((ref) {
  return ArmorRepository(ref.watch(databaseProvider));
});

final armorListProvider = FutureProvider.family<List<ArmorListItem>, ArmorFilter>(
  (ref, filter) async {
    return ref.read(armorRepositoryProvider).getArmorList(
      search: filter.search,
      slot: filter.slot,
      hunterType: filter.hunterType,
    );
  },
);

final armorDetailProvider = FutureProvider.family<ArmorEntity?, int>(
  (ref, armorId) async {
    return ref.read(armorRepositoryProvider).getArmorDetail(armorId);
  },
);
