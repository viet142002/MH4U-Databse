import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../../domain/entities/weapon_entity.dart';

class WeaponRepository {
  final AppDatabase _db;
  WeaponRepository(this._db);

  int _parseAffinity(String? raw) {
    if (raw == null) return 0;
    final s = raw.trim();
    if (s.isEmpty) return 0;
    final part = s.split('/').first.trim();
    return int.tryParse(part) ?? 0;
  }

  List<List<int>> _parseSharpness(String? raw) {
    if (raw == null || raw.isEmpty) return [[], []];
    final parts = raw.trim().split(' ');
    List<int> parse(String s) =>
        s.split('.').map((v) => int.tryParse(v) ?? 0).toList();
    return [
      parts.isNotEmpty ? parse(parts[0]) : [],
      parts.length > 1 ? parse(parts[1]) : [],
    ];
  }

  Future<List<WeaponListItem>> getWeaponList({
    String? search,
    String? wtype,
  }) async {
    final conditions = <String>[];
    if (search != null && search.isNotEmpty) {
      final s = search.replaceAll("'", "''");
      conditions.add("i.name LIKE '%$s%'");
    }
    if (wtype != null && wtype.isNotEmpty) {
      final t = wtype.replaceAll("'", "''");
      conditions.add("w.wtype = '$t'");
    }
    final where =
        conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';

    // Use CAST(col AS INTEGER) so that empty-string values in the real
    // MH4U SQLite DB are coerced to 0, preventing int.parse() failures.
    final rows = await _db.customSelect(
      '''
      SELECT w._id,
             i.name,
             w.wtype,
             COALESCE(CAST(w.attack      AS INTEGER), 0) AS attack,
             w.affinity,
             w.element,
             CAST(w.element_attack       AS INTEGER) AS element_attack,
             COALESCE(CAST(w.num_slots   AS INTEGER), 0) AS num_slots,
             CAST(w.final               AS INTEGER) AS final_weapon,
             COALESCE(CAST(i.rarity     AS INTEGER), 0) AS rarity,
             COALESCE(CAST(w.parent_id   AS INTEGER), 0) AS parent_id,
             COALESCE(CAST(w.tree_depth AS INTEGER), 0) AS tree_depth
      FROM weapons w
      JOIN items i ON i._id = w._id
      $where
      ORDER BY i.name ASC
      ''',
    ).get();

    return rows
        .map((r) => WeaponListItem(
              id: r.read<int>('_id'),
              name: r.read<String>('name'),
              wtype: r.read<String>('wtype'),
              attack: r.read<int>('attack'),
              affinity: _parseAffinity(r.readNullable<String>('affinity')),
              element: (r.readNullable<String>('element') ?? '').isEmpty
                  ? null
                  : r.readNullable<String>('element'),
              elementAttack: r.readNullable<int>('element_attack'),
              numSlots: r.read<int>('num_slots'),
              isFinal: (r.readNullable<int>('final_weapon') ?? 0) == 1,
              rarity: r.read<int>('rarity'),
              parentId: r.readNullable<int>('parent_id'),
              treeDepth: r.read<int>('tree_depth'),
            ))
        .toList();
  }

  Future<List<String>> getWeaponTypes() async {
    final query = _db.selectOnly(_db.weapons)
      ..addColumns([_db.weapons.wtype])
      ..groupBy([_db.weapons.wtype])
      ..orderBy([OrderingTerm.asc(_db.weapons.wtype)]);
    final rows = await query.get();
    return rows.map((r) => r.read(_db.weapons.wtype)!).toList();
  }

