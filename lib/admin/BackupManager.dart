import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:convert';

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

  Future<void> performBackup() async {
    try {
      // Check for backups in the last 2 weeks
      final backupRef = storage.ref('backups/');
      final ListResult result = await backupRef.listAll();
      final DateTime now = DateTime.now();
      final DateTime twoWeeksAgo = now.subtract(const Duration(days: 14));

      bool recentBackupExists = false;

      for (var item in result.items) {
        try {
          // Extract and parse the timestamp from the filename
          final String rawTimestamp = item.name.split('-backup.json').first;
          final DateTime? backupDate = DateTime.tryParse(rawTimestamp);

          if (backupDate != null && backupDate.isAfter(twoWeeksAgo)) {
            recentBackupExists = true;
            print("Recent backup exists: ${item.name}");
            break;
          }
        } catch (e) {
          print("Error parsing date from file name: ${item.name} - $e");
        }
      }

      if (recentBackupExists) {
        print("A recent backup exists. Skipping new backup.");
        return; // Exit the backup process if a recent backup exists
      }

      // Proceed with the backup process
      final Map<String, dynamic> backupData = {};

      for (String collectionName in collectionNames) {
        try {
          final collectionSnapshot = await firestore.collection(collectionName).get();

          if (collectionSnapshot.docs.isNotEmpty) {
            backupData[collectionName] = collectionSnapshot.docs.map((doc) {
              return {'id': doc.id, 'data': doc.data()};
            }).toList();
            print("Fetched collection: $collectionName with ${collectionSnapshot.docs.length} documents.");
          } else {
            print("Collection $collectionName is empty.");
          }
        } catch (e) {
          print("Error fetching collection $collectionName: $e");
        }
      }

      // Convert data to JSON
      final String jsonData = jsonEncode(backupData);

      // Generate a sanitized file name for the backup
      final String backupFileName = '${DateTime.now().toIso8601String()}-backup.json';

      // Upload the JSON file to Firebase Storage
      final ref = storage.ref('backups/$backupFileName');
      await ref.putString(jsonData);

      print("Backup created successfully: $backupFileName");
    } catch (e) {
      print("Error during backup: $e");
    }
  }
}
