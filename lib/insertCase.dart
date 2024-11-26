import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InsertCase extends StatefulWidget {
  @override
  _InsertCaseState createState() => _InsertCaseState();
}

class _InsertCaseState extends State<InsertCase> {
  final _formKey = GlobalKey<FormState>();

      final Map<String, dynamic> formData = {
    'ID_Number': '',
    'S_size': '0',
    'age': '', // Storing age as String to avoid type mismatch
    'area_id': '', // No numeric validation for this field
    'balance': '0',
    'c_size': '0',
    'chest_id': '',
    'created_at': '', // Auto-populated during insertion
    'family_count': '', // Storing family_count as String to avoid type mismatch
    'food_times': '0',
    'grade_id': '',
    'id': '', // New field for `id`, stored as String
    'in_come': '',
    'location': '',
    'name': '',
    'number': '',
    'social_status': '',
    'source': 'لا يوجد',
    'status': 'مفعل',
    'updated_at': '', // Auto-updated during insertion or edit
  };

    

  String? selectedAreaId; // To store the currently selected area ID
  List<Map<String, String>> areas = []; // List to hold fetched areas

  @override
  void initState() {
    super.initState();
    fetchAreas(); // Fetch areas when the widget is initialized
  }

  /// Fetches areas from Firestore
  Future<void> fetchAreas() async {
    try {
      final areasSnapshot = await FirebaseFirestore.instance.collection('areas').get();
      setState(() {
        areas = areasSnapshot.docs.map((doc) {
          return {
            'id': doc['id'].toString(), // Use the 'id' field inside the document
            'name': doc['name'].toString(), // Use the 'name' field for display
          };
        }).toList();
      });
    } catch (error) {
      print('Error fetching areas: $error');
    }
  }

  Future<void> submitForm() async {
  if (!_formKey.currentState!.validate()) return;

  _formKey.currentState!.save();

  // Add or update the necessary fields
  try {
    // Generate `created_at` and `updated_at` timestamps
    formData['created_at'] = DateTime.now().toIso8601String();
    formData['updated_at'] = DateTime.now().toIso8601String();

    // Generate an auto-incrementing `id`
    final querySnapshot = await FirebaseFirestore.instance
        .collection('cases')
        .orderBy('id', descending: true)
        .limit(1)
        .get();

    int nextId = 1; // Default ID if no cases exist
    if (querySnapshot.docs.isNotEmpty) {
      final lastCase = querySnapshot.docs.first.data();
      nextId = (lastCase['id'] != null ? int.parse(lastCase['id']) : 0) + 1;
    }

    // Add the `id` field to the formData
    formData['id'] = nextId.toString(); // Ensure it's saved as a String

    // Save the selected area's ID as it is
    formData['area_id'] = selectedAreaId ?? '';

    // Push form data to Firestore
    final docRef = FirebaseFirestore.instance.collection('cases').doc();
    await docRef.set(formData);

    // Show success message and navigate back
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ الحالة بنجاح')),
    );

    Navigator.pop(context);
  } catch (error) {
    print('Error during submission: $error');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('خطأ أثناء حفظ الحالة: $error')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة حالة'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Directionality( // Ensure right-to-left directionality
          textDirection: TextDirection.rtl,
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                buildTextField('الاسم', 'أدخل الاسم', 'name'),
                buildTextField('العنوان', 'أدخل العنوان', 'location'),
                buildTextField('الحالة الاجتماعية', 'أدخل الحالة الاجتماعية', 'social_status'),
                buildTextField('الدخل', 'أدخل الدخل', 'in_come', inputType: TextInputType.number),
                buildTextField('عدد أعضاء الأسرة', 'أدخل عدد أعضاء الأسرة', 'family_count', inputType: TextInputType.number),
                buildTextField('الرقم القومي', 'أدخل الرقم القومي', 'ID_Number'),
                buildTextField('رقم هاتف', 'أدخل رقم الهاتف', 'number', inputType: TextInputType.phone),
                buildTextField('مقاس الملابس', 'أدخل مقاس الملابس', 'c_size'),
                buildTextField('مقاس جهاز العوسة', 'أدخل مقاس جهاز العوسة', 'S_size'),
                buildTextField('العمر', 'أدخل العمر', 'age', inputType: TextInputType.number),
                buildAreaDropdown(), // Dropdown for areas
                buildTextField(' المرحلة الدراسية', 'أدخل المرحلة الدراسية', 'grade_id', inputType: TextInputType.number),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('إلغاء'),
                    ),
                    ElevatedButton(
                      onPressed: submitForm,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('حفظ'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a dropdown for selecting an area
  Widget buildAreaDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: selectedAreaId,
        items: areas.map((area) {
          return DropdownMenuItem<String>(
            value: area['id'], // Use area ID as value
            child: Text(area['name'] ?? ''), // Display area name
          );
        }).toList(),
        decoration: const InputDecoration(
          labelText: 'المنطقة',
          border: OutlineInputBorder(),
        ),
        validator: (value) => value == null || value.isEmpty ? 'يرجى اختيار المنطقة' : null,
        onChanged: (value) {
          setState(() {
            selectedAreaId = value; // Save the selected area's ID
          });
        },
      ),
    );
  }

  Widget buildTextField(String label, String hint, String key,
      {TextInputType inputType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        textDirection: TextDirection.rtl, // Align text to the right
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        keyboardType: inputType,
        validator: (value) =>
            value == null || value.isEmpty ? 'الرجاء إدخال $label' : null,
        onSaved: (value) => formData[key] = value!,
      ),
    );
  }
}
