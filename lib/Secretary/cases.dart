import 'package:berwehsan/widgets/secretary_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html; // For printing
import 'caseProfile.dart';
import 'insertCase.dart';

class CasesPage extends StatefulWidget {
  const CasesPage({super.key});

  @override
  _CasesPageState createState() => _CasesPageState();
}

class _CasesPageState extends State<CasesPage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('جدول الحالات'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _printAllCases, // Call the printing function here
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'ابحث بالاسم أو الرقم',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
        ),
        drawer: SecretaryDrawer(),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('cases')
              .orderBy('id')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text('لا توجد بيانات', style: TextStyle(fontSize: 18)),
              );
            }

            final cases = snapshot.data!.docs;

            final filteredCases = cases.where((doc) {
              final caseData = doc.data() as Map<String, dynamic>;
              final name = caseData['name']?.toString().toLowerCase() ?? '';
              final id = caseData['id']?.toString();

              if (RegExp(r'^\d+').hasMatch(searchQuery)) {
                return id == searchQuery;
              }

              return name.contains(searchQuery.toLowerCase());
            }).toList();

            return ListView.builder(
              itemCount: filteredCases.length,
              itemBuilder: (context, index) {
                final caseData =
                    filteredCases[index].data() as Map<String, dynamic>;
                final docId = filteredCases[index].id;

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(caseData['name'] ?? 'غير معروف'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('رقم الحالة: ${caseData['id'] ?? 'غير معروف'}'),
                        Text(
                            'رقم التليفون: ${caseData['number'] ?? 'غير معروف'}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CaseProfile(
                                    caseId:
                                        int.parse(caseData['id'].toString())),
                              ),
                            );
                          },
                          child: const Text('عرض الملف'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.green,
          child: const Icon(Icons.add),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InsertCase(),
              ),
            );
          },
          tooltip: 'إضافة حالة جديدة',
        ),
      ),
    );
  }

  /// Helper function to provide Arabic labels for each field
  String _getArabicFieldLabel(String key) {
    switch (key) {
      case 'name':
        return 'الاسم';
      case 'location':
        return 'العنوان';
      case 'social_status':
        return 'الحالة الاجتماعية';
      case 'in_come':
        return 'الدخل';
      case 'family_count':
        return 'عدد أفراد الأسرة';
      case 'ID_Number':
        return 'الرقم القومي';
      case 'number':
        return 'رقم الهاتف';
      case 'c_size':
        return 'مقاس الملابس';
      case 'S_size':
        return 'مقاس جهاز العروس';
      case 'age':
        return 'العمر';
      case 'grade_id':
        return 'المرحلة الدراسية';
      case 'balance':
        return 'القبض';
      case 'area_id':
        return 'رقم المنطقة';
      case 'chest_ids':
        return 'الصناديق';
      case 'sub_ids':
        return 'المشتركين';
      default:
        return key; // Fallback for unknown fields
    }
  }

  /// Function to print all cases
  /// Function to print all cases
  Future<void> _printAllCases() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('cases').get();

      // Sort the documents by ID in ascending order
      final sortedDocs = snapshot.docs
        ..sort((a, b) {
          final idA = int.tryParse(
                  (a.data() as Map<String, dynamic>)['id'].toString()) ??
              0;
          final idB = int.tryParse(
                  (b.data() as Map<String, dynamic>)['id'].toString()) ??
              0;
          return idA.compareTo(idB);
        });

      final buffer = StringBuffer();
      buffer.writeln('<html>');
      buffer.writeln('<head>');
      buffer.writeln('<meta charset="UTF-8">'); // Ensures proper text encoding
      buffer.writeln('<style>');
      buffer.writeln(
          'table { width: 100%; border-collapse: collapse; margin-top: 20px; }');
      buffer.writeln(
          'th, td { border: 1px solid black; padding: 8px; text-align: right; }');
      buffer.writeln('th { background-color: #f2f2f2; }');
      buffer.writeln('</style>');
      buffer.writeln('</head>');
      buffer.writeln(
          '<body style="direction: rtl; font-family: Arial, sans-serif;">');
      buffer.writeln('<h1>جدول الحالات</h1>');
      buffer.writeln('<table>');
      buffer.writeln(
          '<tr><th>رقم الحالة</th><th>اسم الحالة</th><th>رقم التليفون</th></tr>');

      for (final doc in sortedDocs) {
        final data = doc.data() as Map<String, dynamic>;
        buffer.writeln(
            '<tr><td>${data['id'] ?? 'غير معروف'}</td><td>${data['name'] ?? 'غير معروف'}</td><td>${data['number'] ?? 'غير معروف'}</td></tr>');
      }

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
      print('Error printing cases: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الطباعة: $error')),
      );
    }
  }

  /// Generate user-friendly labels for fields
  String _getFieldLabel(String key) {
    switch (key) {
      case 'name':
        return 'اسم الحالة';
      case 'number':
        return 'رقم التليفون';
      default:
        return key;
    }
  }
}
