// lib/core/models/deck_model.dart

import 'card_model.dart'; // We need to import the CardModel

class DeckModel {
  final String id; // Unique identifier for the deck
  String title;
  List<CardModel> cards;
  DateTime createdAt;
  DateTime? lastStudiedAt; // Optional: track when the deck was last studied

  // Settings specific to this deck for autoplay (can override global settings)
  int? customFrontTimeSeconds; // e.g., 5 seconds for front
  int? customBackTimeSeconds;  // e.g., 7 seconds for back

  DeckModel({
    required this.id,
    required this.title,
    List<CardModel>? cards, // Make cards optional, default to empty list
    DateTime? createdAt,   // Optional, defaults to now
    this.lastStudiedAt,
    this.customFrontTimeSeconds,
    this.customBackTimeSeconds,
  }) : cards = cards ?? [], // If cards is null, initialize as an empty list
       createdAt = createdAt ?? DateTime.now(); // If createdAt is null, initialize to current time

  // Optional: A factory constructor to create a DeckModel from a Map
  factory DeckModel.fromMap(Map<String, dynamic> map) {
    return DeckModel(
      id: map['id'] as String,
      title: map['title'] as String,
      cards: (map['cards'] as List<dynamic>? ?? []) // Handle if 'cards' is null or missing
          .map((cardMap) => CardModel.fromMap(cardMap as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastStudiedAt: map['lastStudiedAt'] != null ? DateTime.parse(map['lastStudiedAt'] as String) : null,
      customFrontTimeSeconds: map['customFrontTimeSeconds'] as int?,
      customBackTimeSeconds: map['customBackTimeSeconds'] as int?,
    );
  }

  // Optional: A method to convert a DeckModel instance to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'cards': cards.map((card) => card.toMap()).toList(), // Convert each card to a map
      'createdAt': createdAt.toIso8601String(), // Store dates in a standard string format
      'lastStudiedAt': lastStudiedAt?.toIso8601String(),
      'customFrontTimeSeconds': customFrontTimeSeconds,
      'customBackTimeSeconds': customBackTimeSeconds,
    };
  }

  // Helper methods (optional, but can be convenient)
  int get cardCount => cards.length;

  void addCard(CardModel card) {
    cards.add(card);
  }

  void removeCard(String cardId) {
    cards.removeWhere((card) => card.id == cardId);
  }

  // Optional: For easier debugging
  @override
  String toString() {
    return 'DeckModel(id: $id, title: "$title", cardCount: $cardCount)';
  }
}