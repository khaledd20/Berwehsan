import 'package:berwehsan/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:berwehsan/core/user_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:berwehsan/core/print_style.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:html' as html;

class OutcomePage extends StatefulWidget {
  const OutcomePage({super.key});

  @override
  _OutcomePageState createState() => _OutcomePageState();
}

class _OutcomePageState extends State<OutcomePage> {
  String _nameOrReceiptFilter = '';
  String _selectedCategory = 'الكل';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _sortByDate = true; // true = sort by date (default), false = sort by id

  void _addReceipt() {
    final receiptController = TextEditingController();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String selectedCategory = 'السلفه';
    DateTime? manualDate;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("إضافة إيصال جديد"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: [
                  'بنك',
                  'القبض',
                  'السلفه',
                  'الايجار',
                  'كهرباء',
                  'مياة',
                  'غاز',
                  'البيان',
                  'صندوق خارجي'
                ]
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
              ElevatedButton(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    manualDate = pickedDate;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'تم اختيار التاريخ: ${intl.DateFormat.yMMMd().format(manualDate!)}')),
                    );
                  }
                },
                child: const Text("اختيار تاريخ يدوي"),
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
                  const SnackBar(
                      content: Text("يرجى ملء جميع الحقول المطلوبة.")),
                );
                return;
              }

              try {
                // Fetch the next available id
                final snapshot = await FirebaseFirestore.instance
                    .collection('finance_log')
                    .orderBy('manual_date', descending: true)
                    .limit(1)
                    .get();

                int nextId = 1;
                if (snapshot.docs.isNotEmpty) {
                  nextId = (snapshot.docs.first.data()['id'] ?? 0) + 1;
                }

                // Add new document to the finance_log collection
                await FirebaseFirestore.instance.collection('finance_log').add({
                  "id": nextId,
                  "receipt_number": receiptNumber,
                  "name": name,
                  "phone": phone,
                  "amount": amount,
                  "category": selectedCategory,
                  "date_time": now.toIso8601String(),
                  "manual_date":
                      manualDate?.toIso8601String() ?? now.toIso8601String(),
                  "type": "out",
                  "notes": notes,
                  "userName": UserSession().fullName,
                });

                // Update or create a document for the selected category in the 'finance' collection
                final categoryDocRef = FirebaseFirestore.instance
                    .collection('finance')
                    .doc(selectedCategory);

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
                    "id": categoryDocRef.id,
                    "name": selectedCategory,
                    "amount": amount,
                    "updated_at": DateTime.now().toIso8601String(),
                  });
                }

                // Update total amount in the 'الاجمالي' document in finance collection
                // await _updateTotalAmount(); // Replaced by atomic FieldValue

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("تمت إضافة الإيصال بنجاح!")),
                );
              } catch (e) {
                print("Error adding receipt: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("حدث خطأ أثناء الإضافة: $e")),
                );
              }
            },
            child: const Text("إضافة"),
          ),
        ],
      ),
    );
  }

  Future<void> _printFilteredResults(List<QueryDocumentSnapshot> logs) async {
    try {
      // Initialize totals
      int totalAmount = 0;
      int balance = 0;

      // Fetch the balance from the 'finance/الاجمالي' document
      final financeDoc = await FirebaseFirestore.instance
          .collection('finance')
          .doc('الاجمالي')
          .get();

      if (financeDoc.exists) {
        balance = (financeDoc.data()?['balance'] ?? 0) as int;
      }

      // logs is already filtered by the UI logic (search, category, date)
      // We just need to apply the same sorting here
      if (_sortByDate) {
        logs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aDate = aData['manual_date']?.toString() ?? '';
          final bDate = bData['manual_date']?.toString() ?? '';
          return bDate.compareTo(aDate);
        });
      } else {
        logs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aIdRaw = aData['receipt_number']?.toString() ?? '0';
          final bIdRaw = bData['receipt_number']?.toString() ?? '0';
          final aId =
              int.tryParse(aIdRaw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          final bId =
              int.tryParse(bIdRaw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          return aId.compareTo(bId);
        });
      }

      final buffer = StringBuffer();
      buffer.writeln('<html>');
      buffer.writeln(PrintStyle.htmlHead);
      buffer.writeln('<body>');
      buffer.writeln(PrintStyle.getHeader('إيصال الصادر'));
      buffer.writeln('<table>');
      buffer.writeln('<tr>'
          '<th>رقم الإيصال</th>'
          '<th>اسم المصدر</th>'
          '<th>رقم الهاتف</th>'
          '<th>المبلغ</th>'
          '<th>الفئة</th>'
          '<th>التاريخ</th>'
          '<th>الملاحظات</th>'
          '</tr>');

      // Generate table rows
      for (final log in logs) {
        final data = log.data() as Map<String, dynamic>;

        // Safely cast 'amount' to int
        final amount =
            (data['amount'] ?? 0) is num ? (data['amount'] as num).toInt() : 0;
        totalAmount += amount;

        buffer.writeln('<tr>'
            '<td>${data['receipt_number'] ?? 'غير معروف'}</td>'
            '<td>${data['name'] ?? 'غير معروف'}</td>'
            '<td>${data['phone'] ?? 'غير معروف'}</td>'
            '<td>$amount</td>'
            '<td>${data['category'] ?? 'غير معروف'}</td>'
            '<td>${formatDateTime(data['manual_date'])}</td>'
            '<td>${data['notes'] ?? ''}</td>'
            '</tr>');
      }

      // Append a row for the total amount
      buffer.writeln('<tr>'
          '<td colspan="3" style="font-weight: bold; text-align: center;">الإجمالي</td>'
          '<td style="font-weight: bold;">$totalAmount</td>'
          '<td colspan="3"></td>'
          '</tr>');

      // Append a row for the balance
      buffer.writeln('<tr>'
          '<td colspan="3" style="font-weight: bold; text-align: center;">الرصيد</td>'
          '<td style="font-weight: bold;">$balance</td>'
          '<td colspan="3"></td>'
          '</tr>');

      buffer.writeln('</table>');
      buffer.writeln('</body>');
      buffer.writeln('</html>');

      // Create and open the print file
      final blob = html.Blob([buffer.toString()], 'text/html');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, '_blank');
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء جدول الطباعة بنجاح')),
      );
    } catch (error) {
      print('Error generating print results: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الطباعة: $error')),
      );
    }
  }


  Future<void> _printReceipt(Map<String, dynamic> data) async {
    final buffer = StringBuffer();
    buffer.writeln('<html>');
    buffer.writeln(PrintStyle.htmlHead);
    buffer.writeln('<body>');
    buffer.writeln(PrintStyle.getHeader('إيصال الصادر'));

    // Table with centered content
    buffer.writeln('<table>');
    buffer.writeln('<tr><th>الوصف</th><th>التفاصيل</th></tr>');
    buffer.writeln(
        '<tr><td>رقم الإيصال</td><td>${data['receipt_number']}</td></tr>');
    buffer.writeln('<tr><td>اسم المصدر</td><td>${data['name']}</td></tr>');
    buffer.writeln('<tr><td>رقم الهاتف</td><td>${data['phone']}</td></tr>');
    buffer.writeln('<tr><td>المبلغ</td><td>${data['amount']}</td></tr>');
    buffer.writeln('<tr><td>الفئة</td><td>${data['category']}</td></tr>');
    buffer.writeln(
        '<tr><td>التاريخ</td><td>${formatDateTime(data['manual_date'])}</td></tr>');
    buffer
        .writeln('<tr><td>الملاحظات</td><td>${data['notes'] ?? ''}</td></tr>');
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
        final data = doc.data();
        final amount =
            (data['amount'] ?? 0) is num ? (data['amount'] as num).toInt() : 0;
        totalIn += amount;
      }

      // Fetch total "out" amount
      final outSnapshot = await FirebaseFirestore.instance
          .collection('finance_log')
          .where('type', isEqualTo: 'out')
          .get();

      for (var doc in outSnapshot.docs) {
        final data = doc.data();
        final amount =
            (data['amount'] ?? 0) is num ? (data['amount'] as num).toInt() : 0;
        totalOut += amount;
      }

      // Calculate the balance (total "in" - total "out")
      final totalBalance = totalIn - totalOut;

      // Update or create the "الإجمالي" document in the "finance" collection
      await FirebaseFirestore.instance
          .collection('finance')
          .doc('الاجمالي')
          .set({
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
    await FirebaseFirestore.instance
        .collection('finance_log')
        .doc(docId)
        .delete();
    // await _updateTotalAmount(); // Replaced by atomic FieldValue // Recalculate total amount
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف الإيصال بنجاح!')),
    );
    // Update category totals
  }

