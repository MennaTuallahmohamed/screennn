import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:screen/my_home_page.dart';
import 'package:screen/ranslation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'main.dart';

class ProfessionalDisplayScreen extends StatefulWidget {
  const ProfessionalDisplayScreen({Key? key}) : super(key: key);

  @override
  State<ProfessionalDisplayScreen> createState() => _ProfessionalDisplayScreenState();
}

class _ProfessionalDisplayScreenState extends State<ProfessionalDisplayScreen>
    with TickerProviderStateMixin {
 
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseReference _realtimeDB = FirebaseDatabase.instance.ref();

  
  String? screenName;
  String? screenId;
  List<DocumentSnapshot> ads = [];
  List<Widget> adWidgets = [];
  List<VideoPlayerController?> videoControllers = [];
  int currentAdIndex = 0;
  bool isLoadingAds = true;
  DateTime _lastAdChangeTime = DateTime.now();

  // Localization
  Locale _locale = const Locale('en');
  Map<String, String> _localizedStrings = {};

  // Subscriptions and timers
  StreamSubscription<QuerySnapshot>? adsSubscription;
  StreamSubscription<DocumentSnapshot>? screenControlSubscription;
  Timer? adTimer;
  Timer? _statusTimer;
  Timer? _heartbeatTimer;
  Timer? _playTimeTimer;
  Timer? _progressTimer;
  Timer? _realtimeStatusTimer;
  Timer? _remoteCommandTimer;

  bool _isOnline = true;
  bool _showStatusBar = false;
  bool _showDebugInfo = false;
  String _connectionStatus = 'متصل';
  DateTime? _lastConnectionTime;
  int _currentRetries = 0;
  final int _maxRetries = 3;

  bool _remoteControlEnabled = true;
  bool _isScreenForcedOffline = false;
  String _remoteStatus = 'online'; // online, offline, maintenance, restricted
  String _remoteMessage = '';
  Map<String, dynamic> _remoteSettings = {};
  DateTime? _lastRemoteCommand;
  List<String> _remoteCommandHistory = [];

  bool _isSecureModeActive = false;
  String _securityPin = '';
  DateTime? _lastSecurityCheck;
  int _failedAuthAttempts = 0;
  bool _isLocked = false;

  Map<String, dynamic> _performanceMetrics = {
    'cpu_usage': 0.0,
    'memory_usage': 0.0,
    'network_latency': 0,
    'frame_rate': 60.0,
    'error_count': 0,
    'crash_count': 0,
    'last_crash': null,
  };
  Timer? _performanceMonitorTimer;

  bool _emergencyModeActive = false;
  String _emergencyMessage = '';
  Color _emergencyBgColor = Colors.red;
  bool _emergencyFlashing = false;
  Timer? _emergencyFlashTimer;

  Map<String, dynamic> _scheduleSettings = {
    'auto_on_off': false,
    'morning_start': '08:00',
    'evening_end': '22:00',
    'weekend_schedule': true,
    'holiday_schedule': {},
    'maintenance_windows': [],
  };
  Timer? _scheduleTimer;

  int _totalAdsShown = 0;
  Map<String, int> _adPlayCount = {};
  Duration _totalPlayTime = Duration.zero;
  Map<String, Map<String, dynamic>> _detailedStats = {};
  DateTime _sessionStartTime = DateTime.now();

  bool _enableAnimations = true;
  bool _showProgressBar = false;
  bool _enableSound = true;
  bool _autoRestartOnError = true;
  bool _enableFullScreenMode = false;
  bool _showAdCounter = true;
  bool _enableSwipeGestures = true;
  bool _darkMode = false;
  bool _showWatermark = true;
  bool _enableTransitions = true;

  // Display settings
  double _displayBrightness = 1.0;
  Color _primaryColor = Colors.blue;
  Color _accentColor = Colors.orange;

  String _currentAdType = '';
  Duration _currentAdDuration = Duration.zero;
  double _currentProgress = 0.0;
  int _remainingTime = 0;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _emergencyFlashController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _emergencyFlashAnimation;

  bool _enableKenBurnsEffect = true;
  bool _enableCrossFade = true;
  double _transitionSpeed = 1.0;
  String _transitionType = 'fade';
  bool _enableAutoplay = true;
  bool _showTimestamp = true;
  bool _enableScreenSaver = true;
  Duration _screenSaverDelay = const Duration(minutes: 30);
  Timer? _screenSaverTimer;
  bool _isScreenSaverActive = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSettings();
    _initializeScreen();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _handleLanguageAndNameDialogs();
      await _initializeRealtimeStatus();
      await _setupRemoteControl();
      await _setupPerformanceMonitoring();
      await _setupSmartScheduling();
      _startAllTimers();
    });
  }

  void _initializeScreen() async {
    final prefs = await SharedPreferences.getInstance();
    screenId = prefs.getString('screen_id') ?? _generateScreenId();
    await prefs.setString('screen_id', screenId!);
    _securityPin = prefs.getString('security_pin') ?? '';
    _isSecureModeActive = prefs.getBool('secure_mode') ?? false;
  }

  String _generateScreenId() {
    return 'screen_${DateTime.now().millisecondsSinceEpoch}';
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: (800 / _transitionSpeed).round()),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: (600 / _transitionSpeed).round()),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: Duration(milliseconds: (1000 / _transitionSpeed).round()),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: Duration(milliseconds: (1200 / _transitionSpeed).round()),
      vsync: this,
    );
    _emergencyFlashController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );
    _emergencyFlashAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _emergencyFlashController, curve: Curves.easeInOut),
    );
  }

  Future<void> _setupRemoteControl() async {
    if (!_remoteControlEnabled || screenName == null) return;
    try {
      screenControlSubscription = _firestore
          .collection('screen_controls')
          .doc(screenName)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          _processRemoteCommand(data);
        }
      });

      await _firestore.collection('screen_controls').doc(screenName).set({
        'screen_id': screenId,
        'status': 'online',
        'last_command': null,
        'remote_settings': _remoteSettings,
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ Remote control system initialized');
    } catch (e) {
      debugPrint('❌ Error setting up remote control: $e');
    }
  }

  void _processRemoteCommand(Map<String, dynamic> commandData) {
    final command = commandData['command'] as String?;
    final timestamp = commandData['timestamp'] as Timestamp?;

    if (command == null || timestamp == null) return;

    final commandTime = timestamp.toDate();
    if (_lastRemoteCommand != null && commandTime.isBefore(_lastRemoteCommand!)) return;

    _lastRemoteCommand = commandTime;
    _remoteCommandHistory.add('${command} at ${commandTime}');
    if (_remoteCommandHistory.length > 50) {
      _remoteCommandHistory.removeAt(0);
    }

    debugPrint('🎮 Processing remote command: $command');

    switch (command) {
      case 'force_offline':
        setState(() {
          _isScreenForcedOffline = true;
          _remoteStatus = 'offline';
          _remoteMessage = commandData['message'] ?? 'الشاشة متوقفة عن بُعد';
        });
        break;
      case 'force_online':
        setState(() {
          _isScreenForcedOffline = false;
          _remoteStatus = 'online';
          _remoteMessage = '';
        });
        break;
      case 'maintenance_mode':
        setState(() {
          _remoteStatus = 'maintenance';
          _remoteMessage = commandData['message'] ?? 'وضع الصيانة نشط';
        });
        break;
      case 'emergency_message':
        _activateEmergencyMode(
          commandData['message'] ?? 'رسالة ئ',
          Color(commandData['bg_color'] ?? Colors.red.value),
          commandData['flashing'] ?? true,
        );
        break;
      case 'clear_emergency':
        _deactivateEmergencyMode();
        break;
      case 'restart_app':
        _restartApp();
        break;
      case 'skip_ad':
        _skipCurrentAd();
        break;
      case 'pause_resume':
        _pauseResumeAd();
        break;
      case 'toggle_sound':
        _toggleSound();
        break;
      case 'update_settings':
        _updateRemoteSettings(commandData['settings'] ?? {});
        break;
      case 'lock_screen':
        _lockScreen(commandData['pin'] ?? '');
        break;
      case 'unlock_screen':
        _unlockScreen(commandData['pin'] ?? '');
        break;
      case 'set_brightness':
        _setBrightness(commandData['level']?.toDouble() ?? 1.0);
        break;
      case 'change_theme':
        _changeTheme(commandData['dark_mode'] ?? false);
        break;
    }

    _updateRemoteCommandStatus(command, 'executed');
  }

  Future<void> _updateRemoteCommandStatus(String command, String status) async {
    if (screenName == null) return;
    try {
      await _firestore.collection('screen_controls').doc(screenName).update({
        'last_executed_command': command,
        'last_execution_status': status,
        'last_execution_time': FieldValue.serverTimestamp(),
        'command_history': _remoteCommandHistory.take(10).toList(),
      });
    } catch (e) {
      debugPrint('Error updating command status: $e');
    }
  }

  void _activateEmergencyMode(String message, Color bgColor, bool flashing) {
    setState(() {
      _emergencyModeActive = true;
      _emergencyMessage = message;
      _emergencyBgColor = bgColor;
      _emergencyFlashing = flashing;
    });

    if (flashing) {
      _emergencyFlashTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        _emergencyFlashController.forward().then((_) {
          _emergencyFlashController.reverse();
        });
      });
    }

    Timer(const Duration(seconds: 30), () {
      if (!message.toLowerCase().contains('خطر') &&
          !message.toLowerCase().contains('ئ')) {
        _deactivateEmergencyMode();
      }
    });
  }

  void _deactivateEmergencyMode() {
    setState(() {
      _emergencyModeActive = false;
      _emergencyMessage = '';
      _emergencyFlashing = false;
    });
    _emergencyFlashTimer?.cancel();
    _emergencyFlashController.stop();
  }

  void _lockScreen(String pin) {
    if (_securityPin.isEmpty || pin == _securityPin) {
      setState(() {
        _isLocked = true;
        _failedAuthAttempts = 0;
      });
    } else {
      _failedAuthAttempts++;
      if (_failedAuthAttempts >= 3) {
        _reportSecurityBreach();
      }
    }
  }

  void _unlockScreen(String pin) {
    if (pin == _securityPin) {
      setState(() {
        _isLocked = false;
        _failedAuthAttempts = 0;
      });
    } else {
      _failedAuthAttempts++;
      if (_failedAuthAttempts >= 3) {
        _reportSecurityBreach();
      }
    }
  }

  void _reportSecurityBreach() async {
    if (screenName == null) return;
    try {
      await _firestore.collection('security_logs').add({
        'screen_name': screenName,
        'screen_id': screenId,
        'event': 'failed_authentication',
        'attempts': _failedAuthAttempts,
        'timestamp': FieldValue.serverTimestamp(),
        'device_info': await _getDeviceInfo(),
      });
    } catch (e) {
      debugPrint('Error reporting security breach: $e');
    }
  }

  Future<void> _setupPerformanceMonitoring() async {
    _performanceMonitorTimer = Timer.periodic(
      const Duration(seconds: 10),
          (timer) => _updatePerformanceMetrics(),
    );
  }

  void _updatePerformanceMetrics() async {
    try {
      setState(() {
        _performanceMetrics['timestamp'] = DateTime.now().toIso8601String();
        _performanceMetrics['memory_usage'] = _calculateMemoryUsage();
        _performanceMetrics['error_count'] = _performanceMetrics['error_count'] ?? 0;
      });

      if (DateTime.now().second % 60 == 0) {
        await _sendPerformanceMetrics();
      }
    } catch (e) {
      debugPrint('Error updating performance metrics: $e');
      _performanceMetrics['error_count'] = (_performanceMetrics['error_count'] ?? 0) + 1;
    }
  }

  double _calculateMemoryUsage() {
    return (adWidgets.length * 10.0 + videoControllers.length * 50.0).clamp(0.0, 100.0);
  }

  Future<void> _sendPerformanceMetrics() async {
    if (screenName == null) return;
    try {
      await _firestore.collection('performance_logs').add({
        'screen_name': screenName,
        'screen_id': screenId,
        'metrics': _performanceMetrics,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sending performance metrics: $e');
    }
  }

  Future<void> _setupSmartScheduling() async {
    final prefs = await SharedPreferences.getInstance();
    final scheduleJson = prefs.getString('schedule_settings');
    if (scheduleJson != null) {
      _scheduleSettings = json.decode(scheduleJson);
    }
    if (_scheduleSettings['auto_on_off'] == true) {
      _scheduleTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
        _checkSchedule();
      });
    }
  }

  void _checkSchedule() {
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final morningStart = _scheduleSettings['morning_start'] as String;
    final eveningEnd = _scheduleSettings['evening_end'] as String;

    if (currentTime == morningStart && _isScreenForcedOffline) {
      setState(() {
        _isScreenForcedOffline = false;
        _remoteStatus = 'online';
        _remoteMessage = 'تم تشغيل الشاشة تلقائياً حسب الجدول المحدد';
      });
    } else if (currentTime == eveningEnd && !_isScreenForcedOffline) {
      setState(() {
        _isScreenForcedOffline = true;
        _remoteStatus = 'scheduled_offline';
        _remoteMessage = 'تم إيقاف الشاشة تلقائياً حسب الجدول المحدد';
      });
    }
  }

  void _updateRemoteSettings(Map<String, dynamic> newSettings) {
    setState(() {
      _remoteSettings.addAll(newSettings);
    });

    if (newSettings.containsKey('brightness')) {
      _setBrightness(newSettings['brightness'].toDouble());
    }
    if (newSettings.containsKey('volume')) {
      _setVolume(newSettings['volume'].toDouble());
    }
    if (newSettings.containsKey('dark_mode')) {
      _changeTheme(newSettings['dark_mode']);
    }
    _saveSettings();
  }

  void _setBrightness(double level) {
    setState(() {
      _displayBrightness = level.clamp(0.1, 1.0);
    });
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.black.withOpacity(_displayBrightness),
    ));
  }

  void _setVolume(double level) {
    final controller = videoControllers[currentAdIndex];
    if (controller != null) {
      controller.setVolume(level.clamp(0.0, 1.0));
    }
  }

  void _changeTheme(bool darkMode) {
    setState(() {
      _darkMode = darkMode;
    });
    _saveSettings();
  }

  Future<void> _initializeRealtimeStatus() async {
    if (screenName == null || screenId == null) return;
    try {
      await _realtimeDB.child('screens').child(screenId!).set({
        'screenName': screenName,
        'status': _remoteStatus,
        'forced_offline': _isScreenForcedOffline,
        'lastSeen': ServerValue.timestamp,
        'sessionStart': ServerValue.timestamp,
        'currentAd': currentAdIndex,
        'totalAdsShown': _totalAdsShown,
        'totalPlayTime': _totalPlayTime.inSeconds,
        'appVersion': '2.1.0',
        'deviceInfo': await _getDeviceInfo(),
        'remoteControlEnabled': _remoteControlEnabled,
        'isLocked': _isLocked,
        'emergencyMode': _emergencyModeActive,
        'performanceMetrics': _performanceMetrics,
      });

      await _realtimeDB.child('screens').child(screenId!).onDisconnect().update({
        'status': 'offline',
        'lastSeen': ServerValue.timestamp,
      });

      _startRealtimeStatusUpdates();
      debugPrint('✅ Enhanced Realtime Database initialized for screen: $screenId');
    } catch (e) {
      debugPrint('❌ Error initializing Realtime Database: $e');
    }
  }

  void _startRealtimeStatusUpdates() {
    _realtimeStatusTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateRealtimeStatus();
    });
  }

  Future<void> _updateRealtimeStatus() async {
    if (screenId == null) return;
    try {
      await _realtimeDB.child('screens').child(screenId!).update({
        'status': _isScreenForcedOffline ? 'forced_offline' : 'online',
        'remote_status': _remoteStatus,
        'remote_message': _remoteMessage,
        'forced_offline': _isScreenForcedOffline,
        'lastSeen': ServerValue.timestamp,
        'currentAd': currentAdIndex,
        'totalAdsShown': _totalAdsShown,
        'totalPlayTime': _totalPlayTime.inSeconds,
        'adsCount': ads.length,
        'connectionStatus': _connectionStatus,
        'isPlaying': _isCurrentAdPlaying(),
        'currentAdType': _currentAdType,
        'sessionDuration': DateTime.now().difference(_sessionStartTime).inSeconds,
        'isLocked': _isLocked,
        'emergencyMode': _emergencyModeActive,
        'emergencyMessage': _emergencyMessage,
        'performanceMetrics': _performanceMetrics,
        'brightness': _displayBrightness,
        'soundEnabled': _enableSound,
        'lastRemoteCommand': _lastRemoteCommand?.toIso8601String(),
      });

      if (!_isScreenForcedOffline) {
        setState(() {
          _isOnline = true;
          _connectionStatus = 'متصل';
          _lastConnectionTime = DateTime.now();
        });
      }
    } catch (e) {
      setState(() {
        _isOnline = false;
        _connectionStatus = 'منقطع';
      });
      debugPrint('❌ Error updating enhanced Realtime status: $e');
    }
  }

  bool _isCurrentAdPlaying() {
    if (_isScreenForcedOffline || _isLocked || videoControllers.isEmpty || currentAdIndex >= videoControllers.length) {
      return false;
    }
    final controller = videoControllers[currentAdIndex];
    return controller?.value.isPlaying ?? false;
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    return {
      'platform': defaultTargetPlatform.name,
      'timestamp': DateTime.now().toIso8601String(),
      'app_version': '2.1.0',
      'screen_resolution': '${MediaQuery.of(context).size.width}x${MediaQuery.of(context).size.height}',
      'brightness': _displayBrightness,
      'sound_enabled': _enableSound,
      'remote_control_enabled': _remoteControlEnabled,
    };
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableAnimations = prefs.getBool('enable_animations') ?? true;
      _showProgressBar = prefs.getBool('show_progress_bar') ?? false;
      _enableSound = prefs.getBool('enable_sound') ?? true;
      _autoRestartOnError = prefs.getBool('auto_restart_on_error') ?? true;
      _showAdCounter = prefs.getBool('show_ad_counter') ?? true;
      _enableSwipeGestures = prefs.getBool('enable_swipe_gestures') ?? true;
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _showWatermark = prefs.getBool('show_watermark') ?? true;
      _enableKenBurnsEffect = prefs.getBool('enable_ken_burns') ?? true;
      _enableCrossFade = prefs.getBool('enable_cross_fade') ?? true;
      _transitionSpeed = prefs.getDouble('transition_speed') ?? 1.0;
      _transitionType = prefs.getString('transition_type') ?? 'fade';
      _showTimestamp = prefs.getBool('show_timestamp') ?? true;
      _enableScreenSaver = prefs.getBool('enable_screen_saver') ?? true;
      _remoteControlEnabled = prefs.getBool('remote_control_enabled') ?? true;
      _displayBrightness = prefs.getDouble('display_brightness') ?? 1.0;
    });
  }

  void _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_animations', _enableAnimations);
    await prefs.setBool('show_progress_bar', _showProgressBar);
    await prefs.setBool('enable_sound', _enableSound);
    await prefs.setBool('auto_restart_on_error', _autoRestartOnError);
    await prefs.setBool('show_ad_counter', _showAdCounter);
    await prefs.setBool('enable_swipe_gestures', _enableSwipeGestures);
    await prefs.setBool('dark_mode', _darkMode);
    await prefs.setBool('show_watermark', _showWatermark);
    await prefs.setBool('enable_ken_burns', _enableKenBurnsEffect);
    await prefs.setBool('enable_cross_fade', _enableCrossFade);
    await prefs.setDouble('transition_speed', _transitionSpeed);
    await prefs.setString('transition_type', _transitionType);
    await prefs.setBool('show_timestamp', _showTimestamp);
    await prefs.setBool('enable_screen_saver', _enableScreenSaver);
    await prefs.setBool('remote_control_enabled', _remoteControlEnabled);
    await prefs.setDouble('display_brightness', _displayBrightness);
    await prefs.setString('schedule_settings', json.encode(_scheduleSettings));
  }

  void _startAllTimers() {
    _startHeartbeat();
    _startPlayTimeTracking();
    _startProgressTracking();
    _startScreenSaverTimer();
  }

  void _startScreenSaverTimer() {
    if (!_enableScreenSaver || _isScreenForcedOffline || _isLocked) return;
    _screenSaverTimer?.cancel();
    _screenSaverTimer = Timer(_screenSaverDelay, () {
      setState(() {
        _isScreenSaverActive = true;
      });
      Timer(const Duration(seconds: 10), () {
        setState(() {
          _isScreenSaverActive = false;
        });
        _startScreenSaverTimer();
      });
    });
  }

  void _resetScreenSaverTimer() {
    if (_isScreenSaverActive) {
      setState(() {
        _isScreenSaverActive = false;
      });
    }
    _startScreenSaverTimer();
  }

  void _startProgressTracking() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted && adWidgets.isNotEmpty && !_isScreenForcedOffline && !_isLocked) {
        final controller = videoControllers[currentAdIndex];
        if (controller != null && controller.value.isInitialized) {
          final position = controller.value.position;
          final duration = controller.value.duration;
          setState(() {
            _currentProgress = position.inMilliseconds / duration.inMilliseconds;
            _remainingTime = duration.inSeconds - position.inSeconds;
          });
        } else {
          final elapsed = DateTime.now().difference(_lastAdChangeTime);
          const totalDuration = Duration(seconds: 5);
          setState(() {
            _currentProgress = elapsed.inMilliseconds / totalDuration.inMilliseconds;
            _remainingTime = totalDuration.inSeconds - elapsed.inSeconds;
          });
        }
      }
    });
  }

  void _startPlayTimeTracking() {
    _playTimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isScreenForcedOffline && !_isLocked) {
        setState(() {
          _totalPlayTime += const Duration(seconds: 1);
        });

        final currentAdId = ads.isNotEmpty ? ads[currentAdIndex].id : 'unknown';
        _detailedStats[currentAdId] ??= {
          'play_time': Duration.zero,
          'play_count': 0,
          'last_played': DateTime.now(),
        };
        _detailedStats[currentAdId]!['play_time'] =
            (_detailedStats[currentAdId]!['play_time'] as Duration) + const Duration(seconds: 1);
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (screenName != null) {
        try {
          await _firestore.collection('screen_heartbeat').doc(screenName).set({
            'screen_id': screenId,
            'last_heartbeat': FieldValue.serverTimestamp(),
            'status': _isScreenForcedOffline ? 'forced_offline' : 'active',
            'current_ad': currentAdIndex,
            'ads_count': ads.length,
            'total_play_time': _totalPlayTime.inSeconds,
            'session_duration': DateTime.now().difference(_sessionStartTime).inSeconds,
            'performance_metrics': _performanceMetrics,
            'emergency_mode': _emergencyModeActive,
            'locked': _isLocked,
            'remote_control_active': _remoteControlEnabled,
          }, SetOptions(merge: true));

          if (mounted && !_isScreenForcedOffline) {
            setState(() {
              _connectionStatus = 'متصل';
              _isOnline = true;
              _currentRetries = 0;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _connectionStatus = 'منقطع';
              _isOnline = false;
              _currentRetries++;
            });
          }
          if (_currentRetries >= _maxRetries && _autoRestartOnError) {
            debugPrint('🔄 Auto-restarting due to connection failure');
            await _restartConnection();
          }
          debugPrint('💗 Heartbeat error: $e');
        }
      }
    });
  }

  Future<void> _restartConnection() async {
    try {
      setState(() {
        _currentRetries = 0;
        _connectionStatus = 'إعادة الاتصال...';
      });
      await Future.delayed(const Duration(seconds: 2));
      if (screenName != null) {
        await _loadAdsData();
        setState(() {
          _connectionStatus = 'متصل';
          _isOnline = true;
        });
      }
    } catch (e) {
      debugPrint('❌ Failed to restart connection: $e');
    }
  }

  Future<void> _handleLanguageAndNameDialogs() async {
    final prefs = await SharedPreferences.getInstance();
    screenName = prefs.getString('screen_name');
    if (screenName == null || screenName!.isEmpty) {
      final result = await _showScreenNameDialog();
      if (result != null && result.isNotEmpty) {
        screenName = result;
        await prefs.setString('screen_name', screenName!);
      } else {
        screenName = 'default_screen_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString('screen_name', screenName!);
      }
    }

    final locale = prefs.getString('app_locale');
    if (locale == null) {
      final selectedLocale = await _showLanguageDialog();
      _locale = selectedLocale;
      await prefs.setString('app_locale', _locale.languageCode);
    } else {
      _locale = Locale(locale);
    }

    await _loadLocalizedStrings();
    await _loadAdsData();
  }

  Future<String?> _showScreenNameDialog() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _darkMode ? Colors.grey[900] : Colors.white,
        title: Text(
          _getLocalizedString('enter_screen_name'),
          style: TextStyle(
            color: _darkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          decoration: InputDecoration(
            hintText: _getLocalizedString('screen_name_hint'),
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: _darkMode ? Colors.grey[800] : Colors.grey[100],
          ),
          style: TextStyle(color: _darkMode ? Colors.white : Colors.black87),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop('default_screen'),
            child: Text(_getLocalizedString('use_default')),
          ),
        ],
      ),
    );
  }

  Future<Locale> _showLanguageDialog() async {
    return showDialog<Locale>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _darkMode ? Colors.grey[900] : Colors.white,
        title: Text(
          'اختر اللغة / Choose Language',
          style: TextStyle(
            color: _darkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('العربية', style: TextStyle(fontSize: 18)),
              onTap: () => Navigator.of(context).pop(const Locale('ar')),
            ),
            ListTile(
              title: const Text('English', style: TextStyle(fontSize: 18)),
              onTap: () => Navigator.of(context).pop(const Locale('en')),
            ),
          ],
        ),
      ),
    ).then((value) => value ?? const Locale('ar'));
  }

  Future<void> _loadLocalizedStrings() async {
    _localizedStrings = LocalizedStrings.getStrings(_locale.languageCode);
  }

  String _getLocalizedString(String key) {
    return _localizedStrings[key] ?? key;
  }

  Future<void> _loadAdsData() async {
    if (screenName == null || _isScreenForcedOffline || _isLocked) return;
    setState(() {
      isLoadingAds = true;
      _connectionStatus = 'جاري تحميل الإعلانات...';
    });

    try {
      adsSubscription?.cancel();
      adsSubscription = _firestore
          .collection('ads')
          .where('screen', isEqualTo: screenName)
          .where('isActive', isEqualTo: true)
          .orderBy('order', descending: false)
          .snapshots()
          .listen((snapshot) async {
        if (mounted) {
          await _processAdsSnapshot(snapshot);
        }
      });

      debugPrint('✅ Ads data loading initiated for screen: $screenName');
    } catch (e) {
      setState(() {
        isLoadingAds = false;
        _connectionStatus = 'خطأ في تحميل البيانات';
        _isOnline = false;
      });
      debugPrint('❌ Error loading ads data: $e');
      if (_autoRestartOnError) {
        Timer(const Duration(seconds: 5), () => _loadAdsData());
      }
    }
  }

  Future<void> _processAdsSnapshot(QuerySnapshot snapshot) async {
    try {
      final newAds = snapshot.docs;
      if (newAds.isEmpty) {
        setState(() {
          ads = [];
          adWidgets = [];
          videoControllers = [];
          isLoadingAds = false;
          _connectionStatus = 'لا توجد إعلانات';
        });
        return;
      }

      for (var controller in videoControllers) {
        controller?.dispose();
      }

      setState(() {
        ads = newAds;
        adWidgets = [];
        videoControllers = [];
        currentAdIndex = 0;
        isLoadingAds = true;
      });

      await _buildAdWidgets();

      setState(() {
        isLoadingAds = false;
        _connectionStatus = 'متصل - ${ads.length} إعلان';
        _isOnline = true;
      });

      _startAdRotation();
      debugPrint('✅ Processed ${ads.length} ads successfully');
    } catch (e) {
      setState(() {
        isLoadingAds = false;
        _connectionStatus = 'خطأ في معالجة الإعلانات';
      });
      debugPrint('❌ Error processing ads snapshot: $e');
    }
  }

  Future<void> _buildAdWidgets() async {
    final widgets = <Widget>[];
    final controllers = <VideoPlayerController?>[];

    for (int i = 0; i < ads.length; i++) {
      final ad = ads[i];
      final data = ad.data() as Map<String, dynamic>;
      final type = data['type'] as String;
      final url = data['url'] as String;
      final duration = data['duration'] as int? ?? 5;

      try {
        if (type == 'video') {
          final controller = VideoPlayerController.networkUrl(Uri.parse(url));
          await controller.initialize();
          if (_enableSound) {
            controller.setVolume(1.0);
          } else {
            controller.setVolume(0.0);
          }
          controllers.add(controller);
          widgets.add(_buildVideoWidget(controller, i));
        } else if (type == 'image') {
          controllers.add(null);
          widgets.add(_buildImageWidget(url, i));
        } else if (type == 'text') {
          controllers.add(null);
          widgets.add(_buildTextWidget(data, i));
        } else {
          controllers.add(null);
          widgets.add(_buildErrorWidget('نوع إعلان غير مدعوم: $type'));
        }
      } catch (e) {
        debugPrint('❌ Error building ad widget $i: $e');
        controllers.add(null);
        widgets.add(_buildErrorWidget('خطأ في تحميل الإعلان'));
      }
    }

    setState(() {
      adWidgets = widgets;
      videoControllers = controllers;
    });
  }

  Widget _buildVideoWidget(VideoPlayerController controller, int index) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  Widget _buildImageWidget(String url, int index) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: _enableKenBurnsEffect
          ? _buildKenBurnsImage(url)
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[900],
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
              errorWidget: (context, url, error) => _buildErrorWidget('فشل تحميل الصورة'),
            ),
    );
  }

  Widget _buildKenBurnsImage(String url) {
    return AnimatedBuilder(
      animation: _scaleController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_scaleAnimation.value * 0.1),
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[900],
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
            errorWidget: (context, url, error) => _buildErrorWidget('فشل تحميل الصورة'),
          ),
        );
      },
    );
  }

  Widget _buildTextWidget(Map<String, dynamic> data, int index) {
    final text = data['text'] as String? ?? 'نص فارغ';
    final fontSize = (data['fontSize'] as num?)?.toDouble() ?? 48.0;
    final color = Color(data['color'] as int? ?? Colors.white.value);
    final bgColor = Color(data['backgroundColor'] as int? ?? Colors.black.value);
    final alignment = data['alignment'] as String? ?? 'center';

    Alignment textAlignment;
    switch (alignment) {
      case 'left':
        textAlignment = Alignment.centerLeft;
        break;
      case 'right':
        textAlignment = Alignment.centerRight;
        break;
      default:
        textAlignment = Alignment.center;
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: bgColor,
      child: Align(
        alignment: textAlignment,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              color: color,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.5),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            textDirection: _locale.languageCode == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.red[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'وضع حفظ الشاشة',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _formatTimestamp(DateTime.now()),
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdDisplay() {
    if (adWidgets.isEmpty || currentAdIndex >= adWidgets.length) {
      return _buildLoadingScreen();
    }

    return GestureDetector(
      onTap: _resetScreenSaverTimer,
      onPanUpdate: _enableSwipeGestures
          ? (details) {
              _resetScreenSaverTimer();
              if (details.delta.dx > 10) {
                _moveToNextAd();
              } else if (details.delta.dx < -10) {
                _moveToPreviousAd();
              }
            }
          : null,
      child: Stack(
        children: [
          _buildAnimatedAdContent(),
          if (_showStatusBar || _showDebugInfo) _buildStatusOverlay(),
          if (_showProgressBar) _buildProgressOverlay(),
          if (_showAdCounter) _buildAdCounter(),
          if (_showWatermark) _buildWatermark(),
          if (_showTimestamp) _buildTimestamp(),
        ],
      ),
    );
  }

  Widget _buildAnimatedAdContent() {
    Widget content = adWidgets[currentAdIndex];
    if (!_enableAnimations) return content;

    switch (_transitionType) {
      case 'fade':
        return AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: content,
            );
          },
        );
      case 'slide':
        return AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return SlideTransition(
              position: _slideAnimation,
              child: content,
            );
          },
        );
      case 'scale':
        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: content,
            );
          },
        );
      case 'rotate':
        return AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationAnimation.value * 0.1,
              child: content,
            );
          },
        );
      default:
        return content;
    }
  }

  Widget _buildStatusOverlay() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isOnline ? Icons.wifi : Icons.wifi_off,
                  color: _isOnline ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _connectionStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (_remoteControlEnabled)
                  Icon(
                    Icons.settings_remote,
                    color: Colors.blue[300],
                    size: 20,
                  ),
              ],
            ),
            if (_showDebugInfo) ...[
              const SizedBox(height: 8),
              Text(
                'الشاشة: $screenName',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                'الإعلان: ${currentAdIndex + 1}/${ads.length}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                'النوع: $_currentAdType',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                'إجمالي وقت التشغيل: ${_formatDuration(_totalPlayTime)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                'الأداء: ${_performanceMetrics['memory_usage']?.toStringAsFixed(1)}% ذاكرة',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 6,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: LinearProgressIndicator(
          value: _currentProgress,
          backgroundColor: Colors.white.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
        ),
      ),
    );
  }

  Widget _buildAdCounter() {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _primaryColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${currentAdIndex + 1}/${ads.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildWatermark() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Opacity(
        opacity: 0.6,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'نظام العرض المحترف',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimestamp() {
    return Positioned(
      bottom: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          _formatTimestamp(DateTime.now()),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _moveToPreviousAd() {
    if (ads.isEmpty) return;
    if (currentAdIndex < videoControllers.length && videoControllers[currentAdIndex] != null) {
      videoControllers[currentAdIndex]!.pause();
    }

    setState(() {
      currentAdIndex = currentAdIndex > 0 ? currentAdIndex - 1 : ads.length - 1;
    });

    _displayCurrentAd();
  }

  String _formatTimestamp(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')} - '
        '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  void dispose() {
    _disposeResources();
    super.dispose();
  }

  void _disposeResources() {
    adTimer?.cancel();
    _statusTimer?.cancel();
    _heartbeatTimer?.cancel();
    _playTimeTimer?.cancel();
    _progressTimer?.cancel();
    _realtimeStatusTimer?.cancel();
    _remoteCommandTimer?.cancel();
    _performanceMonitorTimer?.cancel();
    _scheduleTimer?.cancel();
    _screenSaverTimer?.cancel();
    _emergencyFlashTimer?.cancel();

    adsSubscription?.cancel();
    screenControlSubscription?.cancel();

    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    _emergencyFlashController.dispose();

    for (var controller in videoControllers) {
      controller?.dispose();
    }

    debugPrint('🧹 Resources disposed successfully');
  }

  void _handleDoubleTap() {
    setState(() {
      _showDebugInfo = !_showDebugInfo;
    });
  }

  void _handleLongPress() {
    if (_isSecureModeActive) {
      _showSecurityDialog();
    } else {
      _showSettingsDialog();
    }
  }

  Future<void> _showSecurityDialog() async {
    String enteredPin = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _darkMode ? Colors.grey[900] : Colors.white,
        title: Text(
          'إدخال كلمة المرور',
          style: TextStyle(
            color: _darkMode ? Colors.white : Colors.black87,
          ),
        ),
        content: TextField(
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'كلمة المرور',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => enteredPin = value,
          style: TextStyle(color: _darkMode ? Colors.white : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (enteredPin == _securityPin) {
                Navigator.pop(context);
                _showSettingsDialog();
              } else {
                _failedAuthAttempts++;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('كلمة مرور خاطئة'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSettingsDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _darkMode ? Colors.grey[900] : Colors.white,
        title: Text(
          'إعدادات الشاشة',
          style: TextStyle(
            color: _darkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text(
                  'شريط الحالة',
                  style: TextStyle(color: _darkMode ? Colors.white : Colors.black87),
                ),
                value: _showStatusBar,
                onChanged: (value) {
                  setState(() {
                    _showStatusBar = value;
                  });
                  Navigator.pop(context);
                },
              ),
              SwitchListTile(
                title: Text(
                  'شريط التقدم',
                  style: TextStyle(color: _darkMode ? Colors.white : Colors.black87),
                ),
                value: _showProgressBar,
                onChanged: (value) {
                  setState(() {
                    _showProgressBar = value;
                  });
                  Navigator.pop(context);
                },
              ),
              SwitchListTile(
                title: Text(
                  'الصوت',
                  style: TextStyle(color: _darkMode ? Colors.white : Colors.black87),
                ),
                value: _enableSound,
                onChanged: (value) {
                  _toggleSound();
                  Navigator.pop(context);
                },
              ),
              SwitchListTile(
                title: Text(
                  'المؤثرات البصرية',
                  style: TextStyle(color: _darkMode ? Colors.white : Colors.black87),
                ),
                value: _enableAnimations,
                onChanged: (value) {
                  setState(() {
                    _enableAnimations = value;
                  });
                  _saveSettings();
                  Navigator.pop(context);
                },
              ),
              SwitchListTile(
                title: Text(
                  'الوضع المظلم',
                  style: TextStyle(color: _darkMode ? Colors.white : Colors.black87),
                ),
                value: _darkMode,
                onChanged: (value) {
                  _changeTheme(value);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _restartApp();
            },
            child: const Text('إعادة تشغيل'),
          ),
        ],
      ),
    );
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_enableSwipeGestures) return;
    _resetScreenSaverTimer();
    if (details.delta.dx.abs() > details.delta.dy.abs()) {
      if (details.delta.dx > 5) {
        _moveToNextAd();
      } else if (details.delta.dx < -5) {
        _moveToPreviousAd();
      }
    } else if (details.delta.dy.abs() > 5) {
      final newBrightness = _displayBrightness + (details.delta.dy > 0 ? -0.05 : 0.05);
      _setBrightness(newBrightness);
    }
  }

  void _handleError(String error, {String? context}) {
    _performanceMetrics['error_count'] = (_performanceMetrics['error_count'] ?? 0) + 1;
    debugPrint('❌ Error ${context != null ? 'in $context' : ''}: $error');
    _sendErrorReport(error, context);
    if (_autoRestartOnError && _currentRetries < _maxRetries) {
      Timer(const Duration(seconds: 3), () {
        _attemptRecovery();
      });
    }
  }

  Future<void> _sendErrorReport(String error, String? context) async {
    if (screenName == null) return;
    try {
      await _firestore.collection('error_logs').add({
        'screen_name': screenName,
        'screen_id': screenId,
        'error': error,
        'context': context,
        'timestamp': FieldValue.serverTimestamp(),
        'app_version': '2.1.0',
        'performance_metrics': _performanceMetrics,
        'device_info': await _getDeviceInfo(),
      });
    } catch (e) {
      debugPrint('Failed to send error report: $e');
    }
  }

  Future<void> _attemptRecovery() async {
    try {
      debugPrint('🔄 Attempting recovery...');
      setState(() {
        _connectionStatus = 'محاولة الاسترداد...';
      });
      await DefaultCacheManager().emptyCache();
      await _loadAdsData();
      _currentRetries = 0;
      setState(() {
        _connectionStatus = 'تم الاسترداد بنجاح';
      });
      debugPrint('✅ Recovery successful');
    } catch (e) {
      _currentRetries++;
      _handleError('Recovery failed: $e', context: 'recovery');
    }
  }

  Future<void> _sendDailyReport() async {
    if (screenName == null) return;
    try {
      final report = {
        'screen_name': screenName,
        'screen_id': screenId,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'total_ads_shown': _totalAdsShown,
        'total_play_time_seconds': _totalPlayTime.inSeconds,
        'session_duration_seconds': DateTime.now().difference(_sessionStartTime).inSeconds,
        'ad_play_counts': _adPlayCount,
        'detailed_stats': _detailedStats,
        'performance_metrics': _performanceMetrics,
        'errors_count': _performanceMetrics['error_count'] ?? 0,
        'remote_commands_executed': _remoteCommandHistory.length,
        'connection_uptime': _isOnline ? 1.0 : 0.0,
        'emergency_activations': _emergencyModeActive ? 1 : 0,
      };
      await _firestore.collection('daily_reports').add({
        ...report,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('📊 Daily report sent successfully');
    } catch (e) {
      debugPrint('❌ Failed to send daily report: $e');
    }
  }

  void _startAdRotation() {
    adTimer?.cancel();
    if (ads.isEmpty || _isScreenForcedOffline || _isLocked) return;
    _displayCurrentAd();
    adTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted || _isScreenForcedOffline || _isLocked) {
        timer.cancel();
        return;
      }
      bool shouldMoveToNext = false;
      if (currentAdIndex < videoControllers.length && videoControllers[currentAdIndex] != null) {
        final controller = videoControllers[currentAdIndex]!;
        if (controller.value.isInitialized && !controller.value.isPlaying) {
          shouldMoveToNext = true;
        }
      } else {
        final elapsed = DateTime.now().difference(_lastAdChangeTime);
        final adData = ads[currentAdIndex].data() as Map<String, dynamic>;
        final duration = Duration(seconds: adData['duration'] as int? ?? 5);
        if (elapsed >= duration) {
          shouldMoveToNext = true;
        }
      }
      if (shouldMoveToNext) {
        _moveToNextAd();
      }
    });
  }

  void _displayCurrentAd() {
    if (ads.isEmpty || _isScreenForcedOffline || _isLocked) return;
    final ad = ads[currentAdIndex];
    final data = ad.data() as Map<String, dynamic>;
    setState(() {
      _currentAdType = data['type'] as String;
      _lastAdChangeTime = DateTime.now();
    });
    _totalAdsShown++;
    final adId = ad.id;
    _adPlayCount[adId] = (_adPlayCount[adId] ?? 0) + 1;
    _detailedStats[adId] ??= {
      'play_time': Duration.zero,
      'play_count': 0,
      'last_played': DateTime.now(),
    };
    _detailedStats[adId]!['play_count'] = _detailedStats[adId]!['play_count'] + 1;
    _detailedStats[adId]!['last_played'] = DateTime.now();

    if (currentAdIndex < videoControllers.length && videoControllers[currentAdIndex] != null) {
      final controller = videoControllers[currentAdIndex]!;
      controller.seekTo(Duration.zero);
      controller.play();
      setState(() {
        _currentAdDuration = controller.value.duration;
      });
    } else {
      final duration = data['duration'] as int? ?? 5;
      setState(() {
        _currentAdDuration = Duration(seconds: duration);
      });
    }

    if (_enableAnimations) {
      _triggerTransition();
    }
    _resetScreenSaverTimer();
    debugPrint('📺 Displaying ad ${currentAdIndex + 1}/${ads.length}: ${data['type']}');
  }

  void _triggerTransition() {
    switch (_transitionType) {
      case 'fade':
        _fadeController.reset();
        _fadeController.forward();
        break;
      case 'slide':
        _slideController.reset();
        _slideController.forward();
        break;
      case 'scale':
        _scaleController.reset();
        _scaleController.forward();
        break;
      case 'rotate':
        _rotationController.reset();
        _rotationController.forward();
        break;
    }
  }

  void _moveToNextAd() {
    if (ads.isEmpty) return;
    if (currentAdIndex < videoControllers.length && videoControllers[currentAdIndex] != null) {
      videoControllers[currentAdIndex]!.pause();
    }
    setState(() {
      currentAdIndex = (currentAdIndex + 1) % ads.length;
    });
    _displayCurrentAd();
  }

  void _skipCurrentAd() {
    if (!_isScreenForcedOffline && !_isLocked) {
      _moveToNextAd();
    }
  }

  void _pauseResumeAd() {
    if (_isScreenForcedOffline || _isLocked || currentAdIndex >= videoControllers.length) return;
    final controller = videoControllers[currentAdIndex];
    if (controller != null && controller.value.isInitialized) {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    }
  }

  void _toggleSound() {
    setState(() {
      _enableSound = !_enableSound;
    });
    for (var controller in videoControllers) {
      if (controller != null) {
        controller.setVolume(_enableSound ? 1.0 : 0.0);
      }
    }
    _saveSettings();
  }

  void _restartApp() {
    _disposeResources();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MyHomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkMode ? Colors.black : Colors.white,
      body: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    if (_emergencyModeActive) {
      return _buildEmergencyScreen();
    }
    if (_isLocked) {
      return _buildLockScreen();
    }
    if (_isScreenForcedOffline) {
      return _buildOfflineScreen();
    }
    if (isLoadingAds) {
      return _buildLoadingScreen();
    }
    if (ads.isEmpty) {
      return _buildNoAdsScreen();
    }
    if (_isScreenSaverActive) {
      return _buildScreenSaver();
    }
    return _buildAdDisplay();
  }

  Widget _buildEmergencyScreen() {
    return AnimatedBuilder(
      animation: _emergencyFlashAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: _emergencyFlashing
              ? _emergencyBgColor.withOpacity(0.5 + _emergencyFlashAnimation.value * 0.5)
              : _emergencyBgColor,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.emergency,
                  color: Colors.white,
                  size: 120,
                ),
                const SizedBox(height: 32),
                Text(
                  'رسالة طوارئ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _emergencyMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLockScreen() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey[900]!, Colors.black],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              color: Colors.white,
              size: 120,
            ),
            const SizedBox(height: 32),
            const Text(
              'الشاشة مقفلة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'يرجى إدخال كلمة المرور من لوحة التحكم',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 24,
              ),
              textAlign: TextAlign.center,
            ),
            if (_failedAuthAttempts > 0) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red, width: 1),
                ),
                child: Text(
                  'محاولات فاشلة: $_failedAuthAttempts',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineScreen() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue[900]!, Colors.black],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.power_off,
              color: Colors.white,
              size: 120,
            ),
            const SizedBox(height: 32),
            Text(
              _remoteStatus == 'maintenance' ? 'وضع الصيانة' : 'الشاشة متوقفة',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_remoteMessage.isNotEmpty) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _remoteMessage,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 48),
            if (_showTimestamp)
              Text(
                _formatTimestamp(DateTime.now()),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_primaryColor, Colors.black],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 4,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'جاري تحميل الإعلانات...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _connectionStatus,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAdsScreen() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.orange[800]!, Colors.black],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.tv_off,
              color: Colors.white,
              size: 120,
            ),
            const SizedBox(height: 32),
            const Text(
              'لا توجد إعلانات للعرض',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'الشاشة: ${screenName ?? 'غير محدد'}',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: _loadAdsData,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenSaver() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.tv,
              color: Colors.grey[800],
              size: 100,
            ),
            const SizedBox(height: 24),
            Text(
              'شاشة التوقف',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'الشاشة ستعود للعمل تلقائيًا عند التفاعل',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isScreenSaverActive = false;
                });
                _resetScreenSaverTimer();
              },
              child: const Text('إغلاق شاشة التوقف'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Localization helper class
class LocalizedStrings {
  static Map<String, String> getStrings(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return {
          'enter_screen_name': 'أدخل اسم الشاشة',
          'screen_name_hint': 'مثال: شاشة الاستقبال',
          'use_default': 'استخدم الافتراضي',
          'loading': 'جاري التحميل...',
          'no_ads': 'لا توجد إعلانات',
          'connection_error': 'خطأ في الاتصال',
          'retry': 'إعادة المحاولة',
          'settings': 'الإعدادات',
          'sound': 'الصوت',
          'animations': 'المؤثرات البصرية',
          'status_bar': 'شريط الحالة',
          'progress_bar': 'شريط التقدم',
          'dark_mode': 'الوضع المظلم',
          'restart': 'إعادة تشغيل',
          'close': 'إغلاق',
        };
      case 'en':
      default:
        return {
          'enter_screen_name': 'Enter Screen Name',
          'screen_name_hint': 'Example: Reception Screen',
          'use_default': 'Use Default',
          'loading': 'Loading...',
          'no_ads': 'No Ads Available',
          'connection_error': 'Connection Error',
          'retry': 'Retry',
          'settings': 'Settings',
          'sound': 'Sound',
          'animations': 'Animations',
          'status_bar': 'Status Bar',
          'progress_bar': 'Progress Bar',
          'dark_mode': 'Dark Mode',
          'restart': 'Restart',
          'close': 'Close',
        };
    }
  }
}