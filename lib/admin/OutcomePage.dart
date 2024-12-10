import 'package:berwehsan/widgets/admin_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:html' as html;
import 'package:rxdart/rxdart.dart';


class OutcomePage extends StatefulWidget {
  const OutcomePage({Key? key}) : super(key: key);

  @override
  _OutcomePageState createState() => _OutcomePageState();
}

class _OutcomePageState extends State<OutcomePage> {
  String _nameOrReceiptFilter = '';
  String _selectedCategory = 'الكل';
  DateTime? _startDate;
  DateTime? _endDate;


// Function to add a new receipt
  void _addReceipt() {
  final receiptController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  String selectedCategory = 'السلفه';

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("إضافة إيصال جديد"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
                value: selectedCategory.isNotEmpty ? selectedCategory : 'السلفه',
                items: ['القبض','السلفه', 'الايجار', 'كهرباء', 'مياة', 'غاز', 'البيان']
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) => selectedCategory = value!,
              decoration: const InputDecoration(labelText: "الفئة"),
            ),
            TextField(
              controller: receiptController,
              decoration: const InputDecoration(labelText: "رقم الإيصال"),
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "اسم المصدر"),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "رقم الهاتف"),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: "المبلغ"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: "الملاحظات"),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("إلغاء"),
        ),
        ElevatedButton(
          onPressed: () async {
            final receiptNumber = receiptController.text.trim();
            final name = nameController.text.trim();
            final phone = phoneController.text.trim();
            final amount = int.tryParse(amountController.text.trim());
            final notes = noteController.text.trim();
            final now = DateTime.now();

            if (receiptNumber.isEmpty || name.isEmpty || amount == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("يرجى ملء جميع الحقول المطلوبة.")),
              );
              return;
            }

            // Add new document to the finance_log collection
            await FirebaseFirestore.instance.collection('finance_log').add({
              "receipt_number": receiptNumber,
              "name": name,
              "phone": phone,
              "amount": amount,
              "category": selectedCategory,
              "date_time": now.toIso8601String(),
              "type": "out",
              "notes": notes,
            });
            // Update or create a document for the selected category in the 'finance' collection
              final categoryDocRef = FirebaseFirestore.instance
                  .collection('finance')
                  .doc(selectedCategory); // Use category name as document ID

              final categoryDoc = await categoryDocRef.get();

              if (categoryDoc.exists) {
                // Update the existing document by increasing the amount
                final currentAmount = categoryDoc['amount'] ?? 0;
                await categoryDocRef.update({
                  "amount": currentAmount + amount,
                  "updated_at": DateTime.now().toIso8601String(),
                });
              } else {
                // Create a new document for the category
                await categoryDocRef.set({
                "id": categoryDocRef.id, // Add ID to the document
                "name": selectedCategory,
                "amount": amount,
                "updated_at": DateTime.now().toIso8601String(),
              });

              }

            // Update total amount in the 'الاجمالي' document in finance collection
            await _updateTotalAmount();

            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("تمت إضافة الإيصال بنجاح!")),
            );
          },
          child: const Text("إضافة"),
        ),
      ],
    ),
  );
}





 Future<void> _printFilteredResults(List<QueryDocumentSnapshot> logs) async {
  if (logs.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("لا توجد نتائج للطباعة.")),
    );
    return;
  }

  try {
    int totalAmount = 0;
    int balance = 0;

    // Fetch balance for display from 'الاجمالي'
    final financeDoc = await FirebaseFirestore.instance
        .collection('finance')
        .doc('الاجمالي')
        .get();

    if (financeDoc.exists) {
      balance = financeDoc.data()?['balance'] ?? 0;
    }

    final buffer = StringBuffer();
    buffer.writeln('<html>');
    buffer.writeln('<head>');
    buffer.writeln('<meta charset="UTF-8">');
    buffer.writeln('<style>');
    buffer.writeln(
        'table { width: 100%; border-collapse: collapse; margin-top: 20px; }');
    buffer.writeln(
        'th, td { border: 1px solid black; padding: 8px; text-align: center; }');
    buffer.writeln('th { background-color: #f2f2f2; font-size: 18px; }');
    buffer.writeln('td { font-size: 16px; }');
    buffer.writeln('</style>');
    buffer.writeln('</head>');
    buffer.writeln(
        '<body style="direction: rtl; font-family: Arial, sans-serif;">');
    buffer.writeln('<h1 style="text-align: center;">سجل الصادر</h1>');
    buffer.writeln('<table>');
    buffer.writeln(
        '<tr><th>الوصف</th><th>المبلغ</th><th>التاريخ</th></tr>');

    for (final log in logs) {
      final data = log.data() as Map<String, dynamic>;

      final amount = (data['amount'] ?? 0) is num
          ? (data['amount'] as num).toInt()
          : 0;
      final category = data['category'] ?? '---';
      final receiptNumber = data['receipt_number'] ?? '---';
      final dateTime = data['date_time'] ?? '';

      totalAmount += amount;

      buffer.writeln('<tr>'
          '<td>$category - رقم الإيصال: $receiptNumber</td>'
          '<td>$amount</td>'
          '<td>${formatDateTime(dateTime)}</td>'
          '</tr>');
    }

    // Append total row
    buffer.writeln('<tr>'
        '<td colspan="2" style="font-weight: bold; text-align: center;">الإجمالي</td>'
        '<td style="font-weight: bold;">$totalAmount</td>'
        '</tr>');

    // Append balance row
    buffer.writeln('<tr>'
        '<td colspan="2" style="font-weight: bold; text-align: center;">الرصيد</td>'
        '<td style="font-weight: bold;">$balance</td>'
        '</tr>');

    buffer.writeln('</table>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    final blob = html.Blob([buffer.toString()], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إنشاء جدول الطباعة بنجاح')),
    );
  } catch (error) {
    print("Error generating print results: $error");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('حدث خطأ أثناء الطباعة: $error')),
    );
  }
}





  
 Future<void> _printReceipt(Map<String, dynamic> data) async {
  final buffer = StringBuffer();
  buffer.writeln('<html>');
  buffer.writeln('<head>');
  buffer.writeln('<meta charset="UTF-8">');
  buffer.writeln('<style>');
  buffer.writeln('body { direction: rtl; font-family: Arial, sans-serif; margin: 0; padding: 0; }');
  buffer.writeln('h1 { text-align: center; font-size: 36px; margin-top: 20px; color: #333; }');
  buffer.writeln('table { margin: 0 auto; border-collapse: collapse; width: 60%; }');
  buffer.writeln('th, td { border: 2px solid #000; padding: 16px; text-align: center; font-size: 20px; }');
  buffer.writeln('th { background-color: #f2f2f2; font-weight: bold; font-size: 22px; }');
  buffer.writeln('td { color: #444; }');
  buffer.writeln('</style>');
  buffer.writeln('</head>');

  buffer.writeln('<body>');
  buffer.writeln('<h1>إيصال الصادر</h1>');

  // Table with centered content
  buffer.writeln('<table>');
  buffer.writeln('<tr><th>الوصف</th><th>التفاصيل</th></tr>');


    buffer.writeln('<tr><td>رقم الإيصال</td><td>${data['receipt_number'] ?? '---'}</td></tr>');
    buffer.writeln('<tr><td>اسم المصدر</td><td>${data['name'] ?? '---'}</td></tr>');
    buffer.writeln('<tr><td>المبلغ</td><td>${data['amount'] ?? 0}</td></tr>');
    buffer.writeln('<tr><td>الفئة</td><td>${data['category'] ?? '---'}</td></tr>');
    buffer.writeln('<tr><td>التاريخ</td><td>${formatDateTime(data['date_time'])}</td></tr>');
  

  buffer.writeln('</table>');
  buffer.writeln('</body>');
  buffer.writeln('</html>');

  final blob = html.Blob([buffer.toString()], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  html.Url.revokeObjectUrl(url);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('تم طباعة الإيصال بنجاح!')),
  );
}



