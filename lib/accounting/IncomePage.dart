import 'package:berwehsan/widgets/accounting_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:html' as html;

class IncomePage extends StatefulWidget {
  const IncomePage({Key? key}) : super(key: key);

  @override
  _IncomePageState createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  String _nameOrReceiptFilter = '';
  String _selectedCategory = 'الكل';
  DateTime? _startDate;
  DateTime? _endDate;

void _addReceipt() async {
  final receiptController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  DateTime? manualDate;
  String selectedCategory = 'الكفالات';
  String? selectedSubName;
  String? selectedSubId;
  List<String> selectedMonths = [];  // List to hold selected months

  // Fetch subs from the Firestore database
  List<Map<String, dynamic>> subs = [];
  try {
    final subsSnapshot = await FirebaseFirestore.instance.collection('subs').get();
    subs = subsSnapshot.docs
        .map((doc) => {
              'id': doc.id,
              'name': doc.data()['name'] as String,
            })
        .toList();
  } catch (e) {
    print('Error fetching subs: $e');
  }

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text("إضافة إيصال جديد"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedCategory,
                  items: ['الكفالات', 'التبرعات', 'الاشتراكات', 'بنك', 'صندوق خارجي']
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value!;
                    selectedSubName = null; // Reset sub-name if category changes
                  });
                },
                decoration: const InputDecoration(labelText: "الفئة"),
              ),
              TextField(
                controller: receiptController,
                decoration: const InputDecoration(labelText: "رقم الإيصال"),
              ),
              if (selectedCategory == 'الكفالات')
                buildSingleSelectDropdown(
                  'اختر اسم الكفالة',
                  subs,
                  selectedSubId,
                  (value) {
                    setState(() {
                      selectedSubId = value;
                      selectedSubName = subs
                          .firstWhere((sub) => sub['id'] == value)['name'];
                    });
                  },
                )
              else
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
                    setState(() {
                      manualDate = pickedDate;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'تم اختيار التاريخ: ${intl.DateFormat.yMMMd().format(manualDate!)}')),
                    );
                  }
                },
                child: const Text("اختيار تاريخ يدوي"),
              ),
              // Multi-month selection
              if (selectedCategory == 'الكفالات')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("اختر الأشهر:", style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<String>(
                    value: null, // Ensure it's initialized with `null` for multi-selection
                    items: List.generate(12, (index) {
                      final month = intl.DateFormat('MMMM', 'ar').format(DateTime(2020, index + 1));
                      return DropdownMenuItem(
                        value: month,
                        child: Text(month),
                      );
                    }),
                    onChanged: (String? selectedMonth) {
                      if (selectedMonth != null && !selectedMonths.contains(selectedMonth)) {
                        setState(() {
                          selectedMonths.add(selectedMonth);
                        });
                      }
                    },
                    isExpanded: true,
                    decoration: const InputDecoration(
                      hintText: "حدد الأشهر",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                  spacing: 8.0,
                  children: List.generate(12, (index) {
                    final month = intl.DateFormat('MMMM', 'ar').format(DateTime(2020, index + 1));
                    final isSelected = selectedMonths.contains(month);
                    return FilterChip(
                      label: Text(month),
                      selected: isSelected,
                      onSelected: (bool isSelected) {
                        setState(() {
                          if (isSelected) {
                            selectedMonths.add(month);
                          } else {
                            selectedMonths.remove(month);
                          }
                        });
                      },
                    );
                  }),
                ),
                ],
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
              final name = selectedCategory == 'الكفالات'
                  ? selectedSubName
                  : nameController.text.trim();
              final phone = phoneController.text.trim();
              final amount = int.tryParse(amountController.text.trim());
              final notes = noteController.text.trim();
              final now = DateTime.now();

              


              // Conditional validation
              if (receiptNumber.isEmpty || name == null || amount == null || 
                  (selectedCategory == 'الكفالات' && selectedMonths.isEmpty)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("يرجى ملء جميع الحقول المطلوبة.")),
                );
                return;
              }


              try {
                // Fetch next id safely
                final snapshot = await FirebaseFirestore.instance
                    .collection('finance_log')
                    .orderBy('id', descending: true)
                    .limit(1)
                    .get();

                int nextId = 1;
                if (snapshot.docs.isNotEmpty) {
                  nextId = (snapshot.docs.first.data()['id'] ?? 0) + 1;
                }

                // Add the new document to finance_log
                // After successfully adding the new document to finance_log
                  await FirebaseFirestore.instance.collection('finance_log').add({
                    "id": nextId,
                    "receipt_number": receiptNumber,
                    "name": name,
                    "phone": phone,
                    "amount": amount,
                    "category": selectedCategory,
                    "date_time": now.toIso8601String(),
                    "manual_date": manualDate?.toIso8601String() ?? now.toIso8601String(),
                    "type": "in",
                    "notes": notes,
                  });

                  // Call to update total amount
                  await _updateTotalAmount(); // Recalculate total balance

                // Update subs collection if category is الكفالات
                  if (selectedCategory == 'الكفالات' && selectedSubId != null) {
                    try {
                      final subDocRef = FirebaseFirestore.instance.collection('subs').doc(selectedSubId);
                      final subDocSnapshot = await subDocRef.get();

                      final receiptDate = manualDate ?? now;
                      final receiptYear = receiptDate.year.toString();

                      for (var month in selectedMonths) {
                        final monthIndex = intl.DateFormat('MMMM', 'ar').parse(month).month.toString();

                        Map<String, dynamic> updateData = {};

                        if (subDocSnapshot.exists) {
                          Map<String, dynamic> subData = subDocSnapshot.data() as Map<String, dynamic>;

                          subData[receiptYear] ??= {};
                          subData[receiptYear][monthIndex] ??= [];

                          (subData[receiptYear][monthIndex] as List).add({
                            "receipt_number": receiptNumber,
                            "amount": amount,
                          });

                          updateData = {receiptYear: subData[receiptYear]};
                        } else {
                          updateData = {
                            receiptYear: {
                              monthIndex: [
                                {
                                  "receipt_number": receiptNumber,
                                  "amount": amount,
                                }
                              ]
                            }
                          };
                        }

                        await subDocRef.set(updateData, SetOptions(merge: true));
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("تم تحديث الكفالة بنجاح")),
                      );
                    } catch (e) {
                      print("Error updating subs collection: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("حدث خطأ أثناء تحديث الكفالة: $e")),
                      );
                    }
                  }

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
    ),
  );
}


