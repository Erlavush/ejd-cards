// lib/features/deck_list/screens/deck_list_screen.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // For generating unique IDs
import 'package:file_picker/file_picker.dart'; // For file picking
import 'dart:typed_data'; // For Uint8List (file bytes)

// Core Models
import '../../../core/models/deck_model.dart';
import '../../../core/models/card_model.dart';

// Screen Imports for Navigation
import '../../study_mode/screens/manual_study_screen.dart';
import '../../deck_management/screens/deck_edit_screen.dart';
import '../../study_mode/screens/autoplay_screen.dart';

// Service for Importing
import '../../deck_management/services/deck_importer_service.dart';

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  List<DeckModel> _decks = [];
  final _uuid = const Uuid();
  final DeckImporterService _importerService = DeckImporterService(); // Importer service instance

  @override
  void initState() {
    super.initState();
    _loadDummyDecks(); // Keep dummy decks for now, imported decks will be added
  }

  // --- DUMMY DATA & MANAGEMENT (can be removed later if only importing) ---
  void _loadDummyDecks() {
    final card1_1 = CardModel(id: _uuid.v4(), frontText: "What is Flutter?", backText: "An open-source UI toolkit by Google.");
    final card1_2 = CardModel(id: _uuid.v4(), frontText: "What is a Widget in Flutter?", backText: "Everything in Flutter is a widget.");

    final card2_1 = CardModel(id: _uuid.v4(), frontText: "Capital of Japan?", backText: "Tokyo");

    final deck1 = DeckModel(
      id: _uuid.v4(),
      title: "Flutter Basics (Dummy)",
      cards: [card1_1, card1_2],
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    );

    final deck2 = DeckModel(
      id: _uuid.v4(),
      title: "World Capitals (Dummy)",
      cards: [card2_1],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    );

    setState(() {
      _decks = [deck1, deck2];
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
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Deck'),
          content: Text('Are you sure you want to delete the deck "${deck.title}"? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                _deleteDeck(deck.id);
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deck "${deck.title}" deleted.')),
                );
              },
            ),
          ],
        );
      },
    );
  }
  // --- END DUMMY DATA & MANAGEMENT ---


  // --- DECK IMPORT LOGIC ---
  Future<void> _pickAndImportDeck() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'fdeck'], // Allow .txt and our custom .fdeck
      );

      if (result != null && result.files.single.bytes != null) {
        Uint8List fileBytes = result.files.single.bytes!;
        // In a real app, show a loading indicator here
        // setState(() { _isLoadingImport = true; });

        ParseResult parseResult = await _importerService.importDeckFromFile(fileBytes);

        // if (_isLoadingImport && mounted) setState(() { _isLoadingImport = false; });

        if (mounted) { // Check if the widget is still in the tree
          if (parseResult.hasError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Import Error: ${parseResult.error}'),
                backgroundColor: Colors.redAccent,
              ),
            );
          } else if (parseResult.deck != null) {
            // Check if a deck with the same title already exists (optional)
            bool deckExists = _decks.any((deck) => deck.title.toLowerCase() == parseResult.deck!.title.toLowerCase());
            if (deckExists) {
                 ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('A deck with the title "${parseResult.deck!.title}" already exists.')),
                 );
            } else {
                setState(() {
                  _decks.add(parseResult.deck!);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deck "${parseResult.deck!.title}" imported successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
            }
          }
        }
      } else {
        // User canceled the picker or file was empty
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No file selected or file is empty.')),
          );
        }
      }
    } catch (e) {
      // Handle any other exceptions during file picking
      // if (_isLoadingImport && mounted) setState(() { _isLoadingImport = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File picking failed: ${e.toString()}')),
        );
      }
      print("File picking error: $e");
    }
  }
  // --- END DECK IMPORT LOGIC ---

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickAndImportDeck, // Calls the import function
        label: const Text('Import Deck'),
        icon: const Icon(Icons.file_upload),
        tooltip: 'Import a deck from a text file',
      ),
    );
  }

  Widget _buildDeckList() {
    if (_decks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No decks yet. Tap "Import Deck" to add a deck from a file!',
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