// Helper function to update the 'الاجمالي' document in the finance collection
Future<void> _updateTotalAmount() async {
  int totalIn = 0;
  int totalOut = 0;

  try {
    // Fetch total "in" amount
    final inSnapshot = await FirebaseFirestore.instance
        .collection('finance_log')
        .where('type', isEqualTo: 'in')
        .get();

    for (var doc in inSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final amount = (data['amount'] ?? 0) is num ? (data['amount'] as num).toInt() : 0;
      totalIn += amount;
    }

    // Fetch total "out" amount
    final outSnapshot = await FirebaseFirestore.instance
        .collection('finance_log')
        .where('type', isEqualTo: 'out')
        .get();

    for (var doc in outSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final amount = (data['amount'] ?? 0) is num ? (data['amount'] as num).toInt() : 0;
      totalOut += amount;
    }

    // Calculate the balance (total "in" - total "out")
    final totalBalance = totalIn - totalOut;

    // Update or create the "الإجمالي" document in the "finance" collection
    await FirebaseFirestore.instance.collection('finance').doc('الاجمالي').set({
      "total_in": totalIn,
      "total_out": totalOut,
      "balance": totalBalance,
      "updated_at": DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    print("Balance updated successfully: $totalBalance");
  } catch (e) {
    print("Error updating total amounts: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("حدث خطأ أثناء تحديث المجموع")),
    );
  }
}





// Function to delete a document
  Future<void> _deleteReceipt(String docId) async {
  await FirebaseFirestore.instance.collection('finance_log').doc(docId).delete();
  await _updateTotalAmount(); // Recalculate total amount
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('تم حذف الإيصال بنجاح!')),
  );
  // Update category totals
}