  Future<List<WeaponTreeNode>> getUpgradeTree(String wtype) async {
    final escaped = wtype.replaceAll("'", "''");
    final rows = await _db.customSelect(
      '''
      SELECT w._id, i.name, w.wtype,
             COALESCE(CAST(w.attack      AS INTEGER), 0) AS attack,
             w.affinity,
             w.element,
             CAST(w.element_attack       AS INTEGER) AS element_attack,
             COALESCE(CAST(w.num_slots   AS INTEGER), 0) AS num_slots,
             CAST(w.final               AS INTEGER) AS final_weapon,
             COALESCE(CAST(i.rarity     AS INTEGER), 0) AS rarity,
             COALESCE(CAST(w.parent_id   AS INTEGER), 0) AS parent_id,
             COALESCE(CAST(w.tree_depth AS INTEGER), 0) AS tree_depth,
             w.sharpness
      FROM weapons w
      JOIN items i ON i._id = w._id
      WHERE w.wtype = '$escaped'
      ORDER BY CAST(w.tree_depth AS INTEGER) ASC, i.name ASC
      ''',
    ).get();

    final nodes = rows.map((r) {
      final element = r.readNullable<String>('element');
      final parentIdRaw = r.readNullable<int>('parent_id');
      return WeaponTreeNode(
        id: r.read<int>('_id'),
        name: r.read<String>('name'),
        wtype: r.read<String>('wtype'),
        attack: r.read<int>('attack'),
        affinity: _parseAffinity(r.readNullable<String>('affinity')),
        element: (element == null || element.isEmpty) ? null : element,
        elementAttack: r.readNullable<int>('element_attack'),
        numSlots: r.read<int>('num_slots'),
        isFinal: (r.readNullable<int>('final_weapon') ?? 0) == 1,
        rarity: r.read<int>('rarity'),
        parentId:
            (parentIdRaw == null || parentIdRaw == 0) ? null : parentIdRaw,
        treeDepth: r.read<int>('tree_depth'),
        sharpness: _parseSharpness(r.readNullable<String>('sharpness')),
      );
    }).toList();
    return _buildTree(nodes, null);
  }

  List<WeaponTreeNode> _buildTree(List<WeaponTreeNode> all, int? parentId) {
    return all
        .where((n) {
          if (parentId == null) return n.parentId == null || n.parentId == 0;
          return n.parentId == parentId;
        })
        .map((n) => n.copyWith(children: _buildTree(all, n.id)))
        .toList();
  }

