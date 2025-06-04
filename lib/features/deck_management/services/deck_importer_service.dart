// lib/features/deck_management/services/deck_importer_service.dart
import 'dart:convert'; // For utf8 decoding
import 'dart:typed_data'; // For Uint8List
import 'package:uuid/uuid.dart';
import '../../../core/models/card_model.dart';
import '../../../core/models/deck_model.dart';

class DeckImporterService {
  final Uuid _uuid = const Uuid();

  // Result class for parsing
  ParseResult parseDeckFromFileContent(String fileContent) {
    final lines = fileContent.split('\n').map((line) => line.trimRight()).toList(); // Keep leading spaces, trim trailing
    String? deckTitle;
    final List<CardModel> cards = [];
    String currentFrontText = '';
    String currentBackText = '';
    bool parsingFront = false;
    bool parsingBack = false;

    if (lines.isEmpty) {
      return ParseResult(error: "File is empty.");
    }

    // 1. Parse Deck Title
    final titleLine = lines.first.trim();
    if (titleLine.startsWith('[DECK_TITLE:') && titleLine.endsWith(']')) {
      deckTitle = titleLine.substring('[DECK_TITLE:'.length, titleLine.length - 1).trim();
      if (deckTitle.isEmpty) {
        return ParseResult(error: "Deck title cannot be empty.");
      }
    } else {
      return ParseResult(error: "Invalid or missing deck title. Expected format: [DECK_TITLE: Your Title]");
    }

    // 2. Parse Cards
    // Start parsing from the line after the title
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i]; // No trim here, preserve internal structure

      if (line.trim() == '---') { // Card separator
        if (parsingFront || parsingBack) { // If we were parsing a card, save it
          if (currentFrontText.trim().isNotEmpty && currentBackText.trim().isNotEmpty) {
            cards.add(CardModel(
              id: _uuid.v4(),
              frontText: currentFrontText.trim(), // Trim only at the end
              backText: currentBackText.trim(),   // Trim only at the end
            ));
          } else if (currentFrontText.trim().isNotEmpty || currentBackText.trim().isNotEmpty) {
            // Incomplete card, could be an error or just an empty card part
             return ParseResult(error: "Incomplete card found before separator '---'. Both [Q] and [A] parts are needed.");
          }
          // Reset for next card
          currentFrontText = '';
          currentBackText = '';
          parsingFront = false;
          parsingBack = false;
        }
      } else if (line.trim() == '[Q]') {
        if (parsingBack) { // If we were parsing back, it means [Q] came after [A] without ---
             return ParseResult(error: "Found [Q] while expecting card separator '---' or end of answer. Card structure error.");
        }
        parsingFront = true;
        parsingBack = false;
        currentFrontText = ''; // Reset for multi-line Q
      } else if (line.trim() == '[A]') {
        if (!parsingFront) { // [A] appeared without a preceding [Q]
             return ParseResult(error: "Found [A] without a preceding [Q]. Card structure error.");
        }
        parsingFront = false;
        parsingBack = true;
        currentBackText = ''; // Reset for multi-line A
      } else if (parsingFront) {
        currentFrontText += (currentFrontText.isEmpty ? '' : '\n') + line;
      } else if (parsingBack) {
        currentBackText += (currentBackText.isEmpty ? '' : '\n') + line;
      }
      // Lines not part of Q/A or separators are ignored (e.g. empty lines between --- and [Q])
    }

    // Add the last card if any was being parsed
    if (currentFrontText.trim().isNotEmpty && currentBackText.trim().isNotEmpty) {
      cards.add(CardModel(
        id: _uuid.v4(),
        frontText: currentFrontText.trim(),
        backText: currentBackText.trim(),
      ));
    } else if (parsingFront || parsingBack) {
         // Last card was incomplete
         return ParseResult(error: "The last card in the file is incomplete. Ensure it has both [Q] and [A] sections before the end of the file.");
    }


    if (cards.isEmpty && deckTitle.isNotEmpty) {
        // It's valid to have a deck with a title but no cards initially
         DeckModel deck = DeckModel(id: _uuid.v4(), title: deckTitle, cards: cards);
         return ParseResult(deck: deck);
    } else if (cards.isNotEmpty && deckTitle.isNotEmpty) {
        DeckModel deck = DeckModel(id: _uuid.v4(), title: deckTitle, cards: cards);
        return ParseResult(deck: deck);
    }

    return ParseResult(error: "Could not parse the deck. Unknown error or empty card list after processing.");
  }

  Future<ParseResult> importDeckFromFile(Uint8List fileBytes) async {
    try {
      final String content = utf8.decode(fileBytes); // Use utf8.decode
      return parseDeckFromFileContent(content);
    } catch (e) {
      return ParseResult(error: "Error reading file: ${e.toString()}");
    }
  }
}

// Helper class to return parsing result (either a deck or an error)
class ParseResult {
  final DeckModel? deck;
  final String? error;

  ParseResult({this.deck, this.error});

  bool get hasError => error != null;
}