// lib/features/study_mode/screens/autoplay_screen.dart
import 'package:flutter/material.dart';
import '../../../core/models/deck_model.dart'; // Import DeckModel

class AutoplayScreen extends StatelessWidget {
  final DeckModel deck;

  const AutoplayScreen({super.key, required this.deck});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Autoplay: ${deck.title}'),
        leading: IconButton(
          icon: const Icon(Icons.close), // Using close icon for autoplay stop
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Autoplay Screen for "${deck.title}"',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text('This deck has ${deck.cardCount} card(s).'),
            const SizedBox(height: 10),
            Text('Front time: ${deck.customFrontTimeSeconds ?? 'Default'}s'),
            Text('Back time: ${deck.customBackTimeSeconds ?? 'Default'}s'),
            const SizedBox(height: 40),
            const Icon(Icons.play_circle_filled, size: 100, color: Colors.green),
            const SizedBox(height: 20),
            const Text("Autoplay would be happening here!"),
             const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Stop Autoplay & Go Back'),
              onPressed: () {
                Navigator.of(context).pop(); // Go back to DeckListScreen
              },
            ),
          ],
        ),
      ),
    );
  }
}