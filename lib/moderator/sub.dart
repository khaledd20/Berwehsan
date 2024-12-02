import 'package:berwehsan/moderator/insertSub.dart';
import 'package:berwehsan/widgets/moderator_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
                    buildTextField('نشط', '0 أو 1', 'Active', formData,
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
                      await FirebaseFirestore.instance
                          .collection('subs')
                          .doc(subData['docId'])
                          .update(formData);

                      if (!mounted) return;

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

  void _viewCases(BuildContext context, int subId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CasesForSubPage(subId: subId),
      ),
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // Set the layout to Right-to-Left
      child: Scaffold(
        appBar: AppBar(
          title: const Text('جدول الكفالات'),
          centerTitle: true,
        ),
        drawer: ModeratorDrawer(), // Add the drawer here
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                textDirection: TextDirection.rtl, // Set text field to RTL
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
                      title: Text(
                        sub['name'] ?? 'لا يوجد',
                        textDirection: TextDirection.rtl, // Set RTL for text
                      ),
                      subtitle: Text(
                        'الموقع: ${sub['location']}',
                        textDirection: TextDirection.rtl,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => Directionality(
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
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('إغلاق'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'عرض',
                              style: TextStyle(color: Colors.purple),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _viewCases(context, sub['id']),
                            child: const Text(
                              'عرض الحالات',
                              style: TextStyle(color: Colors.green),
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
            // Navigate to add item page
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
}

class CasesForSubPage extends StatelessWidget {
  final int subId;

  const CasesForSubPage({super.key, required this.subId});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // Set RTL for cases page
      child: Scaffold(
        appBar: AppBar(
          title: Text('الحالات للكفالة $subId'),
          centerTitle: true,
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
}
