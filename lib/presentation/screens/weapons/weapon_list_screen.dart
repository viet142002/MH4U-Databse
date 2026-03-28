import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/weapon_repository.dart';
import '../../../domain/entities/weapon_entity.dart';
import '../../widgets/shared_widgets.dart';

final _weaponSearchProvider = StateProvider<String>((ref) => '');
final _weaponTypeProvider = StateProvider<String>((ref) => 'Great Sword');

class WeaponListScreen extends ConsumerWidget {
  const WeaponListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(_weaponTypeProvider);
    final search = ref.watch(_weaponSearchProvider);
    final typesAsync = ref.watch(weaponTypesProvider);
    final weaponsAsync = ref.watch(weaponListProvider((
      search: search.isEmpty ? null : search,
      wtype: selectedType,
    )));

    return Scaffold(
      appBar: AppBar(
        title: const Text('WEAPONS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree),
            tooltip: 'Upgrade Tree',
            onPressed: () => context.push(
              '/weapons/tree/${Uri.encodeComponent(selectedType)}',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          MhSearchBar(
            hint: 'Search weapons...',
            onChanged: (v) => ref.read(_weaponSearchProvider.notifier).state = v,
          ),
          // Weapon type tabs
          AsyncStateWidget<List<String>>(
            state: typesAsync,
            loadingWidget: const SizedBox(height: 38),
            builder: (types) => SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: types.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final t = types[i];
                  final selected = t == selectedType;
                  return GestureDetector(
                    onTap: () =>
                        ref.read(_weaponTypeProvider.notifier).state = t,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _shortName(t),
                        style: TextStyle(
                          color: selected ? Colors.black : AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AsyncStateWidget<List<WeaponListItem>>(
              state: weaponsAsync,
              builder: (weapons) {
                if (weapons.isEmpty) return const EmptyState(message: 'No weapons found');
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: weapons.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _WeaponCard(weapon: weapons[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _shortName(String type) {
    const map = {
      'Great Sword': 'GS', 'Long Sword': 'LS', 'Sword and Shield': 'SnS',
      'Dual Blades': 'DB', 'Hammer': 'Ham', 'Hunting Horn': 'HH',
      'Lance': 'Lnc', 'Gunlance': 'GL', 'Switch Axe': 'SA',
      'Charge Blade': 'CB', 'Insect Glaive': 'IG',
      'Light Bowgun': 'LBG', 'Heavy Bowgun': 'HBG', 'Bow': 'Bow',
    };
    return map[type] ?? type;
  }
}

class _WeaponCard extends StatelessWidget {
  final WeaponListItem weapon;
  const _WeaponCard({required this.weapon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/weapons/${weapon.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: weapon.isFinal
                ? AppColors.primary.withOpacity(0.4)
                : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.architecture,
                  color: AppColors.onSurfaceMuted, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                        child: Text(weapon.name,
                            style: Theme.of(context).textTheme.titleMedium)),
                    RarityBadge(rarity: weapon.rarity),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    _StatChip(Icons.flash_on, weapon.attack.toString(),
                        AppColors.primary),
                    if (weapon.affinity != 0) ...[
                      const SizedBox(width: 6),
                      _StatChip(
                        Icons.percent,
                        '${weapon.affinity > 0 ? '+' : ''}${weapon.affinity}%',
                        weapon.affinity > 0
                            ? AppColors.elementThunder
                            : AppColors.error,
                      ),
                    ],
                    if (weapon.element != null && weapon.element!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      ElementChip(
                        element: weapon.element!,
                        value: weapon.elementAttack,
                      ),
                    ],
                    const Spacer(),
                    if (weapon.numSlots > 0)
                      Text('${'◯' * weapon.numSlots}',
                          style: const TextStyle(
                              color: AppColors.onSurfaceMuted, fontSize: 12)),
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

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _StatChip(this.icon, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 2),
      Text(value,
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    ]);
  }
}