  Future<WeaponEntity?> getWeaponDetail(int weaponId) async {
    // customSelect with CAST so empty-string integers in the real DB
    // don't crash int.parse inside Drift's typeMapping.
    final weaponRows = await _db.customSelect(
      '''
      SELECT w._id, i.name, w.wtype,
             COALESCE(CAST(w.attack        AS INTEGER), 0) AS attack,
             CAST(w.max_attack             AS INTEGER) AS max_attack,
             w.affinity,
             w.element,
             CAST(w.element_attack         AS INTEGER) AS element_attack,
             w.element_2,
             CAST(w.element_2_attack       AS INTEGER) AS element_2_attack,
             w.awaken,
             CAST(w.awaken_attack          AS INTEGER) AS awaken_attack,
             CAST(w.defense                AS INTEGER) AS defense,
             w.sharpness,
             COALESCE(CAST(w.num_slots     AS INTEGER), 0) AS num_slots,
             CAST(w.final                  AS INTEGER) AS final_weapon,
             COALESCE(CAST(i.rarity        AS INTEGER), 0) AS rarity,
             CAST(w.creation_cost          AS INTEGER) AS creation_cost,
             CAST(w.upgrade_cost           AS INTEGER) AS upgrade_cost,
             COALESCE(CAST(w.tree_depth    AS INTEGER), 0) AS tree_depth,
             COALESCE(CAST(w.parent_id     AS INTEGER), 0) AS parent_id,
             w.horn_notes, w.shelling_type, w.phial, w.charges,
             w.coatings, w.recoil, w.reload_speed, w.deviation
      FROM weapons w
      JOIN items i ON i._id = w._id
      WHERE w._id = $weaponId
      ''',
    ).get();
    if (weaponRows.isEmpty) return null;
    final row = weaponRows.first;

    // Materials — CAST quantity to avoid empty-string crash
    final craftRows = await _db.customSelect(
      '''
      SELECT i.name, COALESCE(CAST(c.quantity AS INTEGER), 0) AS quantity, c.type
      FROM components c JOIN items i ON i._id = c.component_item_id
      WHERE c.created_item_id = $weaponId
        AND c.type IN ('Create', 'Create A', 'Create B')
      ''',
    ).get();

    final upgradeRows = await _db.customSelect(
      '''
      SELECT i.name, COALESCE(CAST(c.quantity AS INTEGER), 0) AS quantity, c.type
      FROM components c JOIN items i ON i._id = c.component_item_id
      WHERE c.created_item_id = $weaponId
        AND c.type = 'Improve'
      ''',
    ).get();

    // Parent weapon breadcrumb
    WeaponBreadcrumb? parent;
    final parentIdRaw = row.readNullable<int>('parent_id');
    if (parentIdRaw != null && parentIdRaw > 0) {
      final parentRows = await _db.customSelect(
        '''
        SELECT w._id, i.name
        FROM weapons w JOIN items i ON i._id = w._id
        WHERE w._id = $parentIdRaw
        ''',
      ).get();
      if (parentRows.isNotEmpty) {
        parent = WeaponBreadcrumb(
          id: parentRows.first.read<int>('_id'),
          name: parentRows.first.read<String>('name'),
        );
      }
    }

    final element = row.readNullable<String>('element');
    final element2 = row.readNullable<String>('element_2');
    final awaken = row.readNullable<String>('awaken');
    final sharpnessParsed = _parseSharpness(row.readNullable<String>('sharpness'));

    return WeaponEntity(
      id: row.read<int>('_id'),
      name: row.read<String>('name'),
      wtype: row.read<String>('wtype'),
      attack: row.read<int>('attack'),
      maxAttack: row.readNullable<int>('max_attack'),
      affinity: _parseAffinity(row.readNullable<String>('affinity')),
      element: (element == null || element.isEmpty) ? null : element,
      elementAttack: row.readNullable<int>('element_attack'),
      element2: (element2 == null || element2.isEmpty) ? null : element2,
      element2Attack: row.readNullable<int>('element_2_attack'),
      awaken: (awaken == null || awaken.isEmpty) ? null : awaken,
      awakenAttack: row.readNullable<int>('awaken_attack'),
      defense: row.readNullable<int>('defense'),
      sharpnessBase: sharpnessParsed[0],
      sharpnessPlus1: sharpnessParsed.length > 1 ? sharpnessParsed[1] : [],
      numSlots: row.read<int>('num_slots'),
      isFinal: (row.readNullable<int>('final_weapon') ?? 0) == 1,
      rarity: row.read<int>('rarity'),
      creationCost: row.readNullable<int>('creation_cost'),
      upgradeCost: row.readNullable<int>('upgrade_cost'),
      treeDepth: row.read<int>('tree_depth'),
      parentId: (parentIdRaw == null || parentIdRaw == 0) ? null : parentIdRaw,
      parent: parent,
      hornNotes: row.readNullable<String>('horn_notes'),
      shellingType: row.readNullable<String>('shelling_type'),
      phial: row.readNullable<String>('phial'),
      charges: row.readNullable<String>('charges'),
      coatings: row.readNullable<String>('coatings'),
      recoil: row.readNullable<String>('recoil'),
      reloadSpeed: row.readNullable<String>('reload_speed'),
      deviation: row.readNullable<String>('deviation'),
      craftMaterials: craftRows
          .map((r) => WeaponMaterialEntity(
                itemName: r.read<String>('name'),
                quantity: r.read<int>('quantity'),
                type: r.readNullable<String>('type') ?? '',
              ))
          .toList(),
      upgradeMaterials: upgradeRows
          .map((r) => WeaponMaterialEntity(
                itemName: r.read<String>('name'),
                quantity: r.read<int>('quantity'),
                type: r.readNullable<String>('type') ?? '',
              ))
          .toList(),
    );
  }
}

// ── Manual providers ──────────────────────────────────────────────────────────

typedef WeaponFilter = ({String? search, String? wtype});

final weaponRepositoryProvider = Provider<WeaponRepository>((ref) {
  return WeaponRepository(ref.watch(databaseProvider));
});

final weaponTypesProvider = FutureProvider<List<String>>((ref) async {
  return ref.read(weaponRepositoryProvider).getWeaponTypes();
});

final weaponListProvider =
    FutureProvider.family<List<WeaponListItem>, WeaponFilter>(
  (ref, filter) async {
    return ref.read(weaponRepositoryProvider).getWeaponList(
          search: filter.search,
          wtype: filter.wtype,
        );
  },
);

final weaponTreeProvider = FutureProvider.family<List<WeaponTreeNode>, String>(
  (ref, wtype) async {
    return ref.read(weaponRepositoryProvider).getUpgradeTree(wtype);
  },
);

final weaponDetailProvider = FutureProvider.family<WeaponEntity?, int>(
  (ref, weaponId) async {
    return ref.read(weaponRepositoryProvider).getWeaponDetail(weaponId);
  },
);
