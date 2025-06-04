// lib/features/study_mode/screens/manual_study_screen.dart
import 'package:flutter/material.dart';
import '../../../core/models/deck_model.dart';
import '../../../core/models/card_model.dart';

class ManualStudyScreen extends StatefulWidget {
  final DeckModel deck;

  const ManualStudyScreen({super.key, required this.deck});

  @override
  State<ManualStudyScreen> createState() => _ManualStudyScreenState();
}

class _ManualStudyScreenState extends State<ManualStudyScreen> {
  int _currentIndex = 0; // Index of the current card being viewed
  bool _showFront = true;  // True to show front, false to show back

  // Getter for the current card, handles empty deck case
  CardModel? get _currentCard {
    if (widget.deck.cards.isEmpty || _currentIndex >= widget.deck.cards.length) {
      return null;
    }
    return widget.deck.cards[_currentIndex];
  }

  void _flipCard() {
    if (_currentCard == null) return; // Don't do anything if there's no card
    setState(() {
      _showFront = !_showFront;
    });
  }

  void _nextCard() {
    if (_currentCard == null) return;
    if (_currentIndex < widget.deck.cards.length - 1) {
      setState(() {
        _currentIndex++;
        _showFront = true; // Always show front of new card first
      });
    } else {
      // Optional: Show a message or loop back to the beginning
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You've reached the end of the deck!"))
      );
      // To loop:
      // setState(() {
      //   _currentIndex = 0;
      //   _showFront = true;
      // });
    }
  }

  void _previousCard() {
    if (_currentCard == null) return;
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _showFront = true; // Always show front of new card first
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You're at the beginning of the deck."))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = _currentCard; // Get the current card safely

    return Scaffold(
      appBar: AppBar(
        title: Text('Study: ${widget.deck.title}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Indicator
            if (widget.deck.cards.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Card ${_currentIndex + 1} of ${widget.deck.cards.length}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),

            // Card Display Area
            Expanded(
              child: GestureDetector( // Allow tapping the card to flip
                onTap: _flipCard,
                child: Card(
                  elevation: 4.0,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        card == null
                            ? "This deck has no cards."
                            : (_showFront ? card.frontText : card.backText),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Control Buttons
            if (card != null) // Only show buttons if there's a card
              Column(
                children: [
                  ElevatedButton.icon(
                    icon: Icon(_showFront ? Icons.flip_to_back_outlined : Icons.flip_to_front_outlined),
                    label: Text(_showFront ? 'Show Answer' : 'Show Question'),
                    onPressed: _flipCard,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50), // full width
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.arrow_back_ios_new),
                          label: const Text('Previous'),
                          onPressed: _currentIndex > 0 ? _previousCard : null, // Disable if at first card
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 50),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          label: const Text('Next'),
                          icon: const Icon(Icons.arrow_forward_ios),
                          onPressed: _currentIndex < widget.deck.cards.length - 1 ? _nextCard : null, // Disable if at last card
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 20),
            TextButton( // Back to Decks button
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to Decks List'),
            )
          ],
        ),
      ),
    );
  }
}