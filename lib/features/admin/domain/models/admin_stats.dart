import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class for admin dashboard statistics
class AdminStats {
  final int totalProperties;
  final int activeProperties;
  final int pendingProperties;
  final int totalUsers;
  final int activeUsers;
  final int pendingReviews;
  final double totalRevenue;
  final int inquiriesCount;

  const AdminStats({
    required this.totalProperties,
    required this.activeProperties,
    required this.pendingProperties,
    required this.totalUsers,
    required this.activeUsers,
    required this.pendingReviews,
    required this.totalRevenue,
    required this.inquiriesCount,
  });

  // Factory constructor for empty stats
  factory AdminStats.empty() {
    return const AdminStats(
      totalProperties: 0,
      activeProperties: 0,
      pendingProperties: 0,
      totalUsers: 0,
      activeUsers: 0,
      pendingReviews: 0,
      totalRevenue: 0,
      inquiriesCount: 0,
    );
  }

  // Add the missing generateMockData method
  factory AdminStats.generateMockData() {
    return AdminStats(
      totalProperties: 237,
      activeProperties: 189,
      pendingProperties: 14,
      totalUsers: 512,
      activeUsers: 325,
      pendingReviews: 8,
      totalRevenue: 45750.00,
      inquiriesCount: 143,
    );
  }

  // Factory constructor from Firestore data
  factory AdminStats.fromMap(Map<String, dynamic> map) {
    return AdminStats(
      totalProperties: map['totalProperties'] ?? 0,
      activeProperties: map['activeProperties'] ?? 0,
      pendingProperties: map['pendingProperties'] ?? 0,
      totalUsers: map['totalUsers'] ?? 0,
      activeUsers: map['activeUsers'] ?? 0,
      pendingReviews: map['pendingReviews'] ?? 0,
      totalRevenue: (map['totalRevenue'] ?? 0).toDouble(),
      inquiriesCount: map['inquiriesCount'] ?? 0,
    );
  }
}
