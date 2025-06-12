// lib/core/services/deck_persistence_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/deck_model.dart';

class DeckPersistenceService {
  static const String _decksFolderName = "flashcard_decks";

  // Gets the directory where decks are stored, creating it if it doesn't exist.
  Future<Directory> _getDecksDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final decksDir = Directory('${appDocDir.path}/$_decksFolderName');
    if (!await decksDir.exists()) {
      await decksDir.create(recursive: true);
    }
    return decksDir;
  }

  // Gets the full file path for a given deck ID.
  Future<String> _getFilePath(String deckId) async {
    final dir = await _getDecksDirectory();
    return '${dir.path}/$deckId.json';
  }

  // Saves a single deck to a JSON file.
  Future<void> saveDeck(DeckModel deck) async {
    try {
      final filePath = await _getFilePath(deck.id);
      final file = File(filePath);
      // Use a pretty-printed JSON for easier debugging if needed
      final jsonString = const JsonEncoder.withIndent('  ').convert(deck.toMap());
      await file.writeAsString(jsonString);
      print('Deck saved: ${deck.title} to $filePath');
    } catch (e) {
      print('Error saving deck ${deck.id}: $e');
    }
  }

  // Loads all decks from their respective JSON files.
  Future<List<DeckModel>> loadDecks() async {
    try {
      final dir = await _getDecksDirectory();
      final List<DeckModel> decks = [];
      final List<FileSystemEntity> entities = await dir.list().toList();

      for (FileSystemEntity entity in entities) {
        if (entity is File && entity.path.endsWith('.json')) {
          try {
            final jsonString = await entity.readAsString();
            final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
            decks.add(DeckModel.fromMap(jsonMap));
          } catch (e) {
            print('Error reading or parsing deck file ${entity.path}: $e');
            // Optionally, delete or move corrupted files
          }
        }
      }
      print('Loaded ${decks.length} decks from persistence.');
      return decks;
    } catch (e) {
      print('Error loading decks directory: $e');
      return []; // Return empty list on error
    }
  }

  // Deletes the JSON file for a specific deck.
  Future<void> deleteDeck(String deckId) async {
    try {
      final filePath = await _getFilePath(deckId);
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print('Deck file deleted: $deckId.json');
      }
    } catch (e) {
      print('Error deleting deck file $deckId.json: $e');
    }
  }

  // Deletes the entire decks folder. Used for the "Reset App Data" feature.
  Future<void> deleteAllDecks() async {
    try {
      final dir = await _getDecksDirectory();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        print('All deck files deleted.');
        await _getDecksDirectory(); // Recreate the empty directory for future use
      }
    } catch (e) {
      print('Error deleting all decks: $e');
    }
  }
}