// Function to edit a document
  void _editReceipt(String docId, Map<String, dynamic> data) {
  final receiptController = TextEditingController(text: data['receipt_number']);
  final nameController = TextEditingController(text: data['name']);
  final phoneController = TextEditingController(text: data['phone']);
  final amountController = TextEditingController(text: data['amount'].toString());
  final noteController = TextEditingController(text: data['notes'] ?? '');
  String selectedCategory = data['category'];

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("تعديل الإيصال"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedCategory,
              items: ['القبض','السلفه', 'الايجار', 'كهرباء', 'مياة', 'غاز', 'البيان']
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) => selectedCategory = value!,
              decoration: const InputDecoration(labelText: "الفئة"),
            ),
            TextField(controller: receiptController, decoration: const InputDecoration(labelText: "رقم الإيصال")),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "اسم المصدر")),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: "رقم الهاتف")),
            TextField(controller: amountController, decoration: const InputDecoration(labelText: "المبلغ"), keyboardType: TextInputType.number),
            TextField(controller: noteController, decoration: const InputDecoration(labelText: "الملاحظات")),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
        ElevatedButton(
          onPressed: () async {
            final newAmount = int.tryParse(amountController.text.trim()) ?? 0;
            final newCategory = selectedCategory;

            // Reference to the old and new categories
            final oldCategoryRef = FirebaseFirestore.instance.collection('finance').doc(data['category']);
            final newCategoryRef = FirebaseFirestore.instance.collection('finance').doc(newCategory);

            // Subtract old amount from the old category
            if (data['category'] != newCategory) {
              final oldCategoryDoc = await oldCategoryRef.get();
              final oldAmount = oldCategoryDoc.data()?['amount'] ?? 0;
              await oldCategoryRef.update({"amount": oldAmount - data['amount']});
            }

              // Add new amount to the new category
            final newCategoryDoc = await newCategoryRef.get();
            final newAmountTotal = (newCategoryDoc.data()?['amount'] ?? 0) + newAmount;
            await newCategoryRef.set({
              "name": newCategory,
              "amount": newAmountTotal,
              "updated_at": DateTime.now().toIso8601String(),
            }, SetOptions(merge: true));

            // Update the receipt in 'finance_log'
            await FirebaseFirestore.instance.collection('finance_log').doc(docId).set({
              "receipt_number": receiptController.text.trim(),
              "name": nameController.text.trim(),
              "phone": phoneController.text.trim(),
              "amount": newAmount,
              "category": newCategory,
              "notes": noteController.text.trim(),
              "updated_at": DateTime.now().toIso8601String(), // Add or update the updated_at field
            }, SetOptions(merge: true));

            // Update total amounts
            await _updateTotalAmount();

            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم تحديث الإيصال بنجاح!')),
            );
          },
          child: const Text("حفظ"),
        ),
      ],
    ),
  );
}

DateTime parseCustomDateFormat(String dateString) {
  try {
    // Specify the custom date format
    final format = intl.DateFormat('dd/MM/yyyy');
    return format.parse(dateString);
  } catch (e) {
    print("Error parsing date: $e");
    return DateTime.now(); // Fallback to current date if parsing fails
  }
}

  String formatDateTime(String dateStr) {
  try {
    DateTime dateTime;
    
    // Check if the string contains 'T' to identify ISO 8601
    if (dateStr.contains('T')) {
      dateTime = DateTime.parse(dateStr);
    } else {
      // Parse custom 'dd/MM/yyyy' format
      dateTime = intl.DateFormat('dd/MM/yyyy').parse(dateStr);
    }

    // Format date and time in Arabic
    final formattedDate = intl.DateFormat('dd MMMM yyyy', 'ar').format(dateTime);
    final formattedTime = intl.DateFormat('HH:mm').format(dateTime);

    return "$formattedDate - $formattedTime";
  } catch (e) {
    print("Error formatting date: $e");
    return "Invalid Date";
  }
}



