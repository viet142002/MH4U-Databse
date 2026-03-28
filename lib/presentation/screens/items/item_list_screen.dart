import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/entities/other_entities.dart';
import '../../widgets/shared_widgets.dart';

// ── Filter type ───────────────────────────────────────────────────────────────

typedef ItemFilter = ({String? search, String? type});

// ── Providers ─────────────────────────────────────────────────────────────────

final _itemSearchProvider = StateProvider<String>((ref) => '');
final _itemTypeFilterProvider = StateProvider<String?>((ref) => null);

final itemListProvider =
    FutureProvider.family<List<Item>, ItemFilter>((ref, filter) async {
  final db = ref.watch(databaseProvider);

  final conditions = <String>[];
  if (filter.search != null && filter.search!.isNotEmpty) {
    final s = filter.search!.replaceAll("'", "''");
    conditions.add("name LIKE '%$s%'");
  }
  if (filter.type != null && filter.type!.isNotEmpty) {
    final t = filter.type!.replaceAll("'", "''");
    conditions.add("type = '$t'");
  }
  final where =
      conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';

  // Use CAST(col AS INTEGER) so that empty-string values stored in the
  // real MH4U SQLite DB are coerced to 0, preventing int.parse() failures.
  final rows = await db.customSelect(
    '''
    SELECT _id, name, type, sub_type,
           COALESCE(CAST(rarity         AS INTEGER), 0) AS rarity,
           COALESCE(CAST(carry_capacity AS INTEGER), 0) AS carry_capacity,
           CAST(buy  AS INTEGER) AS buy,
           CAST(sell AS INTEGER) AS sell,
           description, icon_name,
           COALESCE(armor_dupe_name_fix, '') AS armor_dupe_name_fix
    FROM items
    $where
    ORDER BY name ASC
    ''',
  ).get();

  return rows
      .map((r) => Item(
            id: r.read<int>('_id'),
            name: r.read<String>('name'),
            nameDe: '',
            nameFr: '',
            nameEs: '',
            nameIt: '',
            nameJp: null,
            type: r.read<String>('type'),
            subType: r.read<String>('sub_type'),
            rarity: r.read<int>('rarity'),
            carryCapacity: r.read<int>('carry_capacity'),
            buy: r.readNullable<int>('buy'),
            sell: r.readNullable<int>('sell'),
            description: r.readNullable<String>('description'),
            iconName: r.readNullable<String>('icon_name'),
            armorDupeNameFix: r.read<String>('armor_dupe_name_fix'),
          ))
      .toList();
});


final itemDetailProvider =
    FutureProvider.family<ItemEntity?, int>((ref, itemId) async {
  final db = ref.watch(databaseProvider);

  // customSelect with CAST so empty-string integers in the real MH4U DB
  // don't crash int.parse inside Drift's typeMapping.
  final itemRows = await db.customSelect(
    '''
    SELECT _id, name, type, sub_type,
           COALESCE(CAST(rarity         AS INTEGER), 0) AS rarity,
           COALESCE(CAST(carry_capacity AS INTEGER), 0) AS carry_capacity,
           CAST(buy  AS INTEGER) AS buy,
           CAST(sell AS INTEGER) AS sell,
           description, icon_name
    FROM items
    WHERE _id = $itemId
    ''',
  ).get();
  if (itemRows.isEmpty) return null;
  final itemRow = itemRows.first;

  // Combining recipes — CAST all three numeric columns
  final combineRows = await db.customSelect(
    '''
    SELECT i1.name AS ing1, i2.name AS ing2,
           COALESCE(CAST(c.amount_made_min AS INTEGER), 0) AS amount_made_min,
           COALESCE(CAST(c.amount_made_max AS INTEGER), 0) AS amount_made_max,
           COALESCE(CAST(c.percentage      AS INTEGER), 0) AS percentage
    FROM combining c
    JOIN items i1 ON i1._id = c.item_1_id
    JOIN items i2 ON i2._id = c.item_2_id
    WHERE c.created_item_id = $itemId
    ''',
  ).get();

  final recipes = combineRows
      .map((r) => CombineRecipe(
            ingredient1: r.read<String>('ing1'),
            ingredient2: r.read<String>('ing2'),
            amountMin: r.read<int>('amount_made_min'),
            amountMax: r.read<int>('amount_made_max'),
            percentage: r.read<int>('percentage'),
          ))
      .toList();

  return ItemEntity(
    id: itemRow.read<int>('_id'),
    name: itemRow.read<String>('name'),
    type: itemRow.read<String>('type'),
    subType: itemRow.read<String>('sub_type'),
    rarity: itemRow.read<int>('rarity'),
    carryCapacity: itemRow.read<int>('carry_capacity'),
    buy: itemRow.readNullable<int>('buy'),
    sell: itemRow.readNullable<int>('sell'),
    description: itemRow.readNullable<String>('description'),
    iconName: itemRow.readNullable<String>('icon_name'),
    recipes: recipes,
  );
});

