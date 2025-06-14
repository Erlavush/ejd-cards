// lib/core/models/folder_model.dart

class FolderModel {
  final String id;
  String title;
  List<String> deckIds;
  DateTime createdAt;

  FolderModel({
    required this.id,
    required this.title,
    List<String>? deckIds,
    DateTime? createdAt,
  })  : deckIds = deckIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  // Creates a FolderModel instance from a map (e.g., when loading from JSON)
  factory FolderModel.fromMap(Map<String, dynamic> map) {
    return FolderModel(
      id: map['id'] as String,
      title: map['title'] as String,
      // Ensure deckIds is handled as a List<String>
      deckIds: (map['deckIds'] as List<dynamic>?)?.map((id) => id as String).toList() ?? [],
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  // Converts a FolderModel instance to a map (e.g., for saving to JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'deckIds': deckIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}