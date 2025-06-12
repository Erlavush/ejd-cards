// lib/features/study_mode/screens/manual_study_screen.dart

import 'dart:math';
import 'package:ejd_cards/core/models/card_model.dart';
import 'package:ejd_cards/core/models/deck_model.dart';
import 'package:ejd_cards/core/services/deck_persistence_service.dart';
import 'package:ejd_cards/core/widgets/flip_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class ManualStudyScreen extends StatefulWidget {
  final DeckModel deck;

  const ManualStudyScreen({super.key, required this.deck});

  @override
  State<ManualStudyScreen> createState() => _ManualStudyScreenState();
}

class _ManualStudyScreenState extends State<ManualStudyScreen> {
  int _currentIndex = 0;
  bool _showFront = true;
  bool _isShuffled = false;
  List<CardModel> _studyOrderCards = [];

  final Random _random = Random();
  final FlipCardController _flipCardController = FlipCardController();
  final DeckPersistenceService _persistenceService = DeckPersistenceService();

  @override
  void initState() {
    super.initState();
    _resetStudyOrder();
  }

  void _resetStudyOrder() {
    setState(() {
      _studyOrderCards = List<CardModel>.from(widget.deck.cards);
      if (_isShuffled && _studyOrderCards.isNotEmpty) {
        _studyOrderCards.shuffle(_random);
      }
      _currentIndex = 0;
      _showFront = true;
      _flipCardController.reset();
    });
  }

  void _toggleShuffle() {
    setState(() {
      _isShuffled = !_isShuffled;
    });
    _resetStudyOrder();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isShuffled ? 'Cards shuffled!' : 'Cards in original order.')),
    );
  }

  CardModel? get _currentCard => (_studyOrderCards.isEmpty || _currentIndex >= _studyOrderCards.length) ? null : _studyOrderCards[_currentIndex];

  void _flipCard() {
    if (_currentCard == null) return;
    _flipCardController.flip();
    setState(() {
      _showFront = !_showFront;
    });
  }

  void _nextCard() {
    if (_currentCard == null) return;
    if (_currentIndex < _studyOrderCards.length - 1) {
      setState(() {
        _currentIndex++;
        _showFront = true;
      });
      _flipCardController.reset();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You've reached the end of the deck!")));
    }
  }

  void _previousCard() {
    if (_currentCard == null) return;
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _showFront = true;
      });
      _flipCardController.reset();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You're at the beginning of the deck.")));
    }
  }

  Future<void> _markCardAs(bool needsReview) async {
    if (_currentCard == null) return;
    setState(() {
      _currentCard!.needsReview = needsReview;
    });

    final originalCardIndex = widget.deck.cards.indexWhere((card) => card.id == _currentCard!.id);
    if (originalCardIndex != -1) {
      widget.deck.cards[originalCardIndex].needsReview = needsReview;
    }

    await _persistenceService.saveDeck(widget.deck);
    _nextCard();
  }

  void _showExplanationDialog() {
    if (_currentCard?.explanation == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Explanation'),
        content: SingleChildScrollView(child: Text(_currentCard!.explanation!)),
        actions: [TextButton(child: const Text('Close'), onPressed: () => Navigator.of(ctx).pop())],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = _currentCard;
    final theme = Theme.of(context);
    final cardContentStyle = theme.textTheme.displaySmall?.copyWith(fontSize: 32);

    final frontWidget = Text(card?.frontText ?? "This deck is empty.", textAlign: TextAlign.center, style: cardContentStyle);
    final backWidget = Text(card?.backText ?? "Add cards to study.", textAlign: TextAlign.center, style: cardContentStyle);

    return Scaffold(
      appBar: AppBar(
        title: Text('Study: ${widget.deck.title}'),
        actions: [
          Tooltip(
            message: _isShuffled ? "Unshuffle Cards" : "Shuffle Cards",
            child: IconButton(
              icon: Icon(_isShuffled ? Iconsax.shuffle : Iconsax.shuffle),
              onPressed: widget.deck.cards.length > 1 ? _toggleShuffle : null,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_studyOrderCards.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Card ${_currentIndex + 1} of ${_studyOrderCards.length}', textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
              ),
            Expanded(
              child: GestureDetector(
                onTap: card != null ? _flipCard : null,
                child: FlipCardWidget(controller: _flipCardController, front: frontWidget, back: backWidget),
              ),
            ),
            const SizedBox(height: 20),
            if (card != null)
              _showFront
                  ? ElevatedButton.icon(
                      icon: const Icon(Iconsax.eye),
                      label: const Text('Show Answer'),
                      onPressed: _flipCard,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    )
                  : Column(
                      children: [
                        if (card.explanation != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: TextButton.icon(
                              icon: const Icon(Iconsax.document_text_1),
                              label: const Text('Why? Show Explanation'),
                              onPressed: _showExplanationDialog,
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Iconsax.dislike, color: Colors.white),
                                label: const Text('Review Again'),
                                onPressed: () => _markCardAs(true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(0, 50)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Iconsax.like_1, color: Colors.white),
                                label: const Text('I Knew This'),
                                onPressed: () => _markCardAs(false),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(0, 50)),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
            const SizedBox(height: 10),
            if (card != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Iconsax.arrow_left_2),
                      label: const Text('Previous'),
                      onPressed: _currentIndex > 0 ? _previousCard : null,
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      label: const Text('Next'),
                      icon: const Icon(Iconsax.arrow_right_3),
                      onPressed: _currentIndex < _studyOrderCards.length - 1 ? _nextCard : null,
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}