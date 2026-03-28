import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/armor_repository.dart';
import '../../../domain/entities/other_entities.dart';
import '../../widgets/shared_widgets.dart';

final _armorSearchProvider = StateProvider<String>((ref) => '');
final _armorSlotFilterProvider = StateProvider<String?>((ref) => null);
final _armorHunterTypeProvider = StateProvider<String?>((ref) => null);

class ArmorListScreen extends ConsumerWidget {
  const ArmorListScreen({super.key});

  static const _slots = ['Head', 'Body', 'Arms', 'Waist', 'Legs'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(_armorSearchProvider);
    final slotFilter = ref.watch(_armorSlotFilterProvider);
    final hunterFilter = ref.watch(_armorHunterTypeProvider);
    final armorAsync = ref.watch(armorListProvider((
      search: search.isEmpty ? null : search,
      slot: slotFilter,
      hunterType: hunterFilter,
    )));

    return Scaffold(
      appBar: AppBar(title: const Text('ARMOR')),
      body: Column(
        children: [
          MhSearchBar(
            hint: 'Search armor...',
            onChanged: (v) => ref.read(_armorSearchProvider.notifier).state = v,
          ),
          // Slot filter
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _slots.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final slot = _slots[i];
                final selected = slotFilter == slot;
                return GestureDetector(
                  onTap: () => ref.read(_armorSlotFilterProvider.notifier).state =
                      selected ? null : slot,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(slot,
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
          // Hunter type filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: ['Blademaster', 'Gunner'].map((t) {
                final selected = hunterFilter == t;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(t, style: const TextStyle(fontSize: 12)),
                    selected: selected,
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                    onSelected: (_) =>
                        ref.read(_armorHunterTypeProvider.notifier).state =
                            selected ? null : t,
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: AsyncStateWidget<List<ArmorListItem>>(
              state: armorAsync,
              builder: (items) {
                if (items.isEmpty) return const EmptyState(message: 'No armor found');
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _ArmorCard(item: items[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ArmorCard extends StatelessWidget {
  final ArmorListItem item;
  const _ArmorCard({required this.item});

  Color get _slotColor {
    switch (item.slot) {
      case 'Head': return const Color(0xFF42A5F5);
      case 'Body': return const Color(0xFF66BB6A);
      case 'Arms': return const Color(0xFFFFCA28);
      case 'Waist': return const Color(0xFFFF7043);
      case 'Legs': return const Color(0xFFAB47BC);
      default: return AppColors.onSurfaceMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/armor/${item.id}'),
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _slotColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _slotColor.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(item.slot[0],
                    style: TextStyle(
                        color: _slotColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
              ),
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
                    const Icon(Icons.shield, size: 13, color: AppColors.primary),
                    const SizedBox(width: 3),
                    Text('${item.defense}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 10),
                    Text(item.hunterType,
                        style: Theme.of(context).textTheme.bodySmall),
                    const Spacer(),
                    if ((item.numSlots) > 0)
                      Text('${'◯' * item.numSlots}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.onSurfaceMuted)),
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
