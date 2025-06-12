// lib/features/deck_management/services/deck_exporter_service.dart

import 'dart:convert';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';
import '../../../core/models/deck_model.dart';

class DeckExporterService {
  Future<String?> exportDeck(DeckModel deck) async {
    try {
      // Prepare the data for export. We only export the core content.
      final Map<String, dynamic> exportData = {
        'title': deck.title,
        'cards': deck.cards.map((card) => {
              'frontText': card.frontText,
              'backText': card.backText,
              'explanation': card.explanation,
            }).toList(),
      };

      // Use a pretty-printed JSON for better human readability
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      final bytes = utf8.encode(jsonString);

      // Sanitize the filename to remove invalid characters
      final sanitizedTitle = deck.title.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
      final fileName = 'EJD_Cards_${sanitizedTitle}.json';

      if (kIsWeb) {
        // On web, file_saver downloads the file directly to the user's machine.
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: bytes,
          ext: 'json',
          mimeType: MimeType.json,
        );
        return "Deck downloaded as $fileName";
      } else {
        // On mobile/desktop, use the share_plus package to open the native share sheet.
        // This gives the user the option to save to files, send via email, airdrop, etc.
        final xfile = XFile.fromData(
          bytes,
          mimeType: 'application/json',
          name: fileName,
        );
        await Share.shareXFiles([xfile], subject: 'EJD Cards Deck: ${deck.title}');
        return null; // Don't show a snackbar on success, as the share sheet is the feedback.
      }
    } catch (e) {
      print("Error exporting deck: $e");
      return "Failed to export deck. Error: $e";
    }
  }
}