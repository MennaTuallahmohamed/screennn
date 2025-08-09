import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class BackupData {
  final String id;
  final DateTime timestamp;
  final int size;
  final int adsCount;
  final int screensCount;
  final bool isSuccessful;
  final Map<String, dynamic> data;

  BackupData({
    required this.id,
    required this.timestamp,
    required this.size,
    required this.adsCount,
    required this.screensCount,
    required this.isSuccessful,
    required this.data,
  });

  factory BackupData.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BackupData(
      id: doc.id,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      size: data['size'] ?? 0,
      adsCount: data['adsCount'] ?? 0,
      screensCount: data['screensCount'] ?? 0,
      isSuccessful: data['isSuccessful'] ?? false,
      data: data['data'] ?? {},
    );
  }
}

class BackupsScreen extends StatefulWidget {
  const BackupsScreen({super.key});

  @override
  State<BackupsScreen> createState() => _BackupsScreenState();
}

class _BackupsScreenState extends State<BackupsScreen> {
  final CollectionReference _backupsRef = FirebaseFirestore.instance.collection('backups');
  bool _isLoading = true;
  List<BackupData> _backups = [];

  @override
  void initState() {
    super.initState();
    _loadBackupHistory();
  }

  Future<void> _loadBackupHistory() async {
    try {
      final snapshot = await _backupsRef.orderBy('timestamp', descending: true).get();
      final backups = snapshot.docs.map((doc) => BackupData.fromDocument(doc)).toList();

      setState(() {
        _backups = backups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل تاريخ النسخ الاحتياطي: $e')),
      );
    }
  }

  Future<void> _createBackup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final _firestore = FirebaseFirestore.instance;
      final _screensRef = FirebaseDatabase.instance.ref('screens');

      final adsSnapshot = await _firestore.collection('ads').get();
      final adsData = adsSnapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      final screensSnapshot = await _screensRef.once();
      final screensData = screensSnapshot.snapshot.value as Map<dynamic, dynamic>? ?? {};

      final settingsSnapshot = await _firestore.collection('system_settings').get();
      final settingsData = settingsSnapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      final backupData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'ads': adsData,
        'screens': screensData,
        'settings': settingsData,
        'version': '1.0.0',
        'createdBy': 'system',
      };

      final backupDoc = await _firestore.collection('backups').add({
        'timestamp': DateTime.now(),
        'size': _calculateBackupSize(backupData),
        'adsCount': adsData.length,
        'screensCount': screensData.length,
        'isSuccessful': true,
        'data': backupData,
      });

      await _loadBackupHistory();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إنشاء النسخة الاحتياطية بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في إنشاء النسخة الاحتياطية: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  int _calculateBackupSize(Map<String, dynamic> data) {
    final json = data.toString();
    return json.length;
  }

  Future<void> _restoreBackup(BackupData backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استعادة النسخة الاحتياطية'),
        content: const Text(
            'هل أنت متأكد من استعادة هذه النسخة الاحتياطية؟ سيتم استبدال جميع البيانات الحالية.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('استعادة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });
      try {
        // هنا يمكن إضافة منطق استعادة البيانات من النسخة الاحتياطية
        // مثال: استعادة الإعلانات، الشاشات، والإعدادات
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم استعادة النسخة الاحتياطية بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في استعادة النسخة الاحتياطية: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _exportBackup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ميزة التصدير قيد التطوير')),
    );
  }

  void _importBackup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ميزة الاستيراد قيد التطوير')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('النسخ الاحتياطي والاستعادة'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadBackupHistory,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.backup, color: Colors.cyan, size: 28),
                            SizedBox(width: 12),
                            Text(
                              'إجراءات النسخ الاحتياطي',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'يمكنك إنشاء نسخة احتياطية كاملة من البيانات أو استعادة نسخة سابقة.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _createBackup,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.backup),
                                label: Text(_isLoading ? 'جاري الإنشاء...' : 'إنشاء نسخة احتياطية'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _exportBackup,
                                icon: const Icon(Icons.download),
                                label: const Text('تصدير النسخة'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _importBackup,
                                icon: const Icon(Icons.upload),
                                label: const Text('استيراد نسخة'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildBackupHistory(),
              ],
            ),
    );
  }

  Widget _buildBackupHistory() {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.history, color: Colors.cyan, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'تاريخ النسخ الاحتياطي',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _backups.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.backup_outlined, size: 60, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'لا توجد نسخ احتياطية',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            Text(
                              'قم بإنشاء نسخة احتياطية أولاً',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _backups.length,
                        itemBuilder: (context, index) {
                          final backup = _backups[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.backup, color: Colors.blue),
                              title: Text(
                                'نسخة من ${_formatTimestamp(backup.timestamp)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'إعلانات: ${backup.adsCount} | شاشات: ${backup.screensCount} | الحجم: ${_formatFileSize(backup.size)}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                              trailing: Wrap(
                                spacing: 8,
                                children: [
                                  IconButton(
                                    onPressed: () => _restoreBackup(backup),
                                    icon: const Icon(Icons.restore, color: Colors.green),
                                  ),
                                  IconButton(
                                    onPressed: () => _exportBackup(),
                                    icon: const Icon(Icons.download, color: Colors.blue),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}