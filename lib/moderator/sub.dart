import 'package:berwehsan/moderator/insertSub.dart';
import 'package:berwehsan/widgets/moderator_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html;
import 'package:intl/intl.dart' as intl;

class SubsPage extends StatefulWidget {
  @override
  _SubsPageState createState() => _SubsPageState();
}

class _SubsPageState extends State<SubsPage> {
  List<Map<String, dynamic>> subs = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchSubs();
  }

Future<void> fetchSubs() async {
  try {
    Query query = FirebaseFirestore.instance.collection('subs').orderBy('id'); // Default query to order by ID.

    // Check if the search query is not empty.
    if (searchQuery.isNotEmpty) {
      // Check if the search query can be parsed as an integer.
      final parsedId = int.tryParse(searchQuery);
      if (parsedId != null) {
        // If the query is an integer, search by ID.
        query = FirebaseFirestore.instance
            .collection('subs')
            .where('id', isEqualTo: parsedId);
      } else {
        // If the query is a string, search by name (case-insensitive).
        query = FirebaseFirestore.instance
            .collection('subs')
            .where('name', isGreaterThanOrEqualTo: searchQuery)
            .where('name', isLessThanOrEqualTo: searchQuery + '\uf8ff');
      }
    }

    // Execute the query and fetch results.
    QuerySnapshot querySnapshot = await query.get();

    if (!mounted) return;

    setState(() {
      subs = querySnapshot.docs
          .map((doc) => {'docId': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    });
  } catch (error) {
    print('Error fetching subs: $error');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('خطأ أثناء جلب الكفالات: $error')),
    );
  }
}




 

  Future<void> showEditDialog(Map<String, dynamic> subData) async {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> formData = Map<String, dynamic>.from(subData);

  await showDialog(
    context: context,
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تعديل الكفالة'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  buildTextField(
                      'اسم الكفالة', 'أدخل اسم الكفالة', 'name', formData),
                  buildTextField(
                      'الموقع', 'أدخل الموقع', 'location', formData),
                  buildTextField(
                      'رقم الهاتف', 'أدخل رقم الهاتف', 'number', formData,
                      inputType: TextInputType.phone),
                  buildTextField('الوحدة', 'أدخل الوحدة', 'unite', formData,
                      inputType: TextInputType.number),
                  buildTextField('رقم التعريف:', 'ادخل رقم التعريف', 'id', formData,
                      inputType: TextInputType.number),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  try {
                    final int updatedId = int.tryParse(formData['id'].toString()) ?? 0;

                    // Check if the new ID exists in another document
                    QuerySnapshot existingIdSnapshot = await FirebaseFirestore.instance
                        .collection('subs')
                        .where('id', isEqualTo: updatedId)
                        .get();

                    if (existingIdSnapshot.docs.isNotEmpty &&
                        existingIdSnapshot.docs.first.id != subData['docId']) {
                      // If the ID exists in another document, swap the IDs
                      final otherSubDoc = existingIdSnapshot.docs.first;
                      final otherSubData = otherSubDoc.data() as Map<String, dynamic>;
                      final otherSubId = otherSubDoc.id;

                      // Update the other document's ID
                      await FirebaseFirestore.instance
                          .collection('subs')
                          .doc(otherSubId)
                          .update({'id': subData['id']});

                      // Update the current document's ID
                      await FirebaseFirestore.instance
                          .collection('subs')
                          .doc(subData['docId'])
                          .update({'id': updatedId});

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم تبديل أرقام التعريف بنجاح.')),
                      );
                    } else {
                      // If the ID does not exist in another document, simply update it
                      await FirebaseFirestore.instance
                          .collection('subs')
                          .doc(subData['docId'])
                          .update({'id': updatedId});

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم تحديث رقم التعريف بنجاح.')),
                      );
                    }

                    fetchSubs(); // Refresh the list
                    Navigator.pop(context);
                  } catch (error) {
                    print('Error updating sub: $error');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('خطأ أثناء التحديث: $error')),
                      );
                    }
                  }
                }
              },
              child: const Text('تعديل'),
            ),
          ],
        ),
      );
    },
  );
}


  Widget buildTextField(
      String label, String hint, String key, Map<String, dynamic> formData,
      {TextInputType inputType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: formData[key]?.toString(),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        keyboardType: inputType,
        validator: (value) =>
            value == null || value.isEmpty ? 'الرجاء إدخال $label' : null,
        onSaved: (value) {
          if (key == 'unite' || key == 'Active') {
            formData[key] =
                int.tryParse(value ?? '0') ?? 0; // Convert to integer
          } else {
            formData[key] = value; // Keep as string
          }
        },
      ),
    );
  }

  void _viewCases(BuildContext context, int subId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CasesForSubPage(subId: subId),
      ),
    );
  }

