// lib/features/study_mode/screens/manual_study_screen.dart
import 'package:flutter/material.dart';
import '../../../core/models/deck_model.dart'; // Import DeckModel

class ManualStudyScreen extends StatelessWidget {
  final DeckModel deck;

  const ManualStudyScreen({super.key, required this.deck});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Study: ${deck.title}'),
        leading: IconButton( // Add a back button
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Manual Study Screen for "${deck.title}"',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text('This deck has ${deck.cardCount} card(s).'),
            const SizedBox(height: 20),
            if (deck.cards.isNotEmpty)
              Text('First card front: "${deck.cards.first.frontText}"')
            else
              const Text('This deck has no cards yet!'),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Go back to DeckListScreen
              },
              child: const Text('Back to Decks'),
            ),
          ],
        ),
      ),
    );
  }
}