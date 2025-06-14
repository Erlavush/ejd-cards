// lib/features/deck_list/screens/folder_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/card_model.dart';
import '../../../core/models/deck_model.dart';
import '../../../core/models/folder_model.dart';
import '../../../core/services/deck_persistence_service.dart';
import '../../deck_list/widgets/deck_list_item.dart';
import '../../deck_management/screens/deck_edit_screen.dart';
import '../../deck_management/screens/review_notes_screen.dart';
import '../../deck_management/services/deck_exporter_service.dart';
import '../../study_mode/screens/autoplay_screen.dart';
import '../../study_mode/screens/manual_study_screen.dart';

class FolderDetailScreen extends StatefulWidget {
  final FolderModel folder;
  final List<DeckModel> decksInFolder;
  final VoidCallback onDataChanged; // To trigger a refresh on the previous screen

  const FolderDetailScreen({
    super.key,
    required this.folder,
    required this.decksInFolder,
    required this.onDataChanged,
  });

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  late List<DeckModel> _decks;
  final DeckPersistenceService _persistenceService = DeckPersistenceService();
  final DeckExporterService _exporterService = DeckExporterService();

  @override
  void initState() {
    super.initState();
    _decks = List.from(widget.decksInFolder);
  }

  bool get _canStudyAll => _decks.any((deck) => deck.cards.isNotEmpty);

  DeckModel _createMegaDeck() {
    final allCards = <CardModel>[];
    for (final deck in _decks) {
      allCards.addAll(deck.cards);
    }
    // Create a temporary, non-persistent deck
    return DeckModel(
      id: const Uuid().v4(), // Temporary ID
      title: widget.folder.title,
      cards: allCards,
    );
  }

  void _handleAutoplayAll() {
    if (!_canStudyAll) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('There are no cards in this folder to play.')),
      );
      return;
    }
    final megaDeck = _createMegaDeck();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AutoplayScreen(deck: megaDeck, startIndex: 0)),
    );
  }

  void _handleStudyAll() {
    if (!_canStudyAll) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('There are no cards in this folder to study.')),
      );
      return;
    }
    final megaDeck = _createMegaDeck();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ManualStudyScreen(deck: megaDeck)),
    );
  }

  // --- Individual Deck Handlers ---

  Future<void> _deleteDeckAndPersist(String deckId) async {
    final deckToRemove = _decks.firstWhere((d) => d.id == deckId);
    setState(() {
      _decks.removeWhere((d) => d.id == deckId);
    });

    // Remove from the folder model and save the folder
    widget.folder.deckIds.remove(deckId);
    await _persistenceService.saveFolder(widget.folder);

    // Delete the actual deck file
    await _persistenceService.deleteDeck(deckId);

    widget.onDataChanged(); // Notify the previous screen to refresh

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deck "${deckToRemove.title}" deleted.')),
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

  void _handleManualStudyStart(DeckModel deck) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ManualStudyScreen(deck: deck)),
    );
  }

  void _handleAutoplayStart(DeckModel deck) {
    // This logic can be simplified here since it's for a single deck
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AutoplayScreen(deck: deck, startIndex: deck.lastReviewedCardIndex ?? 0)),
    );
  }

  Future<void> _handleDeckEdit(DeckModel deck) async {
    final result = await Navigator.push(
      context,
      // Pass all available folders to the edit screen
      MaterialPageRoute(builder: (context) => DeckEditScreen(initialDeck: deck)),
    );
    if (result == true && mounted) {
      // A change was made, trigger a full refresh on the main list screen
      widget.onDataChanged();
      // Pop this screen to force the user back to the main list, which will be rebuilt
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleDeckReview(DeckModel deck) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReviewNotesScreen(deck: deck)),
    );
    if (result == true && mounted) {
      widget.onDataChanged();
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
        title: Text(widget.folder.title),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'study') _handleStudyAll();
              if (value == 'play') _handleAutoplayAll();
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'study',
                child: ListTile(leading: Icon(Iconsax.book_1), title: Text('Study All')),
              ),
              const PopupMenuItem<String>(
                value: 'play',
                child: ListTile(leading: Icon(Iconsax.play_add), title: Text('Autoplay All')),
              ),
            ],
            icon: const Icon(Iconsax.layer),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _decks.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(Iconsax.document_copy, size: 80.0, color: Colors.grey),
                    const SizedBox(height: 24.0),
                    Text('This Folder is Empty', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 12.0),
                    Text(
                      'Create a new deck or move an existing one into this folder.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
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
                  onReview: () => _handleDeckReview(deck),
                );
              },
            ),
    );
  }
}