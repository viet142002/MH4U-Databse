// Plain Dart classes — no Freezed generator needed

// ── Armor ─────────────────────────────────────────────────────────────────────

class ArmorListItem {
  final int id;
  final String name;
  final String slot;
  final int defense;
  final int? maxDefense;
  final int rarity;
  final String hunterType;
  final String gender;
  final int numSlots;

  const ArmorListItem({
    required this.id, required this.name, required this.slot,
    required this.defense, this.maxDefense, required this.rarity,
    required this.hunterType, required this.gender, required this.numSlots,
  });
}

class ArmorEntity {
  final int id;
  final String name;
  final String slot;
  final int defense;
  final int maxDefense;
  final int fireRes, waterRes, thunderRes, iceRes, dragonRes;
  final int numSlots;
  final int rarity;
  final String hunterType;
  final String gender;
  final String? description;
  final List<ArmorSkillPoint> skillPoints;
  final List<ArmorMaterialEntity> materials;

  const ArmorEntity({
    required this.id, required this.name, required this.slot,
    required this.defense, required this.maxDefense,
    required this.fireRes, required this.waterRes,
    required this.thunderRes, required this.iceRes, required this.dragonRes,
    required this.numSlots, required this.rarity,
    required this.hunterType, required this.gender,
    this.description,
    this.skillPoints = const [],
    this.materials = const [],
  });
}

class ArmorSkillPoint {
  final String skillTreeName;
  final int points;
  const ArmorSkillPoint({required this.skillTreeName, required this.points});
}

class ArmorMaterialEntity {
  final String itemName;
  final int quantity;
  const ArmorMaterialEntity({required this.itemName, required this.quantity});
}

// ── Skill ─────────────────────────────────────────────────────────────────────

class SkillTreeEntity {
  final int id;
  final String name;
  final List<SkillEntity> skills;
  const SkillTreeEntity({required this.id, required this.name, this.skills = const []});
}

class SkillEntity {
  final int id;
  final String name;
  final int requiredPoints;
  final String description;
  const SkillEntity({
    required this.id, required this.name,
    required this.requiredPoints, required this.description,
  });
}

// ── Item ──────────────────────────────────────────────────────────────────────

class ItemEntity {
  final int id;
  final String name;
  final String type;
  final String subType;
  final int rarity;
  final int carryCapacity;
  final int? buy;
  final int? sell;
  final String? description;
  final String? iconName;
  final List<CombineRecipe> recipes;

  const ItemEntity({
    required this.id, required this.name, required this.type,
    required this.subType, required this.rarity, required this.carryCapacity,
    this.buy, this.sell, this.description, this.iconName,
    this.recipes = const [],
  });
}

class CombineRecipe {
  final String ingredient1;
  final String ingredient2;
  final int amountMin;
  final int amountMax;
  final int percentage;

  const CombineRecipe({
    required this.ingredient1, required this.ingredient2,
    required this.amountMin, required this.amountMax, required this.percentage,
  });
}

// ── Quest ─────────────────────────────────────────────────────────────────────

class QuestListItem {
  final int id;
  final String name;
  final String hub;
  final String type;
  final int stars;
  final int reward;
  final String locationName;

  const QuestListItem({
    required this.id, required this.name, required this.hub,
    required this.type, required this.stars, required this.reward,
    required this.locationName,
  });
}

class QuestEntity {
  final int id;
  final String name;
  final String goal;
  final String hub;
  final String type;
  final int stars;
  final int reward;
  final int fee;
  final int timeLimit;
  final String locationName;
  final int? hrp;
  final String? subGoal;
  final int? subReward;
  final List<QuestMonsterEntry> monsters;
  final List<QuestRewardEntry> rewards;

  const QuestEntity({
    required this.id, required this.name, required this.goal,
    required this.hub, required this.type, required this.stars,
    required this.reward, required this.fee, required this.timeLimit,
    required this.locationName, this.hrp, this.subGoal, this.subReward,
    this.monsters = const [],
    this.rewards = const [],
  });
}

class QuestMonsterEntry {
  final int monsterId;
  final String monsterName;
  final bool isUnstable;
  const QuestMonsterEntry({
    required this.monsterId, required this.monsterName, required this.isUnstable,
  });
}

class QuestRewardEntry {
  final String itemName;
  final String rewardSlot;
  final int percentage;
  final int stackSize;
  const QuestRewardEntry({
    required this.itemName, required this.rewardSlot,
    required this.percentage, required this.stackSize,
  });
}
