import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'model_profile_screen.dart';

/// Admin Dashboard Statistics Model
class AdminStats {
  final int totalUsers;
  final int totalModels;
  final int totalModerators;
  final int activeUsersWeek;
  final int totalGroups;
  final double avgGroupSize;
  final double tokensLast30Days;
  final int productionLogsLast30Days;
  final double avgTokensPerLog;
  final int activeContracts;
  final int pendingContracts;
  final int contractsSignedWeek;
  final double estimatedRevenue30Days;
  final int auditLogs24h;
  final List<TopPerformer> topModels;
  
  AdminStats({
    required this.totalUsers,
    required this.totalModels,
    required this.totalModerators,
    required this.activeUsersWeek,
    required this.totalGroups,
    required this.avgGroupSize,
    required this.tokensLast30Days,
    required this.productionLogsLast30Days,
    required this.avgTokensPerLog,
    required this.activeContracts,
    required this.pendingContracts,
    required this.contractsSignedWeek,
    required this.estimatedRevenue30Days,
    required this.auditLogs24h,
    required this.topModels,
  });
  
  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: json['total_users'] ?? 0,
      totalModels: json['total_models'] ?? 0,
      totalModerators: json['total_moderators'] ?? 0,
      activeUsersWeek: json['active_users_week'] ?? 0,
      totalGroups: json['total_groups'] ?? 0,
      avgGroupSize: (json['avg_group_size'] ?? 0).toDouble(),
      tokensLast30Days: (json['tokens_last_30_days'] ?? 0).toDouble(),
      productionLogsLast30Days: json['production_logs_last_30_days'] ?? 0,
      avgTokensPerLog: (json['avg_tokens_per_log'] ?? 0).toDouble(),
      activeContracts: json['active_contracts'] ?? 0,
      pendingContracts: json['pending_contracts'] ?? 0,
      contractsSignedWeek: json['contracts_signed_week'] ?? 0,
      estimatedRevenue30Days: (json['estimated_revenue_30_days'] ?? 0).toDouble(),
      auditLogs24h: json['audit_logs_24h'] ?? 0,
      topModels: (json['top_models_30_days'] as List? ?? [])
          .map((m) => TopPerformer.fromJson(m))
          .toList(),
    );
  }
}

class TopPerformer {
  final String id;
  final String email;
  final String? fullName;
  final double totalTokens;
  
  TopPerformer({
    required this.id,
    required this.email,
    this.fullName,
    required this.totalTokens,
  });
  
  factory TopPerformer.fromJson(Map<String, dynamic> json) {
    return TopPerformer(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      totalTokens: (json['total_tokens'] ?? 0).toDouble(),
    );
  }
}

/// State management for admin dashboard
class AdminDashboardNotifier extends StateNotifier<AsyncValue<AdminStats>> {
  final Dio dio;
  
  AdminDashboardNotifier(this.dio) : super(const AsyncValue.loading()) {
    fetchStats();
  }
  
