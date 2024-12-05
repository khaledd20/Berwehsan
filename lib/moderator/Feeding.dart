import 'package:berwehsan/widgets/moderator_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html; // For printing

class FeedingPage extends StatefulWidget {
  @override
  _FeedingPageState createState() => _FeedingPageState();
}

class _FeedingPageState extends State<FeedingPage> {
  List<Map<String, dynamic>> feedings = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchFeedings();
  }

  Future<void> fetchFeedings() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('feedings')
          .where('name', isGreaterThanOrEqualTo: searchQuery)
          .get();

      if (!mounted) return;

      setState(() {
        feedings = querySnapshot.docs
            .map((doc) =>
                {'docId': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();
      });
    } catch (error) {
      print('Error fetching feedings: $error');
    }
  }

  Future<void> showEditDialog(Map<String, dynamic> feedingData) async {
    final _formKey = GlobalKey<FormState>();
    final Map<String, dynamic> formData =
        Map<String, dynamic>.from(feedingData);

    await showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تعديل بيانات الإطعام'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    buildTextField(
                        'اسم الحالة', 'أدخل اسم الحالة', 'name', formData),
                    buildTextField(
                        'الوصف', 'أدخل الوصف', 'description', formData),
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
                      await FirebaseFirestore.instance
                          .collection('feedings')
                          .doc(feedingData['docId'])
                          .update(formData);

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('تم تحديث بيانات الإطعام بنجاح')),
                      );

                      fetchFeedings();
                      Navigator.pop(context);
                    } catch (error) {
                      print('Error updating feeding: $error');
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

  Future<void> _printAllFeedings() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('feedings').get();

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
      buffer.writeln('<h1>سجل الإطعام</h1>');
      buffer.writeln('<table>');
      buffer.writeln(
          '<tr><th>اسم الحالة</th><th>الوصف</th><th>تاريخ الإنشاء</th></tr>');

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        buffer.writeln(
            '<tr><td>${data['name'] ?? 'غير معروف'}</td><td>${data['description'] ?? 'غير معروف'}</td><td>${data['created_at'] ?? 'غير معروف'}</td></tr>');
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
      print('Error printing feedings: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الطباعة: $error')),
      );
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
          formData[key] = value;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('جدول الإطعام'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _printAllFeedings,
            ),
          ],
        ),
        drawer: ModeratorDrawer(),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'ابحث بالاسم أو التاريخ',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                    fetchFeedings();
                  });
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: feedings.length,
                itemBuilder: (context, index) {
                  final feeding = feedings[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      title: Text(feeding['name'] ?? 'لا يوجد'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('الوصف: ${feeding['description'] ?? 'لا يوجد'}'),
                          Text(
                              'تاريخ الإنشاء: ${feeding['created_at'] ?? 'لا يوجد'}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => showEditDialog(feeding),
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
            showDialog(
              context: context,
              builder: (context) => _buildInsertDialog(),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  /// Build Insert Dialog
  Widget _buildInsertDialog() {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('إضافة إطعام جديد'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الحالة',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال اسم الحالة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'الوصف',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال الوصف';
                  }
                  return null;
                },
              ),
            ],
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
                try {
                  await FirebaseFirestore.instance.collection('feedings').add({
                    'name': nameController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'created_at': DateTime.now().toIso8601String(),
                    'updated_at': DateTime.now().toIso8601String(),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تمت إضافة الإطعام بنجاح')),
                  );

                  fetchFeedings(); // Refresh the feedings list
                  Navigator.pop(context);
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('حدث خطأ أثناء الإضافة: $error')),
                  );
                }
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}
