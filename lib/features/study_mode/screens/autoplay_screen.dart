// lib/features/study_mode/screens/autoplay_screen.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/models/card_model.dart';
import '../../../core/models/deck_model.dart';
import '../../../core/services/deck_persistence_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/widgets/flip_card_widget.dart';

enum AutoplayStatus { playing, paused, stopped, finished }

class AutoplayScreen extends StatefulWidget {
  final DeckModel deck;
  final int startIndex;

  const AutoplayScreen({
    super.key,
    required this.deck,
    this.startIndex = 0,
  });

  @override
  State<AutoplayScreen> createState() => _AutoplayScreenState();
}

class _AutoplayScreenState extends State<AutoplayScreen> {
  int _currentIndex = 0;
  bool _showFront = true;
  AutoplayStatus _status = AutoplayStatus.stopped;
  Timer? _cardTimer;
  Timer? _transitionDelayTimer;

  int _currentTimerDuration = 0;
  int _timeRemaining = 0;

  final SettingsService _settingsService = SettingsService();
  final DeckPersistenceService _persistenceService = DeckPersistenceService();
  final FlipCardController _flipCardController = FlipCardController();
  final Random _random = Random();

  late int _globalFrontTime;
  late int _globalBackTime;
  late bool _shouldShuffle;
  late bool _shouldLoop;
  bool _isLoadingSettings = true;

