import 'dart:typed_data';
import 'package:berwehsan/widgets/app_drawer.dart';
import 'package:berwehsan/core/user_session.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart' as intl;
import 'package:url_launcher/url_launcher.dart';
import 'package:dropdown_search/dropdown_search.dart';

class AdminFilesPage extends StatefulWidget {
  final String? parentFolderId;
  final String folderName;

  const AdminFilesPage({
    super.key,
    this.parentFolderId,
    this.folderName = 'الملفات الادارية',
  });

  @override
  State<AdminFilesPage> createState() => _AdminFilesPageState();
}

class _AdminFilesPageState extends State<AdminFilesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isItemVisible(Map<String, dynamic> data) {
    int? currentRole = UserSession().role;
    String? currentName = UserSession().fullName;

    if (currentRole != 3 && currentRole != 2) {
      String privacyType = data['privacy_type'] ?? 'public';
      if (privacyType == 'roles') {
        List<dynamic> allowedRoles = data['allowed_roles'] ?? [];
        if (currentRole == null || !allowedRoles.contains(currentRole)) return false;
      } else if (privacyType == 'users') {
        List<dynamic> allowedUsers = data['allowed_users'] ?? [];
        if (currentName == null || !allowedUsers.contains(currentName)) return false;
      } else {
        if (data.containsKey('allowed_roles')) {
          List<dynamic> allowedRoles = data['allowed_roles'] ?? [];
          if (allowedRoles.isNotEmpty && (currentRole == null || !allowedRoles.contains(currentRole))) return false;
        }
      }
    }
    return true;
  }

  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    final snapshot = await _firestore.collection('admins').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'FullName': data['FullName'] ?? '',
        'Role': data['Role'] ?? 1,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
          title: _isSearching
              ? Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'ابحث عن ملف أو مجلد...',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                )
              : Text(widget.folderName, style: const TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
              onPressed: () {
                setState(() {
                  if (_isSearching) {
                    _isSearching = false;
                    _searchQuery = '';
                    _searchController.clear();
                  } else {
                    _isSearching = true;
                  }
                });
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        drawer: widget.parentFolderId == null ? const AppDrawer() : null,
        floatingActionButton: !_isSearching && (UserSession().canEditOrDelete || UserSession().isAccounting || UserSession().isSecretary)
            ? FloatingActionButton(
                backgroundColor: Colors.green,
                child: const Icon(Icons.add, color: Colors.white),
                onPressed: () => _showAddOptions(context),
              )
            : null,
        body: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('admin_files')
              .orderBy('created_at', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState('لا توجد ملفات أو مجلدات هنا');
            }

            final allDocs = snapshot.data!.docs;
            final docs = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;

              if (!_isItemVisible(data)) return false;

              final name = (data['name'] ?? '').toString().toLowerCase();

              if (_isSearching && _searchQuery.isNotEmpty) {
                if (!name.contains(_searchQuery)) return false;
                return true;
              }

              final parentId = data['parent_id'];
              if (widget.parentFolderId == null) {
                return parentId == null || parentId == '';
              }
              return parentId == widget.parentFolderId;
            }).toList();

            if (docs.isEmpty) {
              return _buildEmptyState(_isSearching ? 'لا توجد نتائج بحث مطابقة' : 'هذا المجلد فارغ');
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth > 800 ? 5 : (constraints.maxWidth > 500 ? 3 : 2);
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;
                    return _buildItemCard(context, docId, data);
                  },
                );
              }
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.green[200]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(fontSize: 16, color: Colors.grey[500], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.create_new_folder, color: Colors.white)),
                title: const Text('إنشاء مجلد جديد', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () { Navigator.pop(sheetContext); _showCreateFolderDialog(context); },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.drive_folder_upload, color: Colors.white)),
                title: const Text('رفع مجلد مع ملفاته', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () { Navigator.pop(sheetContext); _uploadFolderWithFiles(context); },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.upload_file, color: Colors.white)),
                title: const Text('رفع ملف', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () { Navigator.pop(sheetContext); _uploadFile(context); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, String docId, Map<String, dynamic> data) {
    final bool isFolder = data['type'] == 'folder';
    final name = data['name'] ?? 'بدون اسم';
    final date = data['created_at'] != null ? intl.DateFormat('yyyy-MM-dd').format(DateTime.parse(data['created_at'])) : '';

    return InkWell(
      onTap: isFolder
          ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminFilesPage(parentFolderId: docId, folderName: name)))
          : () => _downloadFile(data['url']),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Icon(isFolder ? Icons.folder : _getFileIcon(name), size: 64, color: isFolder ? Colors.amber[400] : Colors.green[300]),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      InkWell(
                        onTap: () => _showItemOptions(context, docId, data, isFolder),
                        child: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(date, style: TextStyle(fontSize: 11, color: Colors.green[800])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showItemOptions(BuildContext context, String docId, Map<String, dynamic> data, bool isFolder) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const Divider(),
              if (!isFolder)
                ListTile(
                  leading: const Icon(Icons.download, color: Colors.green),
                  title: const Text('تحميل'),
                  onTap: () { Navigator.pop(sheetContext); _downloadFile(data['url']); },
                ),
              if (UserSession().canEditOrDelete || UserSession().isAccounting || UserSession().isSecretary)
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.green),
                  title: const Text('إعادة التسمية'),
                  onTap: () { Navigator.pop(sheetContext); _renameItem(docId, data['name'] ?? '', isFolder); },
                ),
              if (UserSession().canEditOrDelete)
                ListTile(
                  leading: const Icon(Icons.lock_outline, color: Colors.green),
                  title: const Text('صلاحيات الرؤية'),
                  onTap: () { Navigator.pop(sheetContext); _showEditPrivacyDialog(context, docId, data); },
                ),
              if (UserSession().isAdmin || UserSession().isSecretaryModerator || UserSession().isAccountingModerator || UserSession().isAccounting || UserSession().isSecretary)
                ListTile(
                  leading: const Icon(Icons.drive_file_move, color: Colors.green),
                  title: const Text('نقل العنصر'),
                  onTap: () { Navigator.pop(sheetContext); _moveItem(docId, data); },
                ),
              if (UserSession().isAdmin)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('حذف العنصر'),
                  onTap: () { Navigator.pop(sheetContext); _deleteItem(docId, data); },
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String? name) {
    final ext = name?.split('.').last.toLowerCase() ?? '';
    if (ext == 'pdf') return Icons.picture_as_pdf;
    if (ext == 'xlsx' || ext == 'xls') return Icons.table_chart;
    if (ext == 'docx' || ext == 'doc') return Icons.description;
    if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) return Icons.image;
    return Icons.insert_drive_file;
  }

  Future<void> _renameItem(String docId, String currentName, bool isFolder) async {
    final TextEditingController nameController = TextEditingController(text: currentName);

    final bool? shouldRename = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isFolder ? 'إعادة تسمية المجلد' : 'إعادة تسمية الملف'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'الاسم الجديد',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    if (shouldRename == true && nameController.text.trim().isNotEmpty && nameController.text.trim() != currentName) {
      try {
        await _firestore.collection('admin_files').doc(docId).update({
          'name': nameController.text.trim(),
        }).timeout(const Duration(seconds: 10));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تمت إعادة التسمية بنجاح')),
          );
        }
      } on FirebaseException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في الخدمة: ${e.message}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ غير متوقع: $e')),
          );
        }
      }
    }
  }

  Widget _buildPrivacyWidget({
    required String selectedPrivacyType,
    required List<int> selectedRoles,
    required List<String> selectedUsers,
    required void Function(String) onPrivacyTypeChanged,
    required void Function(void Function()) setDialogState,
  }) {
    final Map<int, String> availableRoles = {
      1: 'المستخدم العادي',
      4: 'السكرتارية',
      5: 'المحاسبة',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('نوع الخصوصية:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: selectedPrivacyType,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 10),
          ),
          items: const [
            DropdownMenuItem(value: 'public', child: Text('الكل (عام)')),
            DropdownMenuItem(value: 'roles', child: Text('أدوار محددة')),
            DropdownMenuItem(value: 'users', child: Text('مستخدمين محددين')),
          ],
          onChanged: (val) {
            if (val != null) {
              onPrivacyTypeChanged(val);
              setDialogState(() {});
            }
          },
        ),
        if (selectedPrivacyType == 'roles') ...[
          const SizedBox(height: 15),
          const Text('اختر الأدوار المصرح لها:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          ...availableRoles.entries.map((entry) {
            return CheckboxListTile(
              title: Text(entry.value),
              value: selectedRoles.contains(entry.key),
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              onChanged: (bool? val) {
                setDialogState(() {
                  if (val == true) {
                    selectedRoles.add(entry.key);
                  } else {
                    selectedRoles.remove(entry.key);
                  }
                });
              },
            );
          }),
        ],
        if (selectedPrivacyType == 'users') ...[
          const SizedBox(height: 15),
          const Text('اختر المستخدمين المصرح لهم:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchUsers(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 100,
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              if (userSnapshot.hasError ||
                  !userSnapshot.hasData ||
                  userSnapshot.data!.isEmpty) {
                return const Text('لا يوجد مستخدمين متاحين');
              }
              final users = userSnapshot.data!;
              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    children: users.map((u) {
                      final name = u['FullName'];
                      final int role = u['Role'];
                      // Exclude admin and moderator since they see everything anyway
                      if (role == 3 || role == 2)
                        return const SizedBox.shrink();
                      return CheckboxListTile(
                        title: Text(name),
                        value: selectedUsers.contains(name),
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        onChanged: (bool? val) {
                          setDialogState(() {
                            if (val == true) {
                              selectedUsers.add(name);
                            } else {
                              selectedUsers.remove(name);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Future<void> _showCreateFolderDialog(BuildContext context) async {
    final controller = TextEditingController();
    String selectedPrivacyType = 'public';
    List<int> selectedRoles = [];
    List<String> selectedUsers = [];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إنشاء مجلد جديد'),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: controller,
                      decoration:
                          const InputDecoration(labelText: 'اسم المجلد'),
                    ),
                    const SizedBox(height: 20),
                    _buildPrivacyWidget(
                      selectedPrivacyType: selectedPrivacyType,
                      selectedRoles: selectedRoles,
                      selectedUsers: selectedUsers,
                      onPrivacyTypeChanged: (val) {
                        selectedPrivacyType = val;
                      },
                      setDialogState: setDialogState,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () async {
                  if (controller.text.isNotEmpty) {
                    await _firestore.collection('admin_files').add({
                      'name': controller.text,
                      'type': 'folder',
                      'parent_id': widget.parentFolderId,
                      'privacy_type': selectedPrivacyType,
                      'allowed_roles':
                          selectedPrivacyType == 'roles' ? selectedRoles : [],
                      'allowed_users':
                          selectedPrivacyType == 'users' ? selectedUsers : [],
                      'created_at': DateTime.now().toIso8601String(),
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('إنشاء'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditPrivacyDialog(
      BuildContext context, String docId, Map<String, dynamic> data) async {
    String selectedPrivacyType = data['privacy_type'] ?? 'public';
    List<int> selectedRoles = List<int>.from(data['allowed_roles'] ?? []);
    List<String> selectedUsers = List<String>.from(data['allowed_users'] ?? []);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تعديل صلاحيات الرؤية'),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: _buildPrivacyWidget(
                  selectedPrivacyType: selectedPrivacyType,
                  selectedRoles: selectedRoles,
                  selectedUsers: selectedUsers,
                  onPrivacyTypeChanged: (val) {
                    selectedPrivacyType = val;
                  },
                  setDialogState: setDialogState,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _firestore.collection('admin_files').doc(docId).update({
                    'privacy_type': selectedPrivacyType,
                    'allowed_roles':
                        selectedPrivacyType == 'roles' ? selectedRoles : [],
                    'allowed_users':
                        selectedPrivacyType == 'users' ? selectedUsers : [],
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('تم تحديث صلاحيات الرؤية بنجاح')),
                  );
                },
                child: const Text('حفظ التعديلات'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadFile(BuildContext context) async {
    final folderSnapshot = await _firestore
        .collection('admin_files')
        .where('type', isEqualTo: 'folder')
        .get();

    final folders = folderSnapshot.docs.where((doc) => _isItemVisible(doc.data() as Map<String, dynamic>)).toList();

    Map<String, String> folderPaths = {};
    String getFolderPathSafe(String id, List<String> visited) {
      if (folderPaths.containsKey(id)) return folderPaths[id]!;
      if (visited.contains(id)) return 'مسار دائري';
      visited.add(id);

      final docList = folders.where((f) => f.id == id).toList();
      if (docList.isEmpty) return 'مجلد محذوف';

      final data = docList.first.data() as Map<String, dynamic>;
      final parentId = data['parent_id'];
      final name = data['name'] ?? 'بدون اسم';

      if (parentId == null || parentId == '') {
        folderPaths[id] = name;
        return name;
      } else {
        final parentPath = getFolderPathSafe(parentId, visited);
        final path = '$parentPath / $name';
        folderPaths[id] = path;
        return path;
      }
    }

    for (var f in folders) {
      getFolderPathSafe(f.id, []);
    }

    final folderList = folders.toList();
    folderList.sort(
        (a, b) => (folderPaths[a.id] ?? '').compareTo(folderPaths[b.id] ?? ''));

    String? selectedFolderId = widget.parentFolderId;
    String selectedFolderName = widget.folderName;

    String selectedPrivacyType = 'public';
    List<int> selectedRoles = [];
    List<String> selectedUsers = [];

    final FilePickerResult? pickedResult = await showDialog<FilePickerResult?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('رفع ملف جديد'),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('اختر المجلد الوجهة:'),
                    const SizedBox(height: 10),
                    DropdownSearch<String>(
                      selectedItem: (selectedFolderId != null && folderList.any((f) => f.id == selectedFolderId)) ? selectedFolderId! : '',
                      compareFn: (i1, i2) => i1 == i2,
                      items: (filter, loadProps) {
                        final allItems = ['', ...folderList.map((f) => f.id)];
                        if (filter.isEmpty) return allItems;
                        return allItems.where((id) {
                          final name = id == ''
                              ? 'الرئيسية (الملفات الادارية)'
                              : (folderPaths[id] ?? 'مجلد بدون اسم');
                          return name.toLowerCase().contains(filter.toLowerCase());
                        }).toList();
                      },
                      itemAsString: (String id) {
                        if (id == '') return 'الرئيسية (الملفات الادارية)';
                        return folderPaths[id] ?? 'مجلد بدون اسم';
                      },
                      popupProps: const PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            hintText: 'بحث...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10),
                          ),
                        ),
                      ),
                      decoratorProps: const DropDownDecoratorProps(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedFolderId = val == '' ? null : val;
                          if (selectedFolderId == null) {
                            selectedFolderName = 'الملفات الادارية';
                          } else {
                            selectedFolderName =
                                folderPaths[selectedFolderId!] ?? 'مجلد بدون اسم';
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildPrivacyWidget(
                      selectedPrivacyType: selectedPrivacyType,
                      selectedRoles: selectedRoles,
                      selectedUsers: selectedUsers,
                      onPrivacyTypeChanged: (val) {
                        selectedPrivacyType = val;
                      },
                      setDialogState: setDialogState,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['jpg', 'pdf', 'doc', 'docx', 'xls', 'xlsx'],
                  );
                  if (result != null) {
                    Navigator.pop(context, result);
                  }
                },
                child: const Text('اختيار الملف والرفع'),
              ),
            ],
          ),
        ),
      ),
    );

    if (pickedResult != null && pickedResult.files.single.bytes != null) {
      final fileBytes = pickedResult.files.single.bytes!;
      final fileName = pickedResult.files.single.name;
      final storagePath =
          'admin_files/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      try {
        final task = await _storage.ref(storagePath).putData(fileBytes);
        final downloadUrl = await task.ref.getDownloadURL();

        await _firestore.collection('admin_files').add({
          'name': fileName,
          'type': 'file',
          'url': downloadUrl,
          'storage_path': storagePath,
          'parent_id': selectedFolderId,
          'privacy_type': selectedPrivacyType,
          'allowed_roles': selectedPrivacyType == 'roles' ? selectedRoles : [],
          'allowed_users': selectedPrivacyType == 'users' ? selectedUsers : [],
          'created_at': DateTime.now().toIso8601String(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('تم رفع "$fileName" إلى "$selectedFolderName"')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الرفع: $e')),
        );
      }
    }
  }

  Future<void> _uploadFolderWithFiles(BuildContext context) async {
    final folderSnapshot = await _firestore
        .collection('admin_files')
        .where('type', isEqualTo: 'folder')
        .get();

    final folders = folderSnapshot.docs.where((doc) => _isItemVisible(doc.data() as Map<String, dynamic>)).toList();

    Map<String, String> folderPaths = {};
    String getFolderPathSafe(String id, List<String> visited) {
      if (folderPaths.containsKey(id)) return folderPaths[id]!;
      if (visited.contains(id)) return 'مسار دائري';
      visited.add(id);

      final docList = folders.where((f) => f.id == id).toList();
      if (docList.isEmpty) return 'مجلد محذوف';

      final data = docList.first.data() as Map<String, dynamic>;
      final parentId = data['parent_id'];
      final name = data['name'] ?? 'بدون اسم';

      if (parentId == null || parentId == '') {
        folderPaths[id] = name;
        return name;
      } else {
        final parentPath = getFolderPathSafe(parentId, visited);
        final path = '$parentPath / $name';
        folderPaths[id] = path;
        return path;
      }
    }

    for (var f in folders) {
      getFolderPathSafe(f.id, []);
    }

    final folderList = folders.toList();
    folderList.sort(
        (a, b) => (folderPaths[a.id] ?? '').compareTo(folderPaths[b.id] ?? ''));

    final folderNameController = TextEditingController();
    String? selectedFolderId = widget.parentFolderId;
    String selectedFolderName = widget.folderName;

    String selectedPrivacyType = 'public';
    List<int> selectedRoles = [];
    List<String> selectedUsers = [];

    final FilePickerResult? pickedResult = await showDialog<FilePickerResult?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('رفع مجلد كامل مع ملفاته'),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: folderNameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم المجلد الجديد',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text('اختر المجلد الوجهة:'),
                    const SizedBox(height: 5),
                    DropdownSearch<String>(
                      selectedItem: (selectedFolderId != null && folderList.any((f) => f.id == selectedFolderId)) ? selectedFolderId! : '',
                      compareFn: (i1, i2) => i1 == i2,
                      items: (filter, loadProps) {
                        final allItems = ['', ...folderList.map((f) => f.id)];
                        if (filter.isEmpty) return allItems;
                        return allItems.where((id) {
                          final name = id == ''
                              ? 'الرئيسية (الملفات الادارية)'
                              : (folderPaths[id] ?? 'مجلد بدون اسم');
                          return name.toLowerCase().contains(filter.toLowerCase());
                        }).toList();
                      },
                      itemAsString: (String id) {
                        if (id == '') return 'الرئيسية (الملفات الادارية)';
                        return folderPaths[id] ?? 'مجلد بدون اسم';
                      },
                      popupProps: const PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            hintText: 'بحث...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10),
                          ),
                        ),
                      ),
                      decoratorProps: const DropDownDecoratorProps(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedFolderId = val == '' ? null : val;
                          if (selectedFolderId == null) {
                            selectedFolderName = 'الملفات الادارية';
                          } else {
                            selectedFolderName =
                                folderPaths[selectedFolderId!] ?? 'مجلد بدون اسم';
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildPrivacyWidget(
                      selectedPrivacyType: selectedPrivacyType,
                      selectedRoles: selectedRoles,
                      selectedUsers: selectedUsers,
                      onPrivacyTypeChanged: (val) {
                        selectedPrivacyType = val;
                      },
                      setDialogState: setDialogState,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (folderNameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى إدخال اسم المجلد')),
                    );
                    return;
                  }
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['jpg', 'pdf', 'doc', 'docx', 'xls', 'xlsx'],
                    allowMultiple: true,
                  );
                  if (result != null) {
                    Navigator.pop(context, result);
                  }
                },
                child: const Text('اختيار الملفات والرفع'),
              ),
            ],
          ),
        ),
      ),
    );

    if (pickedResult != null && pickedResult.files.isNotEmpty) {
      final result = pickedResult;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 15),
                  Text('جاري إنشاء المجلد ورفع الملفات...'),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        final folderName = folderNameController.text.trim();

        final newFolderRef = await _firestore.collection('admin_files').add({
          'name': folderName,
          'type': 'folder',
          'parent_id': selectedFolderId,
          'privacy_type': selectedPrivacyType,
          'allowed_roles': selectedPrivacyType == 'roles' ? selectedRoles : [],
          'allowed_users': selectedPrivacyType == 'users' ? selectedUsers : [],
          'created_at': DateTime.now().toIso8601String(),
        });

        final newFolderId = newFolderRef.id;

        for (var file in result.files) {
          if (file.bytes == null) continue;

          final fileBytes = file.bytes!;
          final fileName = file.name;
          final storagePath =
              'admin_files/${DateTime.now().millisecondsSinceEpoch}_$fileName';

          final task = await _storage.ref(storagePath).putData(fileBytes);
          final downloadUrl = await task.ref.getDownloadURL();

          await _firestore.collection('admin_files').add({
            'name': fileName,
            'type': 'file',
            'url': downloadUrl,
            'storage_path': storagePath,
            'parent_id': newFolderId,
            'privacy_type': selectedPrivacyType,
            'allowed_roles':
                selectedPrivacyType == 'roles' ? selectedRoles : [],
            'allowed_users':
                selectedPrivacyType == 'users' ? selectedUsers : [],
            'created_at': DateTime.now().toIso8601String(),
          });
        }

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('تم إنشاء مجلد "$folderName" ورفع جميع الملفات بنجاح')),
        );
      } catch (e) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الرفع: $e')),
        );
      }
    }
  }

  Future<void> _downloadFile(String? url) async {
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _deleteFolderContentsRecursively(String folderId) async {
    final snapshot = await _firestore
        .collection('admin_files')
        .where('parent_id', isEqualTo: folderId)
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final docId = doc.id;
      final isFolder = data['type'] == 'folder';

      if (isFolder) {
        await _deleteFolderContentsRecursively(docId);
      } else {
        final storagePath = data['storage_path'];
        if (storagePath != null) {
          try {
            await _storage.ref(storagePath).delete();
          } catch (e) {
            debugPrint('Error deleting file from storage: $e');
          }
        }
      }
      await _firestore.collection('admin_files').doc(docId).delete();
    }
  }

  Future<void> _moveItem(String docId, Map<String, dynamic> data) async {
    final folderSnapshot = await _firestore
        .collection('admin_files')
        .where('type', isEqualTo: 'folder')
        .get()
        .timeout(const Duration(seconds: 10));

    final folders = folderSnapshot.docs.where((doc) => _isItemVisible(doc.data() as Map<String, dynamic>)).toList();
    Map<String, String> folderPaths = {};
    
    String getFolderPathSafe(String id, List<String> visited) {
      if (folderPaths.containsKey(id)) return folderPaths[id]!;
      if (visited.contains(id)) return 'مسار دائري';
      visited.add(id);

      final docList = folders.where((f) => f.id == id).toList();
      if (docList.isEmpty) return 'مجلد محذوف';

      final fData = docList.first.data() as Map<String, dynamic>;
      final parentId = fData['parent_id'];
      final name = fData['name'] ?? 'بدون اسم';

      if (parentId == null || parentId == '') {
        folderPaths[id] = name;
        return name;
      } else {
        final parentPath = getFolderPathSafe(parentId, visited);
        final path = '$parentPath / $name';
        folderPaths[id] = path;
        return path;
      }
    }

    for (var f in folders) {
      getFolderPathSafe(f.id, []);
    }

    final folderList = folders.where((f) => f.id != docId).toList(); // Cannot move into itself
    folderList.sort((a, b) => (folderPaths[a.id] ?? '').compareTo(folderPaths[b.id] ?? ''));

    String? selectedFolderId = data['parent_id'];
    if (selectedFolderId == '') selectedFolderId = null;

    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('نقل العنصر'),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('نقل "${data['name']}" إلى:'),
                    const SizedBox(height: 10),
                    DropdownSearch<String>(
                      selectedItem: folderList.any((f) => f.id == selectedFolderId) ? selectedFolderId : '',
                      compareFn: (i1, i2) => i1 == i2,
                      items: (filter, loadProps) {
                        final allItems = ['', ...folderList.map((f) => f.id)];
                        if (filter.isEmpty) return allItems;
                        return allItems.where((id) {
                          final name = id == ''
                              ? 'الرئيسية (الملفات الادارية)'
                              : (folderPaths[id] ?? 'مجلد بدون اسم');
                          return name.toLowerCase().contains(filter.toLowerCase());
                        }).toList();
                      },
                      itemAsString: (String id) {
                        if (id == '') return 'الرئيسية (الملفات الادارية)';
                        return folderPaths[id] ?? 'مجلد بدون اسم';
                      },
                      popupProps: const PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            hintText: 'بحث...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10),
                          ),
                        ),
                      ),
                      decoratorProps: const DropDownDecoratorProps(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedFolderId = val == '' ? null : val;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('نقل'),
              ),
            ],
          ),
        ),
      ),
    );

    if (proceed == true) {
      try {
        await _firestore.collection('admin_files').doc(docId).update({
          'parent_id': selectedFolderId,
        }).timeout(const Duration(seconds: 10));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم النقل بنجاح')),
          );
        }
      } on FirebaseException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في قاعدة البيانات: $e')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ غير متوقع: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteItem(String docId, Map<String, dynamic> data) async {
    if (!UserSession().isAdmin) return;
    final isFolder = data['type'] == 'folder';

    final bool confirm = await showDialog(
          context: context,
          builder: (context) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('تأكيد الحذف'),
              content: Text(isFolder
                  ? 'هل أنت متأكد من حذف هذا المجلد وجميع محتوياته من ملفات ومجلدات فرعية؟'
                  : 'هل أنت متأكد من حذف هذا الملف؟'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('إلغاء')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('حذف'),
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (confirm) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 15),
                  Text(isFolder
                      ? 'جاري حذف المجلد ومحتوياته الفرعية...'
                      : 'جاري حذف الملف...'),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        if (isFolder) {
          await _deleteFolderContentsRecursively(docId);
        } else {
          final storagePath = data['storage_path'];
          if (storagePath != null) {
            await _storage.ref(storagePath).delete();
          }
        }
        await _firestore.collection('admin_files').doc(docId).delete();

        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isFolder
                  ? 'تم حذف المجلد ومحتوياته بنجاح'
                  : 'تم حذف الملف بنجاح')),
        );
      } catch (e) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الحذف: $e')),
        );
      }
    }
  }
}
