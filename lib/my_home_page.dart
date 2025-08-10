import 'package:flutter/material.dart';
import 'package:screen/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _screenName = 'غير محدد';
  bool _isLoading = true;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _screenName = prefs.getString('screen_name') ?? 'غير محدد';
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _goToDisplayScreen() async {
    if (_screenName == 'غير محدد' || _screenName.isEmpty) {
      final name = await _showNameDialog();
      if (name == null || name.isEmpty) return;
      setState(() {
        _screenName = name;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('screen_name', name);
    }
    // الانتقال إلى شاشة العرض
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>  AdminDashboardScreen(),
      ),
    );
  }

  Future<String?> _showNameDialog() {
    String name = '';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('أدخل اسم الشاشة'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'مثل: شاشة الاستقبال',
          ),
          onChanged: (value) => name = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (name.trim().isNotEmpty) {
                Navigator.pop(context, name.trim());
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSettingsDialog() async {
    bool darkMode = _darkMode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الإعدادات'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SwitchListTile(
              title: const Text('الوضع المظلم'),
              value: darkMode,
              onChanged: (value) {
                setState(() {
                  darkMode = value;
                });
              },
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('dark_mode', darkMode);
              Navigator.pop(context);
              setState(() {
                _darkMode = darkMode;
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تطبيق الإعدادات')),
                );
              }
            },
            child: const Text('تطبيق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkMode ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        title: const Text('الصفحة الرئيسية'),
        actions: [
          IconButton(
            icon: Icon(_darkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => _showSettingsDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _buildMainView(),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('جاري التحميل...'),
        ],
      ),
    );
  }

  Widget _buildMainView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.tv,
            size: 100,
            color: _darkMode ? Colors.blue[300] : Colors.blue[700],
          ),
          const SizedBox(height: 32),
          Text(
            'نظام العرض الرقمي',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _darkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'اسم الشاشة: $_screenName',
            style: TextStyle(
              fontSize: 18,
              color: _darkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: _goToDisplayScreen,
            icon: const Icon(Icons.play_arrow),
            label: const Text('بدء العرض', style: TextStyle(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () async {
              final name = await _showNameDialog();
              if (name != null && name.isNotEmpty) {
                setState(() {
                  _screenName = name;
                });
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('screen_name', name);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم تغيير اسم الشاشة إلى: $name')),
                );
              }
            },
            child: const Text('تغيير اسم الشاشة'),
          ),
        ],
      ),
    );
  }
}