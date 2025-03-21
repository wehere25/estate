import 'dart:convert';

class SavedSearch {
  final String id;
  final String name;
  final String query;
  final Map<String, dynamic> filters;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final int usageCount;
  final bool notificationsEnabled;

  SavedSearch({
    required this.id,
    required this.name,
    required this.query,
    required this.filters,
    required this.createdAt,
    this.lastUsedAt,
    this.usageCount = 0,
    this.notificationsEnabled = false,
  });

  SavedSearch copyWith({
    String? id,
    String? name,
    String? query,
    Map<String, dynamic>? filters,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    int? usageCount,
    bool? notificationsEnabled,
  }) {
    return SavedSearch(
      id: id ?? this.id,
      name: name ?? this.name,
      query: query ?? this.query,
      filters: filters ?? this.filters,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      usageCount: usageCount ?? this.usageCount,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  // Convenience method to mark a search as used
  SavedSearch markAsUsed() {
    return copyWith(
      lastUsedAt: DateTime.now(),
      usageCount: usageCount + 1,
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'query': query,
      'filters': filters,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'usageCount': usageCount,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  // Convert to JSON string
  String toJson() => json.encode(toMap());

  // Create from Map
  factory SavedSearch.fromMap(Map<String, dynamic> map) {
    return SavedSearch(
      id: map['id'],
      name: map['name'],
      query: map['query'],
      filters: Map<String, dynamic>.from(map['filters']),
      createdAt: DateTime.parse(map['createdAt']),
      lastUsedAt:
          map['lastUsedAt'] != null ? DateTime.parse(map['lastUsedAt']) : null,
      usageCount: map['usageCount'] ?? 0,
      notificationsEnabled: map['notificationsEnabled'] ?? false,
    );
  }

  // Create from JSON string
  factory SavedSearch.fromJson(String source) =>
      SavedSearch.fromMap(json.decode(source));

  @override
  String toString() {
    return 'SavedSearch(id: $id, name: $name, query: $query, filters: $filters, '
        'createdAt: $createdAt, lastUsedAt: $lastUsedAt, usageCount: $usageCount, '
        'notificationsEnabled: $notificationsEnabled)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SavedSearch &&
        other.id == id &&
        other.name == name &&
        other.query == query &&
        _mapsEqual(other.filters, filters) &&
        other.createdAt == createdAt &&
        other.lastUsedAt == lastUsedAt &&
        other.usageCount == usageCount &&
        other.notificationsEnabled == notificationsEnabled;
  }

  // Helper to compare maps
  bool _mapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    return json.encode(a) == json.encode(b);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        query.hashCode ^
        filters.hashCode ^
        createdAt.hashCode ^
        lastUsedAt.hashCode ^
        usageCount.hashCode ^
        notificationsEnabled.hashCode;
  }
}
