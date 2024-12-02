import 'package:berwehsan/widgets/user_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserChestsPage extends StatelessWidget {
  const UserChestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // Set everything to right alignment
      child: Scaffold(
        appBar: AppBar(
          title: const Text('جميع الصناديق'),
          centerTitle: true,
        ),
        drawer: userDrawer(), // Add the menu bar (drawer)
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
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
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

  void _addChest(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController balanceController = TextEditingController();

    showDialog(
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
                      balanceController.text.isNotEmpty) {
                    try {
                      await FirebaseFirestore.instance
                          .collection('chests')
                          .add({
                        'name': nameController.text,
                        'balance': int.tryParse(balanceController.text) ?? 0,
                        'created_at': DateTime.now().toIso8601String(),
                        'updated_at': DateTime.now().toIso8601String(),
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

  void _viewCases(BuildContext context, int chestId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CasesForChestPage(chestId: chestId),
      ),
    );
  }
}

class CasesForChestPage extends StatelessWidget {
  final int chestId;

  const CasesForChestPage({super.key, required this.chestId});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // Set the direction to Right-to-Left
      child: Scaffold(
        appBar: AppBar(
          title: Text('الحالات للصندوق $chestId'),
          centerTitle: true,
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
      ),
    );
  }
}
