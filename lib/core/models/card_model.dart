// lib/core/models/card_model.dart

class CardModel {
  final String id; // Unique identifier for the card, useful for database/keys
  String frontText;
  String backText;
  // bool isLearned; // Optional: For future spaced repetition features
  // DateTime? lastReviewed; // Optional: For future spaced repetition

  CardModel({
    required this.id,
    required this.frontText,
    required this.backText,
    // this.isLearned = false,
    // this.lastReviewed,
  });

  // Optional: A factory constructor to create a CardModel from a Map (e.g., when loading from JSON/database)
  factory CardModel.fromMap(Map<String, dynamic> map) {
    return CardModel(
      id: map['id'] as String,
      frontText: map['frontText'] as String,
      backText: map['backText'] as String,
      // isLearned: map['isLearned'] as bool? ?? false, // Handle potential null
      // lastReviewed: map['lastReviewed'] != null ? DateTime.parse(map['lastReviewed'] as String) : null,
    );
  }

  // Optional: A method to convert a CardModel instance to a Map (e.g., for saving to JSON/database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'frontText': frontText,
      'backText': backText,
      // 'isLearned': isLearned,
      // 'lastReviewed': lastReviewed?.toIso8601String(),
    };
  }

  // Optional: For easier debugging
  @override
  String toString() {
    return 'CardModel(id: $id, front: "$frontText", back: "$backText")';
  }
}