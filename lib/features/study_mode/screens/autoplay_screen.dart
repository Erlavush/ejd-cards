// lib/features/study_mode/screens/autoplay_screen.dart
import 'dart:async'; // Required for Timer
import 'package:flutter/material.dart';
import '../../../core/models/deck_model.dart';
import '../../../core/models/card_model.dart';

// Default timings if not set per deck or globally (we'll add global settings later)
const int DEFAULT_FRONT_SECONDS = 5;
const int DEFAULT_BACK_SECONDS = 7;

enum AutoplayStatus { playing, paused, stopped, finished }

class AutoplayScreen extends StatefulWidget {
  final DeckModel deck;

  const AutoplayScreen({super.key, required this.deck});

  @override
  State<AutoplayScreen> createState() => _AutoplayScreenState();
}

class _AutoplayScreenState extends State<AutoplayScreen> {
  int _currentIndex = 0;
  bool _showFront = true;
  AutoplayStatus _status = AutoplayStatus.stopped;
  Timer? _cardTimer; // Timer for showing front/back of a card
  Timer? _transitionDelayTimer; // Timer for a small delay before next card

  // For displaying progress on the timer bar
  int _currentTimerDuration = 0;
  int _timeRemaining = 0;

  @override
  void initState() {
    super.initState();
    if (widget.deck.cards.isNotEmpty) {
      _status = AutoplayStatus.playing; // Start playing immediately
      _startCardCycle();
    } else {
      _status = AutoplayStatus.finished; // No cards to play
    }
  }

  @override
  void dispose() {
    _cardTimer?.cancel();
    _transitionDelayTimer?.cancel();
    super.dispose();
  }

  CardModel? get _currentCard {
    if (widget.deck.cards.isEmpty || _currentIndex >= widget.deck.cards.length) {
      return null;
    }
    return widget.deck.cards[_currentIndex];
  }

  int get _frontDuration {
    return widget.deck.customFrontTimeSeconds ?? DEFAULT_FRONT_SECONDS;
  }

  int get _backDuration {
    return widget.deck.customBackTimeSeconds ?? DEFAULT_BACK_SECONDS;
  }

  void _startCardCycle() {
    if (_status != AutoplayStatus.playing || _currentCard == null) return;

    setState(() {
      _showFront = true;
      _currentTimerDuration = _frontDuration;
      _timeRemaining = _frontDuration;
    });
    _cardTimer?.cancel(); // Cancel any existing timer

    _cardTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_status != AutoplayStatus.playing) {
        timer.cancel();
        return;
      }
      setState(() {
        _timeRemaining--;
      });

