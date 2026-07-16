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
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حفظ التعديلات بنجاح')));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (caseData.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('تعديل بيانات الحالة كاملة'),
            bottom: TabBar(
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              tabs: const [
                Tab(icon: Icon(Icons.person), text: 'البيانات الشخصية'),
                Tab(icon: Icon(Icons.payments), text: 'المالية والدراسة'),
                Tab(
                    icon: Icon(Icons.connect_without_contact),
                    text: 'الكفلاء والصناديق'),
              ],
            ),
          ),
          body: Form(
            key: _formKey,
            child: TabBarView(
              children: [
                // Tab 1: Personal Info
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTextField('الاسم', 'name', Icons.person),
                      _buildTextField(
                          'اسم الأم', 'mother_name', Icons.person_outline),
                      _buildTextField('الرقم القومي', 'ID_Number', Icons.badge,
                          isNumber: true),
                      _buildTextField('رقم الهاتف', 'number', Icons.phone,
                          isNumber: true),
                      _buildTextField('العنوان', 'location', Icons.location_on),
                      _buildTextField('الحالة الاجتماعية', 'social_status',
                          Icons.family_restroom),
                      _buildTextField(
                          'عدد أفراد الأسرة', 'family_count', Icons.groups,
                          isNumber: true),
                      const SizedBox(height: 8),
                      _buildDatePickerField(),
                    ],
                  ),
                ),

                // Tab 2: Financial & Study Info
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTextField('الدخل', 'in_come', Icons.payments,
                          isNumber: true),
                      _buildTextField('القبض الشهري', 'balance',
                          Icons.account_balance_wallet,
                          isNumber: true),
                      _buildTextField(
                          'المرحلة الدراسية', 'grade_id', Icons.school),
                      _buildTextField('المنطقة ID', 'area_id', Icons.map,
                          isNumber: true),
                      _buildTextField(
                          'مقاس الملابس', 'c_size', Icons.straighten),
                      _buildTextField('مقاس الحذاء', 'S_size', Icons.checkroom),
                    ],
                  ),
                ),

                // Tab 3: Sponsors & Chests Selection
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSelectionBox(
                        title: 'الكفلاء المرتبطون',
                        items: allSubs,
                        selectionMap: selectedSubIds,
                        searchQuery: subSearchQuery,
                        onSearchChanged: (value) =>
                            setState(() => subSearchQuery = value),
                        onSelectionChanged: (id, isSelected) {
                          setState(() {
                            selectedSubIds[id] = isSelected;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildSelectionBox(
                        title: 'الصناديق المرتبطة',
                        items: allChests,
                        selectionMap: selectedChestIds,
                        searchQuery: chestSearchQuery,
                        onSearchChanged: (value) =>
                            setState(() => chestSearchQuery = value),
                        onSelectionChanged: (id, isSelected) {
                          setState(() {
                            selectedChestIds[id] = isSelected;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saveCase,
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text(
                  'حفظ التعديلات',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String key, IconData icon,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        initialValue: caseData[key]?.toString(),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Theme.of(context).primaryColor, width: 2),
          ),
        ),
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

  Widget _buildDatePickerField() {
    return Padding(
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
          decoration: InputDecoration(
            labelText: 'تاريخ الميلاد',
            prefixIcon: Icon(Icons.cake, color: Theme.of(context).primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Text(
            _selectedBirthDate == null
                ? (caseData['age'] != null
                    ? 'تاريخ الميلاد غير مسجل (العمر القديم: ${caseData['age']})'
                    : 'اضغط لاختيار تاريخ الميلاد')
                : '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year} (العمر: ${AgeCalculator.calculateAge(_selectedBirthDate!.toIso8601String(), caseData['age'])})',
            style: TextStyle(
              fontSize: 16,
              color: _selectedBirthDate == null && caseData['age'] == null
                  ? Colors.grey
                  : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionBox({
    required String title,
    required List<Map<String, dynamic>> items,
    required Map<int, bool> selectionMap,
    required String searchQuery,
    required ValueChanged<String> onSearchChanged,
    required Function(int, bool) onSelectionChanged,
  }) {
    final filtered = items
        .where((item) =>
            item['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
            item['id'].toString().contains(searchQuery))
        .toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم أو الرقم...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'لا توجد نتائج مطابقة',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final itemId = item['id'] as int;
                        final isSelected = selectionMap[itemId] ?? false;

                        return CheckboxListTile(
                          activeColor: Theme.of(context).primaryColor,
                          checkboxShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          title: Text(
                            '${item['name']}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text('ID: $itemId',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                          value: isSelected,
                          onChanged: (val) {
                            onSelectionChanged(itemId, val ?? false);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
