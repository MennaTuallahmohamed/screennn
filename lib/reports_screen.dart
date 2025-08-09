import 'package:flutter/material.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedReport = 'summary';
  String _selectedPeriod = '24h';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.insert_chart),
            onSelected: (report) {
              setState(() {
                _selectedReport = report;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'summary', child: Text('ملخص عام')),
              const PopupMenuItem(value: 'performance', child: Text('تقرير الأداء')),
              const PopupMenuItem(value: 'connectivity', child: Text('تقرير الاتصال')),
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
            if (_selectedReport == 'summary') _buildSummaryReport(),
            if (_selectedReport == 'performance') _buildPerformanceReport(),
            if (_selectedReport == 'connectivity') _buildConnectivityReport(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReportHeader('التقرير المختصر'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard('إجمالي الإعلانات', '1,250', Icons.play_circle, Colors.purple),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard('إجمالي الأخطاء', '12', Icons.error, Colors.red),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildScreensPerformanceTable(),
      ],
    );
  }

  Widget _buildReportHeader(String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.teal, Colors.cyan]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildScreensPerformanceTable() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أداء الشاشات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'اسم الشاشة',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'الإعلانات',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'الأخطاء',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('شاشة 1'),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('250'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        '2',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReportHeader('تقرير الأداء'),
        const SizedBox(height: 16),
        Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.purple.shade50, Colors.blue.shade50]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.show_chart, size: 60, color: Colors.purple),
                SizedBox(height: 16),
                Text(
                  'مخططات الأداء التفاعلية',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'قريباً - مخططات مفصلة للأداء',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectivityReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReportHeader('تقرير الاتصال'),
        const SizedBox(height: 16),
        Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.orange.shade50, Colors.red.shade50]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text('بيانات الاتصال'),
          ),
        ),
      ],
    );
  }
}