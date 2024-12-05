import 'package:berwehsan/user/insertSub.dart';
import 'package:berwehsan/widgets/user_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html;

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
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('subs')
          .where('name', isGreaterThanOrEqualTo: searchQuery)
          .get();

      if (!mounted) return;

      setState(() {
        subs = querySnapshot.docs
            .map((doc) =>
                {'docId': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();
      });
    } catch (error) {
      print('Error fetching subs: $error');
    }
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
        drawer: userDrawer(), // UserDrawer added here
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
                    searchQuery = value;
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => InsertSub()),
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
    buffer.writeln('<tr><th>الاسم</th><th>الموقع</th><th>رقم الهاتف</th></tr>');

    try {
      final subsCollection = FirebaseFirestore.instance.collection('subs');
      final querySnapshot = await subsCollection.get();

      print('Subs count: ${querySnapshot.docs.length}'); // Debugging count

      for (var sub in querySnapshot.docs) {
        final subData = sub.data();
        buffer.writeln(
            '<tr><td>${subData['name'] ?? 'غير معروف'}</td><td>${subData['location'] ?? 'غير معروف'}</td><td>${subData['number'] ?? 'غير معروف'}</td></tr>');
      }
    } catch (e) {
      buffer
          .writeln('<tr><td colspan="3">حدث خطأ أثناء جلب البيانات</td></tr>');
      print('Error fetching subs: $e'); // Debugging error
    }

    buffer.writeln('</table>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    // Debugging generated HTML
    print('Generated HTML: ${buffer.toString()}');

    final blob = html.Blob([buffer.toString()], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Debugging blob URL
    print('Blob URL: $url');

    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم طباعة الكفالات بنجاح')),
    );
  }
}

class CasesForSubPage extends StatelessWidget {
  final int subId;

  const CasesForSubPage({super.key, required this.subId});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // Set layout to RTL
      child: Scaffold(
        appBar: AppBar(
          title: Text('الحالات للكفالة $subId'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () =>
                  printCasesForSub(context, subId), // Call the print function
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

  Future<void> printCasesForSub(BuildContext context, int subId) async {
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
    buffer.writeln('<h1>الحالات للكفالة $subId</h1>');
    buffer.writeln('<table>');
    buffer
        .writeln('<tr><th>الاسم</th><th>العنوان</th><th>رقم الهاتف</th></tr>');

    try {
      final casesCollection = FirebaseFirestore.instance.collection('cases');
      final querySnapshot =
          await casesCollection.where('sub_ids', arrayContains: subId).get();

      for (var caseDoc in querySnapshot.docs) {
        final caseData = caseDoc.data();
        buffer.writeln(
            '<tr><td>${caseData['name'] ?? 'غير معروف'}</td><td>${caseData['location'] ?? 'غير معروف'}</td><td>${caseData['number'] ?? 'غير معروف'}</td></tr>');
      }
    } catch (e) {
      buffer
          .writeln('<tr><td colspan="3">حدث خطأ أثناء جلب البيانات</td></tr>');
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
