// Plain Dart classes — no Freezed generator needed

class MonsterEntity {
  final int id;
  final String name;
  final String monsterClass;
  final String signatureMove;
  final String trait;
  final String? iconName;
  final bool isElderDragon;
  final List<MonsterHitzoneEntity> hitzones;
  final List<MonsterWeaknessEntity> weaknesses;
  final List<MonsterDropEntity> drops;
  final List<MonsterHabitatEntity> habitats;
  final List<String> ailments;
  final List<MonsterStatusEntity> statuses;

  const MonsterEntity({
    required this.id,
    required this.name,
    required this.monsterClass,
    required this.signatureMove,
    required this.trait,
    this.iconName,
    required this.isElderDragon,
    this.hitzones = const [],
    this.weaknesses = const [],
    this.drops = const [],
    this.habitats = const [],
    this.ailments = const [],
    this.statuses = const [],
  });
}

class MonsterHitzoneEntity {
  final String bodyPart;
  final int? cut;
  final int? impact;
  final int? shot;
  final int? fire;
  final int? water;
  final int? ice;
  final int? thunder;
  final int? dragon;
  final int? ko;

  const MonsterHitzoneEntity({
    required this.bodyPart,
    this.cut, this.impact, this.shot,
    this.fire, this.water, this.ice,
    this.thunder, this.dragon, this.ko,
  });
}

class MonsterWeaknessEntity {
  final String state;
  final int fire, water, thunder, ice, dragon;
  final int poison, paralysis, sleep;
  final int pitfallTrap, shockTrap, flashBomb, sonicBomb, dungBomb, meat;

  const MonsterWeaknessEntity({
    required this.state,
    required this.fire, required this.water, required this.thunder,
    required this.ice, required this.dragon, required this.poison,
    required this.paralysis, required this.sleep,
    required this.pitfallTrap, required this.shockTrap,
    required this.flashBomb, required this.sonicBomb,
    required this.dungBomb, required this.meat,
  });
}

class MonsterDropEntity {
  final String itemName;
  final String condition;
  final String rank;
  final int stackSize;
  final int percentage;

  const MonsterDropEntity({
    required this.itemName,
    required this.condition,
    required this.rank,
    required this.stackSize,
    required this.percentage,
  });
}

class MonsterHabitatEntity {
  final String locationName;
  final int? startArea;
  final String? moveArea;
  final int? restArea;

  const MonsterHabitatEntity({
    required this.locationName,
    this.startArea, this.moveArea, this.restArea,
  });
}

class MonsterStatusEntity {
  final String status;
  final int? initial, increase, max, duration, damage;

  const MonsterStatusEntity({
    required this.status,
    this.initial, this.increase, this.max,
    this.duration, this.damage,
  });
}
