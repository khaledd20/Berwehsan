import 'package:berwehsan/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:berwehsan/core/user_session.dart';
import 'dart:ui' as ui; // For ui.TextDirection
import 'package:intl/intl.dart';
import 'package:berwehsan/core/print_style.dart';
import 'dart:html' as html; // For printing

class HistoryItemPage extends StatefulWidget {
  const HistoryItemPage({super.key});

  @override
  _HistoryItemPageState createState() => _HistoryItemPageState();
}

class _HistoryItemPageState extends State<HistoryItemPage> {
  DateTime? startDate;
  DateTime? endDate;
  String itemIdFilter = '';
  String commentsFilter = '';
  String itemNameFilter = '';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سجل العناصر'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _printFilteredLogs,
            ),
          ],
        ),
        drawer: const AppDrawer(),
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
                        labelText: 'بحث بالملاحظات',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          commentsFilter = value.trim();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        labelText: 'بحث باسم العنصر',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          itemNameFilter = value.trim();
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
                          startDate = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            0,
                            0,
                            0,
                          );
                        });
                      }
                    },
                    child: Text(
                      startDate == null
                          ? 'تاريخ البداية'
                          : DateFormat('dd MMMM yyyy', 'ar').format(startDate!),
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
                          endDate = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            23,
                            59,
                            59,
                          );
                        });
                      }
                    },
                    child: Text(
                      endDate == null
                          ? 'تاريخ النهاية'
                          : DateFormat('dd MMMM yyyy', 'ar').format(endDate!),
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

                    // Parse `created_at` into `DateTime`
                    DateTime? logDate;
                    if (logData['created_at'] is Timestamp) {
                      logDate = (logData['created_at'] as Timestamp).toDate();
                    } else if (logData['created_at'] is String) {
                      try {
                        logDate = DateTime.parse(logData['created_at']);
                      } catch (e) {
                        return false;
                      }
                    } else {
                      return false;
                    }

                    // Apply date filters
                    if (startDate != null && logDate.isBefore(startDate!)) {
                      return false;
                    }
                    if (endDate != null && logDate.isAfter(endDate!)) {
                      return false;
                    }

                    // Apply other filters
                    if (itemIdFilter.isNotEmpty &&
                        !logData['item_id'].toString().contains(itemIdFilter)) {
                      return false;
                    }
                    if (commentsFilter.isNotEmpty &&
                        !logData['note']
                            .toString()
                            .toLowerCase()
                            .contains(commentsFilter.toLowerCase())) {
                      return false;
                    }
                    if (itemNameFilter.isNotEmpty &&
                        !logData['item_name']
                            .toString()
                            .toLowerCase()
                            .contains(itemNameFilter.toLowerCase())) {
                      return false;
                    }

                    return true;
                  }).toList();

                  return ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index].data() as Map<String, dynamic>;
                      final int itemId = log['item_id'];
                      final String comments = log['note'] ?? 'غير محدد';
                      final String itemName = log['item_name'] ?? 'غير محدد';

                      String formattedDate;
                      try {
                        final DateTime parsedDate =
                            log['created_at'] is Timestamp
                                ? (log['created_at'] as Timestamp).toDate()
                                : DateTime.parse(log['created_at']);
                        formattedDate = DateFormat('dd MMMM yyyy - HH:mm', 'ar')
                            .format(parsedDate);
                      } catch (e) {
                        formattedDate = 'غير معروف';
                      }

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
                              Text('اسم العنصر: $itemName',
                                  textAlign: TextAlign.right),
                              Text('ملاحظات: $comments',
                                  textAlign: TextAlign.right),
                              Text('تاريخ الإنشاء: $formattedDate',
                                  textAlign: TextAlign.right),
                              if (UserSession().isAdmin && log.containsKey('userName'))
                                Text("بواسطة: ${log['userName']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
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

  Future<void> _printFilteredLogs() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('store_log').get();

    // Apply filters to the logs
    final filteredLogs = snapshot.docs.where((log) {
      final logData = log.data();

      // Parse `created_at` into `DateTime`
      DateTime? logDate;
      if (logData['created_at'] is Timestamp) {
        logDate = (logData['created_at'] as Timestamp).toDate();
      } else if (logData['created_at'] is String) {
        try {
          logDate = DateTime.parse(logData['created_at']);
        } catch (e) {
          return false;
        }
      } else {
        return false;
      }

      // Apply date filters
      if (startDate != null && logDate.isBefore(startDate!)) {
        return false;
      }
      if (endDate != null && logDate.isAfter(endDate!)) {
        return false;
      }

      // Apply text-based filters
      if (itemIdFilter.isNotEmpty &&
          !logData['item_id'].toString().contains(itemIdFilter)) {
        return false;
      }
      if (commentsFilter.isNotEmpty &&
          !logData['note']
              .toString()
              .toLowerCase()
              .contains(commentsFilter.toLowerCase())) {
        return false;
      }
      if (itemNameFilter.isNotEmpty &&
          !logData['item_name']
              .toString()
              .toLowerCase()
              .contains(itemNameFilter.toLowerCase())) {
        return false;
      }

      return true;
    }).toList();

    // Generate the HTML for printing
    final buffer = StringBuffer();
    buffer.writeln('<html>');
    buffer.writeln('<head>');
    buffer.writeln('<meta charset="UTF-8">');
    buffer.writeln(PrintStyle.htmlHead);
    buffer.writeln('</head>');
    buffer.writeln(
        '<body style="direction: rtl; font-family: Arial, sans-serif;">');
    buffer.writeln(PrintStyle.getHeader('سجل العناصر'));
    buffer.writeln('<table>');
    buffer.writeln(
        '<tr><th>معرف العنصر</th><th>اسم العنصر</th><th>ملاحظات</th><th>تاريخ الإنشاء</th></tr>');

    for (final log in filteredLogs) {
      final logData = log.data();
      String formattedDate;
      try {
        final DateTime parsedDate = log['created_at'] is Timestamp
            ? (log['created_at'] as Timestamp).toDate()
            : DateTime.parse(log['created_at']);
        formattedDate =
            DateFormat('dd MMMM yyyy - HH:mm', 'ar').format(parsedDate);
      } catch (e) {
        formattedDate = 'غير معروف';
      }

      buffer.writeln(
          '<tr><td>${logData['item_id']}</td><td>${logData['item_name'] ?? 'غير محدد'}</td><td>${logData['note'] ?? 'غير محدد'}</td><td>$formattedDate</td></tr>');
    }

    buffer.writeln('</table>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    // Create a Blob for printing
    final blob = html.Blob([buffer.toString()], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);
  }
}
