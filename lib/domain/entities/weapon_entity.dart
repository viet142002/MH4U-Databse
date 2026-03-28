// Plain Dart classes — no Freezed generator needed

class WeaponListItem {
  final int id;
  final String name;
  final String wtype;
  final int attack;
  final int affinity;
  final String? element;
  final int? elementAttack;
  final int numSlots;
  final bool isFinal;
  final int rarity;
  final int? parentId;
  final int treeDepth;

  const WeaponListItem({
    required this.id,
    required this.name,
    required this.wtype,
    required this.attack,
    required this.affinity,
    this.element,
    this.elementAttack,
    required this.numSlots,
    required this.isFinal,
    required this.rarity,
    this.parentId,
    required this.treeDepth,
  });
}

class WeaponTreeNode {
  final int id;
  final String name;
  final String wtype;
  final int attack;
  final int affinity;
  final String? element;
  final int? elementAttack;
  final int numSlots;
  final bool isFinal;
  final int rarity;
  final int? parentId;
  final int treeDepth;
  final List<List<int>> sharpness;
  final List<WeaponTreeNode> children;

  const WeaponTreeNode({
    required this.id,
    required this.name,
    required this.wtype,
    required this.attack,
    required this.affinity,
    this.element,
    this.elementAttack,
    required this.numSlots,
    required this.isFinal,
    required this.rarity,
    this.parentId,
    required this.treeDepth,
    this.sharpness = const [],
    this.children = const [],
  });

  WeaponTreeNode copyWith({List<WeaponTreeNode>? children}) {
    return WeaponTreeNode(
      id: id, name: name, wtype: wtype, attack: attack,
      affinity: affinity, element: element, elementAttack: elementAttack,
      numSlots: numSlots, isFinal: isFinal, rarity: rarity,
      parentId: parentId, treeDepth: treeDepth, sharpness: sharpness,
      children: children ?? this.children,
    );
  }
}

class WeaponEntity {
  final int id;
  final String name;
  final String wtype;
  final int attack;
  final int? maxAttack;
  final int affinity;
  final String? element;
  final int? elementAttack;
  final String? element2;
  final int? element2Attack;
  final String? awaken;
  final int? awakenAttack;
  final int? defense;
  final List<int> sharpnessBase;
  final List<int> sharpnessPlus1;
  final int numSlots;
  final bool isFinal;
  final int rarity;
  final int? creationCost;
  final int? upgradeCost;
  final int treeDepth;
  final int? parentId;
  final WeaponBreadcrumb? parent;
  final String? hornNotes;
  final String? shellingType;
  final String? phial;
  final String? charges;
  final String? coatings;
  final String? recoil;
  final String? reloadSpeed;
  final String? deviation;
  final List<WeaponMaterialEntity> craftMaterials;
  final List<WeaponMaterialEntity> upgradeMaterials;

  const WeaponEntity({
    required this.id,
    required this.name,
    required this.wtype,
    required this.attack,
    this.maxAttack,
    required this.affinity,
    this.element,
    this.elementAttack,
    this.element2,
    this.element2Attack,
    this.awaken,
    this.awakenAttack,
    this.defense,
    this.sharpnessBase = const [],
    this.sharpnessPlus1 = const [],
    required this.numSlots,
    required this.isFinal,
    required this.rarity,
    this.creationCost,
    this.upgradeCost,
    required this.treeDepth,
    this.parentId,
    this.parent,
    this.hornNotes,
    this.shellingType,
    this.phial,
    this.charges,
    this.coatings,
    this.recoil,
    this.reloadSpeed,
    this.deviation,
    this.craftMaterials = const [],
    this.upgradeMaterials = const [],
  });
}

class WeaponMaterialEntity {
  final String itemName;
  final int quantity;
  final String type;

  const WeaponMaterialEntity({
    required this.itemName,
    required this.quantity,
    required this.type,
  });
}

class WeaponBreadcrumb {
  final int id;
  final String name;
  const WeaponBreadcrumb({required this.id, required this.name});
}
