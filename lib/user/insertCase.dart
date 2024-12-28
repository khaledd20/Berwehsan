import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InsertCase extends StatefulWidget {
  @override
  _InsertCaseState createState() => _InsertCaseState();
}

class _InsertCaseState extends State<InsertCase> {
  final _formKey = GlobalKey<FormState>();
    bool isLoading = false;

  // Controllers for text fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController motherNameController = TextEditingController(); // New controller for mother's name
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
  final TextEditingController balanceController = TextEditingController(); // New controller for `balance`
  final TextEditingController chestSearchController = TextEditingController(); // Search controller for chests
  final TextEditingController subSearchController = TextEditingController();   // Search controller for subs
  

  String? selectedAreaId;
  List<Map<String, dynamic>> areas = [];
  List<Map<String, dynamic>> chests = [];
  List<Map<String, dynamic>> subs = [];
  List<int> selectedChestIds = [];
  List<int> selectedSubIds = [];
  List<Map<String, dynamic>> filteredChests = []; // Filtered list for chests
  List<Map<String, dynamic>> filteredSubs = [];   // Filtered list for subs


  @override
  void initState() {
    super.initState();
    fetchAreas();
    fetchChests();
    fetchSubs();
  }

  Future<void> fetchAreas() async {
    try {
      final areasSnapshot = await FirebaseFirestore.instance.collection('areas').get();
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
    final chestsSnapshot = await FirebaseFirestore.instance.collection('chests').get();
    setState(() {
      chests = chestsSnapshot.docs.map((doc) {
        return {
          'id': doc['id'],
          'name': doc['name'].toString(),
        };
      }).toList();
      filteredChests = List.from(chests); // Initialize filtered list
    });
  } catch (error) {
    print('Error fetching chests: $error');
  }
}


  Future<void> fetchSubs() async {
  try {
    final subsSnapshot = await FirebaseFirestore.instance.collection('subs').get();
    setState(() {
      subs = subsSnapshot.docs.map((doc) {
        return {
          'id': doc['id'],
          'name': doc['name'].toString(),
        };
      }).toList();
      filteredSubs = List.from(subs); // Initialize filtered list
    });
  } catch (error) {
    print('Error fetching subs: $error');
  }
}

void filterChests(String query) {
  setState(() {
    filteredChests = chests
        .where((chest) => chest['name'].toLowerCase().contains(query.toLowerCase()))
        .toList();
  });
}

void filterSubs(String query) {
  setState(() {
    filteredSubs = subs
        .where((sub) => sub['name'].toLowerCase().contains(query.toLowerCase()))
        .toList();
  });
}




