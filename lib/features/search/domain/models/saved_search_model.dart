import 'dart:convert';

/// Model class for saved search
class SavedSearch {
  final String id;
  final String name;
  final String query;
  final Map<String, dynamic> filters;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final int usageCount;

  SavedSearch({
    required this.id,
    required this.name,
    required this.query,
    required this.filters,
    required this.createdAt,
    this.lastUsedAt,
    this.usageCount = 0,
  });

  // Create a copy with updated fields
  SavedSearch copyWith({
    String? id,
    String? name,
    String? query,
    Map<String, dynamic>? filters,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    int? usageCount,
  }) {
    return SavedSearch(
      id: id ?? this.id,
      name: name ?? this.name,
      query: query ?? this.query,
      filters: filters ?? this.filters,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  // Mark as used, incrementing the usage count and updating lastUsedAt
  SavedSearch markAsUsed() {
    return copyWith(
      lastUsedAt: DateTime.now(),
      usageCount: usageCount + 1,
    );
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'query': query,
      'filters': filters,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastUsedAt': lastUsedAt?.millisecondsSinceEpoch,
      'usageCount': usageCount,
    };
  }

  // Create from Map (for storage retrieval)
  factory SavedSearch.fromMap(Map<String, dynamic> map) {
    return SavedSearch(
      id: map['id'],
      name: map['name'],
      query: map['query'],
      filters: Map<String, dynamic>.from(map['filters']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      lastUsedAt: map['lastUsedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastUsedAt'])
          : null,
      usageCount: map['usageCount'] ?? 0,
    );
  }

  // Serialize to JSON string
  String toJson() => json.encode(toMap());

  // Create from JSON string
  factory SavedSearch.fromJson(String source) =>
      SavedSearch.fromMap(json.decode(source));

  @override
  String toString() {
    return 'SavedSearch(id: $id, name: $name, query: $query, filters: $filters, createdAt: $createdAt, lastUsedAt: $lastUsedAt, usageCount: $usageCount)';
  }
}
