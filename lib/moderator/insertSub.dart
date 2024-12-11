import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class InsertSub extends StatefulWidget {
  final Map<String, dynamic>? existingSub; // Pass existing data for editing

  const InsertSub({Key? key, this.existingSub}) : super(key: key);

  @override
  _InsertSubState createState() => _InsertSubState();
}

class _InsertSubState extends State<InsertSub> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  final Map<String, dynamic> formData = {
    'name': '',
    'description': '',
    'phone': '',
    'unit': '',
    'active': '1',
  };

  @override
  void initState() {
    super.initState();
    if (widget.existingSub != null) {
      // Pre-fill form data for editing
      formData['name'] = widget.existingSub!['name'] ?? '';
      formData['description'] = widget.existingSub!['description'] ?? '';
      formData['phone'] = widget.existingSub!['phone'] ?? '';
      formData['unit'] = widget.existingSub!['unit']?.toString() ?? '';
      formData['active'] = widget.existingSub!['active']?.toString() ?? '1';
    }
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    try {
      final url = widget.existingSub == null
          ? Uri.parse('https://yourdomain.com/insert_sub.php') // Insert
          : Uri.parse('https://yourdomain.com/update_sub.php'); // Update

      final response = await http.post(url, body: formData);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الكفالة بنجاح')),
        );
        Navigator.pop(context); // Close the form page
      } else {
        print('Error: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل حفظ البيانات')),
        );
      }
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
        initialValue: formData[key],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: inputType,
        validator: (value) =>
            value == null || value.isEmpty ? 'الرجاء إدخال $label' : null,
        onSaved: (value) => formData[key] = value!,
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
                      key: 'phone',
                      inputType: TextInputType.phone),
                  buildTextField(
                      label: 'الوحدة',
                      key: 'unit',
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
