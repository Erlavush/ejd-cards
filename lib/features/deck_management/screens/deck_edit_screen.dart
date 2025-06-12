// lib/features/deck_management/screens/deck_edit_screen.dart

import 'package:ejd_cards/core/services/deck_persistence_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/card_model.dart';
import '../../../core/models/deck_model.dart';

class DeckEditScreen extends StatefulWidget {
  final DeckModel? initialDeck;

  const DeckEditScreen({super.key, this.initialDeck});

  @override
  State<DeckEditScreen> createState() => _DeckEditScreenState();
}

class _DeckEditScreenState extends State<DeckEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _customFrontTimeController;
  late TextEditingController _customBackTimeController;
  late List<CardModel> _cards;
  late String _deckId;
  late DateTime _createdAt;

  bool _isNewDeck = false;
  final Uuid _uuid = const Uuid();
  final DeckPersistenceService _persistenceService = DeckPersistenceService();

  @override
  void initState() {
    super.initState();
    if (widget.initialDeck == null) {
      _isNewDeck = true;
      _deckId = _uuid.v4();
      _titleController = TextEditingController();
      _customFrontTimeController = TextEditingController();
      _customBackTimeController = TextEditingController();
      _cards = [];
      _createdAt = DateTime.now();
    } else {
      _isNewDeck = false;
      _deckId = widget.initialDeck!.id;
      _createdAt = widget.initialDeck!.createdAt;
      _titleController = TextEditingController(text: widget.initialDeck!.title);
      _customFrontTimeController = TextEditingController(text: widget.initialDeck!.customFrontTimeSeconds?.toString() ?? '');
      _customBackTimeController = TextEditingController(text: widget.initialDeck!.customBackTimeSeconds?.toString() ?? '');
      _cards = List<CardModel>.from(widget.initialDeck!.cards.map(
        (card) => CardModel(
          id: card.id,
          frontText: card.frontText,
          backText: card.backText,
          explanation: card.explanation,
          needsReview: card.needsReview,
        ),
      ));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _customFrontTimeController.dispose();
    _customBackTimeController.dispose();
    super.dispose();
  }

  Future<void> _saveDeck() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final int? customFrontTime = int.tryParse(_customFrontTimeController.text.trim());
      final int? customBackTime = int.tryParse(_customBackTimeController.text.trim());

      final updatedDeck = DeckModel(
        id: _deckId,
        title: _titleController.text.trim(),
        cards: _cards,
        createdAt: _createdAt,
        lastStudiedAt: widget.initialDeck?.lastStudiedAt,
        lastReviewedCardIndex: widget.initialDeck?.lastReviewedCardIndex,
        customFrontTimeSeconds: (customFrontTime != null && customFrontTime > 0) ? customFrontTime : null,
        customBackTimeSeconds: (customBackTime != null && customBackTime > 0) ? customBackTime : null,
      );

      await _persistenceService.saveDeck(updatedDeck);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deck "${updatedDeck.title}" saved successfully!')),
        );
        Navigator.of(context).pop(true);
      }
    }
  }

  void _addOrEditCard({CardModel? existingCard, int? cardIndex}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final frontController = TextEditingController(text: existingCard?.frontText ?? '');
        final backController = TextEditingController(text: existingCard?.backText ?? '');
        final explanationController = TextEditingController(text: existingCard?.explanation ?? '');
        final cardFormKey = GlobalKey<FormState>();

        return AlertDialog(
          title: Text(existingCard == null ? 'Add New Card' : 'Edit Card'),
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
              child: const Text('Save Card'),
              onPressed: () {
                if (cardFormKey.currentState!.validate()) {
                  setState(() {
                    final explanationText = explanationController.text.trim();
                    if (existingCard == null) {
                      _cards.add(CardModel(
                        id: _uuid.v4(),
                        frontText: frontController.text.trim(),
                        backText: backController.text.trim(),
                        explanation: explanationText.isEmpty ? null : explanationText,
                      ));
                    } else {
                      if (cardIndex != null) {
                        _cards[cardIndex] = CardModel(
                          id: existingCard.id,
                          frontText: frontController.text.trim(),
                          backText: backController.text.trim(),
                          explanation: explanationText.isEmpty ? null : explanationText,
                          needsReview: existingCard.needsReview,
                        );
                      }
                    }
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteCard(int index) {
    if (index < 0 || index >= _cards.length) return;
    final cardToDelete = _cards[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Card?'),
        content: Text('Are you sure you want to delete this card?\nFront: "${cardToDelete.frontText}"'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _cards.removeAt(index);
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNewDeck ? 'Create New Deck' : 'Edit Deck'),
        leading: IconButton(
          icon: const Icon(Iconsax.close_circle),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.save_2),
            tooltip: 'Save Deck',
            onPressed: _saveDeck,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Deck Title',
                        border: OutlineInputBorder(),
                        hintText: 'Enter a title for your deck',
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Deck title cannot be empty.' : null,
                    ),
                    const SizedBox(height: 24),
                    Text('Custom Autoplay Times (Optional)', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _buildCustomTimeRow(
                      label: 'Front Time (sec):',
                      controller: _customFrontTimeController,
                      hint: 'Global default',
                    ),
                    _buildCustomTimeRow(
                      label: 'Back Time (sec):',
                      controller: _customBackTimeController,
                      hint: 'Global default',
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Cards (${_cards.length})', style: Theme.of(context).textTheme.titleMedium),
                        ElevatedButton.icon(
                          icon: const Icon(Iconsax.add_square),
                          label: const Text('Add Card'),
                          onPressed: () => _addOrEditCard(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: _cards.isEmpty
                  ? const Center(child: Text('No cards in this deck yet. Add one!'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _cards.length,
                      itemBuilder: (context, index) {
                        final card = _cards[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            leading: card.needsReview ? Tooltip(
                                    message: 'Marked for review',
                                    child: Icon(Iconsax.bookmark, color: Colors.orange[600]),
                                  ) : null,
                            title: Text(card.frontText, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(card.backText, maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Iconsax.edit),
                                  onPressed: () => _addOrEditCard(existingCard: card, cardIndex: index),
                                ),
                                IconButton(
                                  icon: const Icon(Iconsax.trash, color: Colors.redAccent),
                                  onPressed: () => _deleteCard(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTimeRow({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label)),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: hint,
                isDense: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                final num = int.tryParse(value.trim());
                if (num == null || num <= 0) return 'Must be >0';
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}