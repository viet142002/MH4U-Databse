import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../../domain/entities/weapon_entity.dart';

class WeaponRepository {
  final AppDatabase _db;
  WeaponRepository(this._db);

  int _parseAffinity(String raw) {
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
    final w = _db.weapons;
    final i = _db.items;
    final test = await _db.select(w).get();
    print(test);
    final query = _db.select(w).join([innerJoin(i, i.id.equalsExp(w.id))]);
    if (search != null && search.isNotEmpty) {
      query.where(i.name.like('%$search%'));
    }
    if (wtype != null && wtype.isNotEmpty) {
      query.where(w.wtype.equals(wtype));
    }
    query.orderBy([OrderingTerm.asc(i.name)]);
    final rows = await query.get();
    return rows
        .map((r) => WeaponListItem(
              id: r.readTable(w).id,
              name: r.readTable(i).name,
              wtype: r.readTable(w).wtype,
              attack: r.readTable(w).attack,
              affinity: _parseAffinity(r.readTable(w).affinity),
              element: (r.readTable(w).element?.isEmpty ?? true)
                  ? null
                  : r.readTable(w).element,
              elementAttack: r.readTable(w).elementAttack,
              numSlots: r.readTable(w).numSlots,
              isFinal: r.readTable(w).finalWeapon == 1,
              rarity: r.readTable(i).rarity,
              parentId: r.readTable(w).parentId,
              treeDepth: r.readTable(w).treeDepth,
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
    final w = _db.weapons;
    final i = _db.items;
    final query = _db.select(w).join([innerJoin(i, i.id.equalsExp(w.id))])
      ..where(w.wtype.equals(wtype))
      ..orderBy([OrderingTerm.asc(w.treeDepth), OrderingTerm.asc(i.name)]);
    final rows = await query.get();
    final nodes = rows
        .map((r) => WeaponTreeNode(
              id: r.readTable(w).id,
              name: r.readTable(i).name,
              wtype: r.readTable(w).wtype,
              attack: r.readTable(w).attack,
              affinity: _parseAffinity(r.readTable(w).affinity),
              element: (r.readTable(w).element?.isEmpty ?? true)
                  ? null
                  : r.readTable(w).element,
              elementAttack: r.readTable(w).elementAttack,
              numSlots: r.readTable(w).numSlots,
              isFinal: r.readTable(w).finalWeapon == 1,
              rarity: r.readTable(i).rarity,
              parentId: (r.readTable(w).parentId == null ||
                      r.readTable(w).parentId == 0)
                  ? null
                  : r.readTable(w).parentId,
              treeDepth: r.readTable(w).treeDepth,
              sharpness: _parseSharpness(r.readTable(w).sharpness),
            ))
        .toList();
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
    final w = _db.weapons;
    final i = _db.items;
    final row = await (_db.select(w).join([innerJoin(i, i.id.equalsExp(w.id))])
          ..where(w.id.equals(weaponId)))
        .getSingleOrNull();
    if (row == null) return null;

    final weapon = row.readTable(w);
    final item = row.readTable(i);

    // Raw SQL for materials - avoids Drift async issues
    final craftRows = await _db.customSelect(
      '''SELECT c.component_item_id, i.name, c.quantity, c.type
         FROM components c JOIN items i ON i._id = c.component_item_id
         WHERE c.created_item_id = $weaponId
         AND c.type IN ('Create', 'Create A', 'Create B')''',
    ).get();

    final upgradeRows = await _db.customSelect(
      '''SELECT c.component_item_id, i.name, c.quantity, c.type
         FROM components c JOIN items i ON i._id = c.component_item_id
         WHERE c.created_item_id = $weaponId
         AND c.type = 'Improve' ''',
    ).get();

    // Parent weapon breadcrumb
    WeaponBreadcrumb? parent;
    if (weapon.parentId != null && weapon.parentId! > 0) {
      final parentRow =
          await (_db.select(w).join([innerJoin(i, i.id.equalsExp(w.id))])
                ..where(w.id.equals(weapon.parentId!)))
              .getSingleOrNull();
      if (parentRow != null) {
        parent = WeaponBreadcrumb(
          id: parentRow.readTable(w).id,
          name: parentRow.readTable(i).name,
        );
      }
    }

    final sharpnessParsed = _parseSharpness(weapon.sharpness);
    return WeaponEntity(
      id: weapon.id,
      name: item.name,
      wtype: weapon.wtype,
      attack: weapon.attack,
      maxAttack: weapon.maxAttack,
      affinity: _parseAffinity(weapon.affinity),
      element: weapon.element?.isEmpty == true ? null : weapon.element,
      elementAttack: weapon.elementAttack,
      element2: weapon.element2?.isEmpty == true ? null : weapon.element2,
      element2Attack: weapon.element2Attack,
      awaken: weapon.awaken?.isEmpty == true ? null : weapon.awaken,
      awakenAttack: weapon.awakenAttack,
      defense: weapon.defense,
      sharpnessBase: sharpnessParsed[0],
      sharpnessPlus1: sharpnessParsed.length > 1 ? sharpnessParsed[1] : [],
      numSlots: weapon.numSlots,
      isFinal: weapon.finalWeapon == 1,
      rarity: item.rarity,
      creationCost: weapon.creationCost,
      upgradeCost: weapon.upgradeCost,
      treeDepth: weapon.treeDepth,
      parentId: (weapon.parentId == null || weapon.parentId == 0)
          ? null
          : weapon.parentId,
      parent: parent,
      hornNotes: weapon.hornNotes,
      shellingType: weapon.shellingType,
      phial: weapon.phial,
      charges: weapon.charges,
      coatings: weapon.coatings,
      recoil: weapon.recoil,
      reloadSpeed: weapon.reloadSpeed,
      deviation: weapon.deviation,
      craftMaterials: craftRows
          .map((r) => WeaponMaterialEntity(
                itemName: r.read<String>('name'),
                quantity: r.read<int>('quantity'),
                type: r.read<String>('type'),
              ))
          .toList(),
      upgradeMaterials: upgradeRows
          .map((r) => WeaponMaterialEntity(
                itemName: r.read<String>('name'),
                quantity: r.read<int>('quantity'),
                type: r.read<String>('type'),
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