Stream<List<QueryDocumentSnapshot>> _getCombinedLogsStream() {
  // Fetch all documents from finance_log collection
  final financeLogStream = FirebaseFirestore.instance
      .collection('finance_log')
      .where('type', isEqualTo: 'out')
      .snapshots();

  return financeLogStream.map((snapshot) => snapshot.docs);
}




  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("سجل الصادر"),
          actions: [
             IconButton(
              onPressed: _addReceipt,
              icon: const Icon(Icons.add),
              tooltip: "إضافة مصروف جديد",
            ),
            IconButton(
             onPressed: () async {
              try {
                // Fetch logs only from the 'finance_log' collection
                final financeLogSnapshot = await FirebaseFirestore.instance
                    .collection('finance_log')
                    .where('type', isEqualTo: 'out')
                    .get();

                final combinedLogs = financeLogSnapshot.docs;

                // Apply filters
                final filteredLogs = combinedLogs.where((log) {
                  final data = log.data() as Map<String, dynamic>;

                  // Filter by name, receipt number, or case_id
                  final matchesNameOrReceipt = _nameOrReceiptFilter.isEmpty ||
                      (data['name']?.toString()?.contains(_nameOrReceiptFilter) ?? false) ||
                      (data['receipt_number']?.toString()?.contains(_nameOrReceiptFilter) ?? false);
                  // Filter by category
                  final matchesCategory = _selectedCategory == 'الكل' ||
                      data['category'] == _selectedCategory;

                  // Filter by date range
                  final dateField = data['date_time'] ?? '';
                  final matchesDateRange = _startDate == null ||
                      _endDate == null ||
                      (DateTime.parse(dateField).isAtSameMomentAs(_startDate!) ||
                          DateTime.parse(dateField).isAfter(_startDate!)) &&
                          (DateTime.parse(dateField).isAtSameMomentAs(_endDate!) ||
                              DateTime.parse(dateField).isBefore(_endDate!.add(Duration(days: 1))));

                  return matchesNameOrReceipt && matchesCategory && matchesDateRange;
                }).toList();

                // Pass filtered logs to the print function
                await _printFilteredResults(filteredLogs);
              } catch (e) {
                print("Error fetching or filtering data: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("حدث خطأ أثناء جلب البيانات")),
                );
              }
            },
              icon: const Icon(Icons.print),
              tooltip: "طباعة النتائج",
            ),
          ],
        ),
        drawer: AdminDrawer(),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration:
                          const InputDecoration(labelText: "الاسم أو رقم الإيصال"),
                      onChanged: (value) =>
                          setState(() => _nameOrReceiptFilter = value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                         items: ['الكل','القبض','السلفه', 'الايجار', 'كهرباء', 'مياة', 'غاز', 'البيان']
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedCategory = value!),
                      decoration: const InputDecoration(labelText: "الفئة"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          _startDate = picked.start;
                          _endDate = picked.end;
                        });
                      }
                    },
                    child: const Text("تحديد الفترة"),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<QueryDocumentSnapshot>>(
              stream: _getCombinedLogsStream(), // Use the combined stream
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final allLogs = snapshot.data ?? [];

                // Filter logs based on selected category, name, or receipt number
                final filteredLogs = allLogs.where((log) {
                final data = log.data() as Map<String, dynamic>;

                final amount = data['amount'] ?? 0;
                final category = data['category'] ?? '';
                final matchesNameOrReceipt = _nameOrReceiptFilter.isEmpty ||
                    (data['name']?.toString()?.contains(_nameOrReceiptFilter) ?? false) ||
                    (data['receipt_number']?.toString()?.contains(_nameOrReceiptFilter) ?? false) ||
                    (data['case_id']?.toString()?.contains(_nameOrReceiptFilter) ?? false);

                final matchesCategory = _selectedCategory == 'الكل' || data['category'] == _selectedCategory;

                return matchesNameOrReceipt && matchesCategory;
              }).toList();


                return ListView.builder(
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = filteredLogs[index].data() as Map<String, dynamic>;
                    final docId = filteredLogs[index].id;

                    final amount = log['amount'] ?? 0;
                    final category = log['category'] ?? '---';
                    final dateTime = log['date_time'] ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text("رقم الإيصال: ${log['receipt_number'] ?? '---'}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("الفئة: $category"),
                            Text("المبلغ: $amount"),
                            Text("التاريخ: ${formatDateTime(dateTime)}"),
                            if (log.containsKey('notes')) Text("ملاحظات: ${log['notes']}"),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.print, color: Colors.teal),
                              onPressed: () => _printReceipt(log),
                              tooltip: "طباعة",
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editReceipt(docId, log),
                              tooltip: "تعديل",
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteReceipt(docId),
                              tooltip: "حذف",
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
          ]
      )
      )   
    );
  }
}