import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/monster_repository.dart';
import '../../widgets/shared_widgets.dart';

final _monsterSearchProvider = StateProvider<String>((ref) => '');
final _monsterClassFilterProvider = StateProvider<String?>((ref) => null);

class MonsterListScreen extends ConsumerWidget {
  const MonsterListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(_monsterSearchProvider);
    final classFilter = ref.watch(_monsterClassFilterProvider);
    final classesAsync = ref.watch(monsterClassesProvider);
    final monstersAsync = ref.watch(monsterListProvider((
      search: search.isEmpty ? null : search,
      monsterClass: classFilter,
      includeMinions: false,
    )));

    return Scaffold(
      appBar: AppBar(
        title: const Text('MONSTERS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showClassFilter(context, ref, classFilter, classesAsync.valueOrNull ?? []),
          ),
        ],
      ),
      body: Column(
        children: [
          MhSearchBar(
            hint: 'Search monsters...',
            onChanged: (v) => ref.read(_monsterSearchProvider.notifier).state = v,
          ),
          if (classFilter != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Chip(
                    label: Text(classFilter),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () =>
                        ref.read(_monsterClassFilterProvider.notifier).state = null,
                  ),
                ],
              ),
            ),
          Expanded(
            child: AsyncStateWidget<List<Monster>>(
              state: monstersAsync,
              builder: (monsters) {
                if (monsters.isEmpty) return const EmptyState(message: 'No monsters found');
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: monsters.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _MonsterCard(monster: monsters[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showClassFilter(
    BuildContext context,
    WidgetRef ref,
    String? current,
    List<String> classes,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Filter by Class',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: classes.length,
              itemBuilder: (_, i) => ListTile(
                title: Text(classes[i]),
                trailing: current == classes[i]
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  ref.read(_monsterClassFilterProvider.notifier).state =
                      current == classes[i] ? null : classes[i];
                  Navigator.pop(context);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _MonsterCard extends StatelessWidget {
  final Monster monster;
  const _MonsterCard({required this.monster});

  @override
  Widget build(BuildContext context) {
    final isElder = monster.monsterClass == 'Elder Dragon';

    return GestureDetector(
      onTap: () => context.push('/monsters/${monster.id}'),
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
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(Icons.catching_pokemon,
                  color: AppColors.onSurfaceMuted, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(monster.name,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(monster.monsterClass,
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                      if (isElder) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.elementDragon.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Elder Dragon',
                              style: TextStyle(
                                color: AppColors.elementDragon,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      ],
                    ],
                  ),
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
