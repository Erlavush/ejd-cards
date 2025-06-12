// lib/features/deck_list/screens/deck_list_screen.dart

import 'dart:typed_data';
import 'package:ejd_cards/features/deck_list/widgets/deck_list_item.dart';
import 'package:ejd_cards/features/deck_management/screens/deck_edit_screen.dart';
import 'package:ejd_cards/features/deck_management/services/deck_exporter_service.dart';
import 'package:ejd_cards/features/deck_management/services/deck_importer_service.dart';
import 'package:ejd_cards/features/settings/screens/settings_screen.dart';
import 'package:ejd_cards/features/study_mode/screens/autoplay_screen.dart';
import 'package:ejd_cards/features/study_mode/screens/manual_study_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/models/deck_model.dart';
import '../../../core/services/deck_persistence_service.dart';

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  List<DeckModel> _decks = [];
  final DeckPersistenceService _persistenceService = DeckPersistenceService();
  final DeckImporterService _importerService = DeckImporterService();
  final DeckExporterService _exporterService = DeckExporterService();
  bool _isLoading = true;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _loadPersistedDecks();
  }

  Future<void> _loadPersistedDecks() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final loadedDecks = await _persistenceService.loadDecks();

    if (mounted) {
      setState(() {
        _decks = loadedDecks;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteDeckAndPersist(String deckId) async {
    final deckToRemoveIndex = _decks.indexWhere((d) => d.id == deckId);
    if (deckToRemoveIndex == -1) return;

    final deckTitle = _decks[deckToRemoveIndex].title;
    if (mounted) {
      setState(() {
        _decks.removeAt(deckToRemoveIndex);
      });
    }

    await _persistenceService.deleteDeck(deckId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deck "$deckTitle" deleted.')),
      );
    }
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
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteDeckAndPersist(deck.id);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickAndImportDeck() async {
    if (!mounted) return;
    setState(() {
      _isImporting = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.bytes != null) {
        Uint8List fileBytes = result.files.single.bytes!;
        ParseResult parseResult = await _importerService.importDeckFromFile(fileBytes);

        if (mounted) {
          if (parseResult.hasError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Import Error: ${parseResult.error}'),
                backgroundColor: Colors.redAccent,
              ),
            );
          } else if (parseResult.deck != null) {
            bool deckExists = _decks.any((deck) => deck.title.toLowerCase() == parseResult.deck!.title.toLowerCase());
            if (deckExists) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('A deck with the title "${parseResult.deck!.title}" already exists.')),
              );
            } else {
              await _persistenceService.saveDeck(parseResult.deck!);
              _loadPersistedDecks(); // Reload from storage to ensure consistency
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deck "${parseResult.deck!.title}" imported successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File picking failed: ${e.toString()}')),
        );
      }
      print("File picking error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  void _handleManualStudyStart(DeckModel deck) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ManualStudyScreen(deck: deck)),
    );
  }

  void _handleAutoplayStart(DeckModel deck) {
    final int resumeIndex = deck.lastReviewedCardIndex ?? 0;
    if (resumeIndex > 0 && deck.cards.length > resumeIndex) {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Resume Study?'),
            content: Text('You left off on card ${resumeIndex + 1}. Would you like to resume or start over?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Start Over'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _navigateToAutoplay(deck, startIndex: 0);
                },
              ),
              ElevatedButton(
                child: const Text('Resume'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _navigateToAutoplay(deck, startIndex: resumeIndex);
                },
              ),
            ],
          );
        },
      );
    } else {
      _navigateToAutoplay(deck, startIndex: 0);
    }
  }

  Future<void> _navigateToAutoplay(DeckModel deck, {required int startIndex}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AutoplayScreen(deck: deck, startIndex: startIndex),
      ),
    );
    if (result == true && mounted) {
      _loadPersistedDecks();
    }
  }

  Future<void> _handleDeckEdit(DeckModel deck) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DeckEditScreen(initialDeck: deck)),
    );
    if (result == true && mounted) {
      _loadPersistedDecks();
    }
  }

  Future<void> _handleDeckExport(DeckModel deck) async {
    final resultMessage = await _exporterService.exportDeck(deck);
    if (mounted && resultMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Decks'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.setting_2),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading || _isImporting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_isImporting ? "Importing deck..." : "Loading decks..."),
                ],
              ),
            )
          : _buildDeckList(),
      floatingActionButton: PopupMenuButton<String>(
        tooltip: 'Add Deck',
        onSelected: (String value) async {
          if (value == 'create_manual') {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DeckEditScreen()),
            );
            if (result == true && mounted) {
              _loadPersistedDecks();
            }
          } else if (value == 'import_file') {
            _pickAndImportDeck();
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'create_manual',
            child: ListTile(
              leading: Icon(Iconsax.edit),
              title: Text('Create Manually'),
            ),
          ),
          const PopupMenuItem<String>(
            value: 'import_file',
            child: ListTile(
              leading: Icon(Iconsax.document_upload),
              title: Text('Import from JSON'),
            ),
          ),
        ],
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 8.0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Iconsax.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildDeckList() {
    if (_decks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Iconsax.safe_home, size: 80.0, color: Colors.grey),
              const SizedBox(height: 24.0),
              Text('Your Bookshelf is Empty', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12.0),
              Text(
                'Tap the "+" button to create a new deck or import one from a file.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

  return ListView.builder(
    padding: const EdgeInsets.only(bottom: 80), // Padding to avoid FAB overlap
    itemCount: _decks.length,
    itemBuilder: (context, index) {
      final deck = _decks[index];
      return DeckListItem(
        deck: deck,
        onStudy: () => _handleManualStudyStart(deck),
        onPlay: () => _handleAutoplayStart(deck),
        onEdit: () => _handleDeckEdit(deck),
        onDelete: () => _showDeleteConfirmationDialog(deck),
        onExport: () => _handleDeckExport(deck),
      )
          .animate()
          .fadeIn(
            duration: 400.ms,
            curve: Curves.easeOut,
            delay: (index * 100).ms,
          )
          .slideY(
            begin: 0.2,
            end: 0,
            duration: 400.ms,
            curve: Curves.easeOut,
            delay: (index * 100).ms,
          );
    },
  );
}
}