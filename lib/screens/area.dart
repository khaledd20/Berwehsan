import 'package:berwehsan/widgets/app_drawer.dart';
import 'package:berwehsan/core/user_session.dart';
import 'package:flutter/material.dart';
import 'package:berwehsan/core/age_calculator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:berwehsan/core/print_style.dart';
import 'dart:html' as html; // For web-based printing

class AreasPage extends StatefulWidget {
  const AreasPage({super.key});

  @override
  State<AreasPage> createState() => _AreasPageState();
}

class _AreasPageState extends State<AreasPage> {
  bool _sortByDate = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // Right-to-left alignment
      child: Scaffold(
        appBar: AppBar(
          title: const Text('جميع المناطق'),
          centerTitle: true,
        ),
        drawer: const AppDrawer(),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _addArea(context),
          tooltip: 'إضافة منطقة',
          child: const Icon(Icons.add),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('الترتيب: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  ToggleButtons(
                    isSelected: [!_sortByDate, _sortByDate],
                    onPressed: (index) =>
                        setState(() => _sortByDate = index == 1),
                    borderRadius: BorderRadius.circular(8),
                    selectedColor: Colors.white,
                    fillColor: Theme.of(context).primaryColor,
                    constraints:
                        const BoxConstraints(minHeight: 36, minWidth: 70),
                    children: const [
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('الرقم')),
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('التاريخ')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
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

                    final areasDocs = snapshot.data!.docs;
                    var areas = areasDocs.map((doc) => doc).toList();

                    // Apply client-side sort
                    if (_sortByDate) {
                      areas.sort((a, b) {
                        final aData = a.data() as Map<String, dynamic>;
                        final bData = b.data() as Map<String, dynamic>;
                        final aDate = aData['created_at']?.toString() ?? '';
                        final bDate = bData['created_at']?.toString() ?? '';
                        return bDate.compareTo(aDate);
                      });
                    } else {
                      areas.sort((a, b) {
                        final aData = a.data() as Map<String, dynamic>;
                        final bData = b.data() as Map<String, dynamic>;
                        final aIdRaw = aData['id']?.toString() ?? '0';
                        final bIdRaw = bData['id']?.toString() ?? '0';
                        final aId = int.tryParse(
                                aIdRaw.replaceAll(RegExp(r'[^0-9]'), '')) ??
                            0;
                        final bId = int.tryParse(
                                bIdRaw.replaceAll(RegExp(r'[^0-9]'), '')) ??
                            0;
                        return aId.compareTo(bId);
                      });
                    }

                    return ListView.builder(
                      itemCount: areas.length,
                      itemBuilder: (context, index) {
                        final area =
                            areas[index].data() as Map<String, dynamic>;
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
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Text('المعرف: ${area['id'] ?? 'غير معروف'}'),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    // Delete/Edit only for Admin (Role 3)
                                    // Delete only for Admin
                                    if (UserSession().isAdmin)
                                      TextButton(
                                        onPressed: () =>
                                            _deleteArea(context, docId),
                                        child: const Text(
                                          'حذف',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    // Edit for Admin and Moderator
                                    if (UserSession().canEditOrDelete)
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
            ],
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

  /// Function to delete an area
  Future<void> _deleteArea(BuildContext context, String docId) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('areas').doc(docId).get();
      if (!doc.exists) return;
      final areaId = doc.data()?['id'];

      // Cross-collection cleanup: Reset area_id in all cases that were in this area
      if (areaId != null) {
        final casesSnapshot = await FirebaseFirestore.instance
            .collection('cases')
            .where('area_id', isEqualTo: areaId)
            .get();

        final batch = FirebaseFirestore.instance.batch();
        for (var caseDoc in casesSnapshot.docs) {
          batch.update(caseDoc.reference, {'area_id': null});
        }
        await batch.commit();
      }

      await FirebaseFirestore.instance.collection('areas').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم حذف المنطقة بنجاح وتحديث الحالات المرتبطة')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء الحذف: $e')),
      );
    }
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
}

class CasesForAreaPage extends StatefulWidget {
  final int areaId;

  const CasesForAreaPage({super.key, required this.areaId});

