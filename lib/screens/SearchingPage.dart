import 'package:berwehsan/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:berwehsan/core/print_style.dart';
import 'dart:html' as html;

class SearchingPage extends StatefulWidget {
  const SearchingPage({super.key});

  @override
  _SearchingPageState createState() => _SearchingPageState();
}

class _SearchingPageState extends State<SearchingPage> {
  String searchQuery = '';
  List<Map<String, dynamic>> allCases = [];
  List<Map<String, dynamic>> filteredCases = [];
  List<Map<String, dynamic>> selectedCases = [];

  @override
  void initState() {
    super.initState();
    fetchCases();
  }

  Future<void> fetchCases() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('cases').get();

      setState(() {
        allCases = querySnapshot.docs
            .map((doc) =>
                {'docId': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();
        filteredCases = List.from(allCases); // Initially display all cases
      });
    } catch (error) {
      print('Error fetching cases: $error');
    }
  }

  void filterCases() {
    setState(() {
      filteredCases = allCases.where((caseItem) {
        final location = caseItem['location']?.toString() ?? '';
        return location.contains(searchQuery);
      }).toList();
    });
  }

  Future<void> _printSelectedCases() async {
    if (selectedCases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يتم تحديد أي حالات للطباعة')),
      );
      return;
    }

    try {
      final buffer = StringBuffer();
      buffer.writeln('<html>');
      buffer.writeln('<head>');
      buffer.writeln('<meta charset="UTF-8">');
      buffer.writeln(PrintStyle.htmlHead);
      buffer.writeln('</head>');
      buffer.writeln(
          '<body style="direction: rtl; font-family: Arial, sans-serif;">');
      buffer.writeln(PrintStyle.getHeader('الحالات المختارة'));
      buffer.writeln('<table>');
      buffer.writeln(
          '<tr><th>رقم الحالة</th><th>الموقع</th><th>اسم الحالة</th><th>رقم الهاتف</th><th>الحالة الاجتماعية</th><th>الدخل</th></tr>');

      for (final caseItem in selectedCases) {
        buffer.writeln('<tr>'
            '<td>${caseItem['id'] ?? '---'}</td>'
            '<td>${caseItem['location'] ?? '---'}</td>'
            '<td>${caseItem['name'] ?? '---'}</td>'
            '<td>${caseItem['number'] ?? '---'}</td>'
            '<td>${caseItem['social_status'] ?? '---'}</td>'
            '<td>${caseItem['in_come'] ?? '---'}</td>'
            '</tr>');
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
      print('Error printing selected cases: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الطباعة: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('البحث في الحالات'),
          actions: [
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _printSelectedCases,
              tooltip: "طباعة الحالات المختارة",
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'ابحث عن الموقع',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                    filterCases();
                  });
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filteredCases.length,
                itemBuilder: (context, index) {
                  final caseItem = filteredCases[index];
                  final isSelected = selectedCases.contains(caseItem);

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selectedCases.add(caseItem);
                          } else {
                            selectedCases.remove(caseItem);
                          }
                        });
                      },
                      title: Text("رقم الحالة: ${caseItem['id'] ?? '---'}"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("الموقع: ${caseItem['location'] ?? '---'}"),
                          Text("اسم الحالة: ${caseItem['name'] ?? '---'}"),
                          Text("رقم الهاتف: ${caseItem['number'] ?? '---'}"),
                          Text(
                              "الحالة الاجتماعية: ${caseItem['social_status'] ?? '---'}"),
                          Text("الدخل: ${caseItem['in_come'] ?? '---'}"),
                        ],
                      ),
                      secondary:
                          const Icon(Icons.location_on, color: Colors.blue),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
