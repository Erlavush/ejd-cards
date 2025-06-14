// lib/features/deck_list/screens/deck_list_screen.dart

import 'dart:typed_data';
import 'package:ejd_cards/core/models/folder_model.dart';
import 'package:ejd_cards/features/deck_list/screens/folder_detail_screen.dart';
import 'package:ejd_cards/features/deck_list/widgets/deck_list_item.dart';
import 'package:ejd_cards/features/deck_list/widgets/folder_list_item.dart';
import 'package:ejd_cards/features/deck_management/screens/deck_edit_screen.dart';
import 'package:ejd_cards/features/deck_management/screens/review_notes_screen.dart';
import 'package:ejd_cards/features/deck_management/services/deck_exporter_service.dart';
import 'package:ejd_cards/features/deck_management/services/deck_importer_service.dart';
import 'package:ejd_cards/features/settings/screens/settings_screen.dart';
import 'package:ejd_cards/features/study_mode/screens/autoplay_screen.dart';
import 'package:ejd_cards/features/study_mode/screens/manual_study_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/deck_model.dart';
import '../../../core/services/deck_persistence_service.dart';

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  List<DeckModel> _decks = [];
  List<FolderModel> _folders = [];
  final DeckPersistenceService _persistenceService = DeckPersistenceService();
  final DeckImporterService _importerService = DeckImporterService();
  final DeckExporterService _exporterService = DeckExporterService();
  final Uuid _uuid = const Uuid();
  bool _isLoading = true;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final loadedDecks = await _persistenceService.loadDecks();
    final loadedFolders = await _persistenceService.loadFolders();

    if (mounted) {
      setState(() {
        _decks = loadedDecks;
        _folders = loadedFolders;
        _isLoading = false;
      });
    }
  }

  // --- Folder Actions ---

  void _showCreateOrRenameFolderDialog({FolderModel? existingFolder}) {
    final isEditing = existingFolder != null;
    final titleController = TextEditingController(text: isEditing ? existingFolder.title : '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Rename Folder' : 'Create New Folder'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Folder Name'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Folder name cannot be empty.';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final folder = isEditing
                    ? existingFolder
                    : FolderModel(id: _uuid.v4(), title: titleController.text.trim());
                if (isEditing) {
                  folder!.title = titleController.text.trim();
                }
                await _persistenceService.saveFolder(folder!);
                if (mounted) Navigator.of(context).pop();
                await _loadAllData();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFolder(FolderModel folder) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Folder?'),
        content: Text('Are you sure you want to delete the folder "${folder.title}"? The decks inside will NOT be deleted and will become uncategorized.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              await _persistenceService.deleteFolder(folder.id);
              if (mounted) Navigator.of(ctx).pop();
              await _loadAllData();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // --- Deck Actions (for uncategorized decks) ---

  Future<void> _deleteDeckAndPersist(String deckId) async {
    final deckTitle = _decks.firstWhere((d) => d.id == deckId).title;
    await _persistenceService.deleteDeck(deckId);
    await _loadAllData(); // Reload everything to ensure consistency
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

  // --- Navigation Handlers ---

  Future<void> _handleFolderTap(FolderModel folder) async {
    final decksInFolder = _decks.where((d) => folder.deckIds.contains(d.id)).toList();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FolderDetailScreen(
          folder: folder,
          decksInFolder: decksInFolder,
          onDataChanged: _loadAllData,
        ),
      ),
    );
    await _loadAllData();
  }

  Future<void> _handleDeckEdit(DeckModel deck) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DeckEditScreen(initialDeck: deck)),
    );
    if (result == true && mounted) {
      _loadAllData();
    }
  }
  
  // --- Import/Export ---

  Future<void> _processImport(ParseResult parseResult) async {
    if (!mounted) return;

    if (parseResult.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import Error: ${parseResult.error}'), backgroundColor: Colors.redAccent),
      );
    } else if (parseResult.deck != null) {
      await _persistenceService.saveDeck(parseResult.deck!);
      await _loadAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deck "${parseResult.deck!.title}" imported successfully! It is in "Uncategorized".'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
  
  Future<void> _pickAndImportDeck() async {
    if (!mounted) return;
    setState(() => _isImporting = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null && result.files.single.bytes != null) {
        Uint8List fileBytes = result.files.single.bytes!;
        await _processImport(await _importerService.importDeckFromFile(fileBytes));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File picking failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _showImportFromTextDialog() {
    final textController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Import from Text'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: textController,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: 'Paste JSON here',
                hintText: 'Paste the JSON content from your LLM...',
                border: OutlineInputBorder(),
              ),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Pasted text cannot be empty.' : null,
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Import'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final pastedText = textController.text;
                  Navigator.of(context).pop();
                  await _processImport(await _importerService.importDeckFromString(pastedText));
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _handleManualStudyStart(DeckModel deck) => Navigator.push(context, MaterialPageRoute(builder: (context) => ManualStudyScreen(deck: deck)));
  void _handleAutoplayStart(DeckModel deck) => Navigator.push(context, MaterialPageRoute(builder: (context) => AutoplayScreen(deck: deck, startIndex: deck.lastReviewedCardIndex ?? 0)));
  Future<void> _handleDeckReview(DeckModel deck) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => ReviewNotesScreen(deck: deck)));
    if (result == true && mounted) _loadAllData();
  }
  Future<void> _handleDeckExport(DeckModel deck) async {
    final message = await _exporterService.exportDeck(deck);
    if (mounted && message != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Decks'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.setting_2),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
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
                  Text(_isImporting ? "Importing deck..." : "Loading data..."),
                ],
              ),
            )
          : _buildContent(),
      floatingActionButton: PopupMenuButton<String>(
        tooltip: 'Add...',
        onSelected: (String value) async {
          if (value == 'create_deck') {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const DeckEditScreen()));
            if (result == true && mounted) _loadAllData();
          } else if (value == 'create_folder') {
            _showCreateOrRenameFolderDialog();
          } else if (value == 'import_file') {
            _pickAndImportDeck();
          } else if (value == 'import_text') {
            _showImportFromTextDialog();
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'create_folder',
            child: ListTile(leading: Icon(Iconsax.folder_add), title: Text('Create Folder')),
          ),
          const PopupMenuItem<String>(
            value: 'create_deck',
            child: ListTile(leading: Icon(Iconsax.document_text_copy), title: Text('Create Deck')),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            value: 'import_file',
            child: ListTile(leading: Icon(Iconsax.document_upload), title: Text('Import from File')),
          ),
          const PopupMenuItem<String>(
            value: 'import_text',
            child: ListTile(leading: Icon(Iconsax.document_text), title: Text('Paste from Text')),
          ),
        ],
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: theme.colorScheme.primary.withAlpha(77), blurRadius: 8.0, offset: const Offset(0, 4))],
          ),
          child: const Icon(Iconsax.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final allDeckIdsInFolders = _folders.expand((f) => f.deckIds).toSet();
    final uncategorizedDecks = _decks.where((d) => !allDeckIdsInFolders.contains(d.id)).toList();

    if (_folders.isEmpty && uncategorizedDecks.isEmpty) {
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
                'Tap the "+" button to create a folder or a new deck.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      children: [
        if (_folders.isNotEmpty) ...[
          _buildSectionHeader('Folders'),
          ..._folders.map((folder) {
            final deckCount = folder.deckIds.length;
            return FolderListItem(
              folder: folder,
              deckCount: deckCount,
              onTap: () => _handleFolderTap(folder),
              onEdit: () => _showCreateOrRenameFolderDialog(existingFolder: folder),
              onDelete: () => _deleteFolder(folder),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
          }),
        ],
        if (uncategorizedDecks.isNotEmpty) ...[
          _buildSectionHeader('Uncategorized Decks'),
          ...uncategorizedDecks.map((deck) {
            return DeckListItem(
              deck: deck,
              onStudy: () => _handleManualStudyStart(deck),
              onPlay: () => _handleAutoplayStart(deck),
              onEdit: () => _handleDeckEdit(deck),
              onDelete: () => _showDeleteConfirmationDialog(deck),
              onExport: () => _handleDeckExport(deck),
              onReview: () => _handleDeckReview(deck),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
          }),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 16.0, top: 16.0, bottom: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
      ),
    );
  }
}