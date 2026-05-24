import 'dart:typed_data';
import 'package:berwehsan/widgets/app_drawer.dart';
import 'package:berwehsan/core/user_session.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart' as intl;
import 'package:url_launcher/url_launcher.dart';

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
        appBar: AppBar(
          title: Text(widget.folderName),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.create_new_folder),
              onPressed: () => _showCreateFolderDialog(context),
              tooltip: 'إنشاء مجلد',
            ),
            IconButton(
              icon: const Icon(Icons.drive_folder_upload, color: Colors.amber),
              onPressed: () => _uploadFolderWithFiles(context),
              tooltip: 'رفع مجلد مع ملفاته',
            ),
            IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: () => _uploadFile(context),
              tooltip: 'رفع ملف',
            ),
          ],
        ),
        drawer: widget.parentFolderId == null ? const AppDrawer() : null,
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
              return const Center(child: Text('لا توجد ملفات أو مجلدات'));
            }

            // Filter manually to ensure no edge cases with null/empty parent_id
            final allDocs = snapshot.data!.docs;
            final docs = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;

              // Privacy check
              int? currentRole = UserSession().role;
              String? currentName = UserSession().fullName;

              // Admin (3) and Moderator (2) can see everything
              if (currentRole != 3 && currentRole != 2) {
                String privacyType = data['privacy_type'] ?? 'public';
                if (privacyType == 'roles') {
                  List<dynamic> allowedRoles = data['allowed_roles'] ?? [];
                  if (currentRole == null ||
                      !allowedRoles.contains(currentRole)) {
                    return false;
                  }
                } else if (privacyType == 'users') {
                  List<dynamic> allowedUsers = data['allowed_users'] ?? [];
                  if (currentName == null ||
                      !allowedUsers.contains(currentName)) {
                    return false;
                  }
                } else {
                  // Fallback compatibility with old allowed_roles list
                  if (data.containsKey('allowed_roles')) {
                    List<dynamic> allowedRoles = data['allowed_roles'] ?? [];
                    if (allowedRoles.isNotEmpty) {
                      if (currentRole == null ||
                          !allowedRoles.contains(currentRole)) {
                        return false;
                      }
                    }
                  }
                }
              }

              final parentId = data['parent_id'];

              // Handle root level
              if (widget.parentFolderId == null) {
                return parentId == null || parentId == '';
              }

              // Handle nested level
              return parentId == widget.parentFolderId;
            }).toList();

            if (docs.isEmpty) {
              return const Center(
                  child: Text('هذا المجلد فارغ أو لا تملك صلاحية رؤيته'));
            }

            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final docId = docs[index].id;
                final bool isFolder = data['type'] == 'folder';

                return ListTile(
                  leading: Icon(
                    isFolder ? Icons.folder : _getFileIcon(data['name']),
                    color: isFolder ? Colors.amber : Colors.blue,
                  ),
                  title: Text(data['name'] ?? 'بدون اسم'),
                  subtitle: Text(
                    'تاريخ الإضافة: ${intl.DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(data['created_at']))}',
                  ),
                  onTap: isFolder
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminFilesPage(
                                parentFolderId: docId,
                                folderName: data['name'],
                              ),
                            ),
                          )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isFolder)
                        IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () => _downloadFile(data['url']),
                        ),
                      if (UserSession().canEditOrDelete)
                        IconButton(
                          icon: const Icon(Icons.lock_outline,
                              color: Colors.teal),
                          tooltip: 'صلاحيات الرؤية',
                          onPressed: () =>
                              _showEditPrivacyDialog(context, docId, data),
                        ),
                      if (UserSession().isAdmin)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteItem(docId, data),
                        ),
                    ],
                  ),
                );
              },
            );
          },
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

    final folders = folderSnapshot.docs;

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

    final bool? proceed = await showDialog<bool>(
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
                    DropdownButtonFormField<String?>(
                      value: selectedFolderId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('الرئيسية (الملفات الادارية)'),
                        ),
                        ...folderList.map((f) {
                          return DropdownMenuItem(
                            value: f.id,
                            child: Text(folderPaths[f.id] ?? 'مجلد بدون اسم'),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setDialogState(() {
                          selectedFolderId = val;
                          if (val == null) {
                            selectedFolderName = 'الملفات الادارية';
                          } else {
                            selectedFolderName =
                                folderPaths[val] ?? 'مجلد بدون اسم';
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
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('اختيار الملف والرفع'),
              ),
            ],
          ),
        ),
      ),
    );

    if (proceed != true) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'pdf', 'doc', 'docx', 'xls', 'xlsx'],
    );

    if (result != null && result.files.single.bytes != null) {
      final fileBytes = result.files.single.bytes!;
      final fileName = result.files.single.name;
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

    final folders = folderSnapshot.docs;

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

    final bool? proceed = await showDialog<bool>(
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
                    DropdownButtonFormField<String?>(
                      value: selectedFolderId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('الرئيسية (الملفات الادارية)'),
                        ),
                        ...folderList.map((f) {
                          return DropdownMenuItem(
                            value: f.id,
                            child: Text(folderPaths[f.id] ?? 'مجلد بدون اسم'),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setDialogState(() {
                          selectedFolderId = val;
                          if (val == null) {
                            selectedFolderName = 'الملفات الادارية';
                          } else {
                            selectedFolderName =
                                folderPaths[val] ?? 'مجلد بدون اسم';
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
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (folderNameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى إدخال اسم المجلد')),
                    );
                    return;
                  }
                  Navigator.pop(context, true);
                },
                child: const Text('اختيار الملفات والرفع'),
              ),
            ],
          ),
        ),
      ),
    );

    if (proceed != true) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'pdf', 'doc', 'docx', 'xls', 'xlsx'],
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
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
