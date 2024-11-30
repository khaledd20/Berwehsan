import 'package:berwehsan/widgets/admin_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'caseProfile.dart';
import 'insertCase.dart';

class CasesPage extends StatefulWidget {
  const CasesPage({super.key});

  @override
  _CasesPageState createState() => _CasesPageState();
}

class _CasesPageState extends State<CasesPage> {
  String searchQuery = ''; // To hold the search query

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('جدول الحالات'),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value; // Update the search query
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'ابحث بالاسم أو الرقم',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
        ),
        drawer: AdminDrawer(), // Add the drawer here
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('cases').orderBy('id').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text('لا توجد بيانات', style: TextStyle(fontSize: 18)),
              );
            }

            final cases = snapshot.data!.docs;

            // Filter cases based on the search query
            final filteredCases = cases.where((doc) {
              final caseData = doc.data() as Map<String, dynamic>;
              final name = caseData['name']?.toString().toLowerCase() ?? '';
              final id = caseData['id']?.toString();

              // If search query is numeric, match ID exactly
              if (RegExp(r'^\d+$').hasMatch(searchQuery)) {
                return id == searchQuery;
              }

              // Otherwise, perform a partial match for the name
              return name.contains(searchQuery.toLowerCase());
            }).toList();

            return ListView.builder(
              itemCount: filteredCases.length,
              itemBuilder: (context, index) {
                final caseData = filteredCases[index].data() as Map<String, dynamic>;
                final docId = filteredCases[index].id;

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(caseData['name'] ?? 'غير معروف'),
                    subtitle: Text('رقم الحالة: ${caseData['id'] ?? 'غير معروف'}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            _editCase(context, docId, caseData);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _confirmDeleteCase(context, docId);
                          },
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CaseProfile(caseId: int.parse(caseData['id'].toString())),
                              ),
                            );
                          },
                          child: const Text('عرض'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.green,
          child: const Icon(Icons.add),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InsertCase(),
              ),
            );
          },
          tooltip: 'إضافة حالة جديدة',
        ),
      ),
    );
  }

  /// Confirm delete dialog
  void _confirmDeleteCase(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('حذف الحالة'),
            content: const Text('هل أنت متأكد من حذف هذه الحالة؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('cases').doc(docId).delete();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف الحالة بنجاح')),
                  );
                },
                child: const Text('حذف'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Edit case dialog
  Future<void> _editCase(BuildContext context, String docId, Map<String, dynamic> caseData) async {
  final Map<String, TextEditingController> controllers = {};

  // Initialize controllers for all editable fields in caseData
  caseData.forEach((key, value) {
    if (key != 'id' && key != 'created_at' && key != 'updated_at') { // Exclude non-editable fields
      controllers[key] = TextEditingController(text: value?.toString() ?? '');
    }
  });

  await showDialog(
    context: context,
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تعديل الحالة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: controllers.keys.map((key) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    controller: controllers[key],
                    decoration: InputDecoration(
                      labelText: _getFieldLabel(key),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedData = controllers.map((key, controller) => MapEntry(key, controller.text));

                // Add or update `updated_at` field with the current timestamp
                updatedData['updated_at'] = DateTime.now().toIso8601String();

                await FirebaseFirestore.instance.collection('cases').doc(docId).update(updatedData);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تعديل الحالة بنجاح')),
                );
              },
              child: const Text('تعديل'),
            ),
          ],
        ),
      );
    },
  );
}


  /// Generate user-friendly labels for fields
  String _getFieldLabel(String key) {
    switch (key) {
      case 'name':
        return 'اسم الحالة';
      case 'location':
        return 'العنوان';
      case 'social_status':
        return 'الحالة الاجتماعية';
      case 'id_number':
        return 'الرقم القومي';
      case 'age':
        return 'العمر';
      case 'family_count':
        return 'عدد أعضاء الأسرة';
      case 'number':
        return 'رقم الهاتف';
      case 'area_id':
        return 'رقم المنطقة';
      case 'grade_id':
        return 'رقم الصف';
      case 'c_size':
        return 'مقاس الملابس';
      case 's_size':
        return 'مقاس جهاز العوسة';
      case 'in_come':
        return 'الدخل';
      case 'created_at':
        return 'تاريخ الإنشاء';
      case 'updated_at':
        return 'تاريخ التعديل';
      default:
        return key;
    }
  }
}
