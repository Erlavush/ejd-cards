// lib/core/services/deck_persistence_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb; // Important for checking platform
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/deck_model.dart';

class DeckPersistenceService {
  // --- For Web ---
  static const String _webStorageKey = 'all_decks_storage';

  // --- For Mobile/Desktop ---
  static const String _decksFolderName = "flashcard_decks";

  // Gets the directory where decks are stored, creating it if it doesn't exist.
  // This method is ONLY for non-web platforms.
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

  // --- Platform-Aware Methods ---

  Future<void> saveDeck(DeckModel deck) async {
    if (kIsWeb) {
      // WEB: Load all decks, add/update this one, save all back.
      final decks = await loadDecks();
      final index = decks.indexWhere((d) => d.id == deck.id);
      if (index != -1) {
        decks[index] = deck; // Update existing
      } else {
        decks.add(deck); // Add new
      }
      await _saveAllDecksForWeb(decks);
    } else {
      // MOBILE/DESKTOP: Save to individual file.
      try {
        final filePath = await _getFilePath(deck.id);
        final file = File(filePath);
        final jsonString = const JsonEncoder.withIndent('  ').convert(deck.toMap());
        await file.writeAsString(jsonString);
        print('Deck saved: ${deck.title} to $filePath');
      } catch (e) {
        print('Error saving deck ${deck.id}: $e');
      }
    }
  }

  Future<List<DeckModel>> loadDecks() async {
    if (kIsWeb) {
      // WEB: Load the single JSON string from shared_preferences.
      try {
        final prefs = await SharedPreferences.getInstance();
        final String? allDecksJson = prefs.getString(_webStorageKey);
        if (allDecksJson == null) {
          return [];
        }
        final List<dynamic> deckList = jsonDecode(allDecksJson);
        final decks = deckList.map((map) => DeckModel.fromMap(map)).toList();
        print('Loaded ${decks.length} decks from web storage.');
        return decks;
      } catch (e) {
        print('Error loading decks from web storage: $e');
        return [];
      }
    } else {
      // MOBILE/DESKTOP: Load all individual files.
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
            }
          }
        }
        print('Loaded ${decks.length} decks from file system.');
        return decks;
      } catch (e) {
        print('Error loading decks directory: $e');
        return [];
      }
    }
  }

  Future<void> deleteDeck(String deckId) async {
    if (kIsWeb) {
      // WEB: Load all, remove one, save all back.
      final decks = await loadDecks();
      decks.removeWhere((deck) => deck.id == deckId);
      await _saveAllDecksForWeb(decks);
    } else {
      // MOBILE/DESKTOP: Delete the individual file.
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
  }

  Future<void> deleteAllDecks() async {
    if (kIsWeb) {
      // WEB: Just remove the key from shared_preferences.
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_webStorageKey);
      print('All web storage decks deleted.');
    } else {
      // MOBILE/DESKTOP: Delete the whole directory.
      try {
        final dir = await _getDecksDirectory();
        if (await dir.exists()) {
          await dir.delete(recursive: true);
          print('All deck files deleted.');
          await _getDecksDirectory();
        }
      } catch (e) {
        print('Error deleting all decks: $e');
      }
    }
  }

  // Helper method specifically for saving all decks on the web
  Future<void> _saveAllDecksForWeb(List<DeckModel> decks) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> deckListMap = decks.map((deck) => deck.toMap()).toList();
    final allDecksJson = jsonEncode(deckListMap);
    await prefs.setString(_webStorageKey, allDecksJson);
    print('Saved ${decks.length} decks to web storage.');
  }
}