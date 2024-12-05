import 'package:berwehsan/widgets/admin_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html;

class AdminChestsPage extends StatelessWidget {
  const AdminChestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('جميع الصناديق'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () => ChestPrinter().printChestsData(context),
              tooltip: 'طباعة بيانات الصناديق',
            ),
          ],
        ),
        drawer: AdminDrawer(),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _addChest(context),
          child: const Icon(Icons.add),
          tooltip: 'إضافة صندوق',
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chests')
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

              final chests = snapshot.data!.docs;

              return ListView.builder(
                itemCount: chests.length,
                itemBuilder: (context, index) {
                  final chest = chests[index].data() as Map<String, dynamic>;
                  final docId = chests[index].id;

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الصندوق: ${chest['name'] ?? 'غير معروف'}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('المعرف: ${chest['id'] ?? 'غير معروف'}'),
                          Text(
                              'الرصيد: ${chest['balance']?.toString() ?? '0'}'),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => _deleteChest(context, docId),
                                child: const Text(
                                  'حذف',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    _editChest(context, docId, chest),
                                child: const Text(
                                  'تعديل',
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    _viewCases(context, chest['id']),
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

  // Function to Navigate to Cases Page
  void _viewCases(BuildContext context, int chestId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CasesForChestPage(chestId: chestId),
      ),
    );
  }

  Future<void> _addChest(BuildContext context) async {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    final shareController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إضافة صندوق جديد'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم الصندوق'),
                ),
                TextField(
                  controller: balanceController,
                  decoration: const InputDecoration(labelText: 'الرصيد'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: shareController,
                  decoration: const InputDecoration(labelText: 'id'),
                  keyboardType: TextInputType.number,
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
                      balanceController.text.isNotEmpty &&
                      shareController.text.isNotEmpty) {
                    try {
                      // Fetch the last chest to determine the next ID
                      final querySnapshot = await FirebaseFirestore.instance
                          .collection('chests')
                          .orderBy('id', descending: true)
                          .limit(1)
                          .get();

                      int nextId = 1; // Default ID if no chests exist
                      if (querySnapshot.docs.isNotEmpty) {
                        final lastChest = querySnapshot.docs.first.data();
                        nextId = (lastChest['id'] ?? 0) + 1;
                      }

                      await FirebaseFirestore.instance
                          .collection('chests')
                          .add({
                        'name': nameController.text,
                        'balance': int.parse(balanceController.text),
                        'share': int.parse(shareController.text),
                        'created_at': DateTime.now().toIso8601String(),
                        'updated_at': DateTime.now().toIso8601String(),
                        'id': nextId,
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم إضافة الصندوق بنجاح')),
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

  Future<void> _deleteChest(BuildContext context, String docId) async {
    await FirebaseFirestore.instance.collection('chests').doc(docId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف الصندوق بنجاح')),
    );
  }

  Future<void> _editChest(
      BuildContext context, String docId, Map<String, dynamic> chest) async {
    final nameController = TextEditingController(text: chest['name']);
    final balanceController =
        TextEditingController(text: chest['balance'].toString());
    final shareController =
        TextEditingController(text: chest['share'].toString());

    await showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تعديل الصندوق'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم الصندوق'),
                ),
                TextField(
                  controller: balanceController,
                  decoration: const InputDecoration(labelText: 'الرصيد'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: shareController,
                  decoration: const InputDecoration(labelText: 'id'),
                  keyboardType: TextInputType.number,
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
                      .collection('chests')
                      .doc(docId)
                      .update({
                    'name': nameController.text,
                    'balance': int.parse(balanceController.text),
                    'share': int.parse(shareController.text),
                    'updated_at': DateTime.now().toIso8601String(),
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تعديل الصندوق بنجاح')),
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

class ChestPrinter {
  Future<void> printChestsData(BuildContext context) async {
    final chestsCollection = FirebaseFirestore.instance.collection('chests');
    final buffer = StringBuffer();

    buffer.writeln('<html>');
    buffer.writeln('<head>');
    buffer.writeln('<meta charset="UTF-8">');
    buffer.writeln('<style>');
    buffer.writeln(
        'body { direction: rtl; font-family: Arial, sans-serif; margin: 20px; }');
    buffer.writeln(
        'table { width: 100%; border-collapse: collapse; margin-top: 20px; }');
    buffer.writeln(
        'th, td { border: 1px solid black; padding: 8px; text-align: right; }');
    buffer.writeln('th { background-color: #f2f2f2; }');
    buffer.writeln('h1 { text-align: center; font-size: 24px; }');
    buffer.writeln('</style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');

    buffer.writeln('<h1>بيانات الصناديق</h1>');
    buffer.writeln('<table>');
    buffer
        .writeln('<tr><th>اسم الصندوق</th><th>الرصيد</th><th>المعرف</th></tr>');

    try {
      final querySnapshot = await chestsCollection.get();
      for (var chest in querySnapshot.docs) {
        final chestData = chest.data();
        buffer.writeln(
            '<tr><td>${chestData['name'] ?? 'غير معروف'}</td><td>${chestData['balance'] ?? 'غير معروف'}</td><td>${chestData['id'] ?? 'غير معروف'}</td></tr>');
      }
    } catch (error) {
      buffer.writeln(
          '<tr><td colspan="3">حدث خطأ أثناء استرجاع البيانات: $error</td></tr>');
    }

    buffer.writeln('</table>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    final blob = html.Blob([buffer.toString()], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم طباعة بيانات الصناديق بنجاح')),
    );
  }
}

// CasesForChestPage Widget
class CasesForChestPage extends StatelessWidget {
  final int chestId;

  const CasesForChestPage({super.key, required this.chestId});
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // Set direction to Right-to-Left
      child: Scaffold(
        appBar: AppBar(
          title: Text('الحالات للصندوق $chestId'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () => _printCasesForChest(context, chestId),
              tooltip: 'طباعة بيانات الحالات',
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('cases')
              .where('chest_ids', arrayContains: chestId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'لا توجد حالات لهذا الصندوق',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                  textAlign: TextAlign.center, // Center-align the text
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
                      crossAxisAlignment:
                          CrossAxisAlignment.start, // Align text to the right
                      children: [
                        Text(
                          'الحالة: ${caseData['name'] ?? 'غير معروف'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign:
                              TextAlign.right, // Align each field to the right
                        ),
                        Text(
                          'رقم الحالة: ${caseData['id'] ?? 'غير معروف'}',
                          textAlign: TextAlign.right,
                        ),
                        Text(
                          'العنوان: ${caseData['location'] ?? 'غير معروف'}',
                          textAlign: TextAlign.right,
                        ),
                        Text(
                          'الرقم: ${caseData['number'] ?? 'غير معروف'}',
                          textAlign: TextAlign.right,
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
    );
  }

  Future<void> _printCasesForChest(BuildContext context, int chestId) async {
    final casesCollection = FirebaseFirestore.instance.collection('cases');
    final buffer = StringBuffer();

    buffer.writeln('<html>');
    buffer.writeln('<head>');
    buffer.writeln('<meta charset="UTF-8">');
    buffer.writeln('<style>');
    buffer.writeln(
        'body { direction: rtl; font-family: Arial, sans-serif; margin: 20px; }');
    buffer.writeln(
        'table { width: 100%; border-collapse: collapse; margin-top: 20px; }');
    buffer.writeln(
        'th, td { border: 1px solid black; padding: 8px; text-align: right; }');
    buffer.writeln('th { background-color: #f2f2f2; }');
    buffer.writeln('h1 { text-align: center; }');
    buffer.writeln('</style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');

    buffer.writeln('<h1>بيانات الحالات للصندوق $chestId</h1>');
    buffer.writeln('<table>');
    buffer.writeln(
        '<tr><th>اسم الحالة</th><th>العنوان</th><th>رقم الهاتف</th></tr>');

    try {
      final querySnapshot = await casesCollection
          .where('chest_ids', arrayContains: chestId)
          .get();
      for (var caseDoc in querySnapshot.docs) {
        final caseData = caseDoc.data();
        buffer.writeln(
            '<tr><td>${caseData['name'] ?? 'غير معروف'}</td><td>${caseData['location'] ?? 'غير معروف'}</td><td>${caseData['number'] ?? 'غير معروف'}</td></tr>');
      }
    } catch (error) {
      buffer.writeln(
          '<tr><td colspan="3">حدث خطأ أثناء استرجاع البيانات</td></tr>');
    }

    buffer.writeln('</table>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    final blob = html.Blob([buffer.toString()], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم طباعة بيانات الحالات بنجاح')),
    );
  }
}
