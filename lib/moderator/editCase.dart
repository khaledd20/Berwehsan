import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditCase extends StatefulWidget {
  final String caseId;

  const EditCase({Key? key, required this.caseId}) : super(key: key);

  @override
  _EditCaseState createState() => _EditCaseState();
}

class _EditCaseState extends State<EditCase> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for all fields
  final TextEditingController idController =
      TextEditingController(); // Add this
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
  final TextEditingController balanceController = TextEditingController();

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
    fetchCaseDetails();
  }

  // Fetch case details from Firestore
  Future<void> fetchCaseDetails() async {
    try {
      final caseSnapshot = await FirebaseFirestore.instance
          .collection('cases')
          .doc(widget.caseId)
          .get();

      final data = caseSnapshot.data();
      if (data != null) {
        setState(() {
          idController.text = data['id'].toString(); // Populate id field
          nameController.text = data['name'];
          locationController.text = data['location'];
          socialStatusController.text = data['social_status'];
          incomeController.text = data['in_come'].toString();
          familyCountController.text = data['family_count'].toString();
          idNumberController.text = data['ID_Number'];
          numberController.text = data['number'];
          cSizeController.text = data['c_size'];
          sSizeController.text = data['S_size'];
          ageController.text = data['age'].toString();
          gradeIdController.text = data['grade_id'];
          balanceController.text = data['balance'].toString();
          selectedAreaId = data['area_id'].toString();
          selectedChestIds =
              List<int>.from(data['chest_ids'] ?? []); // Chest IDs
          selectedSubIds = List<int>.from(data['sub_ids'] ?? []); // Sub IDs
        });
      }
    } catch (error) {
      print('Error fetching case details: $error');
    }
  }

  Future<void> checkAndUpdateID(String newId) async {
    try {
      // Check if the ID exists in any other case
      final existingCaseSnapshot = await FirebaseFirestore.instance
          .collection('cases')
          .where('id', isEqualTo: int.tryParse(newId))
          .get();

      if (existingCaseSnapshot.docs.isNotEmpty) {
        // ID exists, update that case by removing the ID
        final otherCaseId = existingCaseSnapshot.docs.first.id;

        await FirebaseFirestore.instance
            .collection('cases')
            .doc(otherCaseId)
            .update({'id': FieldValue.delete()});

        print('ID $newId removed from case $otherCaseId');
      }

      // Assign the new ID to the current case
      await FirebaseFirestore.instance
          .collection('cases')
          .doc(widget.caseId)
          .update({'id': int.tryParse(newId)});

      print('ID $newId assigned to case ${widget.caseId}');
    } catch (error) {
      print('Error checking/updating ID: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تعديل المعرف: $error')),
      );
    }
  }

  // Fetch dropdown data
  Future<void> fetchAreas() async {
    final areasSnapshot =
        await FirebaseFirestore.instance.collection('areas').get();
    setState(() {
      areas = areasSnapshot.docs
          .map((doc) => {'id': doc['id'], 'name': doc['name']})
          .toList();
    });
  }

  Future<void> fetchChests() async {
    final chestsSnapshot =
        await FirebaseFirestore.instance.collection('chests').get();
    setState(() {
      chests = chestsSnapshot.docs
          .map((doc) => {'id': doc['id'], 'name': doc['name']})
          .toList();
    });
  }

  Future<void> fetchSubs() async {
    final subsSnapshot =
        await FirebaseFirestore.instance.collection('subs').get();
    setState(() {
      subs = subsSnapshot.docs
          .map((doc) => {'id': doc['id'], 'name': doc['name']})
          .toList();
    });
  }

  // Submit updated data
  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final newId = int.tryParse(idController.text);
    if (newId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال معرف صالح')),
      );
      return;
    }

    try {
      // Fetch current case
      final currentSnapshot = await FirebaseFirestore.instance
          .collection('cases')
          .doc(widget.caseId)
          .get();

      final currentData = currentSnapshot.data();
      final oldId = currentData?['id'] ?? newId;

      // Check if the new ID already exists in another case
      final existingSnapshot = await FirebaseFirestore.instance
          .collection('cases')
          .where('id', isEqualTo: newId)
          .get();

      if (existingSnapshot.docs.isNotEmpty) {
        // Switch IDs if another case already has the new ID
        final otherCaseId = existingSnapshot.docs.first.id;

        await FirebaseFirestore.instance
            .collection('cases')
            .doc(otherCaseId)
            .update({'id': oldId}); // Swap ID with the other case
      }

      // Update the current case with the new ID and form data
      final formData = {
        'id': newId, // Update the ID
        'name': nameController.text,
        'location': locationController.text,
        'social_status': socialStatusController.text,
        'in_come': int.tryParse(incomeController.text) ?? 0,
        'family_count': int.tryParse(familyCountController.text) ?? 0,
        'ID_Number': idNumberController.text,
        'number': numberController.text,
        'c_size': cSizeController.text,
        'S_size': sSizeController.text,
        'age': int.tryParse(ageController.text) ?? 0,
        'grade_id': gradeIdController.text,
        'area_id': int.tryParse(selectedAreaId ?? '0') ?? 0,
        'chest_ids': selectedChestIds,
        'sub_ids': selectedSubIds,
        'balance': int.tryParse(balanceController.text) ?? 0,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance
          .collection('cases')
          .doc(widget.caseId)
          .update(formData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث الحالة بنجاح')),
      );

      Navigator.pop(context);
    } catch (error) {
      print('Error updating case: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل الحالة')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                buildTextField('رقم الحالة', 'أدخل رقم الحالة', idController,
                    inputType: TextInputType.number),
                buildTextField('الاسم', 'أدخل الاسم', nameController),
                buildTextField('العنوان', 'أدخل العنوان', locationController),
                buildTextField('الحالة الاجتماعية', 'أدخل الحالة الاجتماعية',
                    socialStatusController),
                buildTextField('الدخل', 'أدخل الدخل', incomeController,
                    inputType: TextInputType.number),
                buildTextField(
                    'عدد أفراد الأسرة', 'أدخل العدد', familyCountController,
                    inputType: TextInputType.number),
                buildTextField(
                    'الرقم القومي', 'أدخل الرقم القومي', idNumberController),
                buildTextField('الرقم', 'أدخل الرقم', numberController),
                buildTextField('المقاس', 'أدخل المقاس', cSizeController),
                buildTextField('حجم الحذاء', 'أدخل المقاس', sSizeController),
                buildTextField('العمر', 'أدخل العمر', ageController,
                    inputType: TextInputType.number),
                buildTextField(
                    'معرف المرحلة', 'أدخل معرف المرحلة', gradeIdController),
                buildTextField('القبض', 'أدخل القبض', balanceController,
                    inputType: TextInputType.number),
                buildAreaDropdown(),
                buildMultiSelectDropdown(
                    'اختر الصناديق', chests, selectedChestIds),
                buildMultiSelectDropdown(
                    'اختر المشتركين', subs, selectedSubIds),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: submitForm,
                  child: const Text('حفظ التعديلات'),
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
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? 'الرجاء إدخال $label' : null,
      ),
    );
  }

  Widget buildAreaDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedAreaId,
      items: areas.map((area) {
        return DropdownMenuItem<String>(
          value: area['id'].toString(),
          child: Text(area['name']),
        );
      }).toList(),
      onChanged: (value) => setState(() => selectedAreaId = value),
      decoration: const InputDecoration(
        labelText: 'المنطقة',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget buildMultiSelectDropdown(
      String label, List<Map<String, dynamic>> items, List<int> selectedItems) {
    return Card(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ...items.map((item) {
            return CheckboxListTile(
              value: selectedItems.contains(item['id']),
              title: Text(item['name']),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    selectedItems.add(item['id']);
                  } else {
                    selectedItems.remove(item['id']);
                  }
                });
              },
            );
          }),
        ],
      ),
    );
  }
}
