import 'package:berwehsan/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as ui; // For ui.TextDirection
import 'package:intl/intl.dart';
import 'dart:html' as html; // For printing
import 'package:berwehsan/core/print_style.dart';

class FeedingHistoryPage extends StatefulWidget {
  const FeedingHistoryPage({super.key});

  @override
  _FeedingHistoryPageState createState() => _FeedingHistoryPageState();
}

class _FeedingHistoryPageState extends State<FeedingHistoryPage> {
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl, // RTL alignment
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سجل الإطعام'),
          centerTitle: true,
        ),
        drawer: const AppDrawer(),
        body: Column(
          children: [
            // Single Date Filter
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ElevatedButton(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      selectedDate = pickedDate;
                    });
                  }
                },
                child: Text(
                  selectedDate == null
                      ? 'اختر تاريخ الإطعام'
                      : DateFormat('yyyy-MM-dd').format(selectedDate!),
                ),
              ),
            ),

            // Feeding History List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('feedings')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Filter logs based on selected date
                  final filteredLogs = snapshot.data!.docs.where((log) {
                    final logData = log.data() as Map<String, dynamic>;
                    final String feedingDate = logData['feeding_date'] ?? '';

                    DateTime? logDate;
                    try {
                      logDate = DateTime.parse(feedingDate);
                    } catch (e) {
                      return false; // Skip invalid dates
                    }

                    return selectedDate == null ||
                        isSameDay(logDate, selectedDate!);
                  }).toList();

                  return ListView.builder(
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log =
                          filteredLogs[index].data() as Map<String, dynamic>;
                      final String feedingDate =
                          log['feeding_date'] ?? 'غير معروف';
                      final List<dynamic> cases = log['cases'] ?? [];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        elevation: 3,
                        child: ListTile(
                          title: Text(
                            'تاريخ الإطعام: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(feedingDate))}',
                            textAlign: TextAlign.right,
                          ),
                          subtitle: Text(
                            'عدد الحالات: ${cases.length}',
                            textAlign: TextAlign.right,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.print, color: Colors.teal),
                            onPressed: () =>
                                _printFeedingLog(cases, feedingDate),
                            tooltip: 'طباعة',
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

  // Check if two dates are on the same day
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Print Feeding Log
  void _printFeedingLog(List<dynamic> cases, String feedingDate) async {
    // Format the date
    final formattedDate =
        DateFormat('yyyy-MM-dd').format(DateTime.parse(feedingDate));

    final buffer = StringBuffer();
    buffer.writeln('<html>');
    buffer.writeln('<html>');
    buffer.writeln(PrintStyle.htmlHead);
    buffer.writeln('<body>');
    buffer.writeln(PrintStyle.getHeader('سجل الإطعام - $formattedDate'));
    buffer.writeln('<table>');
    buffer.writeln(
        '<tr><th>رقم الحالة</th><th>اسم الحالة</th><th>عدد الأسرة</th><th>رقم الهاتف</th></tr>');

    // Loop through cases without area name
    for (final caseData in cases) {
      buffer.writeln('<tr><td>${caseData['id'] ?? 'غير معروف'}</td>'
          '<td>${caseData['name'] ?? 'غير معروف'}</td>'
          '<td>${caseData['family_count'] ?? 0}</td>'
          '<td>${caseData['number'] ?? 'غير معروف'}</td></tr>');
    }

    buffer.writeln('</table></body></html>');

    // Print HTML content
    final blob = html.Blob([buffer.toString()], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);
  }
}