Future<void> showYearSelectionDialog(
    BuildContext context, String subName, String docId) async {
  int? selectedYear;
  final currentYear = DateTime.now().year;
  final years = List.generate(10, (index) => currentYear - index);

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('اختر السنة'),
        content: DropdownButtonFormField<int>(
          items: years
              .map((year) => DropdownMenuItem<int>(
                    value: year,
                    child: Text(year.toString()),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              selectedYear = value!;
            });
          },
          decoration: const InputDecoration(labelText: 'السنة'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedYear != null) {
                Navigator.pop(context);
                // Pass the Firestore docId and subName here
                printYearlyReport(context, docId, selectedYear.toString(), subName);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى اختيار السنة')),
                );
              }
            },
            child: const Text('طباعة'),
          ),
        ],
      ),
    ),
  );
}



Future<void> printYearlyReport(BuildContext context, String docId, String year, String subName) async {
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
      'th, td { border: 1px solid black; padding: 8px; text-align: center; }');
  buffer.writeln('th { background-color: #f2f2f2; }');
  buffer.writeln('</style>');
  buffer.writeln('</head>');
  buffer.writeln('<body>');

  // Add the main title
  buffer.writeln('<h1>كشف توريد الكفالة للسنة $year</h1>');
  // Add the subtitle with the sub's name
  buffer.writeln('<h3>اسم الكفيل: $subName</h3>');
  buffer.writeln('<table>');
  buffer.writeln('<tr><th>الشهر</th><th>رقم الإيصال</th><th>المبلغ</th></tr>');

  try {
    // Fetch the document using Firestore docId
    final subDocSnapshot = await FirebaseFirestore.instance.collection('subs').doc(docId).get();

    if (!subDocSnapshot.exists) {
      throw 'الكفالة غير موجودة أو تم حذفها.';
    }

    final subData = subDocSnapshot.data() as Map<String, dynamic>?;

    if (subData == null || !subData.containsKey(year)) {
      throw 'لا توجد بيانات لهذا العام.';
    }

    final yearData = subData[year] as Map<String, dynamic>?;

    for (int month = 1; month <= 12; month++) {
      final monthKey = month.toString();
      if (yearData != null && yearData.containsKey(monthKey)) {
        final monthReceipts = yearData[monthKey] as List;

        if (monthReceipts.isNotEmpty) {
          for (final receipt in monthReceipts) {
            if (receipt is Map<String, dynamic>) {
              final receiptNumber = receipt['receipt_number']?.toString() ?? 'لا يوجد';
              final amount = receipt['amount'] ?? 0;

              buffer.writeln(
                  '<tr><td>${intl.DateFormat.MMMM('ar').format(DateTime(0, month))}</td><td>$receiptNumber</td><td>$amount</td></tr>');
            }
          }
        } else {
          buffer.writeln(
              '<tr><td>${intl.DateFormat.MMMM('ar').format(DateTime(0, month))}</td><td>لا يوجد</td><td>0</td></tr>');
        }
      } else {
        buffer.writeln(
            '<tr><td>${intl.DateFormat.MMMM('ar').format(DateTime(0, month))}</td><td>لا يوجد</td><td>0</td></tr>');
      }
    }
  } catch (e) {
    buffer.writeln('<tr><td colspan="3">حدث خطأ أثناء جلب البيانات: $e</td></tr>');
  }

  buffer.writeln('</table>');
  buffer.writeln('</body>');
  buffer.writeln('</html>');

  final blob = html.Blob([buffer.toString()], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  html.Url.revokeObjectUrl(url);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('تم إنشاء التقرير بنجاح')),
  );
}





  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // Set layout to RTL
      child: Scaffold(
        appBar: AppBar(
          title: const Text('جدول الكفالات'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () =>
                  printSubsData(context), // Call the print function
              tooltip: 'طباعة جدول الكفالات',
            ),
          ],
        ),
        drawer: ModeratorDrawer(), // AdminDrawer added here
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'ابحث بالاسم أو الرقم',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.trim(); // Trim extra spaces.
                    fetchSubs();
                  });
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: subs.length,
                itemBuilder: (context, index) {
                  final sub = subs[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      title: Text(sub['name'] ?? 'لا يوجد'),
                      subtitle: Text('الموقع: ${sub['location']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: AlertDialog(
                                      title: const Text('عرض الكفالة'),
                                      content: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('الاسم: ${sub['name']}'),
                                          Text('الموقع: ${sub['location']}'),
                                          Text('رقم الهاتف: ${sub['number']}'),
                                          Text('الوحدة: ${sub['unite']}'),
                                          Text('رقم التعريف: ${sub['id']}'),

                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text(
                                            'إغلاق',
                                            style:
                                                TextStyle(color: Colors.purple),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            child: const Text(
                              'عرض',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _viewCases(context, sub['id']),
                            child: const Text(
                              'عرض الحالات',
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                          TextButton(
                            onPressed: () => showYearSelectionDialog(
                                context, sub['name'], sub['docId']),
                            child: const Text(
                              'كشف توريد الكفالة',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => showEditDialog(sub),
                          ),
                          
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to InsertSub and pass fetchSubs as onSubmit callback
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InsertSub(
                onSubmit: fetchSubs,  // Pass the fetchSubs method as a callback
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      ),
    );
  }

  Future<void> printSubsData(BuildContext context) async {
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
  buffer.writeln('</style>');
  buffer.writeln('</head>');
  buffer.writeln('<body>');
  buffer.writeln('<h1>جدول الكفالات</h1>');
  buffer.writeln('<table>');
  buffer.writeln(
      '<tr><th>رقم التعريف</th><th>الاسم</th><th>الموقع</th><th>رقم الهاتف</th><th>المبلغ</th></tr>');

  try {
    // Reuse the same query logic as fetchSubs
    Query query = FirebaseFirestore.instance.collection('subs').orderBy('id');

    if (searchQuery.isNotEmpty) {
      final parsedId = int.tryParse(searchQuery);
      if (parsedId != null) {
        query = FirebaseFirestore.instance
            .collection('subs')
            .where('id', isEqualTo: parsedId);
      } else {
        query = FirebaseFirestore.instance
            .collection('subs')
            .where('name', isGreaterThanOrEqualTo: searchQuery)
            .where('name', isLessThanOrEqualTo: searchQuery + '\uf8ff');
      }
    }

    QuerySnapshot querySnapshot = await query.get();

    for (var sub in querySnapshot.docs) {
      final subData = sub.data() as Map<String, dynamic>;
      buffer.writeln(
          '<tr><td>${subData['id'] ?? 'غير معروف'}</td><td>${subData['name'] ?? 'غير معروف'}</td><td>${subData['location'] ?? 'غير معروف'}</td><td>${subData['number'] ?? 'غير معروف'}</td><td>${subData['unite'] ?? 'غير معروف'}</td></tr>');
    }
  } catch (e) {
    buffer.writeln('<tr><td colspan="5">حدث خطأ أثناء جلب البيانات</td></tr>');
    print('Error fetching subs: $e');
  }

  buffer.writeln('</table>');
  buffer.writeln('</body>');
  buffer.writeln('</html>');

  final blob = html.Blob([buffer.toString()], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  html.Url.revokeObjectUrl(url);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('تم طباعة الكفالات بنجاح')),
  );
}


}


class CasesForSubPage extends StatelessWidget {
  final int subId;

  const CasesForSubPage({Key? key, required this.subId}) : super(key: key);

  Future<String> fetchSubName(int subId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('subs')
          .where('id', isEqualTo: subId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data()['name'] ?? 'غير معروف';
      }
    } catch (e) {
      print('Error fetching sub name: $e');
    }
    return 'غير معروف';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: fetchSubName(subId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final subName = snapshot.data ?? 'غير معروف';

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: AppBar(
              title: Text('الحالات للكفالة ($subName)'),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.print),
                  onPressed: () => printCasesForSub(context, subId, subName),
                  tooltip: 'طباعة الحالات للكفالة',
                ),
              ],
            ),
            body: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('cases')
                  .where('sub_ids', arrayContains: subId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد حالات لهذه الكفالة',
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
                              'الاسم: ${caseData['name'] ?? 'غير معروف'}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('العنوان: ${caseData['location'] ?? 'غير معروف'}'),
                            Text('رقم الهاتف: ${caseData['number'] ?? 'غير معروف'}'),
                            Text('الرصيد: ${caseData['balance'] ?? 0}'),
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
      },
    );
  }

  Future<void> printCasesForSub(
    BuildContext context, int subId, String subName) async {
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
  buffer.writeln('</style>');
  buffer.writeln('</head>');
  buffer.writeln('<body>');
  buffer.writeln('<h1>الحالات للكفالة ($subName - رقم التعريف: $subId)</h1>');
  buffer.writeln('<table>');
  buffer.writeln(
      '<tr><th>رقم الحالة</th><th>الاسم</th><th>العنوان</th><th>رقم الهاتف</th><th>الرصيد</th></tr>');

  try {
    final casesCollection = FirebaseFirestore.instance.collection('cases');
    final querySnapshot =
        await casesCollection.where('sub_ids', arrayContains: subId).get();

    for (var caseDoc in querySnapshot.docs) {
      final caseData = caseDoc.data();
      buffer.writeln(
          '<tr><td>${caseData['id']}</td><td>${caseData['name'] ?? 'غير معروف'}</td><td>${caseData['location'] ?? 'غير معروف'}</td><td>${caseData['number'] ?? 'غير معروف'}</td><td>${caseData['balance'] ?? 0}</td></tr>');
    }
  } catch (e) {
    buffer
        .writeln('<tr><td colspan="5">حدث خطأ أثناء جلب البيانات</td></tr>');
    print('Error fetching cases: $e');
  }

  buffer.writeln('</table>');
  buffer.writeln('</body>');
  buffer.writeln('</html>');

  final blob = html.Blob([buffer.toString()], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  html.Url.revokeObjectUrl(url);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('تم طباعة الحالات بنجاح')),
  );
}

}