      if (_timeRemaining <= 0) {
        timer.cancel();
        if (_showFront) {
          _showBackSide();
        } else {
          // Optional small delay before moving to the next card
          _transitionDelayTimer = Timer(const Duration(milliseconds: 500), () {
             _moveToNextCard();
          });
        }
      }
    });
  }

  void _showBackSide() {
    if (_status != AutoplayStatus.playing || _currentCard == null) return;

    setState(() {
      _showFront = false;
      _currentTimerDuration = _backDuration;
      _timeRemaining = _backDuration;
    });
    _cardTimer?.cancel();

    _cardTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_status != AutoplayStatus.playing) {
        timer.cancel();
        return;
      }
      setState(() {
        _timeRemaining--;
      });
      if (_timeRemaining <= 0) {
        timer.cancel();
        // Optional small delay before moving to the next card
        _transitionDelayTimer = Timer(const Duration(milliseconds: 500), () {
            _moveToNextCard();
        });
      }
    });
  }

  void _moveToNextCard() {
    if (_status != AutoplayStatus.playing) return;

    if (_currentIndex < widget.deck.cards.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _startCardCycle();
    } else {
      // Reached end of the deck
      setState(() {
        _status = AutoplayStatus.finished;
        _currentTimerDuration = 0;
        _timeRemaining = 0;
      });
      _cardTimer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Autoplay finished: End of deck reached."))
      );
      // Optionally, could implement looping here
    }
  }

  void _togglePlayPause() {
    if (_status == AutoplayStatus.playing) {
      setState(() {
        _status = AutoplayStatus.paused;
      });
      _cardTimer?.cancel(); // Pause the timer by cancelling it
    } else if (_status == AutoplayStatus.paused) {
      setState(() {
        _status = AutoplayStatus.playing;
      });
      // Resume timer logic:
      // If _showFront, continue with remaining _timeRemaining for front, then to _showBackSide
      // If !_showFront, continue with remaining _timeRemaining for back, then to _moveToNextCard
      // For simplicity in this version, we'll just restart the current side's timer
      // A more sophisticated resume would continue from the exact point.
      if (_showFront) {
        _startCardCycle(); // This will restart the front timer
      } else {
        _showBackSide(); // This will restart the back timer
      }
    } else if (_status == AutoplayStatus.finished) {
      // Restart from beginning if finished
      setState(() {
        _currentIndex = 0;
        _status = AutoplayStatus.playing;
      });
      _startCardCycle();
    }
  }

  void _stopAutoplay() {
    setState(() {
      _status = AutoplayStatus.stopped;
    });
    _cardTimer?.cancel();
    _transitionDelayTimer?.cancel();
    Navigator.of(context).pop(); // Go back to deck list
  }


  @override
  Widget build(BuildContext context) {
    final card = _currentCard;
    final bool canPlayPause = _status == AutoplayStatus.playing || _status == AutoplayStatus.paused || _status == AutoplayStatus.finished;

    return Scaffold(
      appBar: AppBar(
        title: Text('Autoplay: ${widget.deck.title}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _stopAutoplay,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Indicator
            if (widget.deck.cards.isNotEmpty && _status != AutoplayStatus.finished)
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
              child: Card(
                elevation: 4.0,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      card == null || _status == AutoplayStatus.stopped
                          ? (widget.deck.cards.isEmpty ? "This deck has no cards." : "Autoplay stopped.")
                          : (_status == AutoplayStatus.finished
                              ? "Autoplay Finished!"
                              : (_showFront ? card.frontText : card.backText)),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Timer Progress Bar (Simple LinearProgressIndicator)
            if (_status == AutoplayStatus.playing && _currentTimerDuration > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: (_currentTimerDuration - _timeRemaining) / _currentTimerDuration,
                      minHeight: 10,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _showFront ? Colors.blueAccent : Colors.greenAccent
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text("Time remaining: $_timeRemaining s", style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
            if (_status == AutoplayStatus.paused)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text("Paused", textAlign: TextAlign.center, style: TextStyle(fontStyle: FontStyle.italic)),
              ),

            const SizedBox(height: 20),

            // Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Previous Button (Manual Override - Optional for V1 Autoplay)
                // IconButton(
                //   icon: const Icon(Icons.skip_previous),
                //   iconSize: 40,
                //   onPressed: (_status == AutoplayStatus.playing || _status == AutoplayStatus.paused) ? _manualPrevious : null,
                // ),
                IconButton(
                  icon: Icon(
                    _status == AutoplayStatus.playing
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                  ),
                  iconSize: 60,
                  color: Theme.of(context).primaryColor,
                  onPressed: canPlayPause ? _togglePlayPause : null,
                  tooltip: _status == AutoplayStatus.playing ? "Pause" : "Play",
                ),
                // Next Button (Manual Override - Optional for V1 Autoplay)
                // IconButton(
                //   icon: const Icon(Icons.skip_next),
                //   iconSize: 40,
                //   onPressed: (_status == AutoplayStatus.playing || _status == AutoplayStatus.paused) ? _manualNext : null,
                // ),
              ],
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Stop Autoplay & Go Back'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              onPressed: _stopAutoplay,
            ),
          ],
        ),
      ),
    );
  }

  // Placeholder for manual next/prev during autoplay if we add them later
  // void _manualNext() {
  //   _cardTimer?.cancel();
  //   _transitionDelayTimer?.cancel();
  //   if (_currentIndex < widget.deck.cards.length - 1) {
  //     setState(() { _currentIndex++; });
  //     _startCardCycle();
  //   } else {
  //      setState(() { _status = AutoplayStatus.finished; });
  //   }
  //   if (_status == AutoplayStatus.paused) _status = AutoplayStatus.playing; // resume if paused
  // }
  // void _manualPrevious() {
  //   _cardTimer?.cancel();
  //   _transitionDelayTimer?.cancel();
  //   if (_currentIndex > 0) {
  //     setState(() { _currentIndex--; });
  //      _startCardCycle();
  //   }
  //   if (_status == AutoplayStatus.paused) _status = AutoplayStatus.playing; // resume if paused
  // }
}