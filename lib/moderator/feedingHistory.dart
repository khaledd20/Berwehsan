import 'package:berwehsan/widgets/moderator_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as ui; // For ui.TextDirection
import 'package:intl/intl.dart';
import 'dart:html' as html; // For printing

class FeedingHistoryPage extends StatefulWidget {
  const FeedingHistoryPage({super.key});

  @override
  _FeedingHistoryPageState createState() => _FeedingHistoryPageState();
}

class _FeedingHistoryPageState extends State<FeedingHistoryPage> {
  DateTime? startDate;
  DateTime? endDate;
  String nameFilter = '';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl, // RTL alignment
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سجل الإطعام'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _printFilteredLogs, // Print function
            ),
          ],
        ),
        drawer: ModeratorDrawer(), // ModeratorDrawer added here
        body: Column(
          children: [
            // Filters
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'بحث بالاسم',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    nameFilter = value.trim();
                  });
                },
              ),
            ),
            // Date Filter
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          startDate = pickedDate;
                        });
                      }
                    },
                    child: Text(
                      startDate == null
                          ? 'تاريخ البداية'
                          : DateFormat('yyyy-MM-dd').format(startDate!),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          endDate = pickedDate;
                        });
                      }
                    },
                    child: Text(
                      endDate == null
                          ? 'تاريخ النهاية'
                          : DateFormat('yyyy-MM-dd').format(endDate!),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('feedings') // Corrected collection name
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final logs = snapshot.data!.docs.where((log) {
                    final logData = log.data() as Map<String, dynamic>;

                    // Filters
                    final String name = logData['name'] ?? '';
                    final String createdAt = logData['created_at'] ?? '';
                    DateTime? logDate;
                    try {
                      logDate = DateTime.parse(createdAt);
                    } catch (e) {
                      return false; // Skip logs with invalid date format
                    }

                    if (startDate != null &&
                        endDate != null &&
                        (logDate.isBefore(startDate!) ||
                            logDate.isAfter(endDate!))) {
                      return false; // Date filter
                    }

                    if (nameFilter.isNotEmpty && !name.contains(nameFilter)) {
                      return false; // Name filter
                    }

                    return true;
                  }).toList();

                  return ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index].data() as Map<String, dynamic>;
                      final String name = log['name'] ?? 'غير معروف';
                      final String createdAt = log['created_at'] ?? 'غير معروف';
                      final String description =
                          log['description'] ?? 'غير معروف';

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        elevation: 3,
                        child: ListTile(
                          title: Text(
                            'اسم الحالة: $name',
                            textAlign: TextAlign.right,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('الوصف: $description',
                                  textAlign: TextAlign.right),
                              Text('تاريخ الإطعام: $createdAt',
                                  textAlign: TextAlign.right),
                            ],
                          ),
                        ),
                      );
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

  void _printFilteredLogs() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('feedings').get();

    final filteredLogs = snapshot.docs.where((log) {
      final logData = log.data() as Map<String, dynamic>;

      final String name = logData['name'] ?? '';
      final String createdAt = logData['created_at'] ?? '';
      DateTime? logDate;
      try {
        logDate = DateTime.parse(createdAt);
      } catch (e) {
        return false;
      }

      if (startDate != null &&
          endDate != null &&
          (logDate.isBefore(startDate!) || logDate.isAfter(endDate!))) {
        return false;
      }

      if (nameFilter.isNotEmpty && !name.contains(nameFilter)) {
        return false;
      }

      return true;
    }).toList();

    final buffer = StringBuffer();
    buffer.writeln('<html>');
    buffer.writeln('<head>');
    buffer.writeln('<meta charset="UTF-8">'); // Ensures proper text encoding
    buffer.writeln('<style>');
    buffer.writeln(
        'table { width: 100%; border-collapse: collapse; margin-top: 20px; }');
    buffer.writeln(
        'th, td { border: 1px solid black; padding: 8px; text-align: right; }');
    buffer.writeln('th { background-color: #f2f2f2; }');
    buffer.writeln('</style>');
    buffer.writeln('</head>');
    buffer.writeln(
        '<body style="direction: rtl; font-family: Arial, sans-serif;">');
    buffer.writeln('<h1>سجل الإطعام</h1>');
    buffer.writeln('<table>');
    buffer.writeln(
        '<tr><th>اسم الحالة</th><th>الوصف</th><th>تاريخ الإطعام</th></tr>');

    for (final log in filteredLogs) {
      final logData = log.data() as Map<String, dynamic>;
      buffer.writeln(
          '<tr><td>${logData['name']}</td><td>${logData['description']}</td><td>${logData['created_at']}</td></tr>');
    }

    buffer.writeln('</table>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    final blob = html.Blob([buffer.toString()], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);
  }
}
