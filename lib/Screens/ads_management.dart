import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdsManagementScreen extends StatefulWidget {
  const AdsManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdsManagementScreen> createState() => _AdsManagementScreenState();
}

class _AdsManagementScreenState extends State<AdsManagementScreen> {
  final CollectionReference _adsRef = FirebaseFirestore.instance.collection('ads');
  bool _isLoading = true;
  List<DocumentSnapshot> _ads = [];

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  Future<void> _loadAds() async {
    try {
      final snapshot = await _adsRef.get();
      setState(() {
        _ads = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل الإعلانات: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddAdDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddAdDialog(),
    ).then((_) => _loadAds());
  }

  void _editAd(DocumentSnapshot ad) {
    showDialog(
      context: context,
      builder: (context) => EditAdDialog(ad: ad),
    ).then((_) => _loadAds());
  }

  Future<void> _deleteAd(String adId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا الإعلان؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adsRef.doc(adId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الإعلان بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAds();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الحذف: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الإعلانات'),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            onPressed: _showAddAdDialog,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ads.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'لا توجد إعلانات بعد',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _ads.length,
                  itemBuilder: (context, index) {
                    final ad = _ads[index];
                    final data = ad.data() as Map<String, dynamic>;
                    final adType = data['adType'] as String? ?? 'text';
                    final isActive = data['isActive'] as bool? ?? true;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isActive ? Colors.green : Colors.grey,
                          child: Icon(
                            adType == 'text'
                                ? Icons.text_format
                                : adType == 'image'
                                    ? Icons.image
                                    : Icons.videocam,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          adType == 'text'
                              ? (data['adText'] as String? ?? 'نص إعلان')
                              : 'إعلان $adType',
                          style: isActive
                              ? null
                              : const TextStyle(color: Colors.grey),
                        ),
                        subtitle: Text(
                          'نوع: ${adType.toUpperCase()} • ${isActive ? 'نشط' : 'معطل'}',
                          style: TextStyle(
                            color: isActive ? null : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              onPressed: () => _editAd(ad),
                              icon: const Icon(Icons.edit, color: Colors.blue),
                            ),
                            IconButton(
                              onPressed: () => _deleteAd(ad.id),
                              icon: const Icon(Icons.delete, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class AddAdDialog extends StatefulWidget {
  const AddAdDialog({Key? key}) : super(key: key);

  @override
  State<AddAdDialog> createState() => _AddAdDialogState();
}

class _AddAdDialogState extends State<AddAdDialog> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _urlController = TextEditingController();
  String _selectedAdType = 'text';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة إعلان جديد'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedAdType,
              decoration: const InputDecoration(labelText: 'نوع الإعلان'),
              items: const [
                DropdownMenuItem(value: 'text', child: Text('نص')),
                DropdownMenuItem(value: 'image', child: Text('صورة')),
                DropdownMenuItem(value: 'video', child: Text('فيديو')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedAdType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_selectedAdType == 'text')
              TextFormField(
                controller: _textController,
                decoration: const InputDecoration(labelText: 'نص الإعلان'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'أدخل نص الإعلان';
                  return null;
                },
              ),
            if (_selectedAdType != 'text')
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'رابط ${_selectedAdType == 'image' ? 'الصورة' : 'الفيديو'}',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'أدخل الرابط';
                  if (!value.startsWith('http'))
                    return 'يجب أن يبدأ الرابط بـ http أو https';
                  return null;
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveAd,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('حفظ'),
        ),
      ],
    );
  }

  Future<void> _saveAd() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final adData = {
        'adType': _selectedAdType,
        'adText': _selectedAdType == 'text' ? _textController.text : '',
        'adImageUrl':
            _selectedAdType != 'text' ? _urlController.text : '',
        'screenIds': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      await FirebaseFirestore.instance.collection('ads').add(adData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت إضافة الإعلان بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الحفظ: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

class EditAdDialog extends StatefulWidget {
  final DocumentSnapshot ad;

  const EditAdDialog({Key? key, required this.ad}) : super(key: key);

  @override
  State<EditAdDialog> createState() => _EditAdDialogState();
}

class _EditAdDialogState extends State<EditAdDialog> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _urlController = TextEditingController();
  late String _selectedAdType;
  bool _isLoading = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final data = widget.ad.data() as Map<String, dynamic>;
    _selectedAdType = data['adType'] as String;
    _textController.text = data['adText'] as String? ?? '';
    _urlController.text = data['adImageUrl'] as String? ?? '';
    _isActive = data['isActive'] as bool? ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تعديل الإعلان'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedAdType,
              decoration: const InputDecoration(labelText: 'نوع الإعلان'),
              items: const [
                DropdownMenuItem(value: 'text', child: Text('نص')),
                DropdownMenuItem(value: 'image', child: Text('صورة')),
                DropdownMenuItem(value: 'video', child: Text('فيديو')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedAdType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('نشط'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_selectedAdType == 'text')
              TextFormField(
                controller: _textController,
                decoration: const InputDecoration(labelText: 'نص الإعلان'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'أدخل نص الإعلان';
                  return null;
                },
              ),
            if (_selectedAdType != 'text')
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'رابط ${_selectedAdType == 'image' ? 'الصورة' : 'الفيديو'}',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'أدخل الرابط';
                  if (!value.startsWith('http'))
                    return 'يجب أن يبدأ الرابط بـ http أو https';
                  return null;
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateAd,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('تحديث'),
        ),
      ],
    );
  }

  Future<void> _updateAd() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final adData = {
        'adType': _selectedAdType,
        'adText': _selectedAdType == 'text' ? _textController.text : '',
        'adImageUrl':
            _selectedAdType != 'text' ? _urlController.text : '',
        'isActive': _isActive,
      };

      await FirebaseFirestore.instance
          .collection('ads')
          .doc(widget.ad.id)
          .update(adData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث الإعلان بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في التحديث: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}