// lib/core/models/card_model.dart

class CardModel {
  final String id;
  String frontText;
  String backText;
  String? explanation;
  bool needsReview;

  CardModel({
    required this.id,
    required this.frontText,
    required this.backText,
    this.explanation,
    this.needsReview = false,
  });

  // Creates a CardModel instance from a map (e.g., when loading from JSON)
  factory CardModel.fromMap(Map<String, dynamic> map) {
    return CardModel(
      id: map['id'] as String,
      frontText: map['frontText'] as String,
      backText: map['backText'] as String,
      explanation: map['explanation'] as String?,
      // Handle old data that might not have this field by defaulting to false
      needsReview: map['needsReview'] as bool? ?? false,
    );
  }

  // Converts a CardModel instance to a map (e.g., for saving to JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'frontText': frontText,
      'backText': backText,
      'explanation': explanation,
      'needsReview': needsReview,
    };
  }

  @override
  String toString() {
    return 'CardModel(id: $id, front: "$frontText", back: "$backText", explanation: "$explanation", needsReview: $needsReview)';
  }
}