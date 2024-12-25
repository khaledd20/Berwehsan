import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddItemPage extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController countController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  void addItem(BuildContext context) async {
    try {
      final newItem = {
        'name': nameController.text,
        'count': int.tryParse(countController.text) ?? 0,
        'note': noteController.text,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Auto-generate an ID for the new item
      final itemRef = FirebaseFirestore.instance.collection('items').doc();
      newItem['id'] = DateTime.now().millisecondsSinceEpoch % 1000; // Example ID generation
      await itemRef.set(newItem);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم إضافة العنصر بنجاح!',
            textAlign: TextAlign.right,
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'فشل في إضافة العنصر: $e',
            textAlign: TextAlign.right,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إضافة عنصر'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Align labels and fields from right to left
            children: [
              TextField(
                controller: nameController,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'اسم العنصر',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: countController,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'العدد',
                  alignLabelWithHint: true,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteController,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => addItem(context),
                child: const Text('إضافة العنصر'),
                style: ElevatedButton.styleFrom(
                  alignment: Alignment.center, // Align button content to the right
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
