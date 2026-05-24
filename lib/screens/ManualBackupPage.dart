import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:convert';

class ManualBackupPage extends StatefulWidget {
  const ManualBackupPage({super.key});

  @override
  State<ManualBackupPage> createState() => _ManualBackupPageState();
}

class _ManualBackupPageState extends State<ManualBackupPage> {
  String status = 'اضغط على الزر لعمل نسخة احتياطية الآن.';
  bool isLoading = false;

  Future<void> _startManualBackup() async {
    setState(() {
      isLoading = true;
      status = 'جاري إنشاء النسخة الاحتياطية...';
    });

    try {
      await BackupManager().manualBackup(); // Call manual backup
      setState(() {
        status = '✅ تم إنشاء النسخة الاحتياطية بنجاح';
      });
    } catch (e) {
      setState(() {
        status = '❌ فشل في إنشاء النسخة: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('نسخ احتياطي يدوي')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.backup),
                  label: const Text('إنشاء نسخة احتياطية الآن'),
                  onPressed: isLoading ? null : _startManualBackup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BackupManager {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  final List<String> collectionNames = [
    'admins',
    'areas',
    'cases',
    'cashs',
    'chest_log',
    'chests',
    'feedings',
    'finance',
    'finance_log',
    'items',
    'itineraries',
    'metadata',
    'store_log',
    'subs'
  ];

  Future<void> manualBackup() async {
    try {
      final Map<String, dynamic> backupData = {};

      for (String collectionName in collectionNames) {
        final collectionSnapshot =
            await firestore.collection(collectionName).get();

        backupData[collectionName] = collectionSnapshot.docs.map((doc) {
          return {'id': doc.id, 'data': doc.data()};
        }).toList();

        print(
            "✅ تم سحب بيانات $collectionName بعدد ${collectionSnapshot.docs.length} سجل");
      }

      final String jsonData = jsonEncode(backupData);
      final String fileName = '${DateTime.now().toIso8601String()}-backup.json';

      final ref = storage.ref('backups/$fileName');
      await ref.putString(jsonData);

      print("✅ النسخة الاحتياطية رفعت بنجاح: $fileName");
    } catch (e) {
      print("❌ خطأ أثناء النسخ الاحتياطي: $e");
      rethrow;
    }
  }
}
