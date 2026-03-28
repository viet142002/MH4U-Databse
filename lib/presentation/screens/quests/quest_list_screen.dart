import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/entities/other_entities.dart';
import '../../widgets/shared_widgets.dart';

// ── Filter record type ────────────────────────────────────────────────────────

typedef QuestFilter = ({String? search, String? hub, String? type});

// ── Providers ─────────────────────────────────────────────────────────────────

final _questSearchProvider = StateProvider<String>((ref) => '');
final _questHubFilterProvider = StateProvider<String?>((ref) => null);
final _questTypeFilterProvider = StateProvider<String?>((ref) => null);

/// Manual FutureProvider.family — avoids @riverpod generator issues
/// with named optional params on complex return types.
final questListProvider =
    FutureProvider.family<List<QuestListItem>, QuestFilter>(
  (ref, filter) async {
    final db = ref.watch(databaseProvider);

    final conditions = <String>[];
    if (filter.search != null && filter.search!.isNotEmpty) {
      final s = filter.search!.replaceAll("'", "''");
      conditions.add("q.name LIKE '%$s%'");
    }
    if (filter.hub != null) {
      final h = filter.hub!.replaceAll("'", "''");
      conditions.add("q.hub = '$h'");
    }
    if (filter.type != null) {
      final t = filter.type!.replaceAll("'", "''");
      conditions.add("q.type = '$t'");
    }
    final where = conditions.isEmpty ? '' : 'AND ${conditions.join(' AND ')}';

    final rows = await db.customSelect(
      '''SELECT q._id, q.name, q.hub, q.type, q.stars, q.reward,
                COALESCE(l.name, 'Unknown') as location_name
         FROM quests q
         LEFT JOIN locations l ON l._id = q.location_id
         WHERE 1=1 $where
         ORDER BY q.stars DESC, q.name ASC''',
    ).get();

    return rows
        .map((r) => QuestListItem(
              id: r.read<int>('_id'),
              name: r.read<String>('name'),
              hub: r.read<String>('hub'),
              type: r.read<String>('type'),
              stars: r.read<int>('stars'),
              reward: r.read<int>('reward'),
              locationName: r.read<String>('location_name'),
            ))
        .toList();
  },
);

final questDetailProvider =
    FutureProvider.family<QuestEntity?, int>((ref, questId) async {
  final db = ref.watch(databaseProvider);

  // Single raw SQL query for quest + location
  final questRows = await db.customSelect(
    '''SELECT q.*, l.name as location_name
       FROM quests q
       LEFT JOIN locations l ON l._id = q.location_id
       WHERE q._id = $questId''',
  ).get();
  if (questRows.isEmpty) return null;
  final q = questRows.first;

  // Monsters in this quest
  final monsterRows = await db.customSelect(
    '''SELECT m._id, m.name, mtq.unstable
       FROM monster_to_quest mtq
       JOIN monsters m ON m._id = mtq.monster_id
       WHERE mtq.quest_id = $questId''',
  ).get();

  // Rewards with item names
  final rewardRows = await db.customSelect(
    '''SELECT qr.reward_slot, qr.percentage, qr.stack_size, i.name as item_name
       FROM quest_rewards qr
       JOIN items i ON i._id = qr.item_id
       WHERE qr.quest_id = $questId
       ORDER BY qr.percentage DESC''',
  ).get();

  return QuestEntity(
    id: q.read<int>('_id'),
    name: q.read<String>('name'),
    goal: q.read<String>('goal'),
    hub: q.read<String>('hub'),
    type: q.read<String>('type'),
    stars: q.read<int>('stars'),
    reward: q.read<int>('reward'),
    fee: q.read<int>('fee'),
    timeLimit: q.read<int>('time_limit'),
    locationName: q.readNullable<String>('location_name') ?? 'Unknown',
    hrp: q.readNullable<int>('hrp'),
    subGoal: q.readNullable<String>('sub_goal'),
    subReward: q.readNullable<int>('sub_reward'),
    monsters: monsterRows
        .map((r) => QuestMonsterEntry(
              monsterId: r.read<int>('_id'),
              monsterName: r.read<String>('name'),
              isUnstable: r.readNullable<String>('unstable') == 'yes',
            ))
        .toList(),
    rewards: rewardRows
        .map((r) => QuestRewardEntry(
              itemName: r.read<String>('item_name'),
              rewardSlot: r.read<String>('reward_slot'),
              percentage: r.read<int>('percentage'),
              stackSize: r.read<int>('stack_size'),
            ))
        .toList(),
  );
});

// ── Quest List Screen ─────────────────────────────────────────────────────────

class QuestListScreen extends ConsumerWidget {
  const QuestListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(_questSearchProvider);
    final hubFilter = ref.watch(_questHubFilterProvider);
    final typeFilter = ref.watch(_questTypeFilterProvider);

    final questsAsync = ref.watch(questListProvider((
      search: search.isEmpty ? null : search,
      hub: hubFilter,
      type: typeFilter,
    )));

