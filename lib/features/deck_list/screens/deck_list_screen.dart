// lib/features/deck_list/screens/deck_list_screen.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // For generating unique IDs

// Core Models
import '../../../core/models/deck_model.dart';
import '../../../core/models/card_model.dart';

// Screen Imports for Navigation
import '../../study_mode/screens/manual_study_screen.dart';
import '../../deck_management/screens/deck_edit_screen.dart';
import '../../study_mode/screens/autoplay_screen.dart';

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  List<DeckModel> _decks = [];
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadDummyDecks();
  }

  void _loadDummyDecks() {
    final card1_1 = CardModel(id: _uuid.v4(), frontText: "What is Flutter?", backText: "An open-source UI toolkit by Google.");
    final card1_2 = CardModel(id: _uuid.v4(), frontText: "What is a Widget in Flutter?", backText: "Everything in Flutter is a widget.");
    final card1_3 = CardModel(id: _uuid.v4(), frontText: "What language is Flutter written in?", backText: "Dart.");

    final card2_1 = CardModel(id: _uuid.v4(), frontText: "Capital of Japan?", backText: "Tokyo");
    final card2_2 = CardModel(id: _uuid.v4(), frontText: "Capital of France?", backText: "Paris");

    final card3_1 = CardModel(id: _uuid.v4(), frontText: "Define 'Ephemeral'", backText: "Lasting for a very short time.");

    final deck1 = DeckModel(
      id: _uuid.v4(),
      title: "Flutter Basics",
      cards: [card1_1, card1_2, card1_3],
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    );

    final deck2 = DeckModel(
      id: _uuid.v4(),
      title: "World Capitals",
      cards: [card2_1, card2_2],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      customFrontTimeSeconds: 3,
      customBackTimeSeconds: 5,
    );

    final deck3 = DeckModel(
      id: _uuid.v4(),
      title: "Vocabulary Builder",
      cards: [card3_1],
      createdAt: DateTime.now(),
    );

    final deck4 = DeckModel(
      id: _uuid.v4(),
      title: "Upcoming Math Exam",
      cards: [],
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    );

    setState(() {
      _decks = [deck1, deck2, deck3, deck4];
    });
  }

  void _addDummyDeck() {
    final newDummyCard = CardModel(id: _uuid.v4(), frontText: "New Q", backText: "New A");
    final newDummyDeck = DeckModel(
      id: _uuid.v4(),
      title: "Newly Added Deck ${_decks.length + 1}",
      cards: [newDummyCard],
      createdAt: DateTime.now(),
    );
    setState(() {
      _decks.add(newDummyDeck);
    });
  }

  void _deleteDeck(String deckId) {
    setState(() {
      _decks.removeWhere((d) => d.id == deckId);
    });
  }

  void _showDeleteConfirmationDialog(DeckModel deck) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) { // Use a different context name to avoid confusion
        return AlertDialog(
          title: const Text('Delete Deck'),
          content: Text('Are you sure you want to delete the deck "${deck.title}"? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Use dialogContext
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                _deleteDeck(deck.id);
                Navigator.of(dialogContext).pop(); // Use dialogContext
                ScaffoldMessenger.of(context).showSnackBar( // Use the main screen's context
                  SnackBar(content: Text('Deck "${deck.title}" deleted.')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Decks'),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.settings),
        //     onPressed: () {
        //       // TODO: Navigate to settings screen
        //     },
        //   ),
        // ],
      ),
      body: _buildDeckList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDummyDeck, // Navigate to add new deck screen later
        tooltip: 'Add Deck',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDeckList() {
    if (_decks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No decks yet. Tap the "+" button to create your first deck!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18.0, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _decks.length,
      itemBuilder: (context, index) {
        final deck = _decks[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                deck.title.isNotEmpty ? deck.title[0].toUpperCase() : "?",
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
            ),
            title: Text(deck.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${deck.cardCount} card${deck.cardCount == 1 ? "" : "s"}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_circle_fill_outlined),
                  color: Colors.green,
                  tooltip: 'Autoplay',
                  onPressed: () {
                    print('Attempting to navigate to Autoplay for: ${deck.title}'); // Debug print
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AutoplayScreen(deck: deck),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  color: Colors.blue,
                  tooltip: 'Edit Deck',
                  onPressed: () {
                    print('Attempting to navigate to Edit for: ${deck.title}'); // Debug print
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DeckEditScreen(deck: deck),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                  tooltip: 'Delete Deck',
                  onPressed: () {
                    _showDeleteConfirmationDialog(deck);
                  },
                ),
              ],
            ),
            onTap: () {
              print('Attempting to navigate to Manual Study for: ${deck.title}'); // Debug print
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ManualStudyScreen(deck: deck),
                ),
              );
            },
          ),
        );
      },
    );
  }
}