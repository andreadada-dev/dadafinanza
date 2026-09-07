import 'package:flutter/material.dart';

class QuickSuggestionItem {
  const QuickSuggestionItem({
    required this.value,
    required this.label,
    this.selected = false,
    this.semanticsLabel,
  });

  final String value;
  final String label;
  final bool selected;
  final String? semanticsLabel;
}

class QuickSuggestionStrip extends StatelessWidget {
  const QuickSuggestionStrip({
    required this.items,
    required this.onSelected,
    this.onShowAll,
    this.showAllLabel = 'Mostra tutte',
    super.key,
  });

  final List<QuickSuggestionItem> items;
  final ValueChanged<String> onSelected;
  final VoidCallback? onShowAll;
  final String showAllLabel;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && onShowAll == null) return const SizedBox.shrink();
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length + (onShowAll == null ? 0 : 1),
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return TextButton.icon(
              onPressed: onShowAll,
              icon: const Icon(Icons.more_horiz_rounded, size: 18),
              label: Text(showAllLabel),
            );
          }
          final item = items[index];
          return Semantics(
            button: true,
            selected: item.selected,
            label: item.semanticsLabel ?? item.label,
            child: FilterChip(
              label: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              selected: item.selected,
              showCheckmark: item.selected,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              onSelected: (_) => onSelected(item.value),
            ),
          );
        },
      ),
    );
  }
}
