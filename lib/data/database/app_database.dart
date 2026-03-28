import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Schema mirrors the community MH4U SQLite DB exactly.
// Key patterns:
//   • armor._id = items._id  — no separate name col, JOIN items for name
//   • weapons._id = items._id — same pattern
//   • components handles ALL crafting (type: Create/Improve)
//   • item_to_skill_tree = armor & decoration skill points
//   • monster_damage = hitzones; monster_weakness = ailment/trap rates
// ─────────────────────────────────────────────────────────────────────────────

class Locations extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  TextColumn get name => text()();
  TextColumn get nameDe => text().named('name_de')();
  TextColumn get nameFr => text().named('name_fr')();
  TextColumn get nameEs => text().named('name_es')();
  TextColumn get nameIt => text().named('name_it')();
  TextColumn get nameJp => text().named('name_jp')();
  TextColumn get mapName => text().named('map')();
  @override String get tableName => 'locations';
}

class Items extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  TextColumn get name => text()();
  TextColumn get nameDe => text().named('name_de')();
  TextColumn get nameFr => text().named('name_fr')();
  TextColumn get nameEs => text().named('name_es')();
  TextColumn get nameIt => text().named('name_it')();
  TextColumn get nameJp => text().named('name_jp').nullable()();
  TextColumn get type => text()();
  TextColumn get subType => text().named('sub_type')();
  IntColumn get rarity => integer().withDefault(const Constant(0))();
  IntColumn get carryCapacity => integer().named('carry_capacity').withDefault(const Constant(0))();
  IntColumn get buy => integer().nullable()();
  IntColumn get sell => integer().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get iconName => text().named('icon_name').nullable()();
  TextColumn get armorDupeNameFix => text().named('armor_dupe_name_fix').withDefault(const Constant(''))();
  @override String get tableName => 'items';
}

class Monsters extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  // 'class' is reserved in Dart — mapped to DB col 'class'
  TextColumn get monsterClass => text().named('class')();
  TextColumn get name => text()();
  TextColumn get nameDe => text().named('name_de')();
  TextColumn get nameFr => text().named('name_fr')();
  TextColumn get nameEs => text().named('name_es')();
  TextColumn get nameIt => text().named('name_it')();
  TextColumn get nameJp => text().named('name_jp')();
  TextColumn get signatureMove => text().named('signature_move')();
  TextColumn get trait => text()();
  TextColumn get iconName => text().named('icon_name').nullable()();
  TextColumn get sortName => text().named('sort_name').withDefault(const Constant(''))();
  @override String get tableName => 'monsters';
}

// Hitzones per body part (cut / impact / shot / elemental / KO)
class MonsterDamage extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  IntColumn get monsterId => integer().named('monster_id').references(Monsters, #id)();
  TextColumn get bodyPart => text().named('body_part')();
  IntColumn get cut => integer().nullable()();
  IntColumn get impact => integer().nullable()();
  IntColumn get shot => integer().nullable()();
  IntColumn get fire => integer().nullable()();
  IntColumn get water => integer().nullable()();
  IntColumn get ice => integer().nullable()();
  IntColumn get thunder => integer().nullable()();
  IntColumn get dragon => integer().nullable()();
  IntColumn get ko => integer().nullable()();
  @override String get tableName => 'monster_damage';
}

// Ailment / trap effectiveness per state (Normal, Enraged, Tired)
class MonsterWeakness extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  IntColumn get monsterId => integer().named('monster_id').references(Monsters, #id)();
  TextColumn get state => text()();
  IntColumn get fire => integer()();
  IntColumn get water => integer()();
  IntColumn get thunder => integer()();
  IntColumn get ice => integer()();
  IntColumn get dragon => integer()();
  IntColumn get poison => integer()();
  IntColumn get paralysis => integer()();
  IntColumn get sleep => integer()();
  IntColumn get pitfallTrap => integer().named('pitfall_trap')();
  IntColumn get shockTrap => integer().named('shock_trap')();
  IntColumn get flashBomb => integer().named('flash_bomb')();
  IntColumn get sonicBomb => integer().named('sonic_bomb')();
  IntColumn get dungBomb => integer().named('dung_bomb')();
  IntColumn get meat => integer()();
  @override String get tableName => 'monster_weakness';
}