  Future<void> fetchStats() async {
    try {
      state = const AsyncValue.loading();
      
      final response = await dio.get('/api/admin/dashboard');
      
      if (response.statusCode == 200) {
        final stats = AdminStats.fromJson(response.data);
        state = AsyncValue.data(stats);
      } else {
        state = AsyncValue.error('Failed to load stats', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> exportData({
    required String exportType,
    required String format,
  }) async {
    try {
      final response = await dio.get(
        '/api/admin/export',
        queryParameters: {
          'type': exportType,
          'format': format,
        },
      );
      
      if (response.statusCode == 200) {
        // Handle export response (download URL)
        print('Export initiated: ${response.data}');
      }
    } catch (e) {
      print('Export error: $e');
    }
  }
}

final adminDashboardProvider = StateNotifierProvider<AdminDashboardNotifier, AsyncValue<AdminStats>>((ref) {
  // Get Dio instance from api_service provider
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
  return AdminDashboardNotifier(dio);
});

/// Admin Dashboard Screen
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(adminDashboardProvider.notifier).fetchStats();
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _showExportDialog(context, ref),
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) => _buildDashboard(context, stats, ref),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(adminDashboardProvider.notifier).fetchStats();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDashboard(BuildContext context, AdminStats stats, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.read(adminDashboardProvider.notifier).fetchStats(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Key Metrics Cards
            _buildMetricsGrid(stats),
            
            const SizedBox(height: 24),
            
            // Revenue Chart
            _buildRevenueCard(stats),
            
            const SizedBox(height: 24),
            
            // Top Performers
            _buildTopPerformers(context, stats),
            
            const SizedBox(height: 24),
            
            // Activity Summary
            _buildActivitySummary(stats),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetricsGrid(AdminStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          title: 'Total Users',
          value: '${stats.totalUsers}',
          icon: Icons.people,
          color: Colors.blue,
        ),
        _buildMetricCard(
          title: 'Total Models',
          value: '${stats.totalModels}',
          icon: Icons.person,
          color: Colors.purple,
        ),
        _buildMetricCard(
          title: 'Active Groups',
          value: '${stats.totalGroups}',
          icon: Icons.group,
          color: Colors.green,
        ),
        _buildMetricCard(
          title: 'Active Contracts',
          value: '${stats.activeContracts}',
          icon: Icons.description,
          color: Colors.orange,
        ),
        _buildMetricCard(
          title: 'Tokens (30d)',
          value: '${(stats.tokensLast30Days / 1000).toStringAsFixed(1)}K',
          icon: Icons.token,
          color: Colors.amber,
        ),
        _buildMetricCard(
          title: 'Revenue (30d)',
          value: '\$${(stats.estimatedRevenue30Days / 1000).toStringAsFixed(1)}K',
          icon: Icons.attach_money,
          color: Colors.teal,
        ),
      ],
    );
  }
  
  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRevenueCard(AdminStats stats) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue Overview (30 Days)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generateRevenueData(stats),
                      isCurved: true,
                      color: Colors.teal,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  List<FlSpot> _generateRevenueData(AdminStats stats) {
    // Generate mock data for the last 30 days
    return List.generate(30, (index) {
      return FlSpot(
        index.toDouble(),
        (stats.estimatedRevenue30Days / 30) * (0.8 + (index % 5) * 0.1),
      );
    });
  }
  
  Widget _buildTopPerformers(BuildContext context, AdminStats stats) {
    if (stats.topModels.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Performers (30 Days)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...stats.topModels.take(5).map((performer) {
              return ListTile(
                leading: CircleAvatar(
                  child: Text(performer.email[0].toUpperCase()),
                ),
                title: Text(performer.fullName ?? performer.email),
                subtitle: Text(performer.email),
                trailing: Text(
                  '${(performer.totalTokens / 1000).toStringAsFixed(1)}K tokens',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ModelProfileScreen(
                        userId: performer.id,
                        userName: performer.fullName ?? performer.email,
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActivitySummary(AdminStats stats) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildActivityRow('Active Users (Week)', '${stats.activeUsersWeek}'),
            _buildActivityRow('Production Logs (30d)', '${stats.productionLogsLast30Days}'),
            _buildActivityRow('Avg Tokens per Log', '${stats.avgTokensPerLog.toStringAsFixed(1)}'),
            _buildActivityRow('Contracts Signed (Week)', '${stats.contractsSignedWeek}'),
            _buildActivityRow('Pending Contracts', '${stats.pendingContracts}'),
            _buildActivityRow('Audit Logs (24h)', '${stats.auditLogs24h}'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActivityRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
  
  void _showExportDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Export as CSV'),
              onTap: () {
                Navigator.pop(context);
                ref.read(adminDashboardProvider.notifier).exportData(
                  exportType: 'payroll',
                  format: 'csv',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CSV export initiated')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_present),
              title: const Text('Export as Excel'),
              onTap: () {
                Navigator.pop(context);
                ref.read(adminDashboardProvider.notifier).exportData(
                  exportType: 'payroll',
                  format: 'excel',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Excel export initiated')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Export as PDF'),
              onTap: () {
                Navigator.pop(context);
                ref.read(adminDashboardProvider.notifier).exportData(
                  exportType: 'payroll',
                  format: 'pdf',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF export initiated')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
