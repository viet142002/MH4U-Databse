abstract final class AppConstants {
  static const appName = 'MH4U Database';
  static const dbName = 'mh4u.db';
  static const dbVersion = 1;
  static const pageSize = 30;
}

abstract final class WeaponType {
  static const greatsword = 'Great Sword';
  static const longsword = 'Long Sword';
  static const swordAndShield = 'Sword and Shield';
  static const dualBlades = 'Dual Blades';
  static const hammer = 'Hammer';
  static const huntingHorn = 'Hunting Horn';
  static const lance = 'Lance';
  static const gunlance = 'Gunlance';
  static const switchAxe = 'Switch Axe';
  static const chargeBlade = 'Charge Blade';
  static const insectGlaive = 'Insect Glaive';
  static const bowgun = 'Bowgun';
  static const bow = 'Bow';

  static const all = [
    greatsword, longsword, swordAndShield, dualBlades,
    hammer, huntingHorn, lance, gunlance, switchAxe,
    chargeBlade, insectGlaive, bowgun, bow,
  ];
}

abstract final class MonsterType {
  static const bird = 'Bird Wyvern';
  static const brute = 'Brute Wyvern';
  static const fanged = 'Fanged Beast';
  static const flying = 'Flying Wyvern';
  static const carapaceon = 'Carapaceon';
  static const piscine = 'Piscine';
  static const leviathan = 'Leviathan';
  static const elder = 'Elder Dragon';
  static const neopteron = 'Neopteron';
}

abstract final class ElementType {
  static const fire = 'Fire';
  static const water = 'Water';
  static const thunder = 'Thunder';
  static const ice = 'Ice';
  static const dragon = 'Dragon';
  static const poison = 'Poison';
  static const sleep = 'Sleep';
  static const paralysis = 'Paralysis';
  static const blast = 'Blast';
  static const none = 'None';
}

abstract final class QuestType {
  static const village = 'Village';
  static const guild = 'Guild';
  static const special = 'Special';
}

abstract final class Rank {
  static const low = 'Low Rank';
  static const high = 'High Rank';
  static const g = 'G Rank';
}
