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
    final conditions = <String>[];
    if (search != null && search.isNotEmpty) {
      final s = search.replaceAll("'", "''");
      conditions.add("i.name LIKE '%$s%'");
    }
    if (slot != null && slot.isNotEmpty) {
      final sl = slot.replaceAll("'", "''");
      conditions.add("a.slot = '$sl'");
    }
    if (hunterType != null && hunterType.isNotEmpty && hunterType != 'Both') {
      final h = hunterType.replaceAll("'", "''");
      conditions.add("a.hunter_type IN ('$h', 'Both')");
    }
    final where =
        conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';

    // Use CAST(col AS INTEGER) so empty-string values in the real MH4U
    // SQLite DB are coerced to 0 instead of crashing int.parse().
    final rows = await _db.customSelect(
      '''
      SELECT a._id,
             i.name,
             a.slot,
             COALESCE(CAST(a.defense     AS INTEGER), 0) AS defense,
             CAST(a.max_defense          AS INTEGER) AS max_defense,
             COALESCE(CAST(i.rarity      AS INTEGER), 0) AS rarity,
             a.hunter_type,
             a.gender,
             COALESCE(CAST(a.num_slots   AS INTEGER), 0) AS num_slots
      FROM armor a
      JOIN items i ON i._id = a._id
      $where
      ORDER BY i.name ASC
      ''',
    ).get();

    return rows
        .map((r) => ArmorListItem(
              id: r.read<int>('_id'),
              name: r.read<String>('name'),
              slot: r.read<String>('slot'),
              defense: r.read<int>('defense'),
              maxDefense: r.readNullable<int>('max_defense'),
              rarity: r.read<int>('rarity'),
              hunterType: r.read<String>('hunter_type'),
              gender: r.read<String>('gender'),
              numSlots: r.read<int>('num_slots'),
            ))
        .toList();
  }

  Future<ArmorEntity?> getArmorDetail(int armorId) async {
    // customSelect with CAST so empty-string integers in the real MH4U DB
    // don't crash int.parse inside Drift's typeMapping.
    final rows = await _db.customSelect(
      '''
      SELECT a._id, i.name, a.slot,
             COALESCE(CAST(a.defense      AS INTEGER), 0) AS defense,
             COALESCE(CAST(a.max_defense  AS INTEGER), CAST(a.defense AS INTEGER)) AS max_defense,
             COALESCE(CAST(a.fire_res     AS INTEGER), 0) AS fire_res,
             COALESCE(CAST(a.water_res    AS INTEGER), 0) AS water_res,
             COALESCE(CAST(a.thunder_res  AS INTEGER), 0) AS thunder_res,
             COALESCE(CAST(a.ice_res      AS INTEGER), 0) AS ice_res,
             COALESCE(CAST(a.dragon_res   AS INTEGER), 0) AS dragon_res,
             COALESCE(CAST(a.num_slots    AS INTEGER), 0) AS num_slots,
             COALESCE(CAST(i.rarity       AS INTEGER), 0) AS rarity,
             a.hunter_type, a.gender, i.description
      FROM armor a
      JOIN items i ON i._id = a._id
      WHERE a._id = $armorId
      ''',
    ).get();

    if (rows.isEmpty) return null;
    final r = rows.first;

    // Raw SQL for skill points — CAST point_value
    final skillRows = await _db.customSelect(
      '''SELECT st.name as tree_name, CAST(its.point_value AS INTEGER) as point_value
         FROM item_to_skill_tree its
         JOIN skill_trees st ON st._id = its.skill_tree_id
         WHERE its.item_id = $armorId''',
    ).get();

    // Raw SQL for materials — CAST quantity
    final matRows = await _db.customSelect(
      '''SELECT i.name, CAST(c.quantity AS INTEGER) as quantity
         FROM components c JOIN items i ON i._id = c.component_item_id
         WHERE c.created_item_id = $armorId
         AND c.type IN ('Create', 'Create A', 'Create B')''',
    ).get();

    return ArmorEntity(
      id: r.read<int>('_id'),
      name: r.read<String>('name'),
      slot: r.read<String>('slot'),
      defense: r.read<int>('defense'),
      maxDefense: r.read<int>('max_defense'),
      fireRes: r.read<int>('fire_res'),
      waterRes: r.read<int>('water_res'),
      thunderRes: r.read<int>('thunder_res'),
      iceRes: r.read<int>('ice_res'),
      dragonRes: r.read<int>('dragon_res'),
      numSlots: r.read<int>('num_slots'),
      rarity: r.read<int>('rarity'),
      hunterType: r.read<String>('hunter_type'),
      gender: r.read<String>('gender'),
      description: r.readNullable<String>('description'),
      skillPoints: skillRows
          .map((r) => ArmorSkillPoint(
                skillTreeName: r.read<String>('tree_name'),
                points: r.readNullable<int>('point_value') ?? 0,
              ))
          .toList(),
      materials: matRows
          .map((r) => ArmorMaterialEntity(
                itemName: r.read<String>('name'),
                quantity: r.readNullable<int>('quantity') ?? 0,
              ))
          .toList(),
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