// Function to edit a document
  void _editReceipt(String docId, Map<String, dynamic> data) {
    final receiptController =
        TextEditingController(text: data['receipt_number']);
    final nameController = TextEditingController(text: data['name']);
    final phoneController = TextEditingController(text: data['phone']);
    final amountController =
        TextEditingController(text: data['amount'].toString());
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
                items: [
                  'بنك',
                  'القبض',
                  'السلفه',
                  'الايجار',
                  'كهرباء',
                  'مياة',
                  'غاز',
                  'البيان',
                  'صندوق خارجي'
                ]
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
                  decoration: const InputDecoration(labelText: "رقم الإيصال")),
              TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "اسم المصدر")),
              TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: "رقم الهاتف")),
              TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: "المبلغ"),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: noteController,
                  decoration: const InputDecoration(labelText: "الملاحظات")),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () async {
              final newAmount = int.tryParse(amountController.text.trim()) ?? 0;
              final newCategory = selectedCategory;

              // Reference to the old and new categories
              final oldCategoryRef = FirebaseFirestore.instance
                  .collection('finance')
                  .doc(data['category']);
              final newCategoryRef = FirebaseFirestore.instance
                  .collection('finance')
                  .doc(newCategory);

              // Subtract old amount from the old category
              if (data['category'] != newCategory) {
                final oldCategoryDoc = await oldCategoryRef.get();
                final oldAmount = oldCategoryDoc.data()?['amount'] ?? 0;
                await oldCategoryRef
                    .update({"amount": oldAmount - data['amount']});
              }

              // Add new amount to the new category
              final newCategoryDoc = await newCategoryRef.get();
              final newAmountTotal =
                  (newCategoryDoc.data()?['amount'] ?? 0) + newAmount;
              await newCategoryRef.set({
                "name": newCategory,
                "amount": newAmountTotal,
                "updated_at": DateTime.now().toIso8601String(),
              }, SetOptions(merge: true));

              // Update the receipt in 'finance_log'
              await FirebaseFirestore.instance
                  .collection('finance_log')
                  .doc(docId)
                  .set({
                "receipt_number": receiptController.text.trim(),
                "name": nameController.text.trim(),
                "phone": phoneController.text.trim(),
                "amount": newAmount,
                "category": newCategory,
                "notes": noteController.text.trim(),
                "userName": UserSession().fullName,
                "updated_at": DateTime.now()
                    .toIso8601String(), // Add or update the updated_at field
              }, SetOptions(merge: true));

              // Update total amounts
              // await _updateTotalAmount(); // Replaced by atomic FieldValue

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
      final formattedDate =
          intl.DateFormat('dd MMMM yyyy', 'ar').format(dateTime);
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
                      final financeLogSnapshot = await FirebaseFirestore
                          .instance
                          .collection('finance_log')
                          .where('type', isEqualTo: 'out')
                          .get();

                      final combinedLogs = financeLogSnapshot.docs;

                      // Apply filters
                      final filteredLogs = combinedLogs.where((log) {
                        final data = log.data() as Map<String, dynamic>;

                        // Filter by name, receipt number, or case_id
                        final matchesNameOrReceipt =
                            _nameOrReceiptFilter.isEmpty ||
                                data['name']
                                    .toString()
                                    .contains(_nameOrReceiptFilter) ||
                                data['receipt_number']
                                    .toString()
                                    .contains(_nameOrReceiptFilter);
                        // Filter by category
                        final matchesCategory = _selectedCategory == 'الكل' ||
                            data['category'] == _selectedCategory;

                        // Filter by date range
                        final matchesDateRange = _startDate == null ||
                            _endDate == null ||
                            (DateTime.parse(data['manual_date'])
                                        .isAtSameMomentAs(_startDate!) ||
                                    DateTime.parse(data['manual_date'])
                                        .isAfter(_startDate!)) &&
                                (DateTime.parse(data['manual_date'])
                                        .isAtSameMomentAs(_endDate!) ||
                                    DateTime.parse(data['manual_date'])
                                        .isBefore(_endDate!
                                            .add(const Duration(days: 1))));

                        return matchesNameOrReceipt &&
                            matchesCategory &&
                            matchesDateRange;
                      }).toList();

                      // Apply current sort
                      if (_sortByDate) {
                        filteredLogs.sort((a, b) {
                          final aDate = DateTime.parse(a.get('manual_date'));
                          final bDate = DateTime.parse(b.get('manual_date'));
                          return bDate.compareTo(aDate); // Newest first
                        });
                      } else {
                        filteredLogs.sort((a, b) {
                          final aId = int.tryParse(a.get('receipt_number').toString()) ?? 0;
                          final bId = int.tryParse(b.get('receipt_number').toString()) ?? 0;
                          return aId.compareTo(bId);
                        });
                      }

                      // Pass filtered logs to the print function
                      await _printFilteredResults(filteredLogs);
                    } catch (e) {
                      print("Error fetching or filtering data: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("حدث خطأ أثناء جلب البيانات")),
                      );
                    }
                  },
                  icon: const Icon(Icons.print),
                  tooltip: "طباعة النتائج",
                ),
              ],
            ),
            drawer: const AppDrawer(),
            body: Column(children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                            labelText: "الاسم أو رقم الإيصال"),
                        onChanged: (value) =>
                            setState(() => _nameOrReceiptFilter = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        items: [
                          'الكل',
                          'بنك',
                          'القبض',
                          'السلفه',
                          'الايجار',
                          'كهرباء',
                          'مياة',
                          'غاز',
                          'البيان',
                          'صندوق خارجي'
                        ]
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
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('الترتيب',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                        ToggleButtons(
                          isSelected: [_sortByDate, !_sortByDate],
                          onPressed: (index) =>
                              setState(() => _sortByDate = index == 0),
                          borderRadius: BorderRadius.circular(8),
                          selectedColor: Colors.white,
                          fillColor: Theme.of(context).primaryColor,
                          constraints:
                              const BoxConstraints(minHeight: 34, minWidth: 58),
                          children: const [
                            Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('التاريخ',
                                    style: TextStyle(fontSize: 12))),
                            Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('الرقم',
                                    style: TextStyle(fontSize: 12))),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('finance_log')
                      .where('type', isEqualTo: 'out')
                      .orderBy('manual_date')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final logs = snapshot.data?.docs ?? [];
                    final filteredLogs = logs.where((log) {
                      final data = log.data() as Map<String, dynamic>;
                      final matchesNameOrReceipt =
                          _nameOrReceiptFilter.isEmpty ||
                              data['name']
                                  .toString()
                                  .contains(_nameOrReceiptFilter) ||
                              data['receipt_number']
                                  .toString()
                                  .contains(_nameOrReceiptFilter);

                      final matchesCategory = _selectedCategory == 'الكل' ||
                          data['category'] == _selectedCategory;

                      final matchesDateRange = _startDate == null ||
                          _endDate == null ||
                          (DateTime.parse(data['manual_date'])
                                      .isAtSameMomentAs(_startDate!) ||
                                  DateTime.parse(data['manual_date'])
                                      .isAfter(_startDate!)) &&
                              (DateTime.parse(data['manual_date'])
                                      .isAtSameMomentAs(_endDate!) ||
                                  DateTime.parse(data['manual_date']).isBefore(
                                      _endDate!.add(const Duration(days: 1))));

                      return matchesNameOrReceipt &&
                          matchesCategory &&
                          matchesDateRange;
                    }).toList();

                    // Apply sort
                    if (_sortByDate) {
                      filteredLogs.sort((a, b) {
                        final aData = a.data() as Map<String, dynamic>;
                        final bData = b.data() as Map<String, dynamic>;
                        final aDate = aData['manual_date']?.toString() ?? '';
                        final bDate = bData['manual_date']?.toString() ?? '';
                        return bDate.compareTo(aDate); // newest first
                      });
                    } else {
                      filteredLogs.sort((a, b) {
                        final aData = a.data() as Map<String, dynamic>;
                        final bData = b.data() as Map<String, dynamic>;
                        final aIdRaw =
                            aData['receipt_number']?.toString() ?? '0';
                        final bIdRaw =
                            bData['receipt_number']?.toString() ?? '0';
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
                      itemCount: filteredLogs.length,
                      itemBuilder: (context, index) {
                        final log =
                            filteredLogs[index].data() as Map<String, dynamic>;
                        final docId = filteredLogs[index].id;

                        final amount = log['amount'] ?? 0;
                        final category = log['category'] ?? '---';
                        final dateTime = log['manual_date'] ?? '';

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          child: ListTile(
                            title: Text(
                                "رقم الإيصال: ${log['receipt_number'] ?? '---'}"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("اسم المصدر: ${log['name']}"),
                                Text("رقم الهاتف: ${log['phone']}"),
                                Text("المبلغ: $amount"),
                                Text("الفئة: $category"),
                                Text("التاريخ: ${formatDateTime(dateTime)}"),
                                Text("ملاحظات: ${log['notes'] ?? ''}"),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.print,
                                      color: Colors.teal),
                                  onPressed: () => _printReceipt(log),
                                  tooltip: "طباعة",
                                ),
                                // Edit and Delete
                                if (UserSession().isAdmin || UserSession().isModerator)
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () => _editReceipt(docId, log),
                                    tooltip: "تعديل",
                                  ),
                                if (UserSession().isAdmin)
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
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
            ])));
  }
}
