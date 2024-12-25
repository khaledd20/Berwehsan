import 'package:berwehsan/widgets/secretary_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html;
import 'package:intl/intl.dart';
import 'dart:ui' as ui; // For ui.TextDirection

class ItineraryPage extends StatefulWidget {
  @override
  _ItineraryPageState createState() => _ItineraryPageState();
}

class _ItineraryPageState extends State<ItineraryPage> {
  List<Map<String, dynamic>> itineraries = [];
  String searchQuery = '';
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    fetchItineraries();
  }

  Future<void> fetchItineraries() async {
  try {
    Query query = FirebaseFirestore.instance.collection('itineraries');

    if (searchQuery.isNotEmpty) {
      query = query.where('name', isGreaterThanOrEqualTo: searchQuery);
    }

    if (startDate != null || endDate != null) {
      query = query.where('date', isNotEqualTo: null);
    }
    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: startDate!.toIso8601String());
    }
    if (endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: endDate!.toIso8601String());
    }

    QuerySnapshot querySnapshot = await query.get();

    if (!mounted) return;

    setState(() {
      itineraries = querySnapshot.docs
          .map((doc) =>
              {'docId': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    });
  } catch (error) {
    print('Error fetching itineraries: $error');
  }
}


  

  Future<void> showEditDialog(Map<String, dynamic> itineraryData) async {
    final _formKey = GlobalKey<FormState>();
    final Map<String, dynamic> formData =
        Map<String, dynamic>.from(itineraryData);

    DateTime selectedDate = itineraryData['date'] != null
        ? DateTime.parse(itineraryData['date'])
        : DateTime.now();

    Future<void> _selectDate() async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );

      if (picked != null && picked != selectedDate) {
        selectedDate = picked;
        setState(() {}); // Update the UI
      }
    }

    await showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            title: Text(itineraryData['docId'] != null
                ? 'تعديل خط السير'
                : 'إضافة خط السير'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    buildTextField('الاسم', 'أدخل الاسم', 'name', formData),
                    buildTextField(
                        'من', 'أدخل نقطة الانطلاق', 'from', formData),
                    buildTextField('إلى', 'أدخل الوجهة', 'to', formData),
                    buildTextField(
                        'ثمن المواصلات', 'أدخل الثمن', 'cost', formData,
                        inputType: TextInputType.number),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            controller: TextEditingController(
                                text:
                                    "${selectedDate.toLocal()}".split(' ')[0]),
                            decoration: const InputDecoration(
                              labelText: 'التاريخ',
                              border: OutlineInputBorder(),
                            ),
                            onTap: _selectDate,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: _selectDate,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    buildTextField(
                        'الوسيلة', 'أدخل الوسيلة', 'method', formData),
                    const SizedBox(height: 10),
                    buildTextField(
                        'ملاحظات', 'أدخل الملاحظات', 'notes', formData),
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
                    formData['date'] = selectedDate.toIso8601String();

                    try {
                      if (itineraryData['docId'] != null) {
                        await FirebaseFirestore.instance
                            .collection('itineraries')
                            .doc(itineraryData['docId'])
                            .update(formData);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('تم تحديث خط السير بنجاح')),
                        );
                      } else {
                        await FirebaseFirestore.instance
                            .collection('itineraries')
                            .add(formData);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('تم إضافة خط السير بنجاح')),
                        );
                      }

                      fetchItineraries();
                      Navigator.pop(context);
                    } catch (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('خطأ أثناء الحفظ: $error')),
                      );
                    }
                  }
                },
                child: const Text('حفظ'),
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
          if (key == 'cost') {
            formData[key] = double.tryParse(value ?? '0') ?? 0.0;
          } else {
            formData[key] = value;
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('جدول خط السير'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () => printItinerariesData(context),
              tooltip: 'طباعة جدول خط السير',
            ),
          ],
        ),
        drawer: SecretaryDrawer(),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'ابحث بالاسم أو الوجهة',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                    fetchItineraries();
                  });
                },
              ),
            ),
            Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        startDate != null
                            ? 'من: ${DateFormat('yyyy-MM-dd').format(startDate!)}'
                            : 'اختر تاريخ البداية',
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            startDate = picked;
                            fetchItineraries();
                          });
                        }
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        endDate != null
                            ? 'إلى: ${DateFormat('yyyy-MM-dd').format(endDate!)}'
                            : 'اختر تاريخ النهاية',
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            endDate = picked;
                            fetchItineraries();
                          });
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'إعادة تعيين التواريخ',
                      onPressed: () {
                        setState(() {
                          startDate = null;
                          endDate = null;
                          fetchItineraries();
                        });
                      },
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: itineraries.length,
                itemBuilder: (context, index) {
                  final itinerary = itineraries[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      title: Text('الاسم: ${itinerary['name'] ?? 'غير معروف'}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('من: ${itinerary['from']}'),
                          Text('إلى: ${itinerary['to']}'),
                          Text('التاريخ: ${itinerary['date'] != null ? DateFormat('yyyy-MM-dd').format(DateTime.parse(itinerary['date'])) : 'غير متوفر'}'),
                          Text(
                              'الوسيلة: ${itinerary['method'] ?? 'غير محددة'}'),
                          Text(
                              'ثمن المواصلات: ${itinerary['cost']?.toString() ?? 'غير معروف'}'),
                          Text('ملحوظات: ${itinerary['notes']}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          
                          
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
            print('FloatingActionButton clicked! Opening add dialog.');
            showEditDialog({
              'name': '',
              'from': '',
              'to': '',
              'cost': 0,
              'date': DateTime.now().toIso8601String(),
              'method': '', // Default transport method
              'notes': '',
            });
          },
          child: const Icon(Icons.add),
          tooltip: 'إضافة خط سير جديد',
        ),
      ),
    );
  }

  Future<void> printItinerariesData(BuildContext context) async {
    final buffer = StringBuffer();

    // Start of HTML document
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
    buffer.writeln('<h1>جدول خط السير</h1>');
    buffer.writeln('<table>');
    buffer.writeln(
        '<tr><th>الاسم</th><th>من</th><th>إلى</th><th>التاريخ</th><th>ثمن المواصلات</th><th>الملاحظات</th></tr>');

    try {
      // Fetch itineraries data
      var query = FirebaseFirestore.instance.collection('itineraries').where('name', isGreaterThanOrEqualTo: searchQuery);

      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: startDate!.toIso8601String());
      }

      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: endDate!.toIso8601String());
      }

      final querySnapshot = await query.get();


      for (var itinerary in querySnapshot.docs) {
        final data = itinerary.data();
        buffer.writeln(
    '<tr><td>${data['name'] ?? 'غير معروف'}</td><td>${data['from'] ?? '-'}</td><td>${data['to'] ?? '-'}</td><td>${data['date'] != null ? DateFormat('yyyy-MM-dd').format(DateTime.parse(data['date'])) : '-'}</td><td>${data['cost']?.toString() ?? '0'}</td><td>${data['notes'] ?? '-'}</td></tr>');

      }
    } catch (e) {
      buffer
          .writeln('<tr><td colspan="6">حدث خطأ أثناء جلب البيانات</td></tr>');
    }

    buffer.writeln('</table>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    // Create a blob and open the file
    final blob = html.Blob([buffer.toString()], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم طباعة جدول خط السير بنجاح')),
    );
  }
}
