import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      timestamp: (map['timestamp'] as DateTime),
      additionalData: map['additionalData'] ?? {},
    );
  }
}

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final CollectionReference _logsRef = FirebaseFirestore.instance.collection('logs');
  bool _isLoading = true;
  List<SystemLog> _logs = [];
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      Query query = _logsRef.orderBy('timestamp', descending: true).limit(100);
      if (_selectedFilter != 'all') {
        query = query.where('eventType', isEqualTo: _selectedFilter);
      }

      final snapshot = await query.get();
      final logs = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return SystemLog(
          id: doc.id,
          screenId: data['screenId'] ?? '',
          screenName: data['screenName'] ?? 'غير معروف',
          eventType: data['eventType'] ?? 'error',
          message: data['message'] ?? '',
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          additionalData: data['additionalData'] ?? {},
        );
      }).toList();

      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل السجلات: $e')),
      );
    }
  }

  Color _getLogTypeColor(String type) {
    switch (type) {
      case 'error':
        return Colors.red;
      case 'adPlayed':
        return Colors.green;
      case 'connectionLost':
        return Colors.orange;
      case 'connectionRestored':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getLogTypeIcon(String type) {
    switch (type) {
      case 'error':
        return Icons.error;
      case 'adPlayed':
        return Icons.play_circle;
      case 'connectionLost':
        return Icons.wifi_off;
      case 'connectionRestored':
        return Icons.wifi;
      default:
        return Icons.info;
    }
  }

  String _getLogTypeDisplayName(String type) {
    switch (type) {
      case 'error':
        return 'خطأ';
      case 'adPlayed':
        return 'عرض إعلان';
      case 'connectionLost':
        return 'انقطع الاتصال';
      case 'connectionRestored':
        return 'استُعيد الاتصال';
      default:
        return 'معلومة';
    }
  }

  String _formatLogTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inDays < 1) return 'منذ ${diff.inHours} ساعة';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  void _showLogDetails(SystemLog log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getLogTypeIcon(log.eventType),
              color: _getLogTypeColor(log.eventType),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'تفاصيل ${_getLogTypeDisplayName(log.eventType)}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLogDetailRow('الرسالة', log.message),
              _buildLogDetailRow('اسم الشاشة', log.screenName),
              _buildLogDetailRow('معرف الشاشة', log.screenId),
              _buildLogDetailRow('نوع الحدث', _getLogTypeDisplayName(log.eventType)),
              _buildLogDetailRow('الوقت', _formatLogTimestamp(log.timestamp)),
              if (log.additionalData.isNotEmpty) ...[
                const Divider(),
                const Text(
                  'بيانات إضافية',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...log.additionalData.entries.map((entry) => _buildLogDetailRow(entry.key, entry.value.toString())),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم نسخ التفاصيل')),
              );
              Navigator.pop(context);
            },
            child: const Text('نسخ'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل النظام'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (filter) {
              setState(() {
                _selectedFilter = filter;
              });
              _loadLogs();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('جميع الأحداث')),
              const PopupMenuItem(value: 'error', child: Text('الأخطاء فقط')),
              const PopupMenuItem(value: 'adPlayed', child: Text('عرض الإعلانات')),
              const PopupMenuItem(value: 'connectionLost', child: Text('انقطاع الاتصال')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(
                  child: Text('لا توجد سجلات بعد'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getLogTypeColor(log.eventType),
                          child: Icon(
                            _getLogTypeIcon(log.eventType),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          log.message,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'الشاشة: ${log.screenName}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _formatLogTimestamp(log.timestamp),
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getLogTypeColor(log.eventType).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getLogTypeColor(log.eventType).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            _getLogTypeDisplayName(log.eventType),
                            style: TextStyle(
                              color: _getLogTypeColor(log.eventType),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onTap: () => _showLogDetails(log),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}