class MonsterHabitat extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  IntColumn get monsterId => integer().named('monster_id').references(Monsters, #id)();
  IntColumn get locationId => integer().named('location_id').references(Locations, #id)();
  IntColumn get startArea => integer().named('start_area').nullable()();
  TextColumn get moveArea => text().named('move_area').nullable()();
  IntColumn get restArea => integer().named('rest_area').nullable()();
  @override String get tableName => 'monster_habitat';
}

class HuntingRewards extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  IntColumn get itemId => integer().named('item_id').references(Items, #id)();
  TextColumn get condition => text()();
  IntColumn get monsterId => integer().named('monster_id').references(Monsters, #id)();
  TextColumn get rank => text()();
  IntColumn get stackSize => integer().named('stack_size')();
  IntColumn get percentage => integer()();
  @override String get tableName => 'hunting_rewards';
}

class MonsterAilment extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  IntColumn get monsterId => integer().named('monster_id').references(Monsters, #id)();
  TextColumn get ailment => text()();
  @override String get tableName => 'monster_ailment';
}

class MonsterStatus extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  IntColumn get monsterId => integer().named('monster_id').references(Monsters, #id)();
  TextColumn get status => text()();
  IntColumn get initial => integer().nullable()();
  IntColumn get increase => integer().nullable()();
  IntColumn get max => integer().nullable()();
  IntColumn get duration => integer().nullable()();
  IntColumn get damage => integer().nullable()();
  @override String get tableName => 'monster_status';
}

class MonsterToQuest extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  IntColumn get monsterId => integer().named('monster_id').references(Monsters, #id)();
  IntColumn get questId => integer().named('quest_id').references(Quests, #id)();
  TextColumn get unstable => text().nullable()();
  @override String get tableName => 'monster_to_quest';
}

// weapon._id = items._id — join items to get name
// affinity = TEXT ("5", "-10", "")
// sharpness = "R.O.Y.G.B.W.P R.O.Y.G.B.W.P" dot-separated, space separates base vs sharpness+1
class Weapons extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  IntColumn get parentId => integer().named('parent_id').nullable()();
  TextColumn get wtype => text()();
  IntColumn get creationCost => integer().named('creation_cost').nullable()();
  IntColumn get upgradeCost => integer().named('upgrade_cost').nullable()();
  IntColumn get attack => integer()();
  IntColumn get maxAttack => integer().named('max_attack').nullable()();
  TextColumn get element => text().nullable()();
  IntColumn get elementAttack => integer().named('element_attack').nullable()();
  TextColumn get element2 => text().named('element_2').nullable()();
  IntColumn get element2Attack => integer().named('element_2_attack').nullable()();
  TextColumn get awaken => text().nullable()();
  IntColumn get awakenAttack => integer().named('awaken_attack').nullable()();
  IntColumn get defense => integer().nullable()();
  TextColumn get sharpness => text().nullable()();
  TextColumn get affinity => text()();
  TextColumn get hornNotes => text().named('horn_notes').nullable()();
  TextColumn get shellingType => text().named('shelling_type').nullable()();
  TextColumn get phial => text().nullable()();
  TextColumn get charges => text().nullable()();
  TextColumn get coatings => text().nullable()();
  TextColumn get recoil => text().nullable()();
  TextColumn get reloadSpeed => text().named('reload_speed').nullable()();
  TextColumn get rapidFire => text().named('rapid_fire').nullable()();
  TextColumn get deviation => text().nullable()();
  TextColumn get ammo => text().nullable()();
  TextColumn get specialAmmo => text().named('special_ammo').nullable()();
  IntColumn get numSlots => integer().named('num_slots')();
  IntColumn get treeDepth => integer().named('tree_depth')();
  IntColumn get finalWeapon => integer().named('final').nullable()();
  @override String get tableName => 'weapons';
}

// armor._id = items._id — join items to get name and rarity
class Armor extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  TextColumn get slot => text()();
  IntColumn get defense => integer()();
  IntColumn get maxDefense => integer().named('max_defense').nullable()();
  IntColumn get fireRes => integer().named('fire_res')();
  IntColumn get thunderRes => integer().named('thunder_res')();
  IntColumn get dragonRes => integer().named('dragon_res')();
  IntColumn get waterRes => integer().named('water_res')();
  IntColumn get iceRes => integer().named('ice_res')();
  TextColumn get gender => text()();
  TextColumn get hunterType => text().named('hunter_type')();
  IntColumn get numSlots => integer().named('num_slots').nullable()();
  @override String get tableName => 'armor';
}

class SkillTrees extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  TextColumn get name => text()();
  TextColumn get nameDe => text().named('name_de')();
  TextColumn get nameFr => text().named('name_fr')();
  TextColumn get nameEs => text().named('name_es')();
  TextColumn get nameIt => text().named('name_it')();
  TextColumn get nameJp => text().named('name_jp')();
  @override String get tableName => 'skill_trees';
}

