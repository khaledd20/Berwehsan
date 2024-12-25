import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InsertCase extends StatefulWidget {
  @override
  _InsertCaseState createState() => _InsertCaseState();
}

class _InsertCaseState extends State<InsertCase> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController socialStatusController = TextEditingController();
  final TextEditingController incomeController = TextEditingController();
  final TextEditingController familyCountController = TextEditingController();
  final TextEditingController idNumberController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  final TextEditingController cSizeController = TextEditingController();
  final TextEditingController sSizeController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController gradeIdController = TextEditingController();
  final TextEditingController balanceController =
      TextEditingController(); // New controller for `balance`

  String? selectedAreaId;
  List<Map<String, dynamic>> areas = [];
  List<Map<String, dynamic>> chests = [];
  List<Map<String, dynamic>> subs = [];
  List<int> selectedChestIds = [];
  List<int> selectedSubIds = [];

  @override
  void initState() {
    super.initState();
    fetchAreas();
    fetchChests();
    fetchSubs();
  }

  Future<void> fetchAreas() async {
    try {
      final areasSnapshot =
          await FirebaseFirestore.instance.collection('areas').get();
      setState(() {
        areas = areasSnapshot.docs.map((doc) {
          return {
            'id': doc['id'],
            'name': doc['name'].toString(),
          };
        }).toList();
      });
    } catch (error) {
      print('Error fetching areas: $error');
    }
  }

  Future<void> fetchChests() async {
    try {
      final chestsSnapshot =
          await FirebaseFirestore.instance.collection('chests').get();
      setState(() {
        chests = chestsSnapshot.docs.map((doc) {
          return {
            'id': doc['id'], // ID is expected to be a number
            'name': doc['name'].toString(),
          };
        }).toList();
      });
    } catch (error) {
      print('Error fetching chests: $error');
    }
  }

  Future<void> fetchSubs() async {
    try {
      final subsSnapshot =
          await FirebaseFirestore.instance.collection('subs').get();
      setState(() {
        subs = subsSnapshot.docs.map((doc) {
          return {
            'id': doc['id'], // ID is expected to be a number
            'name': doc['name'].toString(),
          };
        }).toList();
      });
    } catch (error) {
      print('Error fetching subs: $error');
    }
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Collect all field values
      final formData = {
        'name': nameController.text,
        'location': locationController.text,
        'social_status': socialStatusController.text,
        'in_come':
            int.tryParse(incomeController.text) ?? 0, // Convert to integer
        'family_count': int.tryParse(familyCountController.text) ?? 0,
        'ID_Number': idNumberController.text,
        'number': numberController.text,
        'c_size': cSizeController.text,
        'S_size': sSizeController.text,
        'age': int.tryParse(ageController.text) ?? 0,
        'grade_id': gradeIdController.text,
        'area_id': int.tryParse(selectedAreaId ?? '0') ?? 0,
        'chest_ids': selectedChestIds, // Store as numbers
        'sub_ids': selectedSubIds, // Store as numbers
        'balance': int.tryParse(balanceController.text) ??
            0, // Parse and store as number
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'status': 'مفعل',
      };

      // Generate the smallest available ID starting from 1
      int nextId = 1;
      bool idExists = true;

      while (idExists) {
        final existingCase = await FirebaseFirestore.instance
            .collection('cases')
            .where('id', isEqualTo: nextId)
            .get();

        if (existingCase.docs.isEmpty) {
          idExists = false; // ID is available
        } else {
          nextId++; // Check the next ID
        }
      }

      formData['id'] = nextId;

      // Save the data to Firestore
      final docRef = FirebaseFirestore.instance.collection('cases').doc();
      await docRef.set(formData);

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
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                buildTextField('الاسم', 'أدخل الاسم', nameController),
                buildTextField('العنوان', 'أدخل العنوان', locationController),
                buildTextField('الحالة الاجتماعية', 'أدخل الحالة الاجتماعية',
                    socialStatusController),
                buildTextField('الدخل', 'أدخل الدخل', incomeController,
                    inputType: TextInputType.number),
                buildTextField('عدد أعضاء الأسرة', 'أدخل عدد أعضاء الأسرة',
                    familyCountController,
                    inputType: TextInputType.number),
                buildTextField(
                    'الرقم القومي', 'أدخل الرقم القومي', idNumberController),
                buildTextField('رقم هاتف', 'أدخل رقم الهاتف', numberController,
                    inputType: TextInputType.phone),
                buildTextField(
                    'مقاس الملابس', 'أدخل مقاس الملابس', cSizeController),
                buildTextField(
                    'مقاس  الحذاء', 'أدخل مقاس  الحذاء', sSizeController),
                buildTextField('العمر', 'أدخل العمر', ageController,
                    inputType: TextInputType.number),
                buildTextField('القبض', 'أدخل القبض', balanceController,
                    inputType: TextInputType.number), // New balance field
                buildAreaDropdown(),
                buildMultiSelectDropdown(
                    'اختر الصناديق', chests, selectedChestIds),
                buildMultiSelectDropdown(
                    'اختر المشتركين', subs, selectedSubIds),
                buildTextField('المرحلة الدراسية', 'أدخل المرحلة الدراسية',
                    gradeIdController),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('إلغاء'),
                    ),
                    ElevatedButton(
                      onPressed: submitForm,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
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

  Widget buildTextField(
      String label, String hint, TextEditingController controller,
      {TextInputType inputType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        keyboardType: inputType,
        validator: (value) =>
            value == null || value.isEmpty ? 'الرجاء إدخال $label' : null,
      ),
    );
  }

  Widget buildAreaDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: selectedAreaId,
        items: areas.map((area) {
          return DropdownMenuItem<String>(
            value: area['id'].toString(),
            child: Text(area['name'] ?? ''),
          );
        }).toList(),
        decoration: const InputDecoration(
          labelText: 'المنطقة',
          border: OutlineInputBorder(),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? 'يرجى اختيار المنطقة' : null,
        onChanged: (value) {
          setState(() {
            selectedAreaId = value;
          });
        },
      ),
    );
  }

  Widget buildMultiSelectDropdown(
      String label, List<Map<String, dynamic>> items, List<int> selectedItems) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ...items.map((item) {
              return CheckboxListTile(
                value: selectedItems.contains(item['id']),
                title: Text(item['name'] ?? ''),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      selectedItems.add(item['id']);
                    } else {
                      selectedItems.remove(item['id']);
                    }
                  });
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
