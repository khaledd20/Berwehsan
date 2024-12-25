import 'package:berwehsan/widgets/admin_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html; // For web-based printing

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
        drawer: AdminDrawer(),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
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
                              TextButton(
                                onPressed: () =>
                                    _PrintCases(context, area['id']),
                                child: const Text(
                                  'طبع الحالات المنطقة',
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 121, 4, 255)),
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

  /// Function to add a new area
  Future<void> _addArea(BuildContext context) async {
  final nameController = TextEditingController();

  await showDialog(
    context: context,
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة منطقة جديدة'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'اسم المنطقة'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
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

  /// Function to edit an area
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

  /// Function to view cases for an area
  void _viewCases(BuildContext context, int areaId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CasesForAreaPage(areaId: areaId),
      ),
    );
  }

  Future<void> _PrintCases(BuildContext context, int areaId) async {
    try {
      // Fetch cases related to the area
      final casesSnapshot = await FirebaseFirestore.instance
          .collection('cases')
          .where('area_id', isEqualTo: areaId)
          .get();

      if (casesSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد حالات لهذه المنطقة')),
        );
        return;
      }

      // Sort manually by ID in ascending order
      final sortedCases = casesSnapshot.docs
        ..sort((a, b) {
          final int idA = int.tryParse(a.data()['id'].toString()) ?? 0;
          final int idB = int.tryParse(b.data()['id'].toString()) ?? 0;
          return idA.compareTo(idB);
        });

      // Generate the HTML content for printing
      final buffer = StringBuffer();

      buffer.writeln('<html>');
      buffer.writeln('<head><meta charset="UTF-8"><style>');
      buffer.writeln(
          'body { direction: rtl; font-family: Arial, sans-serif; margin: 20px; }');
      buffer.writeln(
          'table { width: 100%; border-collapse: collapse; margin-top: 20px; }');
      buffer.writeln(
          'th, td { border: 1px solid black; padding: 8px; text-align: right; }');
      buffer.writeln('th { background-color: #f2f2f2; }');
      buffer.writeln('h1 { text-align: center; }');
      buffer.writeln('</style></head><body>');

      buffer.writeln('<h1>الحالات للمنطقة $areaId</h1>');
      buffer.writeln(
          '<table><tr><th>رقم الحالة</th><th>الاسم</th><th>رقم التليفون</th></tr>');

      for (final caseDoc in sortedCases) {
        final caseData = caseDoc.data() as Map<String, dynamic>;
        buffer.writeln('<tr>'
            '<td>${caseData['id'] ?? 'غير معروف'}</td>'
            '<td>${caseData['name'] ?? 'غير معروف'}</td>'
            '<td>${caseData['number'] ?? 'غير معروف'}</td>'
            '</tr>');
      }

      buffer.writeln('</table></body></html>');

      final blob = html.Blob([buffer.toString()], 'text/html');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, '_blank');
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء جدول الطباعة بنجاح')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الطباعة: $error')),
      );
    }
  }
}

class CasesForAreaPage extends StatelessWidget {
  final int areaId;

  const CasesForAreaPage({super.key, required this.areaId});

  @override
  Widget build(BuildContext context) {
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: Text('الحالات للمنطقة $areaId'),
            centerTitle: true,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('cases')
                .where('area_id',
                    isEqualTo:
                        areaId) // Ensure area_id is queried as an integer
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
                          Text(
                              'العنوان: ${caseData['location'] ?? 'غير معروف'}'),
                          Text('الرقم: ${caseData['number'] ?? 'غير معروف'}'),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ));
  }
}