class Skills extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  IntColumn get skillTreeId => integer().named('skill_tree_id').references(SkillTrees, #id)();
  IntColumn get requiredSkillTreePoints => integer().named('required_skill_tree_points')();
  TextColumn get name => text()();
  TextColumn get nameDe => text().named('name_de')();
  TextColumn get nameFr => text().named('name_fr')();
  TextColumn get nameEs => text().named('name_es')();
  TextColumn get nameIt => text().named('name_it')();
  TextColumn get nameJp => text().named('name_jp')();
  TextColumn get description => text()();
  TextColumn get descriptionDe => text().named('description_de')();
  TextColumn get descriptionFr => text().named('description_fr')();
  TextColumn get descriptionEs => text().named('description_es')();
  TextColumn get descriptionIt => text().named('description_it')();
  TextColumn get descriptionJp => text().named('description_jp')();
  @override String get tableName => 'skills';
}

class ItemToSkillTree extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  IntColumn get itemId => integer().named('item_id').references(Items, #id)();
  IntColumn get skillTreeId => integer().named('skill_tree_id').references(SkillTrees, #id)();
  IntColumn get pointValue => integer().named('point_value')();
  @override String get tableName => 'item_to_skill_tree';
}

// Unified crafting: weapons, armor, items. type = 'Create'|'Create A'|'Create B'|'Improve'
class Components extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  IntColumn get createdItemId => integer().named('created_item_id').references(Items, #id)();
  IntColumn get componentItemId => integer().named('component_item_id').references(Items, #id)();
  IntColumn get quantity => integer()();
  TextColumn get type => text().nullable()();
  @override String get tableName => 'components';
}

class Combining extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  IntColumn get createdItemId => integer().named('created_item_id').references(Items, #id)();
  IntColumn get item1Id => integer().named('item_1_id').references(Items, #id)();
  IntColumn get item2Id => integer().named('item_2_id').references(Items, #id)();
  IntColumn get amountMadeMin => integer().named('amount_made_min')();
  IntColumn get amountMadeMax => integer().named('amount_made_max')();
  IntColumn get percentage => integer()();
  @override String get tableName => 'combining';
}

class Quests extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  TextColumn get name => text()();
  TextColumn get goal => text()();
  TextColumn get hub => text()(); // 'Caravan', 'Guild', 'Event'
  TextColumn get type => text()(); // 'Key', 'Normal', 'Urgent'
  IntColumn get stars => integer()();
  IntColumn get locationId => integer().named('location_id').references(Locations, #id)();
  IntColumn get timeLimit => integer().named('time_limit')();
  IntColumn get fee => integer()();
  IntColumn get reward => integer()();
  IntColumn get hrp => integer().nullable()();
  TextColumn get subGoal => text().named('sub_goal').nullable()();
  IntColumn get subReward => integer().named('sub_reward').nullable()();
  IntColumn get subHrp => integer().named('sub_hrp').nullable()();
  @override String get tableName => 'quests';
}

class QuestRewards extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  IntColumn get questId => integer().named('quest_id').references(Quests, #id)();
  IntColumn get itemId => integer().named('item_id').references(Items, #id)();
  TextColumn get rewardSlot => text().named('reward_slot')();
  IntColumn get percentage => integer()();
  IntColumn get stackSize => integer().named('stack_size')();
  @override String get tableName => 'quest_rewards';
}

class QuestPrereqs extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  IntColumn get questId => integer().named('quest_id').references(Quests, #id)();
  IntColumn get prereqId => integer().named('prereq_id').references(Quests, #id)();
  @override String get tableName => 'quest_prereqs';
}

class Gathering extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  IntColumn get itemId => integer().named('item_id').references(Items, #id)();
  IntColumn get locationId => integer().named('location_id').references(Locations, #id)();
  TextColumn get area => text()();
  TextColumn get site => text()();
  TextColumn get rank => text()();
  IntColumn get quantity => integer().nullable()();
  IntColumn get percentage => integer().nullable()();
  @override String get tableName => 'gathering';
}

class Decorations extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  IntColumn get numSlots => integer().named('num_slots')();
  @override String get tableName => 'decorations';
}

class Charms extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  IntColumn get numSlots => integer().named('num_slots')();
  IntColumn get skillTree1Id => integer().named('skill_tree_1_id').references(SkillTrees, #id)();
  IntColumn get skillTree1Amount => integer().named('skill_tree_1_amount')();
  IntColumn get skillTree2Id => integer().named('skill_tree_2_id').nullable().references(SkillTrees, #id)();
  IntColumn get skillTree2Amount => integer().named('skill_tree_2_amount').nullable()();
  @override String get tableName => 'charms';
}

class ArenaQuests extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  TextColumn get name => text()();
  TextColumn get goal => text()();
  IntColumn get locationId => integer().named('location_id').references(Locations, #id)();
  IntColumn get reward => integer()();
  IntColumn get numParticipants => integer().named('num_participants')();
  TextColumn get timeS => text().named('time_s')();
  TextColumn get timeA => text().named('time_a')();
  TextColumn get timeB => text().named('time_b')();
  @override String get tableName => 'arena_quests';
}

class MonsterToArena extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  IntColumn get monsterId => integer().named('monster_id').references(Monsters, #id)();
  IntColumn get arenaId => integer().named('arena_id').references(ArenaQuests, #id)();
  @override String get tableName => 'monster_to_arena';
}

class ArenaRewards extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  IntColumn get arenaId => integer().named('arena_id').references(ArenaQuests, #id)();
  IntColumn get itemId => integer().named('item_id').references(Items, #id)();
  IntColumn get percentage => integer()();
  IntColumn get stackSize => integer().named('stack_size')();
  @override String get tableName => 'arena_rewards';
}

class HuntingFleet extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  TextColumn get type => text()();
  IntColumn get level => integer()();
  TextColumn get location => text()();
  IntColumn get itemId => integer().named('item_id').references(Items, #id)();
  IntColumn get amount => integer()();
  IntColumn get percentage => integer()();
  TextColumn get rank => text()();
  @override String get tableName => 'hunting_fleet';
}

class MogaWoodsRewards extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  IntColumn get monsterId => integer().named('monster_id').references(Monsters, #id)();
  TextColumn get time => text()();
  IntColumn get itemId => integer().named('item_id').references(Items, #id)();
  IntColumn get commodityStars => integer().named('commodity_stars').nullable()();
  IntColumn get killPercentage => integer().named('kill_percentage')();
  IntColumn get capturePercentage => integer().named('capture_percentage').nullable()();
  @override String get tableName => 'moga_woods_rewards';
}

class HornMelodies extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  TextColumn get notes => text()();
  TextColumn get song => text()();
  TextColumn get effect1 => text()();
  TextColumn get effect2 => text()();
  TextColumn get duration => text()();
  TextColumn get extension => text()();
  @override String get tableName => 'horn_melodies';
}

class Wyporium extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  IntColumn get itemInId => integer().named('item_in_id').references(Items, #id)();
  IntColumn get itemOutId => integer().named('item_out_id').references(Items, #id)();
  IntColumn get unlockQuestId => integer().named('unlock_quest_id').nullable().references(Quests, #id)();
  @override String get tableName => 'wyporium';
}

class Trading extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  IntColumn get locationId => integer().named('location_id').references(Locations, #id)();
  IntColumn get offerItemId => integer().named('offer_item_id').references(Items, #id)();
  IntColumn get receiveItemId => integer().named('receive_item_id').references(Items, #id)();
  IntColumn get percentage => integer()();
  @override String get tableName => 'trading';
}

class Planting extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  IntColumn get plantedItemId => integer().named('planted_item_id').references(Items, #id)();
  IntColumn get receivedItemId => integer().named('received_item_id').references(Items, #id)();
  IntColumn get stackSize => integer().named('stack_size')();
  IntColumn get percentage => integer()();
  TextColumn get poolType => text().named('pool_type')();
  @override String get tableName => 'planting';
}

class FelyneSkills extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  TextColumn get skillName => text().named('skill_name')();
  TextColumn get description => text()();
  @override String get tableName => 'felyne_skills';
}

class FoodCombos extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  TextColumn get ingredient1 => text()();
  TextColumn get ingredient2 => text()();
  TextColumn get cooked => text()();
  TextColumn get bonus => text()();
  IntColumn get skill1Id => integer().named('skill1_id').nullable().references(FelyneSkills, #id)();
  IntColumn get skill2Id => integer().named('skill2_id').nullable().references(FelyneSkills, #id)();
  IntColumn get skill3Id => integer().named('skill3_id').nullable().references(FelyneSkills, #id)();
  @override String get tableName => 'food_combos';
}

class Wishlist extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  TextColumn get name => text()();
  @override String get tableName => 'wishlist';
}

class WishlistEntries extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  IntColumn get wishlistId => integer().named('wishlist_id').references(Wishlist, #id)();
  IntColumn get itemId => integer().named('item_id').references(Items, #id)();
  IntColumn get quantity => integer()();
  IntColumn get satisfied => integer().withDefault(const Constant(0))();
  TextColumn get path => text()();
  @override String get tableName => 'wishlist_data'; // Dart class renamed to WishlistEntries to avoid conflict
}

class WishlistComponent extends Table {
  IntColumn get id => integer().named('_id').autoIncrement()();
  IntColumn get wishlistId => integer().named('wishlist_id').references(Wishlist, #id)();
  IntColumn get componentId => integer().named('component_id').references(Items, #id)();
  IntColumn get quantity => integer()();
  IntColumn get notes => integer().withDefault(const Constant(0))();
  @override String get tableName => 'wishlist_component';
}

// ─── Database class ───────────────────────────────────────────────────────────

@DriftDatabase(tables: [
  Locations,
  Items, Components, Combining,
  Monsters, MonsterDamage, MonsterWeakness, MonsterHabitat,
  HuntingRewards, MonsterAilment, MonsterStatus,
  MonsterToQuest, MonsterToArena,
  Weapons,
  Armor,
  SkillTrees, Skills, ItemToSkillTree,
  Quests, QuestRewards, QuestPrereqs,
  Decorations, Charms,
  ArenaQuests, ArenaRewards,
  Gathering, HuntingFleet, MogaWoodsRewards,
  Planting, Wyporium, Trading,
  FelyneSkills, FoodCombos,
  HornMelodies,
  Wishlist, WishlistEntries, WishlistComponent,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => await m.createAll(),
  );
}

/// Copies the bundled mh4u.db asset to app documents on first run,
/// then opens it as a NativeDatabase.
QueryExecutor openAppDatabase() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File('${dbFolder.path}/mh4u.db');
    if (!file.existsSync()) {
      final bytes = await rootBundle.load('assets/data/mh4u.db');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    }
    return NativeDatabase(file);
  });
}
