import 'package:berwehsan/widgets/user_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html;

class FeedingPage extends StatefulWidget {
  const FeedingPage({Key? key}) : super(key: key);

  @override
  _FeedingPageState createState() => _FeedingPageState();
}

class _FeedingPageState extends State<FeedingPage> {
  String? _selectedAreaId;
  List<QueryDocumentSnapshot> _cases = [];
  List<Map<String, dynamic>> _selectedCases = [];
  bool _isLoadingCases = false;
  String _searchQuery = ''; // Search query for filtering cases

  // Fetch cases by area_id
  Future<void> _fetchCasesByArea(String areaId) async {
    setState(() {
      _isLoadingCases = true;
      _cases = [];
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('cases')
          .where('area_id', isEqualTo: int.parse(areaId))
          .get();

      setState(() {
        _cases = querySnapshot.docs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء جلب الحالات: $e')),
      );
    } finally {
      setState(() => _isLoadingCases = false);
    }
  }

  // Save selected cases and print
  Future<void> _saveAndPrintSelectedCases() async {
    if (_selectedCases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("لم يتم تحديد أي حالات")),
      );
      return;
    }

    try {
      final now = DateTime.now();
      final todayKey = "${now.year}-${now.month}-${now.day}";

      await FirebaseFirestore.instance.collection('feedings').doc(todayKey).set({
        'feeding_date': now.toIso8601String(),
        'cases': _selectedCases,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الحالات المختارة بنجاح!')),
      );

      _printFeedingCases(todayKey);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء الحفظ: $e')),
      );
    }
  }

  // Print selected feeding cases
  void _printFeedingCases(String formattedDate) async {
  final buffer = StringBuffer();
  buffer.writeln('<html><head><meta charset="UTF-8">');
  buffer.writeln('<style>table { width: 100%; border-collapse: collapse; }');
  buffer.writeln(
      'th, td { border: 1px solid black; padding: 8px; text-align: right; }');
  buffer.writeln('th { background-color: #f2f2f2; }</style></head>');
  buffer.writeln('<body style="direction: rtl; font-family: Arial;">');
  buffer.writeln('<h1>سجل إطعام اليوم (${formattedDate})</h1>');
  buffer.writeln(
      '<table><tr><th>رقم الحالة</th><th>اسم الحالة</th><th>عدد الأسرة</th><th>رقم الهاتف</th></tr>');

  // Add rows for each selected case
  for (final caseEntry in _selectedCases) {
    buffer.writeln(
        '<tr><td>${caseEntry['id']}</td><td>${caseEntry['name']}</td><td>${caseEntry['family_count'] ?? 0}</td><td>${caseEntry['number'] ?? 'غير معروف'}</td></tr>');
  }

  buffer.writeln('</table></body></html>');

  // Print the HTML content
  final blob = html.Blob([buffer.toString()], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  html.Url.revokeObjectUrl(url);
}



  // Fetch all areas for dropdown
  Future<List<QueryDocumentSnapshot>> _fetchAreas() async {
    try {
      final query = await FirebaseFirestore.instance.collection('areas').get();
      return query.docs;
    } catch (e) {
      print('Error fetching areas: $e');
      return [];
    }
  }

  // Add a custom case
  Future<void> _addCustomCase() async {
    final nameController = TextEditingController();
    final familyCountController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("إضافة حالة جديدة"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "اسم الحالة"),
              ),
              TextField(
                controller: familyCountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "عدد الأسرة"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedCases.add({
                    'id': 'مخصص-${DateTime.now().millisecondsSinceEpoch}',
                    'name': nameController.text.trim(),
                    'family_count': int.tryParse(familyCountController.text.trim()) ?? 0,
                    'number': null,
                  });
                });
                Navigator.pop(context);
              },
              child: const Text("إضافة"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCases = _cases.where((caseDoc) {
      final caseData = caseDoc.data() as Map<String, dynamic>;
      final caseName = caseData['name']?.toString() ?? '';
      final caseId = caseData['id']?.toString() ?? '';
      return caseName.contains(_searchQuery) || caseId.contains(_searchQuery);
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إدارة الإطعام')),
        drawer: userDrawer(),
        body: Column(
          children: [
            // Dropdown to select area
            FutureBuilder<List<QueryDocumentSnapshot>>(
              future: _fetchAreas(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'اختر المنطقة',
                      border: OutlineInputBorder(),
                    ),
                    items: snapshot.data!.map((area) {
                      return DropdownMenuItem<String>(
                        value: area['id'].toString(),
                        child: Text(area['name'] ?? 'منطقة غير معروفة'),
                      );
                    }).toList(),
                    onChanged: (value) => _fetchCasesByArea(value!),
                  ),
                );
              },
            ),
              Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'بحث باسم الحالة أو رقمها',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            // Cases list with checkboxes
            Expanded(
              child: _isLoadingCases
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: filteredCases.length,
                      itemBuilder: (context, index) {
                        final caseData =
                            filteredCases[index].data() as Map<String, dynamic>;
                        final isSelected = _selectedCases
                            .any((c) => c['id'] == caseData['id']);

                        return CheckboxListTile(
                          title: Text("اسم الحالة: ${caseData['name'] ?? 'غير معروف'}"),
                          subtitle: Text(
                              "رقم الحالة: ${caseData['id']} | عدد الأسرة: ${caseData['family_count'] ?? 0}"),
                          value: isSelected,
                          onChanged: (selected) {
                            setState(() {
                              if (selected == true) {
                                _selectedCases.add({
                                  'id': caseData['id'],
                                  'name': caseData['name'],
                                  'family_count': caseData['family_count'] ?? 0,
                                  'number': caseData['number'],
                                });
                              } else {
                                _selectedCases.removeWhere(
                                    (c) => c['id'] == caseData['id']);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _addCustomCase,
                  icon: const Icon(Icons.add),
                  label: const Text("إضافة حالة جديدة"),
                ),
                ElevatedButton.icon(
                  onPressed: _saveAndPrintSelectedCases,
                  icon: const Icon(Icons.save),
                  label: const Text("حفظ وطباعة الحالات"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
