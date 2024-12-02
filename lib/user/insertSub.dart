import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class InsertSub extends StatefulWidget {
  @override
  _InsertSubState createState() => _InsertSubState();
}

class _InsertSubState extends State<InsertSub> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> formData = {
    'name': '',
    'description': '',
  };

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    try {
      final response = await http.post(
        Uri.parse('https://yourdomain.com/insert_sub.php'),
        body: formData,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الكفالة بنجاح')),
        );
        Navigator.pop(context);
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة كفالة'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'اسم الكفالة',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'الرجاء إدخال اسم الكفالة'
                    : null,
                onSaved: (value) => formData['name'] = value!,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'الوصف',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'الرجاء إدخال الوصف'
                    : null,
                onSaved: (value) => formData['description'] = value!,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: submitForm,
                child: const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
