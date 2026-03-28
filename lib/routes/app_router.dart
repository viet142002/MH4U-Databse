import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/screens/main_shell.dart';
import '../presentation/screens/monsters/monster_list_screen.dart';
import '../presentation/screens/monsters/monster_detail_screen.dart';
import '../presentation/screens/weapons/weapon_list_screen.dart';
import '../presentation/screens/weapons/weapon_detail_screen.dart';
import '../presentation/screens/weapons/weapon_tree_screen.dart';
import '../presentation/screens/armor/armor_list_screen.dart';
import '../presentation/screens/armor/armor_detail_screen.dart';
import '../presentation/screens/items/item_list_screen.dart';
import '../presentation/screens/items/item_detail_screen.dart';
import '../presentation/screens/quests/quest_list_screen.dart';
import '../presentation/screens/quests/quest_detail_screen.dart';

abstract final class AppRoutes {
  static const monsters = '/monsters';
  static const monsterDetail = '/monsters/:id';
  static const weapons = '/weapons';
  static const weaponDetail = '/weapons/:id';
  static const weaponTree = '/weapons/tree/:type';
  static const armor = '/armor';
  static const armorDetail = '/armor/:id';
  static const items = '/items';
  static const itemDetail = '/items/:id';
  static const quests = '/quests';
  static const questDetail = '/quests/:id';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.monsters,
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.monsters,
          builder: (context, state) => const MonsterListScreen(),
        ),
        GoRoute(
          path: AppRoutes.weapons,
          builder: (context, state) => const WeaponListScreen(),
        ),
        GoRoute(
          path: AppRoutes.armor,
          builder: (context, state) => const ArmorListScreen(),
        ),
        GoRoute(
          path: AppRoutes.items,
          builder: (context, state) => const ItemListScreen(),
        ),
        GoRoute(
          path: AppRoutes.quests,
          builder: (context, state) => const QuestListScreen(),
        ),
      ],
    ),
    // Detail screens (full screen, outside shell)
    GoRoute(
      path: AppRoutes.monsterDetail,
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return MonsterDetailScreen(id: id);
      },
    ),
    GoRoute(
      path: AppRoutes.weaponDetail,
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return WeaponDetailScreen(id: id);
      },
    ),
    GoRoute(
      path: AppRoutes.weaponTree,
      builder: (context, state) {
        final type = state.pathParameters['type']!;
        return WeaponTreeScreen(weaponType: Uri.decodeComponent(type));
      },
    ),
    GoRoute(
      path: AppRoutes.armorDetail,
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return ArmorDetailScreen(id: id);
      },
    ),
    GoRoute(
      path: AppRoutes.itemDetail,
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return ItemDetailScreen(id: id);
      },
    ),
    GoRoute(
      path: AppRoutes.questDetail,
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return QuestDetailScreen(id: id);
      },
    ),
  ],
);
