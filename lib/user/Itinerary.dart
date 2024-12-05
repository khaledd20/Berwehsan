import 'package:berwehsan/widgets/user_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ItineraryPage extends StatefulWidget {
  @override
  _ItineraryPageState createState() => _ItineraryPageState();
}

class _ItineraryPageState extends State<ItineraryPage> {
  List<Map<String, dynamic>> itineraries = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchItineraries();
  }

  Future<void> fetchItineraries() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('itineraries')
          .where('name', isGreaterThanOrEqualTo: searchQuery)
          .get();

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

  Future<void> addItinerary(BuildContext context) async {
    final _formKey = GlobalKey<FormState>();
    final Map<String, dynamic> formData = {
      'name': '',
      'from': '',
      'to': '',
      'cost': '',
      'date': '',
      'notes': '',
    };

    await showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إضافة خط السير'),
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
                    buildTextField('التاريخ', 'أدخل التاريخ', 'date', formData),
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
                    try {
                      // Save the new itinerary to Firestore
                      await FirebaseFirestore.instance
                          .collection('itineraries')
                          .add(formData);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('تم إضافة خط السير بنجاح')),
                      );

                      fetchItineraries();
                      Navigator.pop(context);
                    } catch (error) {
                      print('Error adding itinerary: $error');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('خطأ أثناء الإضافة: $error')),
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
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('جدول خط السير'),
          centerTitle: true,
        ),
        drawer: userDrawer(),
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
                          Text('التاريخ: ${itinerary['date']}'),
                          Text(
                              'ثمن المواصلات: ${itinerary['cost']?.toString() ?? 'غير معروف'}'),
                          Text(
                              ' ملحوظات: ${itinerary['notes']?.toString() ?? 'غير معروف'}'),
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
          onPressed: () => addItinerary(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
