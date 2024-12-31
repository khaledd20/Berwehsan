import 'dart:convert'; // For JSON encoding/decoding
import 'dart:typed_data'; // For Uint8List
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:berwehsan/widgets/admin_drawer.dart'; // Import AdminDrawer

class RestoreManager {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  // List of Firestore collections to restore
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

  Future<List<String>> fetchBackupDates() async {
    final List<String> backupDates = [];
    final backupRef = storage.ref('backups/');
    final ListResult result = await backupRef.listAll();

    for (var item in result.items) {
      // Extract the timestamp from the file name
      final String fileName = item.name;
      final String rawTimestamp = fileName.split('-backup.json').first;

      // Validate and add to the list
      final DateTime? backupDate = DateTime.tryParse(rawTimestamp);
      if (backupDate != null) {
        backupDates.add(rawTimestamp); // Add full timestamp
      } else {
        print("Invalid date format in file name: $fileName");
      }
    }

    return backupDates;
  }

  Future<void> restoreBackup(String selectedDate) async {
    try {
      final ref = storage.ref('backups/$selectedDate-backup.json');

      // Get the data as Uint8List
      final Uint8List? data = await ref.getData(1024 * 1024 * 10);

      if (data == null) {
        print("No backup data found.");
        return;
      }

      // Decode the Uint8List into a String
      final String jsonData = utf8.decode(data);

      // Parse the JSON data
      final Map<String, dynamic> backupData = jsonDecode(jsonData);

      // Clear Firestore collections
      for (var collectionName in collectionNames) {
        final collection = firestore.collection(collectionName);
        final querySnapshot = await collection.get();
        for (var doc in querySnapshot.docs) {
          await collection.doc(doc.id).delete();
        }
      }

      // Restore data
      backupData.forEach((collectionName, documents) async {
        for (var doc in documents) {
          await firestore
              .collection(collectionName)
              .doc(doc['id'])
              .set(doc['data']);
        }
      });

      print("Database restored successfully.");
    } catch (e) {
      print("Error during restoration: $e");
    }
  }

  Future<void> startImmediateBackup() async {
    try {
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
      print("Error during immediate backup: $e");
    }
  }
}

// Add the missing RestoreBackupScreen class
class RestoreBackupScreen extends StatefulWidget {
  @override
  _RestoreBackupScreenState createState() => _RestoreBackupScreenState();
}

class _RestoreBackupScreenState extends State<RestoreBackupScreen> {
  final RestoreManager restoreManager = RestoreManager();
  String? selectedDate;
  bool isLoading = false;
  List<String> backupDates = [];

  @override
  void initState() {
    super.initState();
    checkRecentBackup();
  }

  void checkRecentBackup() async {
    setState(() {
      isLoading = true;
    });

    final fetchedBackupDates = await restoreManager.fetchBackupDates();
    setState(() {
      backupDates = fetchedBackupDates;
      isLoading = false;
    });
  }

  void restoreSelectedBackup() async {
    if (selectedDate == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      await restoreManager.restoreBackup(selectedDate!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Backup restored successfully!"))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error during restoration: $e"))
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  void startBackupWithoutCheck() async {
    setState(() {
      isLoading = true;
    });

    try {
      await restoreManager.startImmediateBackup();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Backup created successfully without check!"))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error during immediate backup: $e"))
      );
    }

    setState(() {
      isLoading = false;
    });

    // Refresh backup dates after creating a new backup
    checkRecentBackup();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Restore Backup"),
      ),
      drawer: AdminDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButton<String>(
                    hint: const Text("Select a backup date"),
                    value: selectedDate,
                    onChanged: (value) {
                      setState(() {
                        selectedDate = value;
                      });
                    },
                    items: backupDates.map((date) {
                      return DropdownMenuItem(
                        value: date,
                        child: Text(date),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: selectedDate != null ? restoreSelectedBackup : null,
                    child: const Text("Restore Backup"),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: startBackupWithoutCheck,
                    child: const Text("Start Backup Without Check"),
                  ),
                ],
              ),
            ),
    );
  }
}
