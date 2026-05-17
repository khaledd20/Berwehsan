import 'package:berwehsan/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:berwehsan/core/user_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:berwehsan/core/print_style.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:html' as html;

class IncomePage extends StatefulWidget {
  const IncomePage({super.key});

  @override
  _IncomePageState createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  String _nameOrReceiptFilter = '';
  String _selectedCategory = 'الكل';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _sortByDate = true; // true = sort by date (default), false = sort by id

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
    List<Map<String, dynamic>> selectedPeriods =
        []; // List of {'year': 2026, 'month': 12}
    int currentSelectedYear = DateTime.now().year;

    // Fetch subs from the Firestore database
    List<Map<String, dynamic>> subs = [];
    try {
      final subsSnapshot =
          await FirebaseFirestore.instance.collection('subs').get();
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
        builder: (context, setState) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text("إضافة إيصال جديد"),
              content: SizedBox(
                  width: 400,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          items: [
                            'الكفالات',
                            'التبرعات',
                            'الاشتراكات',
                            'بنك',
                            'صندوق خارجي'
                          ]
                              .map((category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCategory = value!;
                              selectedSubName =
                                  null; // Reset sub-name if category changes
                            });
                          },
                          decoration: const InputDecoration(labelText: "الفئة"),
                        ),
                        TextField(
                          controller: receiptController,
                          decoration:
                              const InputDecoration(labelText: "رقم الإيصال"),
                        ),
                        if (selectedCategory == 'الكفالات') ...[
                          const Divider(),
                          buildSingleSelectDropdown(
                            'اختر الكفيل',
                            subs,
                            selectedSubId,
                            (value) {
                              setState(() {
                                selectedSubId = value;
                                selectedSubName = subs.firstWhere(
                                    (sub) => sub['id'] == value)['name'];
                              });
                            },
                          ),
                        ] else
                          TextField(
                            controller: nameController,
                            decoration:
                                const InputDecoration(labelText: "اسم المصدر"),
                          ),
                        TextField(
                          controller: phoneController,
                          decoration:
                              const InputDecoration(labelText: "رقم الهاتف"),
                          keyboardType: TextInputType.phone,
                        ),
                        TextField(
                          controller: amountController,
                          decoration:
                              const InputDecoration(labelText: "المبلغ"),
                          keyboardType: TextInputType.number,
                        ),
                        TextField(
                          controller: noteController,
                          decoration:
                              const InputDecoration(labelText: "الملاحظات"),
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
                        // Multi-year/month selection
                        if (selectedCategory == 'الكفالات')
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(),
                              // Selected periods summary
                              if (selectedPeriods.isNotEmpty) ...[
                                const Text("الأشهر المختارة:",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                        fontSize: 13)),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 4.0,
                                  runSpacing: 2.0,
                                  children: selectedPeriods.map((period) {
                                    final monthName =
                                        intl.DateFormat('MMM', 'ar').format(
                                            DateTime(2020, period['month']));
                                    return Chip(
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      label: Text(
                                          "$monthName ${period['year']}",
                                          style: const TextStyle(fontSize: 11)),
                                      onDeleted: () {
                                        setState(() {
                                          selectedPeriods.remove(period);
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 8),
                              ],
                              // Dynamic Year Selector (Horizontal Scroll)
                              const Text("السنة:",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                              const SizedBox(height: 4),
                              SizedBox(
                                height: 40,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: 10,
                                  itemBuilder: (context, i) {
                                    final year = DateTime.now().year - 2 + i;
                                    final isYearSelected =
                                        currentSelectedYear == year;
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: ChoiceChip(
                                        label: Text(year.toString()),
                                        selected: isYearSelected,
                                        onSelected: (selected) {
                                          if (selected) {
                                            setState(() =>
                                                currentSelectedYear = year);
                                          }
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Compact Month Grid
                              const Text("الأشهر:",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                              const SizedBox(height: 4),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  childAspectRatio: 2.2,
                                  crossAxisSpacing: 4,
                                  mainAxisSpacing: 4,
                                ),
                                itemCount: 12,
                                itemBuilder: (context, index) {
                                  final monthIdx = index + 1;
                                  final monthName = intl.DateFormat('MMM', 'ar')
                                      .format(DateTime(2020, monthIdx));
                                  final isSelected = selectedPeriods.any((p) =>
                                      p['year'] == currentSelectedYear &&
                                      p['month'] == monthIdx);
                                  return FilterChip(
                                    padding: EdgeInsets.zero,
                                    label: Center(
                                        child: Text(monthName,
                                            style:
                                                const TextStyle(fontSize: 12))),
                                    selected: isSelected,
                                    showCheckmark: false,
                                    onSelected: (bool selected) {
                                      setState(() {
                                        if (selected) {
                                          selectedPeriods.add({
                                            'year': currentSelectedYear,
                                            'month': monthIdx
                                          });
                                          // Sort periods for better display
                                          selectedPeriods.sort((a, b) {
                                            if (a['year'] != b['year'])
                                              return a['year']
                                                  .compareTo(b['year']);
                                            return a['month']
                                                .compareTo(b['month']);
                                          });
                                        } else {
                                          selectedPeriods.removeWhere((p) =>
                                              p['year'] ==
                                                  currentSelectedYear &&
                                              p['month'] == monthIdx);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
                  )),
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
                    if (receiptNumber.isEmpty ||
                        name == null ||
                        amount == null ||
                        (selectedCategory == 'الكفالات' &&
                            selectedPeriods.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("يرجى ملء جميع الحقول المطلوبة.")),
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
                      await FirebaseFirestore.instance
                          .collection('finance_log')
                          .add({
                        "id": nextId,
                        "receipt_number": receiptNumber,
                        "name": name,
                        "phone": phone,
                        "amount": amount,
                        "category": selectedCategory,
                        "date_time": now.toIso8601String(),
                        "manual_date": manualDate?.toIso8601String() ??
                            now.toIso8601String(),
                        "type": "in",
                        "notes": notes,
                        "sub_id": selectedSubId,
                        "selected_periods": selectedPeriods,
                        "userName": UserSession().fullName,
                      });

                      // Update subs collection if category is الكفالات
                      if (selectedCategory == 'الكفالات' &&
                          selectedSubId != null) {
                        try {
                          final subDocRef = FirebaseFirestore.instance
                              .collection('subs')
                              .doc(selectedSubId);

                          final subDocSnapshot = await subDocRef.get();
                          Map<String, dynamic> subData = subDocSnapshot.exists
                              ? subDocSnapshot.data() as Map<String, dynamic>
                              : {};

                          for (var period in selectedPeriods) {
                            final year = period['year'].toString();
                            final monthIndex = period['month'].toString();

                            subData[year] ??= {};
                            subData[year][monthIndex] ??= [];

                            (subData[year][monthIndex] as List).add({
                              "receipt_number": receiptNumber,
                              "amount": amount,
                            });
                          }

                          await subDocRef.set(subData, SetOptions(merge: true));

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("تم تحديث الكفالة بنجاح")),
                          );
                        } catch (e) {
                          print("Error updating subs collection: $e");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text("حدث خطأ أثناء تحديث الكفالة: $e")),
                          );
                        }
                      }

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("تمت إضافة الإيصال بنجاح!")),
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
            )),
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
    List<Map<String, dynamic>> filteredItems =
        items; // Initially show all items

    return StatefulBuilder(
      builder: (context, setState) {
        // Find currently selected item name for display
        String? selectedName;
        if (selectedItem != null) {
          final match = items.where((item) => item['id'] == selectedItem);
          if (match.isNotEmpty) {
            selectedName = match.first['name'] as String?;
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header row with label
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_search,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text(label,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const Spacer(),
                      if (selectedName != null)
                        Flexible(
                          child: Text(
                            selectedName,
                            style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
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

                // Items List (filteredItems) in a constrained container
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: ListView(
                    shrinkWrap: true,
                    children: filteredItems.map((item) {
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
                  ),
                ),
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
      buffer.writeln(PrintStyle.getHeader('جدول الوارد'));
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
    buffer.writeln(PrintStyle.getHeader('إيصال الوارد'));

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
    try {
      final doc = await FirebaseFirestore.instance
          .collection('finance_log')
          .doc(docId)
          .get();
      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>;

      // If it's a sponsorship, we must remove it from the 'subs' document
      if (data['category'] == 'الكفالات' && data['sub_id'] != null) {
        final subDocRef = FirebaseFirestore.instance
            .collection('subs')
            .doc(data['sub_id'].toString());
        final subDoc = await subDocRef.get();

        if (subDoc.exists) {
          final subData = subDoc.data() as Map<String, dynamic>;
          final periods = List<Map<String, dynamic>>.from(
              data['selected_periods'] ?? []);

          for (var p in periods) {
            final year = p['year'].toString();
            final month = p['month'].toString();

            if (subData.containsKey(year) && subData[year].containsKey(month)) {
              List receipts = List.from(subData[year][month]);
              receipts.removeWhere(
                  (r) => r['receipt_number'] == data['receipt_number']);

              if (receipts.isEmpty) {
                await subDocRef.update({
                  "$year.$month": FieldValue.delete(),
                });
              } else {
                await subDocRef.update({
                  "$year.$month": receipts,
                });
              }
            }
          }
        }
      }

      await FirebaseFirestore.instance
          .collection('finance_log')
          .doc(docId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الإيصال بنجاح!')),
      );
    } catch (e) {
      print("Error deleting receipt: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الحذف: $e')),
      );
    }
  }

// Function to edit a document
  void _editReceipt(String docId, Map<String, dynamic> data) async {
    final receiptController =
        TextEditingController(text: data['receipt_number']);
    final nameController = TextEditingController(text: data['name']);
    final phoneController = TextEditingController(text: data['phone']);
    final amountController =
        TextEditingController(text: data['amount'].toString());
    final noteController = TextEditingController(text: data['notes'] ?? '');
    DateTime? manualDate = DateTime.tryParse(data['manual_date']);
    String selectedCategory = data['category'];
    String? selectedSubId;
    String? selectedSubName;
    List<Map<String, dynamic>> selectedPeriods = [];
    int currentSelectedYear = DateTime.now().year;

    // Fetch subs from the Firestore database
    List<Map<String, dynamic>> subs = [];
    try {
      final subsSnapshot =
          await FirebaseFirestore.instance.collection('subs').get();
      subs = subsSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                'name': doc.data()['name'] as String,
              })
          .toList();
    } catch (e) {
      print('Error fetching subs: $e');
    }

    // Retrieve existing selectedPeriods and selectedSubName from finance_log or Firestore
    if (selectedCategory == 'الكفالات') {
      if (data.containsKey('selected_periods') &&
          data['selected_periods'] != null) {
        final rawPeriods =
            List<Map<String, dynamic>>.from(data['selected_periods']);
        // Normalize: ensure year and month are ints (handle legacy string-based formats)
        selectedPeriods = rawPeriods.map((p) {
          var year = p['year'];
          var month = p['month'];
          // Convert year to int if it's a string
          if (year is String) year = int.tryParse(year) ?? DateTime.now().year;
          // Convert month: if it's a string name, parse it; if numeric string, parse it
          if (month is String) {
            final parsed = int.tryParse(month);
            if (parsed != null) {
              month = parsed;
            } else {
              // It's an Arabic month name — parse it
              try {
                month = intl.DateFormat('MMMM', 'ar').parse(month).month;
              } catch (_) {
                month = 1;
              }
            }
          }
          return {'year': year, 'month': month};
        }).toList();
        selectedSubId = data['sub_id'];
        selectedSubName = data['name'];
      } else {
        // Fallback for legacy data
        try {
          final subDocRef =
              FirebaseFirestore.instance.collection('subs').doc(data['sub_id']);
          final subDocSnapshot = await subDocRef.get();

          if (subDocSnapshot.exists) {
            final subData = subDocSnapshot.data() as Map<String, dynamic>;

            // Scan all year keys in the sub document to find stored periods for this receipt
            subData.forEach((key, value) {
              if (value is Map && RegExp(r'^\d{4}$').hasMatch(key)) {
                (value as Map<String, dynamic>).forEach((monthKey, monthValue) {
                  if (monthValue is List) {
                    final hasReceipt = monthValue.any((r) =>
                        r is Map &&
                        r['receipt_number'] == data['receipt_number']);
                    if (hasReceipt) {
                      selectedPeriods.add({
                        'year': int.parse(key),
                        'month': int.parse(monthKey)
                      });
                    }
                  }
                });
              }
            });

            selectedSubId = data['sub_id'];
            selectedSubName = subData['name'];
          }
        } catch (e) {
          print('Error retrieving sub data: $e');
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text("تعديل الإيصال"),
              content: SizedBox(
                  width: 400,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          items: [
                            'الكفالات',
                            'التبرعات',
                            'الاشتراكات',
                            'بنك',
                            'صندوق خارجي'
                          ]
                              .map((category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCategory = value!;
                              selectedSubName =
                                  null; // Reset sub-name if category changes
                            });
                          },
                          decoration: const InputDecoration(labelText: "الفئة"),
                        ),
                        TextField(
                          controller: receiptController,
                          decoration:
                              const InputDecoration(labelText: "رقم الإيصال"),
                        ),
                        if (selectedCategory == 'الكفالات') ...[
                          const Divider(),
                          buildSingleSelectDropdown(
                            'اختر الكفيل',
                            subs,
                            selectedSubId,
                            (value) {
                              setState(() {
                                selectedSubId = value;
                                selectedSubName = subs.firstWhere(
                                    (sub) => sub['id'] == value)['name'];
                              });
                            },
                          ),
                        ] else
                          TextField(
                            controller: nameController,
                            decoration:
                                const InputDecoration(labelText: "اسم المصدر"),
                          ),
                        TextField(
                          controller: phoneController,
                          decoration:
                              const InputDecoration(labelText: "رقم الهاتف"),
                          keyboardType: TextInputType.phone,
                        ),
                        TextField(
                          controller: amountController,
                          decoration:
                              const InputDecoration(labelText: "المبلغ"),
                          keyboardType: TextInputType.number,
                        ),
                        TextField(
                          controller: noteController,
                          decoration:
                              const InputDecoration(labelText: "الملاحظات"),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: manualDate ?? DateTime.now(),
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
                                      'تم اختيار التاريخ: ${intl.DateFormat.yMMMd().format(pickedDate)}'),
                                ),
                              );
                            }
                          },
                          child: const Text("اختيار تاريخ يدوي"),
                        ),
                        // Multi-year/month selection
                        if (selectedCategory == 'الكفالات')
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(),
                              // Selected periods summary
                              if (selectedPeriods.isNotEmpty) ...[
                                const Text("الأشهر المختارة:",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                        fontSize: 13)),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 4.0,
                                  runSpacing: 2.0,
                                  children: selectedPeriods.map((period) {
                                    final monthName =
                                        intl.DateFormat('MMM', 'ar').format(
                                            DateTime(2020, period['month']));
                                    return Chip(
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      label: Text(
                                          "$monthName ${period['year']}",
                                          style: const TextStyle(fontSize: 11)),
                                      onDeleted: () {
                                        setState(() {
                                          selectedPeriods.remove(period);
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 8),
                              ],
                              // Dynamic Year Selector (Horizontal Scroll)
                              const Text("السنة:",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                              const SizedBox(height: 4),
                              SizedBox(
                                height: 40,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: 10,
                                  itemBuilder: (context, i) {
                                    final year = DateTime.now().year - 2 + i;
                                    final isYearSelected =
                                        currentSelectedYear == year;
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: ChoiceChip(
                                        label: Text(year.toString()),
                                        selected: isYearSelected,
                                        onSelected: (selected) {
                                          if (selected) {
                                            setState(() =>
                                                currentSelectedYear = year);
                                          }
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Compact Month Grid
                              const Text("الأشهر:",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                              const SizedBox(height: 4),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  childAspectRatio: 2.2,
                                  crossAxisSpacing: 4,
                                  mainAxisSpacing: 4,
                                ),
                                itemCount: 12,
                                itemBuilder: (context, index) {
                                  final monthIdx = index + 1;
                                  final monthName = intl.DateFormat('MMM', 'ar')
                                      .format(DateTime(2020, monthIdx));
                                  final isSelected = selectedPeriods.any((p) =>
                                      p['year'] == currentSelectedYear &&
                                      p['month'] == monthIdx);
                                  return FilterChip(
                                    padding: EdgeInsets.zero,
                                    label: Center(
                                        child: Text(monthName,
                                            style:
                                                const TextStyle(fontSize: 12))),
                                    selected: isSelected,
                                    showCheckmark: false,
                                    onSelected: (bool selected) {
                                      setState(() {
                                        if (selected) {
                                          selectedPeriods.add({
                                            'year': currentSelectedYear,
                                            'month': monthIdx
                                          });
                                          // Sort periods for better display
                                          selectedPeriods.sort((a, b) {
                                            if (a['year'] != b['year'])
                                              return a['year']
                                                  .compareTo(b['year']);
                                            return a['month']
                                                .compareTo(b['month']);
                                          });
                                        } else {
                                          selectedPeriods.removeWhere((p) =>
                                              p['year'] ==
                                                  currentSelectedYear &&
                                              p['month'] == monthIdx);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
                  )),
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
                    if (receiptNumber.isEmpty ||
                        name == null ||
                        amount == null ||
                        (selectedCategory == 'الكفالات' &&
                            selectedPeriods.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("يرجى ملء جميع الحقول المطلوبة.")),
                      );
                      return;
                    }

                    try {
                      // Update the receipt in Firestore (finance_log)
                      await FirebaseFirestore.instance
                          .collection('finance_log')
                          .doc(docId)
                          .update({
                        "receipt_number": receiptNumber,
                        "name": name,
                        "phone": phone,
                        "amount": amount,
                        "category": selectedCategory,
                        "manual_date": manualDate?.toIso8601String() ??
                            now.toIso8601String(),
                        "notes": notes,
                        "sub_id": selectedSubId,
                        "selected_periods": selectedPeriods,
                        "userName": UserSession().fullName,
                      });

                      // Update subs collection if category is الكفالات
                      if (selectedCategory == 'الكفالات' &&
                          selectedSubId != null) {
                        try {
                          final String oldSubId =
                              data['sub_id']?.toString() ?? "";
                          final String newSubId = selectedSubId.toString();

                          // If the Sub ID has changed, we must remove the receipt from the old sub first
                          if (oldSubId.isNotEmpty && oldSubId != newSubId) {
                            final oldSubRef = FirebaseFirestore.instance
                                .collection('subs')
                                .doc(oldSubId);
                            final oldSubSnap = await oldSubRef.get();
                            if (oldSubSnap.exists) {
                              Map<String, dynamic> oldSubData =
                                  oldSubSnap.data() as Map<String, dynamic>;
                              final oldPeriods = data['selected_periods'] !=
                                      null
                                  ? List<Map<String, dynamic>>.from(
                                      data['selected_periods'])
                                  : [];

                              for (var oldP in oldPeriods) {
                                final year = oldP['year'].toString();
                                final month = oldP['month'].toString();
                                if (oldSubData.containsKey(year) &&
                                    oldSubData[year].containsKey(month)) {
                                  List receipts =
                                      List.from(oldSubData[year][month]);
                                  receipts.removeWhere((r) =>
                                      r['receipt_number'] ==
                                      data['receipt_number']);
                                  if (receipts.isEmpty) {
                                    await oldSubRef.update({
                                      "$year.$month": FieldValue.delete(),
                                    });
                                  } else {
                                    await oldSubRef.update({
                                      "$year.$month": receipts,
                                    });
                                  }
                                }
                              }
                            }
                          }

                          // Now update/add to the new sub (or same sub if didn't change)
                          final subDocRef = FirebaseFirestore.instance
                              .collection('subs')
                              .doc(newSubId);
                          final subDocSnapshot = await subDocRef.get();
                          Map<String, dynamic> subData = subDocSnapshot.exists
                              ? subDocSnapshot.data() as Map<String, dynamic>
                              : {};

                          // If same sub, we still need to remove periods that are no longer selected
                          if (oldSubId == newSubId) {
                            final oldPeriods = data['selected_periods'] != null
                                ? List<Map<String, dynamic>>.from(
                                    data['selected_periods'])
                                : [];

                            for (var oldP in oldPeriods) {
                              final stillSelected = selectedPeriods.any((newP) =>
                                  newP['year'] == oldP['year'] &&
                                  newP['month'] == oldP['month']);

                              if (!stillSelected) {
                                final year = oldP['year'].toString();
                                final monthIndex = oldP['month'].toString();
                                if (subData.containsKey(year) &&
                                    subData[year].containsKey(monthIndex)) {
                                  List receipts =
                                      List.from(subData[year][monthIndex]);
                                  receipts.removeWhere((r) =>
                                      r['receipt_number'] ==
                                      data['receipt_number']);
                                  if (receipts.isEmpty) {
                                    await subDocRef.update({
                                      "$year.$monthIndex": FieldValue.delete(),
                                    });
                                  } else {
                                    await subDocRef.update({
                                      "$year.$monthIndex": receipts,
                                    });
                                  }
                                  final upSnap = await subDocRef.get();
                                  subData =
                                      upSnap.data() as Map<String, dynamic>;
                                }
                              }
                            }
                          }

                          // Add/Update current periods in the (potentially new) sub
                          for (var period in selectedPeriods) {
                            final year = period['year'].toString();
                            final monthIndex = period['month'].toString();

                            List receipts = [];
                            if (subData.containsKey(year) &&
                                subData[year].containsKey(monthIndex)) {
                              receipts = List.from(subData[year][monthIndex]);
                            }

                            // Use the NEW receipt number from the controller
                            final index = receipts.indexWhere(
                                (r) => r['receipt_number'] == receiptNumber);
                            if (index != -1) {
                              receipts[index] = {
                                "receipt_number": receiptNumber,
                                "amount": amount,
                              };
                            } else {
                              receipts.add({
                                "receipt_number": receiptNumber,
                                "amount": amount,
                              });
                            }

                            await subDocRef.set({
                              year: {monthIndex: receipts}
                            }, SetOptions(merge: true));

                            final upSnap = await subDocRef.get();
                            subData = upSnap.data() as Map<String, dynamic>;
                          }
                        } catch (e) {
                          print("Error updating subs collection: $e");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text("حدث خطأ أثناء تحديث الكفالة: $e")),
                          );
                        }
                      }

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('تم تحديث الإيصال بنجاح!')),
                      );
                    } catch (e) {
                      print("Error updating receipt: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("حدث خطأ أثناء التحديث: $e")),
                      );
                    }
                  },
                  child: const Text("حفظ"),
                ),
              ],
            )),
      ),
    );
  }

  String formatDateTime(String isoDate) {
    final dateTime = DateTime.parse(isoDate);
    final formattedDate =
        intl.DateFormat('dd MMMM yyyy', 'ar').format(dateTime);
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
                      final data = log.data();
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

                    await _printFilteredResults(filteredLogs);
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
                          'الكفالات',
                          'التبرعات',
                          'الاشتراكات',
                          'بنك',
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

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          child: ListTile(
                            title:
                                Text("رقم الإيصال: ${log['receipt_number']}"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("اسم المصدر: ${log['name']}"),
                                Text("رقم الهاتف: ${log['phone']}"),
                                Text("المبلغ: ${log['amount']}"),
                                Text("الفئة: ${log['category']}"),
                                Text(
                                    "التاريخ: ${formatDateTime(log['manual_date'])}"),
                                Text("ملاحظات: ${log['notes'] ?? ''}"),
                                if (log['category'] == 'الكفالات' &&
                                    log['selected_periods'] != null) ...[
                                  const SizedBox(height: 4),
                                  const Text("الأشهر المكفولة:",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue)),
                                  Wrap(
                                    spacing: 4,
                                    children: (log['selected_periods'] as List)
                                        .map((p) {
                                      final month = p['month'];
                                      final year = p['year'];
                                      final monthName =
                                          intl.DateFormat('MMM', 'ar')
                                              .format(DateTime(2020, month));
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                              color: Colors.blue.shade200),
                                        ),
                                        child: Text("$monthName $year",
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.blue)),
                                      );
                                    }).toList(),
                                  ),
                                ],
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