  Future<void> submitForm() async {
    // Start loading state
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });

    // Perform manual validation for all fields
    if (nameController.text.trim().isEmpty) {
      _showError('الرجاء إدخال الاسم');
      setState(() {
        isLoading = false;
      });
      return;
    }
    if (motherNameController.text.trim().isEmpty) {
      _showError('الرجاء إدخال اسم الأم');
      setState(() {
        isLoading = false;
      });
      return;
    }
    if (locationController.text.trim().isEmpty) {
      _showError('الرجاء إدخال العنوان');
      setState(() {
        isLoading = false;
      });
      return;
    }
    if (socialStatusController.text.trim().isEmpty) {
      _showError('الرجاء إدخال الحالة الاجتماعية');
      setState(() {
        isLoading = false;
      });
      return;
    }
    if (incomeController.text.trim().isEmpty ||
        int.tryParse(incomeController.text.trim()) == null) {
      _showError('الرجاء إدخال الدخل (رقم صحيح)');
      setState(() {
        isLoading = false;
      });
      return;
    }
    if (familyCountController.text.trim().isEmpty ||
        int.tryParse(familyCountController.text.trim()) == null) {
      _showError('الرجاء إدخال عدد أفراد الأسرة (رقم صحيح)');
      setState(() {
        isLoading = false;
      });
      return;
    }
    if (idNumberController.text.trim().isEmpty) {
      _showError('الرجاء إدخال الرقم القومي');
      setState(() {
        isLoading = false;
      });
      return;
    }
    if (numberController.text.trim().isEmpty) {
      _showError('الرجاء إدخال رقم الهاتف');
      setState(() {
        isLoading = false;
      });
      return;
    }
    if (cSizeController.text.trim().isEmpty) {
      _showError('الرجاء إدخال مقاس الملابس');
      setState(() {
        isLoading = false;
      });
      return;
    }
    if (sSizeController.text.trim().isEmpty) {
      _showError('الرجاء إدخال مقاس الحذاء');
      setState(() {
        isLoading = false;
      });
      return;
    }
    if (ageController.text.trim().isEmpty ||
        int.tryParse(ageController.text.trim()) == null) {
      _showError('الرجاء إدخال العمر (رقم صحيح)');
      setState(() {
        isLoading = false;
      });
      return;
    }
    if (balanceController.text.trim().isEmpty ||
        int.tryParse(balanceController.text.trim()) == null) {
      _showError('الرجاء إدخال القبض (رقم صحيح)');
      setState(() {
        isLoading = false;
      });
      return;
    }
    if (gradeIdController.text.trim().isEmpty) {
      _showError('الرجاء إدخال المرحلة الدراسية');
      setState(() {
        isLoading = false;
      });
      return;
    }

    // Additional validations for selectedAreaId, selectedChestIds, and selectedSubIds
    if (selectedAreaId == null || selectedAreaId!.isEmpty) {
      _showError('يرجى اختيار المنطقة');
      setState(() {
        isLoading = false;
      });
      return;
    }

    if (selectedChestIds.isEmpty) {
      _showError('يرجى اختيار صندوق واحد على الأقل');
      setState(() {
        isLoading = false;
      });
      return;
    }

    if (selectedSubIds.isEmpty) {
      _showError('يرجى اختيار مشترك واحد على الأقل');
      setState(() {
        isLoading = false;
      });
      return;
    }

      try {
      // Validate fields as before (omitted for brevity)

       // Find the next available ID in the `cases` collection
        int nextId = 1;
        bool idFound = false;

        while (!idFound) {
          final querySnapshot = await FirebaseFirestore.instance
              .collection('cases')
              .where('id', isEqualTo: nextId)
              .get();

          if (querySnapshot.docs.isEmpty) {
            idFound = true; // No document with this ID exists
          } else {
            nextId++; // Check the next ID
          }
        }

      // Prepare form data
      final formData = {
        'id': nextId,
        'name': nameController.text,
        'mother_name': motherNameController.text,
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
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'status': 'مفعل',
      };

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
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
// Helper function to show error messages
void _showError(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ),
  );
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
                buildTextField('اسم الأم', 'أدخل اسم الأم', motherNameController), // New mother's name field
                buildTextField('العنوان', 'أدخل العنوان', locationController),
                buildTextField('الحالة الاجتماعية', 'أدخل الحالة الاجتماعية', socialStatusController),
                buildTextField('الدخل', 'أدخل الدخل', incomeController, inputType: TextInputType.number),
                buildTextField('عدد أعضاء الأسرة', 'أدخل عدد أعضاء الأسرة', familyCountController, inputType: TextInputType.number),
                buildTextField('الرقم القومي', 'أدخل الرقم القومي', idNumberController),
                buildTextField('رقم هاتف', 'أدخل رقم الهاتف', numberController, inputType: TextInputType.phone),
                buildTextField('مقاس الملابس', 'أدخل مقاس الملابس', cSizeController),
                buildTextField('مقاس الحذاء', 'أدخل مقاس الحذاء', sSizeController),
                buildTextField('العمر', 'أدخل العمر', ageController, inputType: TextInputType.number),
                buildTextField('القبض', 'أدخل القبض', balanceController, inputType: TextInputType.number), // New balance field
                buildAreaDropdown(),
                buildMultiSelectDropdownWithSearch(
                  'اختر الصناديق',
                  chestSearchController,
                  filteredChests,
                  selectedChestIds,
                  filterChests,
                ),
                buildMultiSelectDropdownWithSearch(
                  'اختر المشتركين',
                  subSearchController,
                  filteredSubs,
                  selectedSubIds,
                  filterSubs,
                ),
                buildTextField('المرحلة الدراسية', 'أدخل المرحلة الدراسية', gradeIdController),
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
                      onPressed: isLoading ? null : submitForm, // Disable button while loading
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('حفظ'),
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

  Widget buildTextField(String label, String hint, TextEditingController controller, {TextInputType inputType = TextInputType.text}) {
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
        validator: (value) => value == null || value.isEmpty ? 'الرجاء إدخال $label' : null,
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
        validator: (value) => value == null || value.isEmpty ? 'يرجى اختيار المنطقة' : null,
        onChanged: (value) {
          setState(() {
            selectedAreaId = value;
          });
        },
      ),
    );
  }

  Widget buildMultiSelectDropdownWithSearch(
  String label,
  TextEditingController searchController,
  List<Map<String, dynamic>> items,
  List<int> selectedItems,
  Function(String) onSearch,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Card(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                labelText: 'بحث',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: onSearch,
            ),
          ),
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
