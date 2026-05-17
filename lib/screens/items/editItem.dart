import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:berwehsan/core/user_session.dart';

class EditItemPage extends StatelessWidget {
  final String itemId;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController countController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  EditItemPage({super.key, required this.itemId});

  Future<void> loadItemData() async {
    final doc =
        await FirebaseFirestore.instance.collection('items').doc(itemId).get();
    final itemData = doc.data();
    if (itemData != null) {
      nameController.text = itemData['name'] ?? '';
      countController.text = itemData['count'].toString();
      noteController.text = itemData['note'] ?? '';
    }
  }

  void updateItem(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('items').doc(itemId).update({
        'name': nameController.text,
        'count': int.tryParse(countController.text) ?? 0,
        'note': noteController.text,
        'updated_at': DateTime.now().toIso8601String(),
        'userName': UserSession().fullName,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث العنصر بنجاح!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تحديث العنصر: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: loadItemData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return Directionality(
          textDirection:
              TextDirection.rtl, // Right-to-left alignment for Arabic
          child: Scaffold(
            appBar: AppBar(title: const Text('تعديل العنصر')),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(labelText: 'اسم العنصر'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: countController,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(labelText: 'العدد'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(labelText: 'ملاحظات'),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => updateItem(context),
                      child: const Text('تحديث العنصر'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