  List<CardModel> _currentPlayList = [];

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    print("Wakelock enabled for AutoplayScreen.");
    _loadSettingsAndPrepareDeck();
  }

  Future<void> _loadSettingsAndPrepareDeck() async {
    if (!mounted) return;
    setState(() {
      _isLoadingSettings = true;
    });

    _globalFrontTime = await _settingsService.getDefaultFrontTime();
    _globalBackTime = await _settingsService.getDefaultBackTime();
    _shouldShuffle = await _settingsService.getAutoplayShuffle();
    _shouldLoop = await _settingsService.getAutoplayLoop();

    if (widget.startIndex > 0) {
      _shouldShuffle = false;
    }

    _preparePlayList();
    _currentIndex = (widget.startIndex < _currentPlayList.length) ? widget.startIndex : 0;

    if (mounted) {
      setState(() {
        _isLoadingSettings = false;
      });
      if (_currentPlayList.isNotEmpty) {
        _status = AutoplayStatus.playing;
        _startCardCycle();
      } else {
        _status = AutoplayStatus.finished;
      }
    }
  }

  void _preparePlayList() {
    _currentPlayList = List<CardModel>.from(widget.deck.cards);
    if (_shouldShuffle && _currentPlayList.isNotEmpty) {
      _currentPlayList.shuffle(_random);
    }
    _currentIndex = 0;
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    print("Wakelock disabled for AutoplayScreen.");
    _cardTimer?.cancel();
    _transitionDelayTimer?.cancel();
    super.dispose();
  }

  CardModel? get _currentCard => (_currentPlayList.isEmpty || _currentIndex >= _currentPlayList.length) ? null : _currentPlayList[_currentIndex];
  int get _frontDuration => widget.deck.customFrontTimeSeconds ?? _globalFrontTime;
  int get _backDuration => widget.deck.customBackTimeSeconds ?? _globalBackTime;

  void _startCardCycle() {
    if (_status != AutoplayStatus.playing || _currentCard == null) return;
    _cardTimer?.cancel();
    _transitionDelayTimer?.cancel();
    _flipCardController.reset();

    if (!mounted) return;
    setState(() {
      _showFront = true;
      _currentTimerDuration = _frontDuration;
      _timeRemaining = _frontDuration;
    });

    _cardTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _status != AutoplayStatus.playing) {
        timer.cancel();
        return;
      }
      setState(() {
        _timeRemaining--;
      });
      if (_timeRemaining <= 0) {
        timer.cancel();
        _showBackSide();
      }
    });
  }

  void _showBackSide() {
    if (!mounted || _status != AutoplayStatus.playing || _currentCard == null) return;
    _cardTimer?.cancel();
    _transitionDelayTimer?.cancel();
    _flipCardController.flip();

    setState(() {
      _showFront = false;
      _currentTimerDuration = _backDuration;
      _timeRemaining = _backDuration;
    });

    _cardTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _status != AutoplayStatus.playing) {
        timer.cancel();
        return;
      }
      setState(() {
        _timeRemaining--;
      });
      if (_timeRemaining <= 0) {
        timer.cancel();
        _transitionDelayTimer = Timer(const Duration(milliseconds: 500), _moveToNextCard);
      }
    });
  }

  void _moveToNextCard() {
    if (!mounted || _status != AutoplayStatus.playing) return;
    if (_currentIndex < _currentPlayList.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _startCardCycle();
    } else {
      if (_shouldLoop) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Looping deck...")));
        _preparePlayList();
        if (_currentPlayList.isNotEmpty) {
          _startCardCycle();
        } else {
          if (mounted) setState(() => _status = AutoplayStatus.finished);
        }
      } else {
        if (mounted) {
          setState(() {
            _status = AutoplayStatus.finished;
            _currentTimerDuration = 0;
            _timeRemaining = 0;
          });
        }
        _cardTimer?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Autoplay finished: End of deck reached.")));
      }
    }
  }

  void _togglePlayPause() {
    if (_isLoadingSettings) return;
    if (_status == AutoplayStatus.playing) {
      setState(() => _status = AutoplayStatus.paused);
      _cardTimer?.cancel();
      _transitionDelayTimer?.cancel();
    } else if (_status == AutoplayStatus.paused) {
      setState(() => _status = AutoplayStatus.playing);
      if (_currentCard != null) {
        if (_showFront) _startCardCycle(); else _showBackSide();
      }
    } else if (_status == AutoplayStatus.finished && _currentPlayList.isNotEmpty) {
      _preparePlayList();
      setState(() => _status = AutoplayStatus.playing);
      _startCardCycle();
    } else if (_currentPlayList.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No cards to play.")));
    }
  }

  Future<void> _stopAutoplay() async {
    final bool wasFinished = _status == AutoplayStatus.finished;
    final int indexToSave = (wasFinished || _currentCard == null) ? 0 : _currentIndex;
    widget.deck.lastReviewedCardIndex = indexToSave;
    widget.deck.lastStudiedAt = DateTime.now();
    await _persistenceService.saveDeck(widget.deck);

    if (mounted) setState(() => _status = AutoplayStatus.stopped);
    _cardTimer?.cancel();
    _transitionDelayTimer?.cancel();
    if (mounted) Navigator.of(context).pop(true);
  }

  void _toggleSessionShuffle(bool value) {
    if (!mounted) return;
    setState(() => _shouldShuffle = value);
    _preparePlayList();
    if ((_status == AutoplayStatus.playing || _status == AutoplayStatus.paused) && _currentPlayList.isNotEmpty) {
      if (_status == AutoplayStatus.paused) setState(() => _status = AutoplayStatus.playing);
      _startCardCycle();
    } else if (_currentPlayList.isEmpty) {
      setState(() => _status = AutoplayStatus.finished);
    }
  }

  void _toggleSessionLoop(bool value) {
    if (!mounted) setState(() => _shouldLoop = value);
  }

  void _showExplanationDialog() {
    if (_currentCard?.explanation == null) return;
    if (_status == AutoplayStatus.playing) _togglePlayPause();

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
    if (_isLoadingSettings) {
      return Scaffold(appBar: AppBar(title: Text('Autoplay: ${widget.deck.title}')), body: const Center(child: CircularProgressIndicator()));
    }

    final card = _currentCard;
    final theme = Theme.of(context);
    final cardContentStyle = theme.textTheme.displaySmall?.copyWith(fontSize: 32);

    final frontWidget = Text(card?.frontText ?? (_currentPlayList.isEmpty ? "No cards to play." : "Autoplay Finished!"), textAlign: TextAlign.center, style: cardContentStyle);
    final backWidget = Text(card?.backText ?? "---", textAlign: TextAlign.center, style: cardContentStyle);
    final bool canPlayPause = _status == AutoplayStatus.playing || _status == AutoplayStatus.paused || (_status == AutoplayStatus.finished && _currentPlayList.isNotEmpty);
    final bool shuffleToggleEnabled = _status == AutoplayStatus.playing || _status == AutoplayStatus.paused || (_status == AutoplayStatus.finished && _currentPlayList.isNotEmpty);
    final bool isOriginalDeckEmpty = widget.deck.cards.isEmpty;


    return Scaffold(
      appBar: AppBar(title: Text('Autoplay: ${widget.deck.title}'), leading: IconButton(icon: const Icon(Iconsax.close_circle), onPressed: _stopAutoplay)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_currentPlayList.isNotEmpty && _status != AutoplayStatus.finished && _status != AutoplayStatus.stopped)
              Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text('Card ${_currentIndex + 1} of ${_currentPlayList.length}', textAlign: TextAlign.center, style: theme.textTheme.titleMedium)),
            Expanded(child: FlipCardWidget(controller: _flipCardController, front: frontWidget, back: backWidget)),
            const SizedBox(height: 10),
            if (!_showFront && _currentCard?.explanation != null && _status != AutoplayStatus.finished)
              Padding(padding: const EdgeInsets.only(bottom: 8.0), child: TextButton.icon(icon: const Icon(Iconsax.document_text_1), label: const Text('Why? Show Explanation'), onPressed: _showExplanationDialog)),
            if (_status == AutoplayStatus.playing && _currentTimerDuration > 0 && card != null)
              Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Column(children: [LinearProgressIndicator(value: (_currentTimerDuration > 0) ? ((_currentTimerDuration - _timeRemaining) / _currentTimerDuration) : 0, minHeight: 10, backgroundColor: Colors.grey[300], valueColor: AlwaysStoppedAnimation<Color>(_showFront ? theme.primaryColor : Colors.green)), const SizedBox(height: 4), Text("Time remaining: $_timeRemaining s", style: theme.textTheme.labelSmall)])),
            if (_status == AutoplayStatus.paused && card != null)
              const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text("Paused", textAlign: TextAlign.center, style: TextStyle(fontStyle: FontStyle.italic))),
            const SizedBox(height: 10),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Flexible(child: Column(mainAxisSize: MainAxisSize.min, children: [const Text("Shuffle"), Switch(value: _shouldShuffle, onChanged: isOriginalDeckEmpty ? null : (shuffleToggleEnabled ? _toggleSessionShuffle : null))])), Flexible(child: Column(mainAxisSize: MainAxisSize.min, children: [const Text("Loop Deck"), Switch(value: _shouldLoop, onChanged: isOriginalDeckEmpty ? null : _toggleSessionLoop)]))])),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [IconButton(icon: Icon(_status == AutoplayStatus.playing ? Iconsax.pause_circle : Iconsax.play_circle, size: 60), color: theme.primaryColor, onPressed: isOriginalDeckEmpty ? null : (canPlayPause ? _togglePlayPause : null), tooltip: _status == AutoplayStatus.playing ? "Pause" : "Play/Restart")]),
            const SizedBox(height: 20),
            OutlinedButton.icon(icon: const Icon(Iconsax.stop_circle, size: 20), label: const Text('Stop Autoplay & Go Back'), style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)), onPressed: _stopAutoplay),
          ],
        ),
      ),
    );
  }
}