Widget buildSingleSelectDropdown(
    String label,
    List<Map<String, dynamic>> items,
    String? selectedItem,
    Function(String?) onItemSelected,
  ) {
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








  Future<void> _printFilteredResults(List<QueryDocumentSnapshot> logs) async {
  try {
    // Initialize totals
    int totalAmount = 0; 
    int balance = 0;
    
    await _updateTotalAmount(); // Recalculate total balance

    // Fetch the balance from the 'finance/الاجمالي' document
    final financeDoc = await FirebaseFirestore.instance
        .collection('finance')
        .doc('الاجمالي')
        .get();

    if (financeDoc.exists) {
      balance = (financeDoc.data()?['balance'] ?? 0) as int; 
    }

    // Sort logs by manual_date
    logs.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;

      // Extract manual_date
      final aDate = DateTime.parse(aData['manual_date']?.toString() ?? '');
      final bDate = DateTime.parse(bData['manual_date']?.toString() ?? '');

      return aDate.compareTo(bDate);
    });


    final buffer = StringBuffer();
    buffer.writeln('<html>');
    buffer.writeln('<head>');
    buffer.writeln('<meta charset="UTF-8">');
    buffer.writeln('<style>');
    buffer.writeln('table { width: 100%; border-collapse: collapse; margin-top: 20px; }');
    buffer.writeln('th, td { border: 1px solid black; padding: 8px; text-align: center; }');
    buffer.writeln('th { background-color: #f2f2f2; font-size: 18px; }');
    buffer.writeln('td { font-size: 16px; }');
    buffer.writeln('</style>');
    buffer.writeln('</head>');
    buffer.writeln('<body style="direction: rtl; font-family: Arial, sans-serif;">');
    buffer.writeln('<h1 style="text-align: center;">سجل الوارد</h1>');
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
      final amount = (data['amount'] ?? 0) is num ? (data['amount'] as num).toInt() : 0;
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
  buffer.writeln('<h1>إيصال الوارد</h1>');

  // Table with centered content
  buffer.writeln('<table>');
  buffer.writeln('<tr><th>الوصف</th><th>التفاصيل</th></tr>');
  buffer.writeln('<tr><td>رقم الإيصال</td><td>${data['receipt_number']}</td></tr>');
  buffer.writeln('<tr><td>اسم المصدر</td><td>${data['name']}</td></tr>');
  buffer.writeln('<tr><td>رقم الهاتف</td><td>${data['phone']}</td></tr>');
  buffer.writeln('<tr><td>المبلغ</td><td>${data['amount']}</td></tr>');
  buffer.writeln('<tr><td>الفئة</td><td>${data['category']}</td></tr>');
  buffer.writeln('<tr><td>التاريخ</td><td>${formatDateTime(data['manual_date'])}</td></tr>');
  buffer.writeln('<tr><td>الملاحظات</td><td>${data['notes'] ?? ''}</td></tr>');
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












  String formatDateTime(String isoDate) {
    final dateTime = DateTime.parse(isoDate);
    final formattedDate = intl.DateFormat('dd MMMM yyyy', 'ar').format(dateTime);
    final formattedTime = intl.DateFormat('HH:mm').format(dateTime);
    return "$formattedDate - $formattedTime";
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("سجل الوارد"),
          actions: [
             IconButton(
              onPressed: _addReceipt,
              icon: const Icon(Icons.add),
              tooltip: "إضافة إيصال جديد",
            ),
            IconButton(
              onPressed: () async {
                final snapshot = await FirebaseFirestore.instance
                    .collection('finance_log')
                    .where('type', isEqualTo: 'in')
                    .get();
                final filteredLogs = snapshot.docs.where((log) {
                  final data = log.data() as Map<String, dynamic>;
                  final matchesNameOrReceipt = _nameOrReceiptFilter.isEmpty ||
                      data['name'].toString().contains(_nameOrReceiptFilter) ||
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
                              DateTime.parse(data['manual_date'])
                                  .isBefore(_endDate!.add(Duration(days: 1))));

                  return matchesNameOrReceipt &&
                      matchesCategory &&
                      matchesDateRange;
                }).toList();

                await _printFilteredResults(filteredLogs);
              },
              icon: const Icon(Icons.print),
              tooltip: "طباعة النتائج",
            ),
          ],
        ),
        drawer: AccountingDrawer(),
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
                        items: ['الكل', 'الكفالات', 'التبرعات', 'الاشتراكات', 'بنك', 'صندوق خارجي']
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
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                  .collection('finance_log')
                  .where('type', isEqualTo: 'in')
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
                    final matchesNameOrReceipt = _nameOrReceiptFilter.isEmpty ||
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
                                DateTime.parse(data['manual_date'])
                                    .isBefore(_endDate!
                                        .add(const Duration(days: 1))));

                    return matchesNameOrReceipt &&
                        matchesCategory &&
                        matchesDateRange;
                  }).toList();

                  return ListView.builder(
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                     final log = filteredLogs[index].data() as Map<String, dynamic>;
                     final docId = filteredLogs[index].id;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        child: ListTile(
                          title: Text("رقم الإيصال: ${log['receipt_number']}"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("اسم المصدر: ${log['name']}"),
                              Text("رقم الهاتف: ${log['phone']}"),
                              Text("المبلغ: ${log['amount']}"),
                              Text("الفئة: ${log['category']}"),
                              Text("التاريخ: ${formatDateTime(log['manual_date'])}"),
                              Text("ملاحظات: ${log['notes'] ?? ''}"),
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