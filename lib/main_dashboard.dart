import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum ScreenStatus { online, offline, error }

extension ScreenStatusExtension on ScreenStatus {
  String get displayName {
    switch (this) {
      case ScreenStatus.online:
        return 'متصل';
      case ScreenStatus.offline:
        return 'غير متصل';
      case ScreenStatus.error:
        return 'خطأ';
    }
  }
}

class ScreenData {
  final String id;
  final String name;
  final ScreenStatus status;
  final String connectionType;
  final double connectionStrength;
  final int totalAdsPlayed;
  final int errorCount;
  final DateTime lastHeartbeat;
  final DateTime sessionStart;

  ScreenData({
    required this.id,
    required this.name,
    required this.status,
    required this.connectionType,
    required this.connectionStrength,
    required this.totalAdsPlayed,
    required this.errorCount,
    required this.lastHeartbeat,
    required this.sessionStart,
  });
}

enum SystemEventType { error, adPlayed, connectionLost, connectionRestored, info }

class SystemLog {
  final String id;
  final String screenId;
  final String screenName;
  final String eventType;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> additionalData;

  SystemLog({
    required this.id,
    required this.screenId,
    required this.screenName,
    required this.eventType,
    required this.message,
    required this.timestamp,
    this.additionalData = const {},
  });

  factory SystemLog.fromMap(Map<String, dynamic> map) {
    return SystemLog(
      id: map['id'] ?? '',
      screenId: map['screenId'] ?? '',
      screenName: map['screenName'] ?? 'شاشة غير معروفة',
      eventType: map['eventType'] ?? 'info',
      message: map['message'] ?? '',
      timestamp: (map['timestamp'] is Timestamp)
          ? (map['timestamp'] as Timestamp).toDate()
          : (map['timestamp'] as DateTime? ?? DateTime.now()),
      additionalData: map['additionalData'] ?? {},
    );
  }
}

