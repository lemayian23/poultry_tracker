import 'package:flutter/material.dart';
import '../services/batch_service.dart';
import '../services/export_service.dart';
import '../models/batch.dart';
import 'batch_list_screen.dart';
import 'batch_detail_screen.dart';
import 'subscription_plans_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final BatchService _batchService = BatchService();
  final ExportService _exportService = ExportService();
  List<Batch> _batches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<Map<String, dynamic>> _getEnhancedMetrics() async {
    final totalBirds = await _getTotalBirdsAlive();
    final mortalityRate = await _getMortalityRate();
    final totalFeedCost = await _batchService.getFarmTotalFeedCost();
    
    int weeklyEggs = 0;
    for (final batch in _batches.where((batch) => batch.type == 'layer')) {
      weeklyEggs += await _batchService.getEggsThisWeek(batch.id);
    }

    return {
      'totalBirds': totalBirds,
      'mortalityRate': mortalityRate,
      'totalFeedCost': totalFeedCost,
      'weeklyEggs': weeklyEggs,
    };
  }

  Future<double> _getMortalityRate() async { // REMOVED Batch parameter
    int totalInitialBirds = 0; // FIXED: Changed 'totaInitialBirds' to 'totalInitialBirds'
    int totalMortality = 0;

    for (final batch in _batches) {
      totalInitialBirds += batch.initialBirds; // FIXED: Changed 'b' to 'batch'
      final mortality = await _batchService.getTotalMortality(batch.id);
      totalMortality += mortality;
    }
    if (totalInitialBirds == 0) return 0.0;
    return (totalMortality / totalInitialBirds) * 100;
  }

  Future<void> _loadDashboardData() async {
    try {
      final batches = await _batchService.getActiveBatches();
      setState(() {
        _batches = batches;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Calculate total birds alive
  Future<int> _getTotalBirdsAlive() async {
    int total = 0;
    for (final batch in _batches) {
      final mortality = await _batchService.getTotalMortality(batch.id);
      total += batch.getCurrentBirds(mortality);
    }
    return total;
  }

  // ADD THIS METHOD FOR SUBSCRIPTION NAVIGATION
  void _navigateToSubscription(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SubscriptionPlansScreen(userId: 'demo_user'),
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Pro'),
        content: const Text(
          'Unlock all features including:\n\n'
          '• Unlimited batches\n'
          '• Advanced analytics\n'
          '• Vaccination tracking\n'
          '• Export reports\n'
          '• Priority support',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToSubscription(context);
            },
            child: const Text('View Plans'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Poultry Manager'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Professional poultry management app for farmers.'),
            SizedBox(height: 10),
            Text('Track batches, monitor production, and manage your farm efficiently.'),
            SizedBox(height: 10),
            Text('© 2024 Poultry Manager. All rights reserved.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _exportData(BuildContext context) async {
    try {
      final totalBirds = await _getTotalBirdsAlive();
      final summary = _exportService.generateExportSummary(
        _batches.length,
        totalBirds,
        _calculateTotalEggs(),
      );

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Report'),
          content: SingleChildScrollView(
            child: Text(summary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Report ready for download!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Download'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  int _calculateTotalEggs() {
    return _batches.length * 50;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Dashboard'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download, size: 20),
                    SizedBox(width: 8),
                    Text('Export Report'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'upgrade',
                child: Row(
                  children: [
                    Icon(Icons.upgrade, size: 20),
                    SizedBox(width: 8),
                    Text('Upgrade to Pro'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info, size: 20),
                    SizedBox(width: 8),
                    Text('About'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _exportData(context);
                  break;
                case 'upgrade':
                  _navigateToSubscription(context);
                  break;
                case 'about':
                  _showAboutDialog(context);
                  break;
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _batches.isEmpty
              ? _buildEmptyState()
              : _buildDashboard(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BatchListScreen()),
          );
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.agriculture, color: Colors.white),
        heroTag: 'dashboard_fab',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          const Text(
            'No Farm Data',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Add batches to see your farm analytics',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BatchListScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add First Batch'),
          ),
          const SizedBox(height: 20),
          _buildSubscriptionCard(),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.agriculture, color: Colors.green, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Farm Overview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_batches.length} active batch${_batches.length != 1 ? 'es' : ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          _buildSubscriptionCard(),
          const SizedBox(height: 20),

          const Text(
            'Key Metrics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          FutureBuilder<Map<String, dynamic>>(
            future: _getEnhancedMetrics(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              final metrics = snapshot.data ?? {};
              final totalBirds = metrics['totalBirds'] ?? 0;
              final mortalityRate = metrics['mortalityRate'] ?? 0.0;
              final totalFeedCost = metrics['totalFeedCost'] ?? 0.0;
              final weeklyEggs = metrics['weeklyEggs'] ?? 0; // FIXED: Changed 'weeklEggs' to 'weeklyEggs'

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Total Birds',
                          value: totalBirds.toString(),
                          subtitle: 'Alive',
                          icon: Icons.flag,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Mortality Rate',
                          value: '${mortalityRate.toStringAsFixed(1)}%',
                          subtitle: 'Overall',
                          icon: Icons.warning,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Weekly Eggs',
                          value: weeklyEggs.toString(), // FIXED: Removed toStringAsFixed()
                          subtitle: 'This Week',
                          icon: Icons.egg,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Feed Costs',
                          value: 'KSH ${totalFeedCost.toStringAsFixed(0)}',
                          subtitle: 'Total',
                          icon: Icons.attach_money,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ), // FIXED: Removed extra '>' and added missing comma

          const SizedBox(height: 24),

          const Text(
            'Active Batches',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _batches.length,
            itemBuilder: (context, index) {
              final batch = _batches[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: _getBatchIcon(batch.type),
                  title: Text(
                    batch.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: FutureBuilder<int>(
                    future: _batchService.getTotalMortality(batch.id),
                    builder: (context, snapshot) {
                      final mortality = snapshot.data ?? 0;
                      final currentBirds = batch.getCurrentBirds(mortality);
                      return Text(
                        '$currentBirds birds • ${_formatBatchType(batch.type)} • ${batch.ageInDays} days',
                      );
                    },
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BatchDetailScreen(batch: batch),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.upgrade, color: Colors.blue, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upgrade to Pro',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Unlock unlimited batches, advanced analytics, and premium features',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _navigateToSubscription(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text('View Subscription Plans'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
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
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getBatchIcon(String type) {
    Color color;
    IconData icon;
    
    switch (type) {
      case 'broiler':
        color = Colors.orange;
        icon = Icons.emoji_people;
        break;
      case 'layer':
        color = Colors.yellow[700]!;
        icon = Icons.egg;
        break;
      case 'kienyeji':
        color = Colors.brown;
        icon = Icons.agriculture;
        break;
      default:
        color = Colors.green;
        icon = Icons.pets;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _formatBatchType(String type) {
    switch (type) {
      case 'broiler':
        return 'Broiler';
      case 'layer':
        return 'Layer';
      case 'kienyeji':
        return 'Kienyeji';
      default:
        return type;
    }
  }
}