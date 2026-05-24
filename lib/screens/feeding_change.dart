import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:berwehsan/core/user_session.dart';
import 'package:berwehsan/widgets/app_drawer.dart';

class FeedingChangePage extends StatefulWidget {
  const FeedingChangePage({super.key});

  @override
  State<FeedingChangePage> createState() => _FeedingChangePageState();
}

class _FeedingChangePageState extends State<FeedingChangePage> {
  String? selectedDocId;
  final TextEditingController newDateController = TextEditingController();
  bool isLoading = false;

  Future<List<String>> fetchFeedingDocIds() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('feedings').get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  Future<void> renameFeedingDoc(String oldId, String newId) async {
    setState(() => isLoading = true);
    try {
      final docRef =
          FirebaseFirestore.instance.collection('feedings').doc(oldId);
      final docSnap = await docRef.get();
      if (!docSnap.exists) throw Exception('المستند غير موجود');
      final data = docSnap.data();

      // Create new doc with newId
      await FirebaseFirestore.instance
          .collection('feedings')
          .doc(newId)
          .set(data!);
      // Delete old doc
      await docRef.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تغيير اسم المستند بنجاح!')),
      );
      setState(() {
        selectedDocId = null;
        newDateController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تغيير تاريخ مستند التغذية')),
        drawer: const AppDrawer(),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<List<String>>(
            future: fetchFeedingDocIds(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docIds = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('اختر تاريخ المستند الحالي:'),
                  DropdownButton<String>(
                    value: selectedDocId,
                    isExpanded: true,
                    items: docIds.map((id) {
                      return DropdownMenuItem(
                        value: id,
                        child: Text(id, textAlign: TextAlign.right),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => selectedDocId = val),
                    hint: const Text('اختر تاريخ المستند'),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: newDateController,
                    decoration: const InputDecoration(
                      labelText: 'التاريخ الجديد (مثال: 2024-07-02)',
                      border: OutlineInputBorder(),
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isLoading ||
                            selectedDocId == null ||
                            newDateController.text.isEmpty ||
                            !UserSession().isAdmin
                        ? null
                        : () => renameFeedingDoc(
                            selectedDocId!, newDateController.text.trim()),
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text('تغيير التاريخ'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
