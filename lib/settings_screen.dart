import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _enableAnimations = true;
  bool _showProgressBar = false;
  bool _enableSound = true;
  bool _autoRestartOnError = true;
  bool _showAdCounter = true;
  bool _darkMode = false;
  bool _enableNotifications = true;
  int _heartbeatInterval = 15;
  int _maxRetries = 3;
  double _displayBrightness = 0.8;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableAnimations = prefs.getBool('enable_animations') ?? true;
      _showProgressBar = prefs.getBool('show_progress_bar') ?? false;
      _enableSound = prefs.getBool('enable_sound') ?? true;
      _autoRestartOnError = prefs.getBool('auto_restart_on_error') ?? true;
      _showAdCounter = prefs.getBool('show_ad_counter') ?? true;
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _enableNotifications = prefs.getBool('enable_notifications') ?? true;
      _heartbeatInterval = prefs.getInt('heartbeat_interval') ?? 15;
      _maxRetries = prefs.getInt('max_retries') ?? 3;
      _displayBrightness = prefs.getDouble('display_brightness') ?? 0.8;
    });
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('enable_animations', _enableAnimations);
      await prefs.setBool('show_progress_bar', _showProgressBar);
      await prefs.setBool('enable_sound', _enableSound);
      await prefs.setBool('auto_restart_on_error', _autoRestartOnError);
      await prefs.setBool('show_ad_counter', _showAdCounter);
      await prefs.setBool('dark_mode', _darkMode);
      await prefs.setBool('enable_notifications', _enableNotifications);
      await prefs.setInt('heartbeat_interval', _heartbeatInterval);
      await prefs.setInt('max_retries', _maxRetries);
      await prefs.setDouble('display_brightness', _displayBrightness);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الإعدادات بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في حفظ الإعدادات: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة تعيين الإعدادات'),
        content: const Text('هل أنت متأكد من إعادة تعيين جميع الإعدادات إلى القيم الافتراضية؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إعادة تعيين'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _loadSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إعادة تعيين الإعدادات بنجاح')),
      );
    }
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildSliderTile(String title, String subtitle, double value, double min, double max, Function(double) onChanged,
      {int? divisions, String? valueLabel}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: valueLabel,
          onChanged: onChanged,
          activeColor: Colors.cyan,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.build, color: Colors.cyan, size: 24),
                SizedBox(width: 12),
                Text(
                  'أدوات إضافية',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة تشغيل النظام'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.warning),
                    label: const Text('فحص النظام'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
          ),
          IconButton(
            onPressed: _resetToDefaults,
            icon: const Icon(Icons.restore),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSwitchTile('تفعيل الرسوم المتحركة', 'عرض انتقالات سلسة بين الإعلانات', _enableAnimations,
                    (value) => setState(() => _enableAnimations = value)),
                _buildSwitchTile('شريط التقدم', 'إظهار شريط تقدم الإعلان', _showProgressBar,
                    (value) => setState(() => _showProgressBar = value)),
                _buildSwitchTile('عداد الإعلانات', 'إظهار رقم الإعلان الحالي', _showAdCounter,
                    (value) => setState(() => _showAdCounter = value)),
                _buildSwitchTile('الوضع المظلم', 'استخدام ألوان داكنة', _darkMode, (value) => setState(() => _darkMode = value)),
                const Divider(),
                _buildSliderTile('سطوع الشاشة', 'تحكم في سطوع العرض', _displayBrightness, 0.1, 1.0, (value) {
                  setState(() {
                    _displayBrightness = value;
                  });
                }, divisions: 9, valueLabel: '${(_displayBrightness * 100).round()}%'),
                _buildSliderTile('فترة نبضة القلب (ثانية)', 'معدل إرسال تحديثات الحالة', _heartbeatInterval.toDouble(),
                    5.0, 30.0, (value) {
                  setState(() {
                    _heartbeatInterval = value.round();
                  });
                }, divisions: 5, valueLabel: '${_heartbeatInterval}s'),
                _buildSliderTile('محاولات إعادة الاتصال', 'عدد محاولات إعادة الاتصال', _maxRetries.toDouble(), 1.0, 10.0,
                    (value) {
                  setState(() {
                    _maxRetries = value.round();
                  });
                }, divisions: 9, valueLabel: _maxRetries.toString()),
                const Divider(),
                _buildActionButtons(),
              ],
            ),
    );
  }
}