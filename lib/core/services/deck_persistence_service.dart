// lib/core/services/deck_persistence_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:ejd_cards/core/models/folder_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Important for checking platform
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/deck_model.dart';

class DeckPersistenceService {
  // --- For Web ---
  // This key now points to a JSON object containing both decks and folders.
  // e.g., { "decks": [...], "folders": [...] }
  static const String _webStorageContainerKey = 'app_data_storage';

  // --- For Mobile/Desktop ---
  static const String _decksFolderName = "flashcard_decks";
  static const String _foldersFolderName = "flashcard_folders";

  // --- Directory Helpers (Mobile/Desktop) ---

  Future<Directory> _getDecksDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final decksDir = Directory('${appDocDir.path}/$_decksFolderName');
    if (!await decksDir.exists()) {
      await decksDir.create(recursive: true);
    }
    return decksDir;
  }

  Future<Directory> _getFoldersDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final foldersDir = Directory('${appDocDir.path}/$_foldersFolderName');
    if (!await foldersDir.exists()) {
      await foldersDir.create(recursive: true);
    }
    return foldersDir;
  }

  Future<String> _getDeckFilePath(String deckId) async {
    final dir = await _getDecksDirectory();
    return '${dir.path}/$deckId.json';
  }

  Future<String> _getFolderFilePath(String folderId) async {
    final dir = await _getFoldersDirectory();
    return '${dir.path}/$folderId.json';
  }

  // --- Web Storage Helpers ---

  Future<Map<String, dynamic>> _loadWebContainer() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_webStorageContainerKey);
    if (jsonString == null) {
      return {'decks': [], 'folders': []}; // Return empty structure
    }
    try {
      final data = jsonDecode(jsonString);
      return {
        'decks': data['decks'] ?? [],
        'folders': data['folders'] ?? [],
      };
    } catch (e) {
      print("Error loading web container, resetting. Error: $e");
      return {'decks': [], 'folders': []};
    }
  }

  Future<void> _saveWebContainer(List<DeckModel> decks, List<FolderModel> folders) async {
    final prefs = await SharedPreferences.getInstance();
    final containerMap = {
      'decks': decks.map((d) => d.toMap()).toList(),
      'folders': folders.map((f) => f.toMap()).toList(),
    };
    final jsonString = jsonEncode(containerMap);
    await prefs.setString(_webStorageContainerKey, jsonString);
    print('Saved ${decks.length} decks and ${folders.length} folders to web storage.');
  }

  // --- Deck Methods ---

  Future<void> saveDeck(DeckModel deck) async {
    if (kIsWeb) {
      final container = await _loadWebContainer();
      final decks = (container['decks'] as List).map((d) => DeckModel.fromMap(d)).toList();
      final folders = (container['folders'] as List).map((f) => FolderModel.fromMap(f)).toList();
      
      final index = decks.indexWhere((d) => d.id == deck.id);
      if (index != -1) {
        decks[index] = deck;
      } else {
        decks.add(deck);
      }
      await _saveWebContainer(decks, folders);
    } else {
      try {
        final filePath = await _getDeckFilePath(deck.id);
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
      final container = await _loadWebContainer();
      final decks = (container['decks'] as List).map((d) => DeckModel.fromMap(d)).toList();
      print('Loaded ${decks.length} decks from web storage.');
      return decks;
    } else {
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
      final container = await _loadWebContainer();
      final decks = (container['decks'] as List).map((d) => DeckModel.fromMap(d)).toList();
      final folders = (container['folders'] as List).map((f) => FolderModel.fromMap(f)).toList();
      
      decks.removeWhere((deck) => deck.id == deckId);
      // Also remove this deckId from any folder that contains it
      for (var folder in folders) {
        folder.deckIds.remove(deckId);
      }

      await _saveWebContainer(decks, folders);
    } else {
      try {
        final filePath = await _getDeckFilePath(deckId);
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
          print('Deck file deleted: $deckId.json');
        }
        // We also need to update any folder that contains this deckId
        final folders = await loadFolders();
        for (var folder in folders) {
          if (folder.deckIds.contains(deckId)) {
            folder.deckIds.remove(deckId);
            await saveFolder(folder);
          }
        }
      } catch (e) {
        print('Error deleting deck file $deckId.json: $e');
      }
    }
  }

  // --- Folder Methods ---

  Future<void> saveFolder(FolderModel folder) async {
    if (kIsWeb) {
      final container = await _loadWebContainer();
      final decks = (container['decks'] as List).map((d) => DeckModel.fromMap(d)).toList();
      final folders = (container['folders'] as List).map((f) => FolderModel.fromMap(f)).toList();
      
      final index = folders.indexWhere((f) => f.id == folder.id);
      if (index != -1) {
        folders[index] = folder;
      } else {
        folders.add(folder);
      }
      await _saveWebContainer(decks, folders);
    } else {
      try {
        final filePath = await _getFolderFilePath(folder.id);
        final file = File(filePath);
        final jsonString = const JsonEncoder.withIndent('  ').convert(folder.toMap());
        await file.writeAsString(jsonString);
        print('Folder saved: ${folder.title} to $filePath');
      } catch (e) {
        print('Error saving folder ${folder.id}: $e');
      }
    }
  }

  Future<List<FolderModel>> loadFolders() async {
    if (kIsWeb) {
      final container = await _loadWebContainer();
      final folders = (container['folders'] as List).map((f) => FolderModel.fromMap(f)).toList();
      print('Loaded ${folders.length} folders from web storage.');
      return folders;
    } else {
      try {
        final dir = await _getFoldersDirectory();
        final List<FolderModel> folders = [];
        final List<FileSystemEntity> entities = await dir.list().toList();

        for (FileSystemEntity entity in entities) {
          if (entity is File && entity.path.endsWith('.json')) {
            try {
              final jsonString = await entity.readAsString();
              final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
              folders.add(FolderModel.fromMap(jsonMap));
            } catch (e) {
              print('Error reading or parsing folder file ${entity.path}: $e');
            }
          }
        }
        print('Loaded ${folders.length} folders from file system.');
        return folders;
      } catch (e) {
        print('Error loading folders directory: $e');
        return [];
      }
    }
  }

  Future<void> deleteFolder(String folderId) async {
    if (kIsWeb) {
      final container = await _loadWebContainer();
      final decks = (container['decks'] as List).map((d) => DeckModel.fromMap(d)).toList();
      final folders = (container['folders'] as List).map((f) => FolderModel.fromMap(f)).toList();
      
      folders.removeWhere((folder) => folder.id == folderId);
      await _saveWebContainer(decks, folders);
    } else {
      try {
        final filePath = await _getFolderFilePath(folderId);
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
          print('Folder file deleted: $folderId.json');
        }
      } catch (e) {
        print('Error deleting folder file $folderId.json: $e');
      }
    }
  }

  // --- Global Methods ---

  // This method replaces the old `deleteAllDecks`
  Future<void> deleteAllData() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_webStorageContainerKey);
      print('All web storage data deleted.');
    } else {
      try {
        final decksDir = await _getDecksDirectory();
        if (await decksDir.exists()) {
          await decksDir.delete(recursive: true);
          print('All deck files deleted.');
        }
        final foldersDir = await _getFoldersDirectory();
        if (await foldersDir.exists()) {
          await foldersDir.delete(recursive: true);
          print('All folder files deleted.');
        }
        // Re-create the directories so the app doesn't crash
        await _getDecksDirectory();
        await _getFoldersDirectory();
      } catch (e) {
        print('Error deleting all data: $e');
      }
    }
  }
}