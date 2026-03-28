import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/monster_repository.dart';
import '../../../domain/entities/monster_entity.dart';
import '../../widgets/shared_widgets.dart';

class MonsterDetailScreen extends ConsumerWidget {
  final int id;
  const MonsterDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(monsterDetailProvider(id));
    return AsyncStateWidget<MonsterEntity?>(
      state: detailAsync,
      builder: (monster) {
        if (monster == null) {
          return Scaffold(appBar: AppBar(), body: const EmptyState(message: 'Monster not found'));
        }
        return _MonsterDetailView(monster: monster);
      },
    );
  }
}

class _MonsterDetailView extends StatelessWidget {
  final MonsterEntity monster;
  const _MonsterDetailView({required this.monster});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              title: Text(monster.name.toUpperCase()),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: AppColors.surface,
                  child: const Center(
                    child: Icon(Icons.catching_pokemon,
                        size: 100, color: AppColors.onSurfaceMuted),
                  ),
                ),
              ),
              bottom: const TabBar(
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.onSurfaceMuted,
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Hitzones'),
                  Tab(text: 'Drops'),
                  Tab(text: 'Info'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _OverviewTab(monster: monster),
              _HitzoneTab(hitzones: monster.hitzones),
              _DropsTab(drops: monster.drops),
              _InfoTab(monster: monster),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Overview ──────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final MonsterEntity monster;
  const _OverviewTab({required this.monster});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SectionHeader(title: 'DETAILS'),
        StatRow(label: 'Class', value: monster.monsterClass),
        StatRow(
          label: 'Elder Dragon',
          value: monster.isElderDragon ? 'Yes' : 'No',
          valueColor: monster.isElderDragon ? AppColors.elementDragon : null,
        ),
        if (monster.trait.isNotEmpty) ...[
          const Divider(indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trait', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(monster.trait,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
        if (monster.signatureMove.isNotEmpty) ...[
          const Divider(indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Signature Move',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(monster.signatureMove,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
        // Ailment weaknesses (Normal state)
        if (monster.weaknesses.isNotEmpty) ...[
          const SectionHeader(title: 'AILMENT EFFECTIVENESS'),
          ...monster.weaknesses
              .where((w) => w.state == 'Normal')
              .map((w) => _WeaknessRow(weakness: w)),
        ],
        // Ailments inflicted
        if (monster.ailments.isNotEmpty) ...[
          const SectionHeader(title: 'INFLICTS'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: monster.ailments.map((a) => Chip(label: Text(a))).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _WeaknessRow extends StatelessWidget {
  final MonsterWeaknessEntity weakness;
  const _WeaknessRow({required this.weakness});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ResCell('Fire', weakness.fire, AppColors.elementFire),
              _ResCell('Water', weakness.water, AppColors.elementWater),
              _ResCell('Thunder', weakness.thunder, AppColors.elementThunder),
              _ResCell('Ice', weakness.ice, AppColors.elementIce),
              _ResCell('Dragon', weakness.dragon, AppColors.elementDragon),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _ResCell('Poison', weakness.poison, AppColors.elementPoison),
              _ResCell('Para', weakness.paralysis, const Color(0xFF9C27B0)),
              _ResCell('Sleep', weakness.sleep, const Color(0xFF2196F3)),
              _ResCell('Pitfall', weakness.pitfallTrap, AppColors.onSurfaceMuted),
              _ResCell('Shock', weakness.shockTrap, AppColors.elementThunder),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResCell extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _ResCell(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    final effective = value >= 2;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: effective ? color.withOpacity(0.15) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: effective ? color.withOpacity(0.4) : AppColors.divider,
          ),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    color: effective ? color : AppColors.onSurfaceMuted)),
            Text('$value',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: effective ? color : AppColors.onSurfaceMuted)),
          ],
        ),
      ),
    );
  }
}

// ── Hitzones ──────────────────────────────────────────────────────────────────

class _HitzoneTab extends StatelessWidget {
  final List<MonsterHitzoneEntity> hitzones;
  const _HitzoneTab({required this.hitzones});