  @override
  State<CasesForAreaPage> createState() => _CasesForAreaPageState();
}

class _CasesForAreaPageState extends State<CasesForAreaPage> {
  String _ageFilter = '';
  List<QueryDocumentSnapshot> _currentFilteredCases = [];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('الحالات للمنطقة ${widget.areaId}'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () => _printCurrentCases(context),
              tooltip: 'طباعة الحالات المعروضة',
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'تصفية بالعمر',
                  hintText: 'أدخل العمر...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.filter_alt),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _ageFilter = value.trim();
                  });
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('cases')
                    .where('area_id', isEqualTo: widget.areaId)
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

                  // Apply age filter locally
                  var filteredDocs = snapshot.data!.docs.where((doc) {
                    if (_ageFilter.isEmpty) return true;
                    final data = doc.data() as Map<String, dynamic>;
                    final age = AgeCalculator.calculateAge(
                            data['birth_date']?.toString(), data['age'])
                        .toString();
                    return age == _ageFilter;
                  }).toList();

                  // Sort by ID
                  filteredDocs.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aId =
                        int.tryParse(aData['id']?.toString() ?? '0') ?? 0;
                    final bId =
                        int.tryParse(bData['id']?.toString() ?? '0') ?? 0;
                    return aId.compareTo(bId);
                  });

                  // Update current list for printing
                  _currentFilteredCases = filteredDocs;

                  if (filteredDocs.isEmpty) {
                    return const Center(
                      child: Text('لا توجد حالات تطابق العمر المدخل'),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final caseData =
                          filteredDocs[index].data() as Map<String, dynamic>;

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'الحالة: ${caseData['name'] ?? 'غير معروف'}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                  'رقم الحالة: ${caseData['id'] ?? 'غير معروف'}'),
                              Text(
                                  'اسم الأم: ${caseData['mother_name'] ?? 'غير معروف'}'),
                              Text(
                                  'العنوان: ${caseData['location'] ?? 'غير معروف'}'),
                              Text(
                                  'الرقم: ${caseData['number'] ?? 'غير معروف'}'),
                              Text(
                                  'العمر: ${AgeCalculator.calculateAge(caseData['birth_date']?.toString(), caseData['age'])}'),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printCurrentCases(BuildContext context) async {
    if (_currentFilteredCases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد بيانات للطباعة')),
      );
      return;
    }

    try {
      final buffer = StringBuffer();
      buffer.writeln('<html>');
      buffer.writeln(PrintStyle.htmlHead);
      buffer.writeln('<body>');

      buffer.writeln(
          'body { direction: rtl; font-family: Arial, sans-serif; margin: 20px; }');
      buffer.writeln(
          'table { width: 100%; border-collapse: collapse; margin-top: 20px; font-size: 12px; }');
      buffer.writeln(
          'th, td { border: 1px solid black; padding: 6px; text-align: right; }');
      buffer.writeln('th { background-color: #f2f2f2; }');
      buffer.writeln('h1 { text-align: center; }');
      buffer.writeln('</style></head><body>');

      buffer.writeln(PrintStyle.getHeader(
          'بيانات الحالات - منطقة ${widget.areaId} ${_ageFilter.isNotEmpty ? "(عمر: $_ageFilter)" : ""}'));
      buffer.writeln('<table><tr>'
          '<th>رقم الحالة</th>'
          '<th>الاسم</th>'
          '<th>اسم الأم</th>'
          '<th>عدد الأفراد</th>'
          '<th>العنوان</th>'
          '<th>الحالة الاجتماعية</th>'
          '<th>العمر</th>'
          '<th>رقم التليفون</th>'
          '</tr>');

      for (final doc in _currentFilteredCases) {
        final data = doc.data() as Map<String, dynamic>;
        buffer.writeln('<tr>'
            '<td>${data['id'] ?? '-'}</td>'
            '<td>${data['name'] ?? '-'}</td>'
            '<td>${data['mother_name'] ?? '-'}</td>'
            '<td>${data['family_count'] ?? '-'}</td>'
            '<td>${data['location'] ?? '-'}</td>'
            '<td>${data['social_status'] ?? '-'}</td>'
            '<td>${AgeCalculator.calculateAge(data['birth_date']?.toString(), data['age'])}</td>'
            '<td>${data['number'] ?? '-'}</td>'
            '</tr>');
      }

      buffer.writeln('</table></body></html>');

      final blob = html.Blob([buffer.toString()], 'text/html');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, '_blank');
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الطباعة: $e')),
      );
    }
  }
}
