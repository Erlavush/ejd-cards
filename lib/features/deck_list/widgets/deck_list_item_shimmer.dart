import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class DeckListItemShimmer extends StatelessWidget {
  const DeckListItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Use a less prominent base color for shimmer, derived from surfaceVariant or similar
    // Ensure good contrast between base and highlight if possible.
    // Material 3 often uses subtle shades for surfaces.
    final shimmerBaseColor = colorScheme.surfaceContainerHighest.withOpacity(0.5); // Example: A slightly visible container color
    final shimmerHighlightColor = colorScheme.surfaceContainerHighest; // Example: The container color itself or slightly brighter

    return Shimmer.fromColors(
      baseColor: shimmerBaseColor,
      highlightColor: shimmerHighlightColor,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: colorScheme.surface, // This color is for the card's actual shape, shimmer will draw over it.
                                     // It should be a color that makes sense if shimmer is slow or fails.
                                     // Often, this is the same as the shimmer's placeholder colors or a neutral background.
                                     // For M3, this might be colorScheme.surface.
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: double.infinity, height: 20.0, color: Colors.white), // Title line 1
                      const SizedBox(height: 4),
                      Container(width: MediaQuery.of(context).size.width * 0.4, height: 20.0, color: Colors.white), // Title line 2 (shorter)
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(width: 24.0, height: 24.0, color: Colors.white), // Placeholder for PopupMenuButton icon
              ],
            ),
            const SizedBox(height: 8),
            Container(width: MediaQuery.of(context).size.width * 0.25, height: 16.0, color: Colors.white), // Card count line
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: MediaQuery.of(context).size.width * 0.2, height: 12.0, color: Colors.white), // Progress text
                      const SizedBox(height: 4),
                      Container(width: double.infinity, height: 8.0, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))), // Progress bar
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(width: 48.0, height: 48.0, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)), // Play button
              ],
            ),
          ],
        ),
      ),
    );
  }
}
