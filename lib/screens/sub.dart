import 'package:berwehsan/screens/insertSub.dart';
import 'package:berwehsan/screens/sub-case.dart';
import 'package:berwehsan/widgets/app_drawer.dart';
import 'package:berwehsan/core/user_session.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:berwehsan/core/print_style.dart';
import 'dart:html' as html;
import 'package:intl/intl.dart' as intl;

class SubsPage extends StatefulWidget {
  const SubsPage({super.key});

  @override
  _SubsPageState createState() => _SubsPageState();
}

class _SubsPageState extends State<SubsPage> {
  List<Map<String, dynamic>> subs = [];
  String searchQuery = '';
  bool _sortByDate = false; // false = sort by name, true = sort by date

  @override
  void initState() {
    super.initState();
    fetchSubs();
  }

  Future<void> fetchSubs() async {
    try {
      Query query = FirebaseFirestore.instance
          .collection('subs')
          .orderBy('name'); // Default query to order by name.

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
              .where('name', isLessThanOrEqualTo: '$searchQuery\uf8ff');
        }
      }

      // Execute the query and fetch results.
      QuerySnapshot querySnapshot = await query.get();

      if (!mounted) return;

      setState(() {
        subs = querySnapshot.docs
            .map((doc) =>
                {'docId': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();

        // Apply client-side sort
        if (_sortByDate) {
          subs.sort((a, b) {
            final aDate = a['created_at']?.toString() ?? '';
            final bDate = b['created_at']?.toString() ?? '';
            return bDate.compareTo(aDate); // newest first
          });
        } else {
          subs.sort((a, b) {
            final aName = a['name']?.toString() ?? '';
            final bName = b['name']?.toString() ?? '';
            return aName.compareTo(bName);
          });
        }
      });
    } catch (error) {
      print('Error fetching subs: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء جلب الكفالات: $error')),
      );
    }
  }

  Future<void> deleteSub(String docId, dynamic subId) async {
    try {
      // Cross-collection cleanup: Remove subId from all cases
      final casesSnapshot = await FirebaseFirestore.instance
          .collection('cases')
          .where('sub_ids', arrayContains: subId)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in casesSnapshot.docs) {
        batch.update(doc.reference, {
          'sub_ids': FieldValue.arrayRemove([subId])
        });
      }
      await batch.commit();

      // Delete the sub document
      await FirebaseFirestore.instance.collection('subs').doc(docId).delete();
      if (!mounted) return;

      fetchSubs();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الكفالة بنجاح وتم تحديث الحالات المرتبطة')),
      );
    } catch (error) {
      print('Error deleting sub: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء حذف الكفالة: $error')),
        );
      }
    }
  }

  Future<void> showEditDialog(Map<String, dynamic> subData) async {
    final formKey = GlobalKey<FormState>();
    final Map<String, dynamic> formData = Map<String, dynamic>.from(subData);

    await showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تعديل الكفالة'),
            content: Form(
              key: formKey,
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
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();

                    try {
                      await FirebaseFirestore.instance
                          .collection('subs')
                          .doc(subData['docId'])
                          .update({
                        'name': formData['name'],
                        'location': formData['location'],
                        'number': formData['number'],
                        'unite': formData['unite'],
                        'userName': UserSession().fullName,
                        'updated_at': DateTime.now().toString(),
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم تحديث الكفالة بنجاح')),
                      );

                      fetchSubs();
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
          if (key == 'unite') {
            formData[key] = int.tryParse(value ?? '0') ?? 0;
          } else {
            formData[key] = value;
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
                  printYearlyReport(
                      context, docId, selectedYear.toString(), subName);
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

  Future<void> printYearlyReport(
      BuildContext context, String docId, String year, String subName) async {
    final buffer = StringBuffer();

    buffer.writeln('<html>');
    buffer.writeln(PrintStyle.htmlHead);
    buffer.writeln('<body>');
    buffer.writeln(PrintStyle.getHeader('كشف توريد الكفالة للسنة $year'));
    buffer.writeln('<h3>اسم الكفيل: $subName</h3>');
    buffer.writeln('<table>');
    buffer
        .writeln('<tr><th>الشهر</th><th>رقم الإيصال</th><th>المبلغ</th></tr>');

    try {
      final subDocSnapshot =
          await FirebaseFirestore.instance.collection('subs').doc(docId).get();

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
                final receiptNumber =
                    receipt['receipt_number']?.toString() ?? 'لا يوجد';
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
      buffer.writeln(
          '<tr><td colspan="3">حدث خطأ أثناء جلب البيانات: $e</td></tr>');
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
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('جدول الكفالات'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () => printSubsData(context, subs),
              tooltip: 'طباعة جدول الكفالات',
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'ابحث بالاسم أو الرقم',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.trim();
                        fetchSubs();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('الترتيب: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      ToggleButtons(
                        isSelected: [!_sortByDate, _sortByDate],
                        onPressed: (index) {
                          setState(() {
                            _sortByDate = index == 1;
                            fetchSubs();
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        selectedColor: Colors.white,
                        fillColor: Theme.of(context).primaryColor,
                        constraints:
                            const BoxConstraints(minHeight: 36, minWidth: 70),
                        children: const [
                          Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('الاسم')),
                          Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('التاريخ')),
                        ],
                      ),
                    ],
                  ),
                ],
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
                                          if (UserSession().isAdmin &&
                                              sub.containsKey('userName'))
                                            Text('بواسطة: ${sub['userName']}'),
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
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LinkCasesToSubPage(
                                    subId: sub['id'],
                                    subName: sub['name'],
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'ربط/فصل الحالات',
                              style: TextStyle(color: Colors.purple),
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
                          if (UserSession().isAdmin ||
                              UserSession().isModerator)
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => showEditDialog(sub),
                            ),
                          if (UserSession().isAdmin)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('تأكيد الحذف'),
                                    content: const Text(
                                        'هل تريد حقًا حذف هذه الكفالة؟'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('إلغاء'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          deleteSub(sub['docId'], sub['id']);
                                        },
                                        child: const Text('حذف'),
                                      ),
                                    ],
                                  ),
                                );
                              },
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
              MaterialPageRoute(
                builder: (context) => InsertSub(
                  onSubmit: fetchSubs,
                ),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Future<void> printSubsData(
      BuildContext context, List<Map<String, dynamic>> subsList) async {
    final buffer = StringBuffer();

    buffer.writeln('<html>');
    buffer.writeln(PrintStyle.htmlHead);
    buffer.writeln('<body>');
    buffer.writeln(PrintStyle.getHeader('جدول الكفالات'));
    buffer.writeln('<table>');
    buffer.writeln(
        '<tr><th>رقم التعريف</th><th>الاسم</th><th>الموقع</th><th>رقم الهاتف</th><th>المبلغ</th></tr>');

    if (subsList.isEmpty) {
      buffer.writeln('<tr><td colspan="5">لا توجد بيانات للطباعة</td></tr>');
    } else {
      for (var subData in subsList) {
        buffer.writeln(
            '<tr><td>${subData['id'] ?? 'غير معروف'}</td><td>${subData['name'] ?? 'غير معروف'}</td><td>${subData['location'] ?? 'غير معروف'}</td><td>${subData['number'] ?? 'غير معروف'}</td><td>${subData['unite'] ?? 'غير معروف'}</td></tr>');
      }
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

class CasesForSubPage extends StatefulWidget {
  final int subId;

  const CasesForSubPage({super.key, required this.subId});

  @override
  _CasesForSubPageState createState() => _CasesForSubPageState();
}

class _CasesForSubPageState extends State<CasesForSubPage> {
  bool _sortByName = true; // true = sort by name, false = sort by id

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
      future: fetchSubName(widget.subId),
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
                  onPressed: () => printCasesForSub(context, widget.subId, subName),
                  tooltip: 'طباعة الحالات للكفالة',
                ),
              ],
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Text('الترتيب: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      ToggleButtons(
                        isSelected: [_sortByName, !_sortByName],
                        onPressed: (index) {
                          setState(() {
                            _sortByName = index == 0;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        selectedColor: Colors.white,
                        fillColor: Theme.of(context).primaryColor,
                        constraints:
                            const BoxConstraints(minHeight: 36, minWidth: 70),
                        children: const [
                          Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('الاسم')),
                          Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('رقم التعريف')),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('cases')
                        .where('sub_ids', arrayContains: widget.subId)
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
                      final sortedCases = List.from(cases);
                      
                      if (_sortByName) {
                        sortedCases.sort((a, b) {
                          final aName = (a.data() as Map<String, dynamic>)['name']?.toString() ?? '';
                          final bName = (b.data() as Map<String, dynamic>)['name']?.toString() ?? '';
                          return aName.compareTo(bName);
                        });
                      } else {
                        sortedCases.sort((a, b) {
                          final aId = int.tryParse((a.data() as Map<String, dynamic>)['id']?.toString() ?? '') ?? 0;
                          final bId = int.tryParse((b.data() as Map<String, dynamic>)['id']?.toString() ?? '') ?? 0;
                          return aId.compareTo(bId);
                        });
                      }

                      return ListView.builder(
                        itemCount: sortedCases.length,
                        itemBuilder: (context, index) {
                          final caseData =
                              sortedCases[index].data() as Map<String, dynamic>;

                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'الاسم: ${caseData['name'] ?? 'غير معروف'}',
                                    style:
                                        const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                      'رقم التعريف: ${caseData['id'] ?? 'غير معروف'}'),
                                  Text(
                                      'العنوان: ${caseData['location'] ?? 'غير معروف'}'),
                                  Text(
                                      'رقم الهاتف: ${caseData['number'] ?? 'غير معروف'}'),
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
              ],
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
    buffer.writeln(PrintStyle.htmlHead);
    buffer.writeln('<body>');
    buffer.writeln(
        PrintStyle.getHeader('الحالات للكفالة ($subName - رقم التعريف: $subId)'));
    buffer.writeln('<table>');
    buffer.writeln(
        '<tr><th>رقم الحالة</th><th>الاسم</th><th>العنوان</th><th>رقم الهاتف</th><th>الرصيد</th></tr>');

    try {
      final casesCollection = FirebaseFirestore.instance.collection('cases');
      final querySnapshot =
          await casesCollection.where('sub_ids', arrayContains: subId).get();

      final cases = List.from(querySnapshot.docs);
      if (_sortByName) {
        cases.sort((a, b) {
          final aName = (a.data() as Map<String, dynamic>)['name']?.toString() ?? '';
          final bName = (b.data() as Map<String, dynamic>)['name']?.toString() ?? '';
          return aName.compareTo(bName);
        });
      } else {
        cases.sort((a, b) {
          final aId = int.tryParse((a.data() as Map<String, dynamic>)['id']?.toString() ?? '') ?? 0;
          final bId = int.tryParse((b.data() as Map<String, dynamic>)['id']?.toString() ?? '') ?? 0;
          return aId.compareTo(bId);
        });
      }

      for (var caseDoc in cases) {
        final caseData = caseDoc.data() as Map<String, dynamic>;
        buffer.writeln(
            '<tr><td>${caseData['id']}</td><td>${caseData['name'] ?? 'غير معروف'}</td><td>${caseData['location'] ?? 'غير معروف'}</td><td>${caseData['number'] ?? 'غير معروف'}</td><td>${caseData['balance'] ?? 0}</td></tr>');
      }
    } catch (e) {
      buffer.writeln(
          '<tr><td colspan="5">حدث خطأ أثناء جلب البيانات</td></tr>');
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
