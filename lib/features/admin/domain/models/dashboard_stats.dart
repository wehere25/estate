
/// Model class for dashboard statistics data
class DashboardStats {
  final int totalProperties;
  final int activeProperties;
  final int pendingProperties;
  final int totalUsers;
  final int activeUsers;
  final int pendingReviews;
  final double totalRevenue;
  final int inquiriesCount;

  DashboardStats({
    this.totalProperties = 0,
    this.activeProperties = 0,
    this.pendingProperties = 0,
    this.totalUsers = 0,
    this.activeUsers = 0,
    this.pendingReviews = 0,
    this.totalRevenue = 0.0,
    this.inquiriesCount = 0,
  });

  DashboardStats copyWith({
    int? totalProperties,
    int? activeProperties,
    int? pendingProperties,
    int? totalUsers,
    int? activeUsers,
    int? pendingReviews,
    double? totalRevenue,
    int? inquiriesCount,
  }) {
    return DashboardStats(
      totalProperties: totalProperties ?? this.totalProperties,
      activeProperties: activeProperties ?? this.activeProperties,
      pendingProperties: pendingProperties ?? this.pendingProperties,
      totalUsers: totalUsers ?? this.totalUsers,
      activeUsers: activeUsers ?? this.activeUsers,
      pendingReviews: pendingReviews ?? this.pendingReviews,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      inquiriesCount: inquiriesCount ?? this.inquiriesCount,
    );
  }
}
