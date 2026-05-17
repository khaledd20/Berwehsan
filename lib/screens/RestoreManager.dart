import 'dart:convert'; // For JSON encoding/decoding
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle; // To access assets
import 'package:berwehsan/widgets/app_drawer.dart'; // Import AdminDrawer

class RestoreManager {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

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

  // List backup dates from assets (manual list or dynamic if feasible)
  Future<List<String>> fetchBackupDates() async {
    // Manually define backup filenames or list them dynamically
    return [
      "2025-01-15T09_54_46.392"
      // Add additional backup files here if needed
    ];
  }

  Future<void> restoreBackupFromAssets(String selectedDate) async {
    try {
      // Load the JSON backup file from assets
      final String filePath = 'backups/$selectedDate-backup.json';
      final String jsonData = await rootBundle.loadString(filePath);

      // Parse the JSON data
      final Map<String, dynamic> backupData = jsonDecode(jsonData);

      // Restore Firestore collections
      for (String collectionName in backupData.keys) {
        final List<dynamic> documents = backupData[collectionName] ?? [];

        for (var doc in documents) {
          final String docId = doc['id'];
          final Map<String, dynamic> newData = doc['data'];

          final DocumentSnapshot existingDoc =
              await firestore.collection(collectionName).doc(docId).get();

          if (existingDoc.exists) {
            // Update only if data is different
            final Map<String, dynamic>? existingData =
                existingDoc.data() as Map<String, dynamic>?;
            if (existingData != null && !mapsAreEqual(existingData, newData)) {
              await firestore
                  .collection(collectionName)
                  .doc(docId)
                  .set(newData);
              print("Updated document in $collectionName: $docId");
            } else {
              print(
                  "Document in $collectionName: $docId is already up to date.");
            }
          } else {
            // Add new document
            await firestore.collection(collectionName).doc(docId).set(newData);
            print("Added new document to $collectionName: $docId");
          }
        }
      }

      print("Database restored successfully from $selectedDate.");
    } catch (e) {
      print("Error during restoration: $e");
    }
  }

  // Helper function to compare two maps
  bool mapsAreEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    for (String key in map1.keys) {
      if (map1[key] != map2[key]) {
        return false;
      }
    }
    return true;
  }
}

// Add the RestoreBackupScreen class
class RestoreBackupScreen extends StatefulWidget {
  const RestoreBackupScreen({super.key});

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
    fetchBackupDates();
  }

  void fetchBackupDates() async {
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
      await restoreManager.restoreBackupFromAssets(selectedDate!);
      if (!mounted) return; // Ensure widget is still mounted
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Backup restored successfully!")),
      );
    } catch (e) {
      if (!mounted) return; // Ensure widget is still mounted
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error during restoration: $e")),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Restore Backup"),
      ),
      drawer: const AppDrawer(),
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
                    onPressed:
                        selectedDate != null ? restoreSelectedBackup : null,
                    child: const Text("Restore Backup"),
                  ),
                ],
              ),
            ),
    );
  }
}
