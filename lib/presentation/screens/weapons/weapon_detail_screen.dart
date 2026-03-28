import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/weapon_repository.dart';
import '../../../domain/entities/weapon_entity.dart';
import '../../widgets/shared_widgets.dart';

// ── Weapon Detail ─────────────────────────────────────────────────────────────

class WeaponDetailScreen extends ConsumerWidget {
  final int id;
  const WeaponDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(weaponDetailProvider(id));
    return AsyncStateWidget<WeaponEntity?>(
      state: detailAsync,
      builder: (weapon) {
        if (weapon == null) {
          return Scaffold(appBar: AppBar(), body: const EmptyState(message: 'Weapon not found'));
        }
        return _WeaponDetailView(weapon: weapon);
      },
    );
  }
}

class _WeaponDetailView extends StatelessWidget {
  final WeaponEntity weapon;
  const _WeaponDetailView({required this.weapon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(weapon.name.toUpperCase())),
      body: ListView(
        children: [
          // Header card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: weapon.isFinal
                    ? AppColors.primary.withOpacity(0.5)
                    : AppColors.divider,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.architecture, size: 48, color: AppColors.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(weapon.name,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Row(children: [
                        Text(weapon.wtype,
                            style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(width: 8),
                        RarityBadge(rarity: weapon.rarity),
                        if (weapon.isFinal) ...[
                          const SizedBox(width: 8),
                          _FinalBadge(),
                        ],
                      ]),
                      if (weapon.parent != null) ...[
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => context.push('/weapons/${weapon.parent!.id}'),
                          child: Text('↑ ${weapon.parent!.name}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  decoration: TextDecoration.underline)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SectionHeader(title: 'STATS'),
          StatRow(label: 'Attack',
              value: weapon.attack.toString(),
              valueColor: AppColors.primary),
          if (weapon.maxAttack != null)
            StatRow(label: 'Max Attack', value: weapon.maxAttack.toString()),
          StatRow(
            label: 'Affinity',
            value: '${weapon.affinity >= 0 ? '+' : ''}${weapon.affinity}%',
            valueColor: weapon.affinity >= 0
                ? AppColors.elementThunder
                : AppColors.error,
          ),
          if (weapon.element != null && weapon.element!.isNotEmpty)
            StatRow(
              label: weapon.awaken != null ? 'Awaken' : 'Element',
              value: '${weapon.element} ${weapon.elementAttack ?? ''}',
            ),
          if (weapon.element2 != null && weapon.element2!.isNotEmpty)
            StatRow(
              label: 'Element 2',
              value: '${weapon.element2} ${weapon.element2Attack ?? ''}',
            ),
          if (weapon.defense != null && weapon.defense! > 0)
            StatRow(label: 'Defense Bonus', value: '+${weapon.defense}'),
          StatRow(label: 'Slots', value: weapon.numSlots > 0 ? '◯' * weapon.numSlots : '—'),

          // Sharpness bar
          if (weapon.sharpnessBase.isNotEmpty) ...[
            const SectionHeader(title: 'SHARPNESS'),
            _SharpnessBar(base: weapon.sharpnessBase, plus1: weapon.sharpnessPlus1),
          ],

          // Type-specific
          if (weapon.hornNotes != null) ...[
            const SectionHeader(title: 'HORN NOTES'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(weapon.hornNotes!,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
          if (weapon.shellingType != null)
            StatRow(label: 'Shelling Type', value: weapon.shellingType!),
          if (weapon.phial != null)
            StatRow(label: 'Phial', value: weapon.phial!),
          if (weapon.coatings != null) ...[
            const SectionHeader(title: 'COATINGS'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(weapon.coatings!,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
          if (weapon.recoil != null)
            StatRow(label: 'Recoil', value: weapon.recoil!),
          if (weapon.reloadSpeed != null)
            StatRow(label: 'Reload Speed', value: weapon.reloadSpeed!),
          if (weapon.deviation != null)
            StatRow(label: 'Deviation', value: weapon.deviation!),

          // Crafting cost
          if (weapon.creationCost != null && weapon.creationCost! > 0)
            StatRow(label: 'Creation Cost', value: '${weapon.creationCost}z'),
          if (weapon.upgradeCost != null && weapon.upgradeCost! > 0)
            StatRow(label: 'Upgrade Cost', value: '${weapon.upgradeCost}z'),

          // Materials
          if (weapon.craftMaterials.isNotEmpty) ...[
            const SectionHeader(title: 'CRAFTING MATERIALS'),
            ...weapon.craftMaterials.map((m) => _MaterialRow(m)),
          ],
          if (weapon.upgradeMaterials.isNotEmpty) ...[
            const SectionHeader(title: 'UPGRADE MATERIALS'),
            ...weapon.upgradeMaterials.map((m) => _MaterialRow(m)),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _FinalBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.primary.withOpacity(0.5)),
      ),
      child: const Text('FINAL',
          style: TextStyle(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1)),
    );
  }
}

// Sharpness format: [R, O, Y, G, B, W, P] hits
class _SharpnessBar extends StatelessWidget {
  final List<int> base;
  final List<int> plus1;

  const _SharpnessBar({required this.base, required this.plus1});

  static const _colors = [
    Color(0xFFE53935), Color(0xFFFF6F00), Color(0xFFFFD600),
    Color(0xFF43A047), Color(0xFF1E88E5), Color(0xFFE0E0E0),
    Color(0xFFCE93D8),
  ];

  Widget _bar(List<int> hits, String label) {
    final total = hits.fold(0, (a, b) => a + b).toDouble();
    if (total == 0) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.onSurfaceMuted)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 18,
              child: Row(
                children: [
                  for (int i = 0; i < hits.length; i++)
                    if (hits[i] > 0)
                      Flexible(
                        flex: hits[i],
                        child: Container(color: _colors[i]),
                      ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _bar(base, 'Base'),
        const SizedBox(height: 8),
        if (plus1.isNotEmpty && plus1.any((v) => v > 0))
          _bar(plus1, 'Sharpness +1'),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _MaterialRow extends StatelessWidget {
  final WeaponMaterialEntity material;
  const _MaterialRow(this.material);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 8, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
              child: Text(material.itemName,
                  style: Theme.of(context).textTheme.bodyMedium)),
          Text('x${material.quantity}',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Weapon Tree Screen ────────────────────────────────────────────────────────

class WeaponTreeScreen extends ConsumerWidget {
  final String weaponType;
  const WeaponTreeScreen({super.key, required this.weaponType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeAsync = ref.watch(weaponTreeProvider(weaponType));
    return Scaffold(
      appBar: AppBar(title: Text('$weaponType TREE')),
      body: AsyncStateWidget<List<WeaponTreeNode>>(
        state: treeAsync,
        builder: (roots) {
          if (roots.isEmpty) return const EmptyState(message: 'No weapons in tree');
          return ListView(
            padding: const EdgeInsets.all(16),
            children: roots
                .map((w) => _TreeNode(weapon: w, depth: 0))
                .toList(),
          );
        },
      ),
    );
  }
}

class _TreeNode extends StatefulWidget {
  final WeaponTreeNode weapon;
  final int depth;
  const _TreeNode({required this.weapon, required this.depth});

  @override
  State<_TreeNode> createState() => _TreeNodeState();
}

class _TreeNodeState extends State<_TreeNode> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final w = widget.weapon;
    final indent = widget.depth * 20.0;
    final hasChildren = w.children.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => context.push('/weapons/${w.id}'),
          child: Container(
            margin: EdgeInsets.only(left: indent, bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: w.isFinal
                  ? AppColors.primary.withOpacity(0.08)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: w.isFinal
                    ? AppColors.primary.withOpacity(0.4)
                    : AppColors.divider,
              ),
            ),
            child: Row(
              children: [
                if (widget.depth > 0)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.subdirectory_arrow_right,
                        size: 16, color: AppColors.onSurfaceMuted),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(w.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Row(children: [
                        const Icon(Icons.flash_on,
                            size: 12, color: AppColors.primary),
                        const SizedBox(width: 2),
                        Text(w.attack.toString(),
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                        if (w.element != null && w.element!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          ElementChip(element: w.element!, value: w.elementAttack),
                        ],
                        const Spacer(),
                        RarityBadge(rarity: w.rarity),
                      ]),
                    ],
                  ),
                ),
                if (hasChildren)
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.onSurfaceMuted),
                  ),
              ],
            ),
          ),
        ),
        if (hasChildren && _expanded)
          ...w.children.map((child) => _TreeNode(
                weapon: child,
                depth: widget.depth + 1,
              )),
      ],
    );
  }
}