// ── Item List Screen ──────────────────────────────────────────────────────────

class ItemListScreen extends ConsumerWidget {
  const ItemListScreen({super.key});

  static const _types = [
    'Material', 'Consumable', 'Ammo', 'Coating',
    'Tool', 'Trap', 'Account',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(_itemSearchProvider);
    final typeFilter = ref.watch(_itemTypeFilterProvider);
    final itemsAsync = ref.watch(itemListProvider((
      search: search.isEmpty ? null : search,
      type: typeFilter,
    )));

    return Scaffold(
      appBar: AppBar(title: const Text('ITEMS')),
      body: Column(
        children: [
          MhSearchBar(
            hint: 'Search items...',
            onChanged: (v) => ref.read(_itemSearchProvider.notifier).state = v,
          ),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _types.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final t = _types[i];
                final selected = typeFilter == t;
                return GestureDetector(
                  onTap: () => ref
                      .read(_itemTypeFilterProvider.notifier)
                      .state = selected ? null : t,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(t,
                        style: TextStyle(
                          color: selected ? Colors.black : AppColors.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AsyncStateWidget<List<Item>>(
              state: itemsAsync,
              builder: (items) {
                if (items.isEmpty) return const EmptyState(message: 'No items found');
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _ItemCard(item: items[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final Item item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/items/${item.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory_2,
                  color: AppColors.onSurfaceMuted, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                        child: Text(item.name,
                            style: Theme.of(context).textTheme.titleMedium)),
                    RarityBadge(rarity: item.rarity),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(item.type,
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                    const Spacer(),
                    if (item.sell != null && item.sell! > 0)
                      Text('${item.sell}z',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                  ]),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.onSurfaceMuted),
          ],
        ),
      ),
    );
  }
}

// ── Item Detail Screen ────────────────────────────────────────────────────────

class ItemDetailScreen extends ConsumerWidget {
  final int id;
  const ItemDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemDetailProvider(id));
    return AsyncStateWidget<ItemEntity?>(
      state: itemAsync,
      builder: (item) {
        if (item == null) {
          return Scaffold(appBar: AppBar(), body: const EmptyState());
        }
        return Scaffold(
          appBar: AppBar(title: Text(item.name.toUpperCase())),
          body: ListView(
            children: [
              const SectionHeader(title: 'DETAILS'),
              StatRow(label: 'Type', value: item.type),
              if (item.subType.isNotEmpty)
                StatRow(label: 'Sub Type', value: item.subType),
              StatRow(label: 'Rarity', value: 'R${item.rarity}'),
              StatRow(label: 'Carry', value: '${item.carryCapacity}'),
              if (item.buy != null && item.buy! > 0)
                StatRow(label: 'Buy', value: '${item.buy}z'),
              if (item.sell != null && item.sell! > 0)
                StatRow(label: 'Sell', value: '${item.sell}z'),
              if (item.description != null && item.description!.isNotEmpty) ...[
                const Divider(indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(item.description!,
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
              ],
              if (item.recipes.isNotEmpty) ...[
                const SectionHeader(title: 'COMBINE RECIPE'),
                ...item.recipes.map((r) => _RecipeRow(recipe: r)),
              ],
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class _RecipeRow extends StatelessWidget {
  final CombineRecipe recipe;
  const _RecipeRow({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
              child: Text(recipe.ingredient1,
                  style: Theme.of(context).textTheme.bodyMedium)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.add, size: 16, color: AppColors.onSurfaceMuted),
          ),
          Expanded(
              child: Text(recipe.ingredient2,
                  style: Theme.of(context).textTheme.bodyMedium)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${recipe.percentage}%',
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
              Text(
                recipe.amountMin == recipe.amountMax
                    ? 'x${recipe.amountMin}'
                    : 'x${recipe.amountMin}-${recipe.amountMax}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
