import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:berwehsan/core/user_session.dart';

class InsertSub extends StatefulWidget {
  final Map<String, dynamic>? existingSub; // Pass existing data for editing
  final VoidCallback onSubmit; // Callback to refresh data after submit

  const InsertSub({super.key, this.existingSub, required this.onSubmit});

  @override
  _InsertSubState createState() => _InsertSubState();
}

class _InsertSubState extends State<InsertSub> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false; // Flag to track submission status

  final Map<String, dynamic> formData = {
    'name': '',
    'location': '',
    'number': '',
    'unite': 0,
    'Active': 1,
  };

  @override
  void initState() {
    super.initState();
    if (widget.existingSub != null) {
      formData['name'] = widget.existingSub!['name'] ?? '';
      formData['location'] = widget.existingSub!['location'] ?? '';
      formData['number'] = widget.existingSub!['number'] ?? '';
      formData['unite'] = widget.existingSub!['unite'] ?? 0;
      formData['Active'] = widget.existingSub!['Active'] ?? 1;
    }
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Prevent duplicate submissions
    if (isLoading) return;

    setState(() {
      isLoading = true; // Start loading
    });

    _formKey.currentState!.save();

    try {
      final subsCollection = FirebaseFirestore.instance.collection('subs');

      int nextId = 1;

      if (widget.existingSub == null) {
        QuerySnapshot querySnapshot =
            await subsCollection.orderBy('id', descending: true).limit(1).get();

        if (querySnapshot.docs.isNotEmpty) {
          nextId = querySnapshot.docs.first['id'] + 1;
        }
      } else {
        nextId = widget.existingSub!['id'];
      }

      Map<String, dynamic> subData = {
        'Active': formData['Active'],
        'case_count': 0,
        'created_at': widget.existingSub == null
            ? DateTime.now().toString()
            : widget.existingSub!['created_at'],
        'id': nextId,
        'location': formData['location'],
        'name': formData['name'],
        'number': formData['number'],
        'unite': int.tryParse(formData['unite'].toString()) ?? 0,
        'pied_times':
            widget.existingSub == null ? 0 : widget.existingSub!['pied_times'],
        'updated_at': DateTime.now().toString(),
        'userName': UserSession().fullName,
      };

      if (widget.existingSub == null) {
        await subsCollection.add(subData);
      } else {
        await subsCollection.doc(widget.existingSub!['docId']).update(subData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الكفالة بنجاح')),
      );

      widget.onSubmit(); // Call the callback to refresh the page

      // Navigate back after successful submission
      Navigator.pop(context);
    } catch (error) {
      print('Error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $error')),
      );
    } finally {
      setState(() {
        isLoading = false; // Stop loading
      });
    }
  }

  Widget buildTextField({
    required String label,
    required String key,
    TextInputType inputType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: formData[key].toString(),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: inputType,
        validator: (value) =>
            value == null || value.isEmpty ? 'الرجاء إدخال $label' : null,
        onSaved: (value) => formData[key] = value ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.existingSub == null
              ? 'إضافة كفالة جديدة'
              : 'تعديل بيانات الكفالة'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  buildTextField(label: 'اسم الكفالة', key: 'name'),
                  buildTextField(label: 'الموقع', key: 'location'),
                  buildTextField(
                      label: 'رقم الهاتف',
                      key: 'number',
                      inputType: TextInputType.phone),
                  buildTextField(
                      label: 'الوحدة',
                      key: 'unite',
                      inputType: TextInputType.number),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed:
                        isLoading ? null : submitForm, // Disable if loading
                    child: isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : Text(widget.existingSub == null ? 'إضافة' : 'تعديل'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
