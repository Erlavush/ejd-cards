// lib/features/deck_list/widgets/deck_list_item.dart

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/models/deck_model.dart';

class DeckListItem extends StatelessWidget {
  final DeckModel deck;
  final VoidCallback onPlay;
  final VoidCallback onStudy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onExport;
  final VoidCallback onReview;

  const DeckListItem({
    super.key,
    required this.deck,
    required this.onPlay,
    required this.onStudy,
    required this.onEdit,
    required this.onDelete,
    required this.onExport,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = (deck.cardCount > 0 && deck.lastReviewedCardIndex != null && deck.lastReviewedCardIndex! > 0)
        ? ((deck.lastReviewedCardIndex! + 1) / deck.cardCount)
        : 0.0;

    return GestureDetector(
      onTap: onStudy,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    deck.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Iconsax.more, color: colorScheme.onSurfaceVariant),
                  onSelected: (value) {
                    if (value == 'review') onReview();
                    if (value == 'edit') onEdit();
                    if (value == 'export') onExport();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'review',
                      child: ListTile(leading: Icon(Iconsax.document_text), title: Text('Review & Edit Cards')),
                    ),
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: ListTile(leading: Icon(Iconsax.edit), title: Text('Edit Deck Settings')),
                    ),
                    const PopupMenuItem<String>(
                      value: 'export',
                      child: ListTile(leading: Icon(Iconsax.export_3), title: Text('Export/Share')),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(leading: Icon(Iconsax.trash, color: Colors.red), title: Text('Delete', style: TextStyle(color: Colors.red))),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${deck.cardCount} card${deck.cardCount == 1 ? "" : "s"}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress: ${(progress * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress > 1.0 ? 1.0 : progress, // Ensure value is not > 1
                          minHeight: 8,
                          backgroundColor: colorScheme.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: deck.cardCount > 0 ? onPlay : null, // Disable play if no cards
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),

                  child: const Icon(Iconsax.play, size: 28),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}