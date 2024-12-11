import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InsertSub extends StatefulWidget {
  final Map<String, dynamic>? existingSub; // Pass existing data for editing
  final VoidCallback onSubmit;  // Callback to refresh data after submit

  const InsertSub({Key? key, this.existingSub, required this.onSubmit}) : super(key: key);

  @override
  _InsertSubState createState() => _InsertSubState();
}

class _InsertSubState extends State<InsertSub> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
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
      // Pre-fill form data for editing
      formData['name'] = widget.existingSub!['name'] ?? '';
      formData['location'] = widget.existingSub!['location'] ?? '';
      formData['number'] = widget.existingSub!['number'] ?? '';
      formData['unite'] = widget.existingSub!['unite'] ?? 0;
      formData['Active'] = widget.existingSub!['Active'] ?? 1;
    }
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    try {
      final subsCollection = FirebaseFirestore.instance.collection('subs');

      // Prepare the data to be inserted
      Map<String, dynamic> subData = {
        'Active': formData['Active'],
        'case_count': 0,
        'created_at': DateTime.now().toString(),
        'id': DateTime.now().millisecondsSinceEpoch, // Use timestamp as id
        'location': formData['location'],
        'name': formData['name'],
        'number': formData['number'],
        'unite': int.tryParse(formData['unite'].toString()) ?? 0,
        'pied_times': 0,
        'updated_at': DateTime.now().toString(),
      };

      if (widget.existingSub == null) {
        // Insert new document
        await subsCollection.add(subData);
      } else {
        // Update existing document
        await subsCollection.doc(widget.existingSub!['docId']).update(subData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الكفالة بنجاح')),
      );
      widget.onSubmit(); // Call the callback to refresh the page
      Navigator.pop(context); // Close the form page
    } catch (error) {
      print('Error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $error')),
      );
    }
  }

  // Function to build text fields dynamically
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
      textDirection: TextDirection.rtl, // RTL layout
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
                    onPressed: submitForm,
                    child: Text(widget.existingSub == null ? 'إضافة' : 'تعديل'),
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
