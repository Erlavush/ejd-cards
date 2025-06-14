// lib/features/deck_management/screens/review_notes_screen.dart

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/models/card_model.dart';
import '../../../core/models/deck_model.dart';
import '../../../core/services/deck_persistence_service.dart';

class ReviewNotesScreen extends StatefulWidget {
  final DeckModel deck;

  const ReviewNotesScreen({super.key, required this.deck});

  @override
  State<ReviewNotesScreen> createState() => _ReviewNotesScreenState();
}

class _ReviewNotesScreenState extends State<ReviewNotesScreen> {
  late List<CardModel> _cards;
  final DeckPersistenceService _persistenceService = DeckPersistenceService();

  @override
  void initState() {
    super.initState();
    // Create a mutable copy of the cards list to allow for in-place editing
    _cards = List<CardModel>.from(widget.deck.cards);
  }

  Future<void> _saveDeckChanges() async {
    // Update the original deck object with the modified cards list
    widget.deck.cards = _cards;
    await _persistenceService.saveDeck(widget.deck);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved.')),
      );
    }
  }

  void _editCard(int cardIndex) {
    final cardToEdit = _cards[cardIndex];
    final frontController = TextEditingController(text: cardToEdit.frontText);
    final backController = TextEditingController(text: cardToEdit.backText);
    final explanationController = TextEditingController(text: cardToEdit.explanation ?? '');
    final cardFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Card'),
          content: SingleChildScrollView(
            child: Form(
              key: cardFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: frontController,
                    decoration: const InputDecoration(labelText: 'Front Text (Question)'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Front text cannot be empty' : null,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: backController,
                    decoration: const InputDecoration(labelText: 'Back Text (Answer)'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Back text cannot be empty' : null,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: explanationController,
                    decoration: const InputDecoration(labelText: 'Explanation (Optional)'),
                    maxLines: 4,
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Save Changes'),
              onPressed: () async {
                if (cardFormKey.currentState!.validate()) {
                  final explanationText = explanationController.text.trim();
                  setState(() {
                    _cards[cardIndex].frontText = frontController.text.trim();
                    _cards[cardIndex].backText = backController.text.trim();
                    _cards[cardIndex].explanation = explanationText.isEmpty ? null : explanationText;
                  });
                  await _saveDeckChanges();
                  if (mounted) Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Review: ${widget.deck.title}'),
        centerTitle: true,
        // Let the user know that changes are saved automatically via snackbar
        // but they can pop the screen to return.
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => Navigator.of(context).pop(true), // Return true to signal a potential update
        ),
      ),
      body: _cards.isEmpty
          ? const Center(
              child: Text(
                'This deck has no cards to review.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                final card = _cards[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRow(
                          context: context,
                          icon: Iconsax.message_question,
                          title: 'Question',
                          content: card.frontText,
                        ),
                        const Divider(height: 24),
                        _buildRow(
                          context: context,
                          icon: Iconsax.message_text_1,
                          title: 'Answer',
                          content: card.backText,
                        ),
                        if (card.explanation != null && card.explanation!.isNotEmpty) ...[
                          const Divider(height: 24),
                          _buildRow(
                            context: context,
                            icon: Iconsax.document_text,
                            title: 'Explanation',
                            content: card.explanation!,
                          ),
                        ],
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(Iconsax.edit, size: 18),
                            label: const Text('Edit Card'),
                            onPressed: () => _editCard(index),
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                content,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}