  @override
  Widget build(BuildContext context) {
    if (hitzones.isEmpty) {
      return const EmptyState(message: 'No hitzone data', icon: Icons.shield);
    }
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        child: DataTable(
          headingRowHeight: 36,
          dataRowMinHeight: 36,
          dataRowMaxHeight: 44,
          columnSpacing: 16,
          headingTextStyle: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          dataTextStyle: const TextStyle(
            color: AppColors.onSurface,
            fontSize: 12,
          ),
          columns: const [
            DataColumn(label: Text('Part')),
            DataColumn(label: Text('Cut'), numeric: true),
            DataColumn(label: Text('Impact'), numeric: true),
            DataColumn(label: Text('Shot'), numeric: true),
            DataColumn(label: Text('Fire'), numeric: true),
            DataColumn(label: Text('Water'), numeric: true),
            DataColumn(label: Text('Thunder'), numeric: true),
            DataColumn(label: Text('Ice'), numeric: true),
            DataColumn(label: Text('Dragon'), numeric: true),
            DataColumn(label: Text('KO'), numeric: true),
          ],
          rows: hitzones.map((h) => DataRow(cells: [
            DataCell(Text(h.bodyPart,
                style: const TextStyle(fontWeight: FontWeight.w600))),
            DataCell(_HitzoneCell(h.cut)),
            DataCell(_HitzoneCell(h.impact)),
            DataCell(_HitzoneCell(h.shot)),
            DataCell(_HitzoneCell(h.fire, color: AppColors.elementFire)),
            DataCell(_HitzoneCell(h.water, color: AppColors.elementWater)),
            DataCell(_HitzoneCell(h.thunder, color: AppColors.elementThunder)),
            DataCell(_HitzoneCell(h.ice, color: AppColors.elementIce)),
            DataCell(_HitzoneCell(h.dragon, color: AppColors.elementDragon)),
            DataCell(_HitzoneCell(h.ko)),
          ])).toList(),
        ),
      ),
    );
  }
}

class _HitzoneCell extends StatelessWidget {
  final int? value;
  final Color? color;
  const _HitzoneCell(this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    if (value == null) return const Text('—');
    final c = color ?? (value! >= 45 ? AppColors.primary : AppColors.onSurface);
    return Text(
      '$value',
      style: TextStyle(
        color: c,
        fontWeight: value! >= 45 ? FontWeight.w700 : FontWeight.normal,
      ),
    );
  }
}

// ── Drops ─────────────────────────────────────────────────────────────────────

class _DropsTab extends StatelessWidget {
  final List<MonsterDropEntity> drops;
  const _DropsTab({required this.drops});

  @override
  Widget build(BuildContext context) {
    if (drops.isEmpty) {
      return const EmptyState(message: 'No drop data', icon: Icons.inventory);
    }
    final grouped = <String, List<MonsterDropEntity>>{};
    for (final d in drops) {
      grouped.putIfAbsent(d.rank, () => []).add(d);
    }
    return ListView(
      children: [
        for (final rank in ['LR', 'HR', 'G'])
          if (grouped.containsKey(rank)) ...[
            SectionHeader(title: _rankLabel(rank)),
            ...grouped[rank]!.map((d) => _DropRow(drop: d)),
          ],
      ],
    );
  }

  String _rankLabel(String rank) {
    switch (rank) {
      case 'LR': return 'LOW RANK';
      case 'HR': return 'HIGH RANK';
      case 'G': return 'G RANK';
      default: return rank;
    }
  }
}

class _DropRow extends StatelessWidget {
  final MonsterDropEntity drop;
  const _DropRow({required this.drop});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(drop.itemName,
                    style: Theme.of(context).textTheme.bodyMedium),
                Text(drop.condition,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text('x${drop.stackSize}',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('${drop.percentage}%',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ── Info (Habitats + Status) ──────────────────────────────────────────────────

class _InfoTab extends StatelessWidget {
  final MonsterEntity monster;
  const _InfoTab({required this.monster});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        if (monster.habitats.isNotEmpty) ...[
          const SectionHeader(title: 'HABITATS'),
          ...monster.habitats.map((h) => ListTile(
                leading: const Icon(Icons.location_on,
                    color: AppColors.primary, size: 20),
                title: Text(h.locationName),
                subtitle: h.startArea != null
                    ? Text('Start: ${h.startArea}'
                        '${h.restArea != null ? '  Rest: ${h.restArea}' : ''}',
                        style: Theme.of(context).textTheme.bodySmall)
                    : null,
                dense: true,
              )),
        ],
        if (monster.statuses.isNotEmpty) ...[
          const SectionHeader(title: 'STATUS THRESHOLDS'),
          ...monster.statuses.map((s) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                        width: 80,
                        child: Text(s.status,
                            style: Theme.of(context).textTheme.bodyMedium)),
                    if (s.initial != null)
                      _StatusChip('Init: ${s.initial}'),
                    if (s.max != null)
                      _StatusChip('Max: ${s.max}'),
                    if (s.duration != null)
                      _StatusChip('${s.duration}s'),
                  ],
                ),
              )),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  const _StatusChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 11, color: AppColors.onSurface)),
    );
  }
}
