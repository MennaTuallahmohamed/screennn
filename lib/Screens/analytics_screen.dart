import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:screen/Screens/main_dashboard.dart';
import 'package:screen/main_dashboard.dart';


class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final DatabaseReference _screensRef = FirebaseDatabase.instance.ref('screens');
  bool _isLoading = true;
  Map<String, ScreenData> _screens = {};
  String _selectedMetric = 'ads';
  String _selectedPeriod = '24h';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final snapshot = await _screensRef.once();
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>? ?? {};
      final Map<String, ScreenData> screens = {};

      data.forEach((key, value) {
        final statusStr = value['status'] as String? ?? 'offline';
        ScreenStatus status = ScreenStatus.offline;
        if (statusStr == 'online') status = ScreenStatus.online;
        if (statusStr == 'error') status = ScreenStatus.error;

        screens[key] = ScreenData(
          id: key,
          name: value['name'] ?? 'شاشة غير معروفة',
          status: status,
          connectionType: value['connectionType'] ?? 'غير معروف',
          connectionStrength: (value['connectionStrength'] ?? 0.5).toDouble(),
          totalAdsPlayed: value['totalAdsPlayed'] ?? 0,
          errorCount: value['errorCount'] ?? 0,
          lastHeartbeat: DateTime.fromMillisecondsSinceEpoch(
              value['lastHeartbeat'] ?? 0),
          sessionStart: DateTime.fromMillisecondsSinceEpoch(
              value['sessionStart'] ?? 0),
        );
      });

      setState(() {
        _screens = screens;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
      );
    }
  }

  String _getMetricDisplayName(String metric) {
    switch (metric) {
      case 'ads':
        return 'الإعلانات';
      case 'errors':
        return 'الأخطاء';
      case 'performance':
        return 'الأداء';
      default:
        return 'المقياس';
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.grey;
      case 2:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }

  Widget _buildTopPerformers() {
    final sortedScreens = _screens.values.toList();
    if (_selectedMetric == 'ads') {
      sortedScreens.sort((a, b) => b.totalAdsPlayed.compareTo(a.totalAdsPlayed));
    } else if (_selectedMetric == 'errors') {
      sortedScreens.sort((a, b) => a.errorCount.compareTo(b.errorCount));
    }

    final topScreens = sortedScreens.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أفضل 5 شاشات حسب ${_getMetricDisplayName(_selectedMetric)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...topScreens.asMap().entries.map((entry) {
              final index = entry.key;
              final screen = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getRankColor(index).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getRankColor(index),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _getRankColor(index),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        (index + 1).toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            screen.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _selectedMetric == 'ads'
                                ? 'عدد الإعلانات: ${screen.totalAdsPlayed}'
                                : 'عدد الأخطاء: ${screen.errorCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsOverview() {
    final totalAds = _screens.values.fold<int>(0, (sum, screen) => sum + screen.totalAdsPlayed);
    final totalErrors = _screens.values.fold<int>(0, (sum, screen) => sum + screen.errorCount);
    final avgPerformance = _screens.isEmpty ? 0.0 : (totalAds / _screens.length);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMetricBox('الإعلانات', totalAds.toString(), Icons.play_circle),
          _buildMetricBox('الأخطاء', totalErrors.toString(), Icons.error),
          _buildMetricBox('متوسط الأداء', avgPerformance.toStringAsFixed(1), Icons.trending_up),
        ],
      ),
    );
  }

  Widget _buildMetricBox(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.purple, size: 30),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('تحليل الأداء'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.analytics),
            onSelected: (metric) {
              setState(() {
                _selectedMetric = metric;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'ads', child: Text('إحصائيات الإعلانات')),
              const PopupMenuItem(value: 'errors', child: Text('إحصائيات الأخطاء')),
              const PopupMenuItem(value: 'performance', child: Text('أداء النظام')),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.date_range),
            onSelected: (period) {
              setState(() {
                _selectedPeriod = period;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '1h', child: Text('آخر ساعة')),
              const PopupMenuItem(value: '24h', child: Text('آخر 24 ساعة')),
              const PopupMenuItem(value: '7d', child: Text('آخر أسبوع')),
              const PopupMenuItem(value: '30d', child: Text('آخر شهر')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAnalyticsOverview(),
            const SizedBox(height: 16),
            _buildTopPerformers(),
          ],
        ),
      ),
    );
  }
}