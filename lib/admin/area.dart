import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AreasPage extends StatelessWidget {
  const AreasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // Right-to-left alignment
      child: Scaffold(
        appBar: AppBar(
          title: const Text('جميع المناطق'),
          centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _addArea(context),
          child: const Icon(Icons.add),
          tooltip: 'إضافة منطقة',
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('areas')
                .orderBy('id')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'لا توجد بيانات',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                );
              }

              final areas = snapshot.data!.docs;

              return ListView.builder(
                itemCount: areas.length,
                itemBuilder: (context, index) {
                  final area = areas[index].data() as Map<String, dynamic>;
                  final docId = areas[index].id;

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'المنطقة: ${area['name'] ?? 'غير معروف'}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('المعرف: ${area['id'] ?? 'غير معروف'}'),
                          Text('الوصف: ${area['description'] ?? 'غير معروف'}'),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              TextButton(
                                onPressed: () => _deleteArea(context, docId),
                                child: const Text(
                                  'حذف',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    _editArea(context, docId, area),
                                child: const Text(
                                  'تعديل',
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    _viewCases(context, area['id']),
                                child: const Text(
                                  'عرض الحالات',
                                  style: TextStyle(color: Colors.green),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _viewCases(BuildContext context, int areaId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CasesForAreaPage(areaId: areaId),
      ),
    );
  }

  Future<void> _addArea(BuildContext context) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إضافة منطقة جديدة'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم المنطقة'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'الوصف'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty &&
                      descriptionController.text.isNotEmpty) {
                    try {
                      final querySnapshot = await FirebaseFirestore.instance
                          .collection('areas')
                          .orderBy('id', descending: true)
                          .limit(1)
                          .get();

                      int nextId = 1;
                      if (querySnapshot.docs.isNotEmpty) {
                        final lastArea = querySnapshot.docs.first.data();
                        nextId = (lastArea['id'] ?? 0) + 1;
                      }

                      await FirebaseFirestore.instance.collection('areas').add({
                        'name': nameController.text,
                        'description': descriptionController.text,
                        'created_at': DateTime.now().toIso8601String(),
                        'updated_at': DateTime.now().toIso8601String(),
                        'id': nextId,
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم إضافة المنطقة بنجاح')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('حدث خطأ: $e')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى ملء جميع الحقول')),
                    );
                  }
                },
                child: const Text('إضافة'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteArea(BuildContext context, String docId) async {
    await FirebaseFirestore.instance.collection('areas').doc(docId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف المنطقة بنجاح')),
    );
  }

  Future<void> _editArea(
      BuildContext context, String docId, Map<String, dynamic> area) async {
    final nameController = TextEditingController(text: area['name']);
    final descriptionController =
        TextEditingController(text: area['description']);

    await showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تعديل المنطقة'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم المنطقة'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'الوصف'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('areas')
                      .doc(docId)
                      .update({
                    'name': nameController.text,
                    'description': descriptionController.text,
                    'updated_at': DateTime.now().toIso8601String(),
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تعديل المنطقة بنجاح')),
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
}

// Define the CasesForAreaPage class
class CasesForAreaPage extends StatelessWidget {
  final int areaId;

  const CasesForAreaPage({super.key, required this.areaId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الحالات للمنطقة $areaId'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('cases')
            .where('area_id',
                isEqualTo: areaId) // Ensure area_id is queried as an integer
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد حالات لهذه المنطقة',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final cases = snapshot.data!.docs;

          return ListView.builder(
            itemCount: cases.length,
            itemBuilder: (context, index) {
              final caseData = cases[index].data() as Map<String, dynamic>;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الحالة: ${caseData['name'] ?? 'غير معروف'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('رقم الحالة: ${caseData['id'] ?? 'غير معروف'}'),
                      Text('العنوان: ${caseData['location'] ?? 'غير معروف'}'),
                      Text('الرقم: ${caseData['number'] ?? 'غير معروف'}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
