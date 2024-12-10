import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreFieldFixer extends StatelessWidget {
  const FirestoreFieldFixer({super.key});

  // Function to fix field types
  Future<void> _fixFieldTypes(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;
    final casesCollection = firestore.collection('cases');

    try {
      final snapshot = await casesCollection.get();

      for (var doc in snapshot.docs) {
        final data = doc.data();

        await casesCollection.doc(doc.id).update({
          'id': int.tryParse(data['id'].toString()) ?? 0,
          'name': data['name']?.toString() ?? '',
          'ID_Number': data['ID_Number']?.toString() ?? '',
          'number': data['number']?.toString() ?? '',
          'location': data['location']?.toString() ?? '',
          'social_status': data['social_status']?.toString() ?? '',
          'in_come': int.tryParse(data['in_come'].toString()) ?? 0,
          'family_count': int.tryParse(data['family_count'].toString()) ?? 0,
          'c_size': data['c_size']?.toString() ?? '',
          'S_size': data['S_size']?.toString() ?? '',
          'age': int.tryParse(data['age'].toString()) ?? 0,
          'grade_id': int.tryParse(data['grade_id'].toString()) ?? 0,
          'area_id': int.tryParse(data['area_id'].toString()) ?? 0,
          'balance': int.tryParse(data['balance'].toString()) ?? 0,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إصلاح الأنواع بنجاح لجميع الحقول.')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الإصلاح: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () => _fixFieldTypes(context),
        child: const Text('إصلاح أنواع الحقول في Firestore'),
      ),
    );
  }
}
