import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/admin_provider.dart';
import '../widgets/audit_log_list.dart';
import '../../domain/models/property_trend.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        if (adminProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Dashboard'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => adminProvider.refreshStats(),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatsGrid(adminProvider),
              const SizedBox(height: 24),
              _buildCharts(context, adminProvider),
              const SizedBox(height: 24),
              _buildAuditLogs(adminProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid(AdminProvider provider) {
    final stats = provider.stats;
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildStatCard(
          title: 'Total Properties',
          value: stats.totalProperties.toString(),
          icon: Icons.home,
        ),
        _buildStatCard(
          title: 'Active Users',
          value: stats.activeUsers.toString(),
          icon: Icons.people,
        ),
        _buildStatCard(
          title: 'Total Revenue',
          value: '\$${stats.totalRevenue.toStringAsFixed(0)}',
          icon: Icons.attach_money,
        ),
        _buildStatCard(
          title: 'Pending Reviews',
          value: stats.pendingReviews.toString(),
          icon: Icons.rate_review,
        ),
      ],
    );
  }
  
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            // Fix deprecated withOpacity
            color: Colors.grey.withAlpha(26), // Replace withOpacity(0.1)
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 32,
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharts(BuildContext context, AdminProvider provider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Property Trends',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DropdownButton<String>(
                  value: 'Last 6 Months',
                  items: ['Last 3 Months', 'Last 6 Months', 'Last Year']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {
                    // Handle dropdown change
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: _buildLineChart(context, provider.propertyTrends),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLineChart(BuildContext context, List<PropertyTrend> trends) {
    if (trends.isEmpty) {
      return const Center(child: Text('No trend data available'));
    }
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 100,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              // Fix deprecated withOpacity
              color: Colors.grey.withAlpha(76), // ~0.3 opacity
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}');
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= trends.length) {
                  return const Text('');
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    trends[value.toInt()].month,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300),
            left: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        minX: 0,
        maxX: trends.length.toDouble() - 1,
        minY: 0,
        maxY: (trends.map((e) => e.count).reduce((a, b) => a > b ? a : b) * 1.2)
            .toDouble(),
        lineBarsData: [
          LineChartBarData(
            spots: trends.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.count.toDouble());
            }).toList(),
            isCurved: true,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            color: Theme.of(context).colorScheme.primary,
            belowBarData: BarAreaData(
              show: true,
              // Fix deprecated withOpacity
              color: Theme.of(context).colorScheme.primary.withAlpha(51), // ~0.2 opacity
            ),
          ),
          LineChartBarData(
            spots: trends.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.viewCount.toDouble() / 10);
            }).toList(),
            isCurved: true,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            color: Colors.orange,
            dashArray: [5, 5],
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            // Remove the problematic parameter and use the default tooltip appearance
            // Instead of trying different parameter names, we'll let it use the default
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final index = barSpot.x.toInt();
                if (index >= 0 && index < trends.length) {
                  final trend = trends[index];
                  
                  String title = 'Properties';
                  int value = trend.count;
                  if (barSpot.bar.color == Colors.orange) {
                    title = 'Views';
                    value = trend.viewCount;
                  }
                  
                  return LineTooltipItem(
                    '$title: $value\n${trend.month}',
                    const TextStyle(color: Colors.black),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAuditLogs(AdminProvider provider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  onPressed: provider.refreshAuditLogs,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 350,
              child: AuditLogList(
                logs: provider.auditLogs.map((log) => log.toMapWithId()).toList(),
                showHeader: false,
                onRefresh: provider.refreshAuditLogs,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  // Navigate to full audit log
                },
                child: const Text('View All Activity'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
