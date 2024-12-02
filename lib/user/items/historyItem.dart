import 'package:berwehsan/widgets/user_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as ui; // For ui.TextDirection
import 'package:intl/intl.dart';
import 'dart:html' as html;

class HistoryItemPage extends StatefulWidget {
  const HistoryItemPage({super.key});

  @override
  _HistoryItemPageState createState() => _HistoryItemPageState();
}

class _HistoryItemPageState extends State<HistoryItemPage> {
  DateTime? startDate;
  DateTime? endDate;
  String itemIdFilter = '';
  String countFilter = '';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl, // RTL alignment
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سجل العناصر'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _printFilteredLogs, // Print function
            ),
          ],
        ),
        drawer: userDrawer(), // Add the drawer here,
        body: Column(
          children: [
            // Filters
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        labelText: 'بحث بمعرف العنصر',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          itemIdFilter = value.trim();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        labelText: 'بحث بالعدد',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          countFilter = value.trim();
                        });
                      },
                    ),
                  ),
                ],
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
                    .collection('store_log')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final logs = snapshot.data!.docs.where((log) {
                    final logData = log.data() as Map<String, dynamic>;

                    // Validate data types
                    if (logData['item_id'] is! int ||
                        logData['count'] is! int) {
                      return false; // Skip logs with invalid data types
                    }

                    // Filters
                    final int itemId = logData['item_id'];
                    final int count = logData['count'];
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

                    if (itemIdFilter.isNotEmpty &&
                        !itemId.toString().contains(itemIdFilter)) {
                      return false; // Item ID filter
                    }

                    if (countFilter.isNotEmpty &&
                        !count.toString().contains(countFilter)) {
                      return false; // Count filter
                    }

                    return true;
                  }).toList();

                  return ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index].data() as Map<String, dynamic>;
                      final int itemId = log['item_id'];
                      final int count = log['count'];
                      final String status = log['status'] ?? 'غير معروف';
                      final String createdAt = log['created_at'] ?? 'غير معروف';

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        elevation: 3,
                        child: ListTile(
                          title: Text(
                            'معرف العنصر: $itemId',
                            textAlign: TextAlign.right,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'الحالة: ${status == 'in' ? 'إضافة' : 'سحب'}',
                                  textAlign: TextAlign.right),
                              Text('العدد: $count', textAlign: TextAlign.right),
                              Text('تاريخ الإنشاء: $createdAt',
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
        await FirebaseFirestore.instance.collection('store_log').get();

    final filteredLogs = snapshot.docs.where((log) {
      final logData = log.data() as Map<String, dynamic>;

      if (logData['item_id'] is! int || logData['count'] is! int) {
        return false;
      }

      final int itemId = logData['item_id'];
      final int count = logData['count'];
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

      if (itemIdFilter.isNotEmpty &&
          !itemId.toString().contains(itemIdFilter)) {
        return false;
      }

      if (countFilter.isNotEmpty && !count.toString().contains(countFilter)) {
        return false;
      }

      return true;
    }).toList();

    final buffer = StringBuffer();
    buffer.writeln('<html>');
    buffer.writeln('<head>');
    buffer.writeln('<meta charset="UTF-8">'); // Ensures proper text encoding
    buffer.writeln('<style>');
    buffer.writeln('table { width: 100%; border-collapse: collapse; }');
    buffer.writeln(
        'th, td { border: 1px solid black; padding: 8px; text-align: right; }');
    buffer.writeln('th { background-color: #f2f2f2; }');
    buffer.writeln('</style>');
    buffer.writeln('</head>');
    buffer.writeln(
        '<body style="direction: rtl; font-family: Arial, sans-serif;">');
    buffer.writeln('<h1>سجل العناصر</h1>');
    buffer.writeln('<table>');
    buffer.writeln(
        '<tr><th>معرف العنصر</th><th>العدد</th><th>الحالة</th><th>تاريخ الإنشاء</th></tr>');

    for (final log in filteredLogs) {
      final logData = log.data() as Map<String, dynamic>;
      buffer.writeln(
          '<tr><td>${logData['item_id']}</td><td>${logData['count']}</td><td>${logData['status'] == 'in' ? 'إضافة' : 'سحب'}</td><td>${logData['created_at']}</td></tr>');
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
