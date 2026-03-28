import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/armor_repository.dart';
import '../../../domain/entities/other_entities.dart';
import '../../widgets/shared_widgets.dart';

class ArmorDetailScreen extends ConsumerWidget {
  final int id;
  const ArmorDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final armorAsync = ref.watch(armorDetailProvider(id));
    return AsyncStateWidget<ArmorEntity?>(
      state: armorAsync,
      builder: (armor) {
        if (armor == null) {
          return Scaffold(appBar: AppBar(), body: const EmptyState());
        }
        return _ArmorDetailView(armor: armor);
      },
    );
  }
}

class _ArmorDetailView extends StatelessWidget {
  final ArmorEntity armor;
  const _ArmorDetailView({required this.armor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(armor.name.toUpperCase())),
      body: ListView(
        children: [
          // Header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield, size: 48, color: AppColors.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(armor.name,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Row(children: [
                        Text(armor.slot,
                            style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(width: 8),
                        RarityBadge(rarity: armor.rarity),
                        const SizedBox(width: 8),
                        Text(armor.hunterType,
                            style: Theme.of(context).textTheme.bodySmall),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Defense & Resistances
          const SectionHeader(title: 'DEFENSE & RESISTANCES'),
          _ResistanceTable(armor: armor),

          // Skill Points
          if (armor.skillPoints.isNotEmpty) ...[
            const SectionHeader(title: 'SKILL POINTS'),
            ...armor.skillPoints.map((sp) => _SkillPointRow(sp: sp)),
          ],

          // Materials
          if (armor.materials.isNotEmpty) ...[
            const SectionHeader(title: 'CRAFTING MATERIALS'),
            ...armor.materials.map((m) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(children: [
                    const Icon(Icons.circle, size: 8, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(m.itemName,
                            style: Theme.of(context).textTheme.bodyMedium)),
                    Text('x${m.quantity}',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                  ]),
                )),
          ],

          if (armor.description != null) ...[
            const Divider(indent: 16, endIndent: 16, height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(armor.description!,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ResistanceTable extends StatelessWidget {
  final ArmorEntity armor;
  const _ResistanceTable({required this.armor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            // Defense row
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                const Text('Defense',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${armor.defense}',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                Text(' / ${armor.maxDefense}',
                    style: Theme.of(context).textTheme.bodySmall),
                if (armor.numSlots > 0) ...[
                  const SizedBox(width: 12),
                  Text('◯' * armor.numSlots,
                      style: const TextStyle(color: AppColors.onSurfaceMuted)),
                ],
              ]),
            ),
            const Divider(height: 1),
            // Resistances
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  _ResCell2('🔥', armor.fireRes, AppColors.elementFire),
                  _ResCell2('💧', armor.waterRes, AppColors.elementWater),
                  _ResCell2('⚡', armor.thunderRes, AppColors.elementThunder),
                  _ResCell2('❄️', armor.iceRes, AppColors.elementIce),
                  _ResCell2('🐉', armor.dragonRes, AppColors.elementDragon),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResCell2 extends StatelessWidget {
  final String emoji;
  final int value;
  final Color color;
  const _ResCell2(this.emoji, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    final positive = value >= 0;
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          Text(
            '${positive ? '+' : ''}$value',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: positive ? color : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillPointRow extends StatelessWidget {
  final ArmorSkillPoint sp;
  const _SkillPointRow({required this.sp});

  @override
  Widget build(BuildContext context) {
    final positive = sp.points > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
              child: Text(sp.skillTreeName,
                  style: Theme.of(context).textTheme.bodyMedium)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: positive
                  ? AppColors.elementThunder.withValues(alpha: 0.12)
                  : AppColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${positive ? '+' : ''}${sp.points}',
              style: TextStyle(
                color: positive ? AppColors.elementThunder : AppColors.error,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
