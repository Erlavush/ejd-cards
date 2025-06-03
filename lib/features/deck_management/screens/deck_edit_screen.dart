// lib/features/deck_management/screens/deck_edit_screen.dart
import 'package:flutter/material.dart';
import '../../../core/models/deck_model.dart'; // Import DeckModel

class DeckEditScreen extends StatelessWidget {
  final DeckModel deck; // Or DeckModel? if creating a new deck

  // For now, let's assume we are always editing an existing deck
  const DeckEditScreen({super.key, required this.deck});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit: ${deck.title}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // TODO: Implement save logic
              Navigator.of(context).pop(); // Go back after "saving"
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Editing Deck: "${deck.title}"',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: deck.title,
              decoration: const InputDecoration(
                labelText: 'Deck Title',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // We'd update a temporary state here before saving
                // For now, this doesn't do anything persistent
              },
            ),
            const SizedBox(height: 20),
            Text('Number of cards: ${deck.cardCount}'),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement actual save logic
                  Navigator.of(context).pop(); // Go back
                },
                child: const Text('Save Changes (Placeholder)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}