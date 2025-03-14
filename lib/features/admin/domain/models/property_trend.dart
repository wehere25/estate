class PropertyTrend {
  final String month;
  final int count;
  final double revenue;
  final int viewCount;
  
  PropertyTrend({
    required this.month,
    required this.count,
    required this.revenue,
    required this.viewCount,
  });
  
  factory PropertyTrend.fromMap(Map<String, dynamic> map) {
    return PropertyTrend(
      month: map['month'] ?? '',
      count: map['count'] ?? 0,
      revenue: (map['revenue'] ?? 0.0).toDouble(),
      viewCount: map['viewCount'] ?? 0,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'month': month,
      'count': count,
      'revenue': revenue,
      'viewCount': viewCount,
    };
  }
}
