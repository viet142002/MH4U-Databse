import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';

// ─── Search Bar ───────────────────────────────────────────────────────────────

class MhSearchBar extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final EdgeInsetsGeometry? padding;

  const MhSearchBar({
    super.key,
    required this.hint,
    required this.onChanged,
    this.padding,
  });

  @override
  State<MhSearchBar> createState() => _MhSearchBarState();
}

class _MhSearchBarState extends State<MhSearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                  },
                )
              : null,
        ),
      ),
    );
  }
}

// ─── Async State Widget ───────────────────────────────────────────────────────
// Generic typed so builder receives T, not Object.

class AsyncStateWidget<T> extends StatelessWidget {
  final AsyncValue<T> state;
  final Widget Function(T data) builder;
  final Widget? loadingWidget;
  final Widget? emptyWidget;

  const AsyncStateWidget({
    super.key,
    required this.state,
    required this.builder,
    this.loadingWidget,
    this.emptyWidget,
  });

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () =>
          loadingWidget ??
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text('Error: $e',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
      data: builder,
    );
  }
}

// ─── Rarity Badge ─────────────────────────────────────────────────────────────

class RarityBadge extends StatelessWidget {
  final int rarity;
  const RarityBadge({super.key, required this.rarity});

  Color get _color {
    if (rarity <= 2) return const Color(0xFF9E9E9E);
    if (rarity <= 4) return const Color(0xFF66BB6A);
    if (rarity <= 6) return const Color(0xFF42A5F5);
    if (rarity <= 8) return const Color(0xFFAB47BC);
    return const Color(0xFFFFD700);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _color.withValues(alpha: 0.5)),
      ),
      child: Text('R$rarity',
          style: TextStyle(
              color: _color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─── Element Chip ─────────────────────────────────────────────────────────────

class ElementChip extends StatelessWidget {
  final String element;
  final int? value;

  const ElementChip({super.key, required this.element, this.value});

  Color get _color {
    switch (element.toLowerCase()) {
      case 'fire':     return AppColors.elementFire;
      case 'water':    return AppColors.elementWater;
      case 'thunder':  return AppColors.elementThunder;
      case 'ice':      return AppColors.elementIce;
      case 'dragon':   return AppColors.elementDragon;
      case 'poison':   return AppColors.elementPoison;
      case 'blast':    return AppColors.elementBlast;
      default:         return AppColors.onSurfaceMuted;
    }
  }

  IconData get _icon {
    switch (element.toLowerCase()) {
      case 'fire':    return Icons.local_fire_department;
      case 'water':   return Icons.water_drop;
      case 'thunder': return Icons.bolt;
      case 'ice':     return Icons.ac_unit;
      case 'dragon':  return Icons.auto_awesome;
      case 'poison':  return Icons.science;
      case 'blast':   return Icons.flash_on; // explosion icon doesn't exist
      default:        return Icons.remove;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: _color, size: 14),
          const SizedBox(width: 4),
          Text(
            value != null ? '$element $value' : element,
            style: TextStyle(
                color: _color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── Weakness Rating ──────────────────────────────────────────────────────────

class WeaknessRatingWidget extends StatelessWidget {
  final int rating;
  const WeaknessRatingWidget({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => Icon(Icons.star, size: 14,
            color: i < rating ? AppColors.primary : AppColors.divider),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyState({
    super.key,
    this.message = 'No results found',
    this.icon = Icons.search_off,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppColors.onSurfaceMuted),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

// ─── Stat Row ─────────────────────────────────────────────────────────────────

class StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const StatRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text(value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: valueColor ?? AppColors.onBackground,
                    fontWeight: FontWeight.w600,
                  )),
        ],
      ),
    );
  }
}
