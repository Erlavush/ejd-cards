// lib/features/deck_management/services/deck_importer_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../../../core/models/deck_model.dart';
import '../../../core/models/card_model.dart';

class DeckImporterService {
  final Uuid _uuid = const Uuid();

  Future<ParseResult> importDeckFromFile(Uint8List fileBytes) async {
    try {
      final String content = utf8.decode(fileBytes);
      final Map<String, dynamic> jsonMap = jsonDecode(content);

      // Validate top-level keys
      if (!jsonMap.containsKey('title') || !jsonMap.containsKey('cards')) {
        return ParseResult(error: "JSON file is missing 'title' or 'cards' field.");
      }

      final String title = jsonMap['title'];
      final List<dynamic> cardMaps = jsonMap['cards'];

      if (title.trim().isEmpty) {
        return ParseResult(error: "Deck 'title' in JSON cannot be empty.");
      }

      // Create a new DeckModel from the parsed data.
      // We generate new IDs for the imported deck and cards to avoid conflicts.
      final newDeck = DeckModel(
        id: _uuid.v4(),
        title: title,
        cards: cardMaps.map((cardMap) {
          return CardModel(
            id: _uuid.v4(),
            frontText: cardMap['frontText'] ?? '',
            backText: cardMap['backText'] ?? '',
            explanation: cardMap['explanation'],
            // needsReview is intentionally not imported, as it's user-specific progress
            needsReview: false,
          );
        }).toList(),
        createdAt: DateTime.now(),
      );

      return ParseResult(deck: newDeck);
    } catch (e) {
      return ParseResult(error: "Failed to parse JSON file. Error: ${e.toString()}");
    }
  }
}

class ParseResult {
  final DeckModel? deck;
  final String? error;

  ParseResult({this.deck, this.error});

  bool get hasError => error != null;
}