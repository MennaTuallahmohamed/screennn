import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseReference _realtimeRef = FirebaseDatabase.instance.ref();

  // Data variables
  List<Map<String, dynamic>> screens = [];
  List<Map<String, dynamic>> ads = [];
  Map<String, Map<String, dynamic>> screenStatuses = {};
  bool isLoading = true;
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // UI state
  int selectedTabIndex = 0;
  String searchQuery = '';
  bool isDarkMode = false;

  // Stream subscriptions
  StreamSubscription<DatabaseEvent>? _screensSubscription;
  StreamSubscription<QuerySnapshot>? _adsSubscription;
  StreamSubscription<QuerySnapshot>? _screensFirestoreSubscription;

  // Colors
  final Color primaryColor = const Color(0xFF2196F3);
  final Color accentColor = const Color(0xFFFF9800);
  final Color successColor = const Color(0xFF4CAF50);
  final Color errorColor = const Color(0xFFF44336);
  final Color warningColor = const Color(0xFFFF9800);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    // Load screens from Realtime Database
    _loadScreenStatuses();
    
    // Load screens from Firestore
    _loadScreensFromFirestore();
    
    // Load ads from Firestore
    _loadAdsFromFirestore();
  }

  void _loadScreenStatuses() {
    _screensSubscription = _realtimeRef.child('screens').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          screenStatuses = data.map((key, value) => MapEntry(
            key.toString(),
            Map<String, dynamic>.from(value as Map),
          ));
        });
      } else {
        setState(() {
          screenStatuses = {};
        });
      }
    });
  }

  void _loadScreensFromFirestore() {
    _screensFirestoreSubscription = _firestore
        .collection('screens')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        screens = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        
        _checkIfLoadingComplete();
      });
    });
  }

  void _loadAdsFromFirestore() {
    _adsSubscription = _firestore
        .collection('ads')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        ads = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        
        _checkIfLoadingComplete();
      });
    });
  }

  void _checkIfLoadingComplete() {
    // Check if both screens and ads data have been loaded
    if (screens.isNotEmpty || ads.isNotEmpty) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _screensSubscription?.cancel();
    _adsSubscription?.cancel();
    _screensFirestoreSubscription?.cancel();
    super.dispose();
  }

  // UI Helper methods
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'online':
        return successColor;
      case 'offline':
        return errorColor;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'online':
        return 'متصل';
      case 'offline':
        return 'غير متصل';
      default:
        return 'غير معروف';
    }
  }

  String _formatTimestamp(int? timestamp) {
    if (timestamp == null) return 'غير محدد';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }

  // Enhanced Tab Bar with better animations
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTab('الشاشات', 0, Icons.tv, screens.length),
          _buildTab('الإعلانات', 1, Icons.campaign, ads.length),
          _buildTab('الإحصائيات', 2, Icons.analytics, null),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index, IconData icon, int? count) {
    final isSelected = selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTabIndex = index;
          });
          HapticFeedback.lightImpact();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            boxShadow: isSelected ? [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ] : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
              if (count != null) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        onChanged: (value) {
          setState(() {
            searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: selectedTabIndex == 0 ? 'البحث عن شاشة...' : 'البحث عن إعلان...',
          prefixIcon: Icon(Icons.search, color: primaryColor),
          suffixIcon: searchQuery.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: isDarkMode ? Colors.grey[850] : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildScreensTab() {
    final filteredScreens = screens.where((screen) {
      final name = (screen['name'] ?? '').toString().toLowerCase();
      final screenId = (screen['screen_id'] ?? '').toString().toLowerCase();
      return name.contains(searchQuery) || screenId.contains(searchQuery);
    }).toList();

    if (filteredScreens.isEmpty && !isLoading) {
      return _buildEmptyState(
        'لا توجد شاشات',
        'لم يتم العثور على أي شاشة مسجلة',
        Icons.tv_off,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredScreens.length,
        itemBuilder: (context, index) {
          final screen = filteredScreens[index];
          final screenId = screen['screen_id'] ?? screen['id'];
          final realtimeData = screenStatuses[screenId];
          
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildScreenCard(screen, realtimeData, index),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScreenCard(
    Map<String, dynamic> screen, 
    Map<String, dynamic>? realtimeData,
    int index,
  ) {
    final status = realtimeData?['status'];
    final lastSeen = realtimeData?['lastSeen'];
    final screenName = screen['name'] ?? 'بدون اسم';
    final screenId = screen['screen_id'] ?? screen['id'];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: isDarkMode ? Colors.grey[850] : Colors.white,
      child: InkWell(
        onTap: () => _showScreenDetails(screen, realtimeData),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Hero(
                    tag: 'screen_icon_$index',
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _getStatusColor(status).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        status == 'online' ? Icons.tv : Icons.tv_off,
                        color: _getStatusColor(status),
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          screenName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${screenId.toString().substring(0, 12)}...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: _getStatusColor(status).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                status == 'online' ? Icons.circle : Icons.circle_outlined,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getStatusText(status),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isDarkMode ? Colors.grey[800] : Colors.grey[50]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      'آخر نشاط',
                      _formatTimestamp(lastSeen),
                      Icons.access_time,
                      primaryColor,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'إجمالي الإعلانات',
                      '${realtimeData?['totalAdsShown'] ?? screen['total_ads_shown'] ?? 0}',
                      Icons.play_circle,
                      successColor,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'وقت التشغيل',
                      _formatDuration(realtimeData?['totalPlayTimeSeconds'] ?? screen['total_play_time_seconds'] ?? 0),
                      Icons.timer,
                      warningColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildAdsTab() {
    final filteredAds = ads.where((ad) {
      final text = (ad['adText'] ?? '').toString().toLowerCase();
      final type = (ad['adType'] ?? '').toString().toLowerCase();
      return text.contains(searchQuery) || type.contains(searchQuery);
    }).toList();

    if (filteredAds.isEmpty && !isLoading) {
      return _buildEmptyState(
        'لا توجد إعلانات',
        'لم يتم العثور على أي إعلان',
        Icons.campaign_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredAds.length,
        itemBuilder: (context, index) {
          final ad = filteredAds[index];
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildAdCard(ad, index),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdCard(Map<String, dynamic> ad, int index) {
    final adType = ad['adType'] ?? 'text';
    final screenIds = ad['screenIds'] as List<dynamic>? ?? [];
    
    IconData typeIcon;
    Color typeColor;
    String typeText;
    
    switch (adType) {
      case 'video':
        typeIcon = Icons.play_circle_filled;
        typeColor = successColor;
        typeText = 'فيديو';
        break;
      case 'image':
        typeIcon = Icons.image;
        typeColor = warningColor;
        typeText = 'صورة';
        break;
      default:
        typeIcon = Icons.text_fields;
        typeColor = primaryColor;
        typeText = 'نص';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: isDarkMode ? Colors.grey[850] : Colors.white,
      child: InkWell(
        onTap: () => _showAdDetails(ad),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Hero(
                    tag: 'ad_icon_$index',
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: typeColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        typeIcon,
                        color: typeColor,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            typeText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${screenIds.length} شاشة مخصصة',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (adType == 'text') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (isDarkMode ? Colors.grey[800] : Colors.grey[50]),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: typeColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    ad['adText'] ?? '',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ] else if (adType == 'image' && ad['adImageUrl'] != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: ad['adImageUrl'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.error, size: 50),
                      ),
                    ),
                  ),
                ),
              ] else if (adType == 'video') ...[
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_circle_filled,
                          color: Colors.white,
                          size: 60,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'ملف فيديو',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsTab() {
    final totalScreens = screens.length;
    final onlineScreens = screenStatuses.values
        .where((status) => status['status'] == 'online')
        .length;
    final totalAds = ads.length;
    final offlineScreens = totalScreens - onlineScreens;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'نظرة عامة',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatCard(
                  'إجمالي الشاشات',
                  totalScreens.toString(),
                  Icons.tv,
                  primaryColor,
                ),
                _buildStatCard(
                  'الشاشات المتصلة',
                  onlineScreens.toString(),
                  Icons.wifi,
                  successColor,
                ),
                _buildStatCard(
                  'إجمالي الإعلانات',
                  totalAds.toString(),
                  Icons.campaign,
                  warningColor,
                ),
                _buildStatCard(
                  'الشاشات غير المتصلة',
                  offlineScreens.toString(),
                  Icons.wifi_off,
                  errorColor,
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              'حالة الشاشات',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatusChart(onlineScreens, offlineScreens),
            const SizedBox(height: 30),
            Text(
              'أنواع الإعلانات',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            _buildAdTypesChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: isDarkMode ? Colors.grey[850] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChart(int online, int offline) {
    final total = online + offline;
    if (total == 0) return Container();
    
    final onlinePercentage = (online / total);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: isDarkMode ? Colors.grey[850] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: (onlinePercentage * 100).round(),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: successColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: ((1 - onlinePercentage) * 100).round(),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: errorColor,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem('متصل', successColor, online),
                _buildLegendItem('غير متصل', errorColor, offline),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdTypesChart() {
    final textAds = ads.where((ad) => ad['adType'] == 'text').length;
    final imageAds = ads.where((ad) => ad['adType'] == 'image').length;
    final videoAds = ads.where((ad) => ad['adType'] == 'video').length;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: isDarkMode ? Colors.grey[850] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem('نص', primaryColor, textAds),
            _buildLegendItem('صورة', warningColor, imageAds),
            _buildLegendItem('فيديو', successColor, videoAds),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showScreenDetails(Map<String, dynamic> screen, Map<String, dynamic>? realtimeData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildScreenDetailsModal(screen, realtimeData),
    );
  }

  void _showAdDetails(Map<String, dynamic> ad) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAdDetailsModal(ad),
    );
  }

  Widget _buildScreenDetailsModal(Map<String, dynamic> screen, Map<String, dynamic>? realtimeData) {
    final status = realtimeData?['status'];
    final screenName = screen['name'] ?? 'بدون اسم';
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      status == 'online' ? Icons.tv : Icons.tv_off,
                      color: _getStatusColor(status),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          screenName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            _getStatusText(status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildDetailItem('معرف الشاشة', screen['screen_id'] ?? screen['id']),
                  _buildDetailItem('آخر نشاط', _formatTimestamp(realtimeData?['lastSeen'])),
                  _buildDetailItem('إجمالي الإعلانات المعروضة', '${realtimeData?['totalAdsShown'] ?? screen['total_ads_shown'] ?? 0}'),
                  _buildDetailItem('وقت التشغيل الإجمالي', _formatDuration(realtimeData?['totalPlayTimeSeconds'] ?? screen['total_play_time_seconds'] ?? 0)),
                  _buildDetailItem('حالة الاتصال', realtimeData?['connectionStatus'] ?? 'غير محدد'),
                  _buildDetailItem('تاريخ الإنشاء', screen['created_at'] != null ? 'محدد' : 'غير محدد'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdDetailsModal(Map<String, dynamic> ad) {
    final adType = ad['adType'] ?? 'text';
    final screenIds = ad['screenIds'] as List<dynamic>? ?? [];
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      adType == 'video' ? Icons.play_circle_filled :
                      adType == 'image' ? Icons.image : Icons.text_fields,
                      color: primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تفاصيل الإعلان',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            adType == 'video' ? 'فيديو' :
                            adType == 'image' ? 'صورة' : 'نص',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildDetailItem('نوع الإعلان', adType == 'video' ? 'فيديو' : adType == 'image' ? 'صورة' : 'نص'),
                  _buildDetailItem('عدد الشاشات المخصصة', screenIds.length.toString()),
                  if (adType == 'text')
                    _buildDetailItem('النص', ad['adText'] ?? ''),
                  if (ad['adImageUrl'] != null)
                    _buildDetailItem('رابط الوسائط', ad['adImageUrl']),
                  _buildDetailItem('معرف الإعلان', ad['id']),
                  if (screenIds.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'الشاشات المخصصة:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...screenIds.map((screenId) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (isDarkMode ? Colors.grey[800] : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          screenId.toString(),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )).toList(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: (isDarkMode ? Colors.grey[800] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return '0 ثانية';
    
    final duration = Duration(seconds: seconds);
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    List<String> parts = [];
    if (days > 0) parts.add('${days}ي');
    if (hours > 0) parts.add('${hours}س');
    if (minutes > 0) parts.add('${minutes}د');
    if (secs > 0 || parts.isEmpty) parts.add('${secs}ث');

    return parts.take(2).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'لوحة التحكم الإدارية',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                isDarkMode = !isDarkMode;
              });
              HapticFeedback.lightImpact();
            },
            tooltip: isDarkMode ? 'الوضع النهاري' : 'الوضع الليلي',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadData();
              HapticFeedback.mediumImpact();
            },
            tooltip: 'تحديث البيانات',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _exportData();
                  break;
                case 'settings':
                  _showSettings();
                  break;
                case 'about':
                  _showAbout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download),
                    SizedBox(width: 8),
                    Text('تصدير البيانات'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('الإعدادات'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info),
                    SizedBox(width: 8),
                    Text('حول'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'جاري تحميل البيانات...',
                    style: TextStyle(
                      fontSize: 18,
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'يرجى الانتظار',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                _buildTabBar(),
                if (selectedTabIndex < 2) _buildSearchBar(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: selectedTabIndex == 0
                        ? _buildScreensTab()
                        : selectedTabIndex == 1
                            ? _buildAdsTab()
                            : _buildStatsTab(),
                  ),
                ),
              ],
            ),
      floatingActionButton: selectedTabIndex < 2 
          ? FloatingActionButton.extended(
              onPressed: () {
                if (selectedTabIndex == 0) {
                  _addNewScreen();
                } else {
                  _addNewAd();
                }
              },
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text(selectedTabIndex == 0 ? 'إضافة شاشة' : 'إضافة إعلان'),
            )
          : null,
    );
  }

  void _addNewScreen() {
    // Implementation for adding new screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('ميزة إضافة شاشة جديدة قيد التطوير'),
        backgroundColor: warningColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _addNewAd() {
    // Implementation for adding new ad
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('ميزة إضافة إعلان جديد قيد التطوير'),
        backgroundColor: warningColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _exportData() {
    final data = {
      'screens': screens,
      'ads': ads,
      'screen_statuses': screenStatuses,
      'export_time': DateTime.now().toIso8601String(),
    };
    
    debugPrint('Exported Data: $data');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم تصدير البيانات بنجاح'),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'عرض',
          textColor: Colors.white,
          onPressed: () {
            // Show export dialog or save file
          },
        ),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSettingsModal(),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'لوحة التحكم الإدارية',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.dashboard,
          color: Colors.white,
          size: 30,
        ),
      ),
      children: [
        const Text('نظام إدارة الإعلانات والشاشات الرقمية'),
        const SizedBox(height: 16),
        const Text('تم تطويره باستخدام Flutter و Firebase'),
      ],
    );
  }

  Widget _buildSettingsModal() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'الإعدادات',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: primaryColor,
            ),
            title: const Text('الوضع الداكن'),
            trailing: Switch(
              value: isDarkMode,
              onChanged: (value) {
                setState(() {
                  isDarkMode = value;
                });
              },
              activeColor: primaryColor,
            ),
          ),
          ListTile(
            leading: Icon(Icons.notifications, color: primaryColor),
            title: const Text('الإشعارات'),
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // Implementation for notifications toggle
              },
              activeColor: primaryColor,
            ),
          ),
          ListTile(
            leading: Icon(Icons.refresh, color: primaryColor),
            title: const Text('التحديث التلقائي'),
            subtitle: const Text('تحديث البيانات كل 30 ثانية'),
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // Implementation for auto refresh toggle
              },
              activeColor: primaryColor,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}