// Full Case Edit Page with Sub and Chest Search
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:berwehsan/core/user_session.dart';
import 'package:berwehsan/core/age_calculator.dart';

class EditFullCase extends StatefulWidget {
  final String docId;
  const EditFullCase({super.key, required this.docId});

  @override
  State<EditFullCase> createState() => _EditFullCaseState();
}

class _EditFullCaseState extends State<EditFullCase> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> caseData = {};
  DateTime? _selectedBirthDate;

  List<Map<String, dynamic>> allSubs = [];
  Map<int, bool> selectedSubIds = {};
  String subSearchQuery = '';

  List<Map<String, dynamic>> allChests = [];
  Map<int, bool> selectedChestIds = {};
  String chestSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCase();
    _loadSubs();
    _loadChests();
  }

  Future<void> _loadCase() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('cases')
        .doc(widget.docId)
        .get();
    setState(() {
      caseData = snapshot.data() ?? {};
      if (caseData['birth_date'] != null &&
          caseData['birth_date'].toString().isNotEmpty) {
        _selectedBirthDate =
            DateTime.tryParse(caseData['birth_date'].toString());
      }
      for (var id in List<int>.from(caseData['sub_ids'] ?? [])) {
        selectedSubIds[id] = true;
      }
      for (var id in List<int>.from(caseData['chest_ids'] ?? [])) {
        selectedChestIds[id] = true;
      }
    });
  }

  Future<void> _loadSubs() async {
    final query = await FirebaseFirestore.instance.collection('subs').get();
    setState(() {
      allSubs = query.docs.map((doc) {
        final data = doc.data();
        return {'id': data['id'], 'name': data['name']};
      }).toList();
    });
  }

  Future<void> _loadChests() async {
    final query = await FirebaseFirestore.instance.collection('chests').get();
    setState(() {
      allChests = query.docs.map((doc) {
        final data = doc.data();
        return {'id': data['id'], 'name': data['name']};
      }).toList();
    });
  }

  Future<void> _saveCase() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final sIds = selectedSubIds.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();
      final cIds = selectedChestIds.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      caseData['sub_ids'] = sIds;
      caseData['chest_ids'] = cIds;
      caseData['updated_at'] = DateTime.now().toIso8601String();
      caseData['birth_date'] = _selectedBirthDate?.toIso8601String() ?? '';
      caseData['age'] = AgeCalculator.calculateAge(
          _selectedBirthDate?.toIso8601String(), caseData['age']);
      caseData['userName'] = UserSession().fullName;
      await FirebaseFirestore.instance
          .collection('cases')
          .doc(widget.docId)
          .update(caseData);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم حفظ التعديلات')));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (caseData.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final filteredSubs = allSubs
        .where((sub) =>
            sub['name'].toLowerCase().contains(subSearchQuery.toLowerCase()) ||
            sub['id'].toString().contains(subSearchQuery))
        .toList();

    final filteredChests = allChests
        .where((chest) =>
            chest['name']
                .toLowerCase()
                .contains(chestSearchQuery.toLowerCase()) ||
            chest['id'].toString().contains(chestSearchQuery))
        .toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تعديل بيانات الحالة كاملة'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveCase,
            )
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField('الاسم', 'name'),
                _buildTextField('اسم الأم', 'mother_name'),
                _buildTextField('الرقم القومي', 'ID_Number', isNumber: true),
                _buildTextField('رقم الهاتف', 'number', isNumber: true),
                _buildTextField('العنوان', 'location'),
                _buildTextField('الحالة الاجتماعية', 'social_status'),
                _buildTextField('الدخل', 'in_come', isNumber: true),
                _buildTextField('عدد أفراد الأسرة', 'family_count',
                    isNumber: true),
                _buildTextField('مقاس الملابس', 'c_size'),
                _buildTextField('مقاس الحذاء', 'S_size'),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedBirthDate ?? DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedBirthDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'تاريخ الميلاد',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _selectedBirthDate == null
                            ? (caseData['age'] != null
                                ? 'تاريخ الميلاد غير مسجل (العمر القديم: ${caseData['age']})'
                                : 'اضغط لاختيار تاريخ الميلاد')
                            : '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year} (العمر: ${AgeCalculator.calculateAge(_selectedBirthDate!.toIso8601String(), caseData['age'])})',
                        style: TextStyle(
                            color: _selectedBirthDate == null &&
                                    caseData['age'] == null
                                ? Colors.grey
                                : Colors.black),
                      ),
                    ),
                  ),
                ),
                _buildTextField('المرحلة الدراسية', 'grade_id'),
                _buildTextField('المنطقة ID', 'area_id', isNumber: true),
                _buildTextField('القبض', 'balance', isNumber: true),
                const SizedBox(height: 16),
                const Text('بحث في الكفلاء:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextFormField(
                  onChanged: (value) => setState(() => subSearchQuery = value),
                  decoration: const InputDecoration(
                      hintText: 'ابحث بالاسم أو الرقم',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                const Text('الكفلاء المرتبطون',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...filteredSubs.map((sub) {
                  final subId = sub['id'];
                  return CheckboxListTile(
                    title: Text('${sub['name']} (ID: $subId)'),
                    value: selectedSubIds[subId] ?? false,
                    onChanged: (val) =>
                        setState(() => selectedSubIds[subId] = val!),
                  );
                }),
                const SizedBox(height: 24),
                const Text('بحث في الصناديق:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextFormField(
                  onChanged: (value) =>
                      setState(() => chestSearchQuery = value),
                  decoration: const InputDecoration(
                      hintText: 'ابحث بالاسم أو الرقم',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                const Text('الصناديق المرتبطة',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...filteredChests.map((chest) {
                  final chestId = chest['id'];
                  return CheckboxListTile(
                    title: Text('${chest['name']} (ID: $chestId)'),
                    value: selectedChestIds[chestId] ?? false,
                    onChanged: (val) =>
                        setState(() => selectedChestIds[chestId] = val!),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String key, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        initialValue: caseData[key]?.toString(),
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        onSaved: (val) {
          if (isNumber) {
            caseData[key] = int.tryParse(val ?? '') ?? 0;
          } else {
            caseData[key] = val ?? '';
          }
        },
      ),
    );
  }
}
