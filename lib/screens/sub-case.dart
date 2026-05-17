// New page to manage sub-case relationships with filters and search

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LinkCasesToSubPage extends StatefulWidget {
  final int subId;
  final String subName;
  const LinkCasesToSubPage(
      {super.key, required this.subId, required this.subName});

  @override
  State<LinkCasesToSubPage> createState() => _LinkCasesToSubPageState();
}

class _LinkCasesToSubPageState extends State<LinkCasesToSubPage> {
  Map<String, bool> selectedCases = {};
  List<QueryDocumentSnapshot> allCases = [];
  String searchQuery = '';
  String selectedArea = 'الكل';
  String selectedStatus = 'الكل';

  final List<String> areas = ['الكل', 'منشية ناصر', 'عين شمس', 'السلام'];
  final List<String> socialStatuses = ['الكل', 'يتيم', 'مطلقة', 'أرملة'];

  @override
  void initState() {
    super.initState();
    loadCases();
  }

  Future<void> loadCases() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('cases').get();

    setState(() {
      allCases = querySnapshot.docs;
      for (var doc in allCases) {
        final data = doc.data() as Map<String, dynamic>;
        final subIds = List.from(data['sub_ids'] ?? []);
        selectedCases[doc.id] = subIds.contains(widget.subId);
      }
    });
  }

  Future<void> saveSelections() async {
    List<Future> updateFutures = [];

    for (var doc in allCases) {
      final docId = doc.id;
      final data = doc.data() as Map<String, dynamic>;
      final currentSubIds = List<int>.from(data['sub_ids'] ?? []);
      final isSelected = selectedCases[docId] ?? false;

      final alreadyLinked = currentSubIds.contains(widget.subId);

      if (isSelected && !alreadyLinked) {
        currentSubIds.add(widget.subId);
      } else if (!isSelected && alreadyLinked) {
        currentSubIds.remove(widget.subId);
      } else {
        continue; // لا حاجة للتحديث إذا لم تتغير القيمة
      }

      // بدلاً من await داخل الحلقة نستخدم قائمة futures
      updateFutures.add(
        FirebaseFirestore.instance
            .collection('cases')
            .doc(docId)
            .update({'sub_ids': currentSubIds}),
      );
    }

    try {
      await Future.wait(updateFutures); // تنفيذ المتغيرات بالتوازي
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث الحالات بنجاح')),
      );
    } catch (e) {
      print('Error updating cases: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء حفظ التغييرات: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredCases = allCases.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = data['name']?.toString().toLowerCase() ?? '';
      final location = data['location'] ?? '';
      final status = data['social_status'] ?? '';
      final id = data['id']?.toString() ?? '';

      final matchesSearch = searchQuery.isEmpty ||
          name.contains(searchQuery.toLowerCase()) ||
          id == searchQuery;
      final matchesArea = selectedArea == 'الكل' || location == selectedArea;
      final matchesStatus =
          selectedStatus == 'الكل' || status == selectedStatus;

      return matchesSearch && matchesArea && matchesStatus;
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('ربط الحالات بالكفالة: ${widget.subName}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: saveSelections,
              tooltip: 'حفظ التغييرات',
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'بحث بالاسم أو رقم الحالة',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) =>
                    setState(() => searchQuery = value.trim()),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                DropdownButton<String>(
                  value: selectedArea,
                  items: areas
                      .map((area) =>
                          DropdownMenuItem(value: area, child: Text(area)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedArea = val!),
                ),
                DropdownButton<String>(
                  value: selectedStatus,
                  items: socialStatuses
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedStatus = val!),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: filteredCases.isEmpty
                  ? const Center(child: Text('لا توجد حالات مطابقة'))
                  : ListView.builder(
                      itemCount: filteredCases.length,
                      itemBuilder: (context, index) {
                        final doc = filteredCases[index];
                        final data = doc.data() as Map<String, dynamic>;

                        return CheckboxListTile(
                          title: Text(data['name'] ?? 'بدون اسم'),
                          subtitle: Text('رقم الحالة: ${data['id']}'),
                          value: selectedCases[doc.id] ?? false,
                          onChanged: (val) {
                            setState(() => selectedCases[doc.id] = val!);
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