    return Scaffold(
      appBar: AppBar(title: const Text('QUESTS')),
      body: Column(
        children: [
          MhSearchBar(
            hint: 'Search quests...',
            onChanged: (v) => ref.read(_questSearchProvider.notifier).state = v,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Row(
              children: ['Caravan', 'Guild', 'Event'].map((h) {
                final sel = hubFilter == h;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(h, style: const TextStyle(fontSize: 12)),
                    selected: sel,
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                    onSelected: (_) => ref
                        .read(_questHubFilterProvider.notifier)
                        .state = sel ? null : h,
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: ['Key', 'Normal', 'Urgent'].map((t) {
                final sel = typeFilter == t;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(t, style: const TextStyle(fontSize: 12)),
                    selected: sel,
                    selectedColor: AppColors.secondary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.secondary,
                    onSelected: (_) => ref
                        .read(_questTypeFilterProvider.notifier)
                        .state = sel ? null : t,
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: AsyncStateWidget<List<QuestListItem>>(
              state: questsAsync,
              builder: (quests) {
                if (quests.isEmpty) {
                  return const EmptyState(message: 'No quests found');
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: quests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _QuestCard(quest: quests[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final QuestListItem quest;
  const _QuestCard({required this.quest});

  Color get _hubColor {
    switch (quest.hub) {
      case 'Caravan':
        return const Color(0xFF66BB6A);
      case 'Guild':
        return const Color(0xFF42A5F5);
      default:
        return AppColors.secondary;
    }
  }

  Color get _typeColor {
    switch (quest.type) {
      case 'Key':
        return AppColors.primary;
      case 'Urgent':
        return AppColors.secondary;
      default:
        return AppColors.onSurfaceMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/quests/${quest.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: quest.type == 'Urgent'
                ? AppColors.secondary.withValues(alpha: 0.4)
                : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                '★' * quest.stars.clamp(0, 7),
                style: const TextStyle(
                    color: AppColors.primary, fontSize: 9, letterSpacing: 1),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(quest.name,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Row(children: [
                    _Tag(quest.hub, _hubColor),
                    const SizedBox(width: 6),
                    _Tag(quest.type, _typeColor),
                    const SizedBox(width: 6),
                    Text(quest.locationName,
                        style: Theme.of(context).textTheme.bodySmall),
                  ]),
                ],
              ),
            ),
            Text('${quest.reward}z',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            const Icon(Icons.chevron_right, color: AppColors.onSurfaceMuted),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Quest Detail Screen ───────────────────────────────────────────────────────

class QuestDetailScreen extends ConsumerWidget {
  final int id;
  const QuestDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questAsync = ref.watch(questDetailProvider(id));
    return AsyncStateWidget<QuestEntity?>(
      state: questAsync,
      builder: (quest) {
        if (quest == null) {
          return Scaffold(appBar: AppBar(), body: const EmptyState());
        }
        return Scaffold(
          appBar: AppBar(title: Text(quest.name.toUpperCase())),
          body: ListView(
            children: [
              const SectionHeader(title: 'QUEST INFO'),
              StatRow(label: 'Hub', value: quest.hub),
              StatRow(label: 'Type', value: quest.type),
              StatRow(label: 'Stars', value: '★' * quest.stars),
              StatRow(label: 'Reward', value: '${quest.reward}z'),
              StatRow(label: 'Fee', value: '${quest.fee}z'),
              StatRow(label: 'Time Limit', value: '${quest.timeLimit} min'),
              StatRow(label: 'Location', value: quest.locationName),
              if (quest.hrp != null)
                StatRow(label: 'HRP', value: '${quest.hrp}'),
              const SectionHeader(title: 'OBJECTIVE'),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(quest.goal,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
              if (quest.subGoal != null && quest.subGoal!.isNotEmpty) ...[
                const SectionHeader(title: 'SUB OBJECTIVE'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(quest.subGoal!,
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
                if (quest.subReward != null)
                  StatRow(label: 'Sub Reward', value: '${quest.subReward}z'),
              ],
              if (quest.monsters.isNotEmpty) ...[
                const SectionHeader(title: 'MONSTERS'),
                ...quest.monsters.map((m) => ListTile(
                      leading: const Icon(Icons.catching_pokemon,
                          color: AppColors.primary, size: 20),
                      title: Text(m.monsterName),
                      trailing: m.isUnstable
                          ? const Chip(label: Text('Unstable'))
                          : null,
                      dense: true,
                      onTap: () => context.push('/monsters/${m.monsterId}'),
                    )),
              ],
              if (quest.rewards.isNotEmpty) ...[
                const SectionHeader(title: 'REWARDS'),
                ..._buildRewards(context, quest.rewards),
              ],
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  String _slotLabel(String slot) {
    switch (slot) {
      case 'A':
        return 'Main Reward';
      case 'B':
        return 'Bonus Reward';
      case 'Sub':
        return 'Sub Reward';
      default:
        return slot;
    }
  }

  List<Widget> _buildRewards(BuildContext ctx, List<QuestRewardEntry> rewards) {
    final grouped = <String, List<QuestRewardEntry>>{};
    for (final r in rewards) {
      grouped.putIfAbsent(r.rewardSlot, () => []).add(r);
    }
    final result = <Widget>[];
    // DB uses 'A' (main reward), 'B' (bonus), 'Sub' (sub reward)
    for (final slot in ['A', 'Sub', 'B']) {
      if (!grouped.containsKey(slot)) continue;
      result.add(Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Text(_slotLabel(slot),
            style:
                const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12)),
      ));
      for (final r in grouped[slot]!) {
        result.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: [
            Expanded(
                child: Text(r.itemName, style: const TextStyle(fontSize: 13))),
            Text('x${r.stackSize}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.onSurfaceMuted)),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('${r.percentage}%',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
          ]),
        ));
      }
    }
    return result;
  }
}