// ===================================================================
// MAIN DASHBOARD - لوحة التحكم
// ===================================================================
class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  final DatabaseReference _screensRef = FirebaseDatabase.instance.ref('screens');
  final CollectionReference _logsRef = FirebaseFirestore.instance.collection('logs');
  bool _isLoading = true;
  int totalScreens = 0;
  int onlineScreens = 0;
  int offlineScreens = 0;
  int errorScreens = 0;
  int totalAds = 0;
  int totalErrors = 0;
  double avgPerformance = 0.0;
  List<ScreenData> _screens = [];
  List<SystemLog> _errorLogs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // تحميل بيانات الشاشات من Realtime Database
      final snapshot = await _screensRef.once();
      final rawData = snapshot.snapshot.value;
      final data = (rawData as Map?)?.cast<String, dynamic>() ?? {};
      final List<ScreenData> screens = [];

      data.forEach((key, value) {
        final statusStr = value['status'] as String? ?? 'offline';
        ScreenStatus status = ScreenStatus.offline;
        if (statusStr == 'online') status = ScreenStatus.online;
        if (statusStr == 'error') status = ScreenStatus.error;

        screens.add(ScreenData(
          id: key,
          name: value['name'] ?? 'شاشة غير معروفة',
          status: status,
          connectionType: value['connectionType'] ?? 'غير معروف',
          connectionStrength: (value['connectionStrength'] is num)
              ? (value['connectionStrength'] as num).toDouble()
              : 0.5,
          totalAdsPlayed: value['totalAdsPlayed'] ?? 0,
          errorCount: value['errorCount'] ?? 0,
          lastHeartbeat: DateTime.fromMillisecondsSinceEpoch(value['lastHeartbeat'] ?? 0),
          sessionStart: DateTime.fromMillisecondsSinceEpoch(value['sessionStart'] ?? 0),
        ));
      });

      // تحميل اللوجات من Firestore
      final logsSnapshot = await _logsRef
          .where('eventType', isEqualTo: 'error')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      final errorLogs = logsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return SystemLog(
          id: doc.id,
          screenId: data['screenId'] ?? '',
          screenName: data['screenName'] ?? 'شاشة غير معروفة',
          eventType: data['eventType'] ?? 'info',
          message: data['message'] ?? '',
          timestamp: (data['timestamp'] is Timestamp)
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
          additionalData: data['additionalData'] ?? {},
        );
      }).toList();

      setState(() {
        _screens = screens;
        _errorLogs = errorLogs;
        totalScreens = screens.length;
        onlineScreens = screens.where((s) => s.status == ScreenStatus.online).length;
        offlineScreens = screens.where((s) => s.status == ScreenStatus.offline).length;
        errorScreens = screens.where((s) => s.status == ScreenStatus.error).length;
        totalAds = screens.fold(0, (sum, s) => sum + s.totalAdsPlayed);
        totalErrors = screens.fold(0, (sum, s) => sum + s.errorCount);
        avgPerformance = totalScreens > 0 ? (onlineScreens / totalScreens) * 100 : 0;
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

  Widget _buildAnalyticsMetric(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal, size: 28),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectivityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('حالة الشبكة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildNetworkStatusCard('الشاشات', totalScreens, Icons.tv, Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildNetworkStatusCard('متصلة', onlineScreens, Icons.signal_wifi_4_bar, Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _buildNetworkStatusCard('غير متصلة', offlineScreens, Icons.wifi_off, Colors.grey)),
                const SizedBox(width: 12),
                Expanded(child: _buildNetworkStatusCard('أخطاء', errorScreens, Icons.error, Colors.red)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkStatusCard(String title, int count, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(count.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: iconColor)),
          Text(title, style: TextStyle(fontSize: 12, color: iconColor.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildErrorsSummary(List<SystemLog> errorLogs) {
    final displayLogs = errorLogs.length > 5 ? errorLogs.sublist(0, 5) : errorLogs;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ملخص الأخطاء (${errorLogs.length} خطأ)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (errorLogs.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle, size: 60, color: Colors.green),
                    SizedBox(height: 16),
                    Text('لا توجد أخطاء!', style: TextStyle(fontSize: 16, color: Colors.green)),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayLogs.length,
                itemBuilder: (context, index) => _buildLogItem(displayLogs[index]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(SystemLog log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            log.eventType == 'connectionLost' ? Icons.wifi_off : Icons.wifi,
            color: log.eventType == 'connectionLost' ? Colors.red : Colors.green,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.message, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(_formatLogTimestamp(log.timestamp), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatLogTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inDays < 1) return 'منذ ${diff.inHours} ساعة';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(icon: const Icon(Icons.person), onPressed: _showUserProfile),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'مرحبًا بك في نظام اللافتات الرقمية',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildAnalyticsMetric('إجمالي الإعلانات', totalAds.toString(), Icons.play_circle)),
                const SizedBox(width: 12),
                Expanded(child: _buildAnalyticsMetric('إجمالي الأخطاء', totalErrors.toString(), Icons.error)),
                const SizedBox(width: 12),
                Expanded(child: _buildAnalyticsMetric('متوسط الأداء', '${avgPerformance.toStringAsFixed(1)}%', Icons.trending_up)),
              ],
            ),
            const SizedBox(height: 20),
            _buildConnectivityCard(),
            const SizedBox(height: 20),
            _buildErrorsSummary(_errorLogs),
            const SizedBox(height: 20),
            _buildScreensList(),
          ],
        ),
      ),
    );
  }

  Widget _buildScreensList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('الشاشات النشطة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _screens.length,
              itemBuilder: (context, index) => _buildScreenItem(_screens[index]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenItem(ScreenData screen) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusColor(screen.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getStatusColor(screen.status).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: _getStatusColor(screen.status), borderRadius: BorderRadius.circular(8)),
            child: Icon(_getStatusIcon(screen.status), color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(screen.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                Text('${screen.status.displayName} • ${screen.connectionType}', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${(screen.connectionStrength * 100).toInt()}%', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(width: 4),
              Icon(
                Icons.signal_wifi_4_bar,
                size: 14,
                color: screen.connectionStrength > 0.7
                    ? Colors.green
                    : screen.connectionStrength > 0.4
                        ? Colors.orange
                        : Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ScreenStatus status) {
    switch (status) {
      case ScreenStatus.online:
        return Colors.green;
      case ScreenStatus.offline:
        return Colors.grey;
      case ScreenStatus.error:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(ScreenStatus status) {
    switch (status) {
      case ScreenStatus.online:
        return Icons.circle;
      case ScreenStatus.offline:
        return Icons.circle_outlined;
      case ScreenStatus.error:
        return Icons.error;
    }
  }

  void _showUserProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('الملف الشخصي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.purple,
              child: const Text('م', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            const Text('مدير النظام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('مدير النظام الرئيسي', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
        ],
      ),
    );
  }
}
