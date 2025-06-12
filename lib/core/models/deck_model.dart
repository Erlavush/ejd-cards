// lib/core/models/deck_model.dart

import 'card_model.dart';

class DeckModel {
  final String id;
  String title;
  List<CardModel> cards;
  DateTime createdAt;
  DateTime? lastStudiedAt;
  int? lastReviewedCardIndex;

  // Autoplay settings specific to this deck
  int? customFrontTimeSeconds;
  int? customBackTimeSeconds;

  DeckModel({
    required this.id,
    required this.title,
    List<CardModel>? cards,
    DateTime? createdAt,
    this.lastStudiedAt,
    this.lastReviewedCardIndex,
    this.customFrontTimeSeconds,
    this.customBackTimeSeconds,
  })  : cards = cards ?? [],
        createdAt = createdAt ?? DateTime.now();

  // Helper getter for card count
  int get cardCount => cards.length;

  // Creates a DeckModel instance from a map (e.g., when loading from JSON)
  factory DeckModel.fromMap(Map<String, dynamic> map) {
    return DeckModel(
      id: map['id'] as String,
      title: map['title'] as String,
      cards: (map['cards'] as List<dynamic>? ?? [])
          .map((cardMap) => CardModel.fromMap(cardMap as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastStudiedAt: map['lastStudiedAt'] != null ? DateTime.parse(map['lastStudiedAt'] as String) : null,
      lastReviewedCardIndex: map['lastReviewedCardIndex'] as int?,
      customFrontTimeSeconds: map['customFrontTimeSeconds'] as int?,
      customBackTimeSeconds: map['customBackTimeSeconds'] as int?,
    );
  }

  // Converts a DeckModel instance to a map (e.g., for saving to JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'cards': cards.map((card) => card.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastStudiedAt': lastStudiedAt?.toIso8601String(),
      'lastReviewedCardIndex': lastReviewedCardIndex,
      'customFrontTimeSeconds': customFrontTimeSeconds,
      'customBackTimeSeconds': customBackTimeSeconds,
    };
  }
}