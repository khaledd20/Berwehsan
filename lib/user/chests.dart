import 'package:berwehsan/user/chestsHistory.dart';
import 'package:berwehsan/widgets/user_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html;
import 'package:intl/intl.dart' as intl;
class UserChestsPage extends StatelessWidget {
  const UserChestsPage({super.key});

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
        drawer: userDrawer(),
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
                                onPressed: () =>
                                    _viewCases(context, chest['id']),
                                child: const Text(
                                  'عرض الحالات',
                                  style: TextStyle(color: Colors.green),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ItemDetailsChest(chestId: docId),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'تفاصيل الرصيد',
                                  style: TextStyle(color: Colors.orange),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ChestsHistoryPage(chestId: docId),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'سجل الصندوق',
                                  style: TextStyle(color: Colors.purple),
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

                    await FirebaseFirestore.instance.collection('chests').add({
                      'name': nameController.text,
                      'balance': int.parse(balanceController.text),
                      'created_at': DateTime.now().toIso8601String(),
                      'updated_at': DateTime.now().toIso8601String(),
                      'id': nextId, // Assign the auto-generated ID
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

class ItemDetailsChest extends StatelessWidget {
  final String chestId;

  const ItemDetailsChest({Key? key, required this.chestId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الصندوق'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chests')
            .doc(chestId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final int balance = data['balance'] ?? 0;
          final String name = data['name'] ?? 'غير معروف';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'اسم الصندوق: $name',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'الرصيد الحالي: $balance',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _updateChestBalance(context, chestId, balance,
                            isAdd: true);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        _updateChestBalance(context, chestId, balance,
                            isAdd: false);
                      },
                      icon: const Icon(Icons.remove),
                      label: const Text('سحب'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildSingleSelectDropdown(String label, List<Map<String, dynamic>> items, String? selectedItem, Function(String?) onItemSelected) {
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredItems = items; // Initially show all items

  return StatefulBuilder(
    builder: (context, setState) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Card(
          child: Column(
            children: [
              // Label
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),

              // Search Bar
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: 'بحث',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      filteredItems = items
                          .where((item) => item['name']
                              .toString()
                              .toLowerCase()
                              .contains(value.toLowerCase()))
                          .toList();
                    });
                  },
                ),
              ),

              // Items List (filteredItems)
              ...filteredItems.map((item) {
                return RadioListTile<String>(
                  value: item['id'],
                  groupValue: selectedItem,
                  title: Text(item['name'] ?? ''),
                  onChanged: (value) {
                    setState(() {
                      onItemSelected(value);
                    });
                  },
                );
              }).toList(),
            ],
          ),
        ),
      );
    },
  );
}

void _updateChestBalance(
    BuildContext context, String chestId, int currentBalance,
    {required bool isAdd}) {
  showDialog(
    context: context,
    builder: (context) {
      final TextEditingController balanceController = TextEditingController();
      final TextEditingController manualNameController =
          TextEditingController();
      DateTime? selectedDate;
      String? selectedEntityId; // Holds the selected donor/case ID
      String? selectedEntityName; // Holds the selected donor/case name
      bool isManualInput = false; // Toggle between manual input and selection

      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: Text(isAdd ? 'إضافة إلى الرصيد' : 'سحب من الرصيد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Current Balance
                Text('الرصيد الحالي: $currentBalance'),
                const SizedBox(height: 16),

                // Date Picker
                ElevatedButton(
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      setState(() => selectedDate = pickedDate);
                    }
                  },
                  child: Text(
                    selectedDate == null
                        ? 'اختر تاريخ الإيصال'
                        : intl.DateFormat('yyyy-MM-dd').format(selectedDate!),
                  ),
                ),
                const SizedBox(height: 16),

                // Amount Input
                TextField(
                  controller: balanceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'أدخل المبلغ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Toggle Between Manual Input and Collection Selection
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('اختر من القائمة'),
                        value: false,
                        groupValue: isManualInput,
                        onChanged: (value) {
                          setState(() {
                            isManualInput = value!;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('إضافة يدويًا'),
                        value: true,
                        groupValue: isManualInput,
                        onChanged: (value) {
                          setState(() {
                            isManualInput = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                // Show Dropdown or Manual Input Based on Selection
                if (!isManualInput)
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection(isAdd ? 'subs' : 'cases')
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }
                      final entities = snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return {'id': doc.id, 'name': data['name']};
                      }).toList();

                      return buildSingleSelectDropdown(
                        isAdd ? 'اختر المتبرع' : 'اختر الحالة',
                        entities,
                        selectedEntityId,
                        (value) {
                          setState(() {
                            selectedEntityId = value;
                            selectedEntityName = entities
                                .firstWhere(
                                    (item) => item['id'] == value)['name'];
                          });
                        },
                      );
                    },
                  )
                else
                  TextField(
                    controller: manualNameController,
                    decoration: InputDecoration(
                      labelText: isAdd ? 'اسم المتبرع' : 'اسم الحالة',
                      border: const OutlineInputBorder(),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () async {
                final int updateAmount =
                    int.tryParse(balanceController.text) ?? 0;

                // Validate inputs
                if (updateAmount <= 0 ||
                    selectedDate == null ||
                    (!isManualInput &&
                        (selectedEntityId == null || selectedEntityName == null)) ||
                    (isManualInput && manualNameController.text.trim().isEmpty)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('يرجى ملء جميع الحقول المطلوبة بشكل صحيح.')),
                  );
                  return;
                }

                final int beforeAmount = currentBalance;
                final int afterAmount = isAdd
                    ? currentBalance + updateAmount
                    : (currentBalance - updateAmount >= 0
                        ? currentBalance - updateAmount
                        : 0);

                final String currentTime = DateTime.now().toIso8601String();

                // Update chest balance and add history log
                await FirebaseFirestore.instance
                    .collection('chests')
                    .doc(chestId)
                    .update({
                  'balance': afterAmount,
                  'updated_at': currentTime,
                });

                await FirebaseFirestore.instance.collection('chest_log').add({
                  'chest_id': chestId,
                  'amount': updateAmount,
                  'status': isAdd ? 'in' : 'out',
                  'before_amount': beforeAmount,
                  'after_amount': afterAmount,
                  'created_date': currentTime,
                  'created_at': selectedDate?.toIso8601String(),
                  isAdd ? 'donor_name' : 'case_name': isManualInput
                      ? manualNameController.text
                      : selectedEntityName,
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isAdd
                          ? 'تم إضافة $updateAmount بنجاح.'
                          : 'تم سحب $updateAmount بنجاح.',
                    ),
                  ),
                );
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      });
    },
  );
}




}
