import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:html' as html;

class ChestsHistoryPage extends StatefulWidget {
  final String chestId;

  const ChestsHistoryPage({Key? key, required this.chestId}) : super(key: key);

  @override
  _ChestsHistoryPageState createState() => _ChestsHistoryPageState();
}

class _ChestsHistoryPageState extends State<ChestsHistoryPage> {
  DateTime? _startDate;
  DateTime? _endDate;

  String formatDateTime(String isoDate) {
    final dateTime = DateTime.parse(isoDate);
    return intl.DateFormat('dd/MM/yyyy HH:mm:ss').format(dateTime);
  }

  Future<void> _printSingleLog(Map<String, dynamic> data) async {
    final buffer = StringBuffer();

    buffer.writeln('<html>');
    buffer.writeln('<head>');
    buffer.writeln('<meta charset="UTF-8">');
    buffer.writeln('<style>');
    buffer.writeln('body { direction: rtl; font-family: Arial, sans-serif; }');
    buffer.writeln(
        'table { margin: auto; border-collapse: collapse; width: 60%; }');
    buffer.writeln(
        'th, td { border: 1px solid black; padding: 8px; text-align: right; }');
    buffer.writeln('th { background-color: #f2f2f2; text-align: center; }');
    buffer.writeln('</style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('<h1 style="text-align: center;">تفاصيل العملية</h1>');
    buffer.writeln('<table>');
    buffer.writeln('<tr><td>المبلغ</td><td>${data['amount']}</td></tr>');
    buffer.writeln(
        '<tr><td>الحالة</td><td>${data['status'] == 'in' ? 'إضافة' : 'سحب'}</td></tr>');
    buffer.writeln(
        '<tr><td>قبل العملية</td><td>${data['before_amount']}</td></tr>');
    buffer.writeln(
        '<tr><td>بعد العملية</td><td>${data['after_amount']}</td></tr>');
    if (data.containsKey('donor_name')) {
      buffer.writeln('<tr><td>المتبرع</td><td>${data['donor_name']}</td></tr>');
    }
    if (data.containsKey('case_name')) {
      buffer.writeln('<tr><td>الحالة</td><td>${data['case_name']}</td></tr>');
    }
    buffer.writeln(
        '<tr><td>التاريخ</td><td>${formatDateTime(data['created_at'])}</td></tr>');
    buffer.writeln('</table>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    final blob = html.Blob([buffer.toString()], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _editLog(String docId, Map<String, dynamic> data) async {
    final TextEditingController amountController =
        TextEditingController(text: data['amount'].toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تعديل العملية"),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "أدخل المبلغ"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () async {
              final int updatedAmount =
                  int.tryParse(amountController.text) ?? 0;
              if (updatedAmount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("أدخل مبلغًا صحيحًا.")),
                );
                return;
              }

              await FirebaseFirestore.instance
                  .collection('chest_log')
                  .doc(docId)
                  .update({
                'amount': updatedAmount,
                'updated_at': DateTime.now().toIso8601String(),
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("تم تعديل العملية بنجاح.")),
              );
            },
            child: const Text("حفظ"),
          ),
        ],
      ),
    );
  }

  

  Future<void> PrintHistoryLogs(List<Map<String, dynamic>> logs, String chestId) async {
    int totalAdded = logs
        .where((log) => log['status'] == 'in')
        .fold(0, (sum, log) => sum + (log['amount'] as int));
    int totalWithdrawn = logs
        .where((log) => log['status'] == 'out')
        .fold(0, (sum, log) => sum + (log['amount'] as int));

    int currentBalance = 0;
    try {
      final chestDoc = await FirebaseFirestore.instance
          .collection('chests')
          .doc(chestId)
          .get();

      if (chestDoc.exists) {
        currentBalance = chestDoc.data()?['balance'] ?? 0;
      }
    } catch (e) {
      print('Error fetching chest balance: $e');
    }

    final buffer = StringBuffer();

    buffer.writeln('<html>');
    buffer.writeln('<head><meta charset="UTF-8"><style>'
        'body { direction: rtl; font-family: Arial, sans-serif; }'
        'table { width: 100%; border: 1px solid black; border-collapse: collapse; }'
        'th, td { border: 1px solid black; padding: 8px; text-align: right; }'
        'th { background-color: #f2f2f2; text-align: center; }'
        '</style></head>');
    buffer.writeln('<body><h1 style="text-align: center;">سجل العمليات للصندوق</h1>');
    buffer.writeln(
        '<table><tr><th>المتبرع/الحالة</th><th>بعد العملية</th><th>قبل العملية</th><th>الحالة</th><th>المبلغ</th><th>التاريخ</th></tr>');

    for (var log in logs) {
      buffer.writeln(
          '<tr><td style="text-align: center;">${log['donor_name'] ?? log['case_name'] ?? 'غير معروف'}</td><td style="text-align: center;">${log['after_amount']}</td><td style="text-align: center;">${log['before_amount']}</td><td style="text-align: center;">${log['status'] == 'in' ? 'إضافة' : 'سحب'}</td><td style="text-align: center;">${log['amount']}</td><td style="text-align: center;">${formatDateTime(log['created_at'])}</td></tr>');
    }

    buffer.writeln(
        '<tr><td colspan="5" style="text-align: center;">إجمالي المضاف</td><td style="text-align: center;">$totalAdded</td></tr>');
    buffer.writeln(
        '<tr><td colspan="5" style="text-align: center;">إجمالي السحب</td><td style="text-align: center;">$totalWithdrawn</td></tr>');
    buffer.writeln(
        '<tr><td colspan="5" style="text-align: center;">الرصيد الحالي</td><td style="text-align: center;">$currentBalance</td></tr>');

    buffer.writeln('</table>');
    buffer.writeln('</body></html>');

    final blob = html.Blob([buffer.toString()], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سجل الصندوق'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () async {
                try {
                  // Fetch all logs for the chest
                  final snapshot = await FirebaseFirestore.instance
                      .collection('chest_log')
                      .where('chest_id', isEqualTo: widget.chestId)
                      .get();

                  // Filter logs by date
                  final logs = snapshot.docs
                      .map((doc) => doc.data() as Map<String, dynamic>)
                      .where((log) {
                        final createdAt = DateTime.parse(log['created_at']);
                        return _startDate == null ||
                            _endDate == null ||
                            (createdAt.isAfter(_startDate!) &&
                                createdAt.isBefore(_endDate!.add(const Duration(days: 1))));
                      })
                      .toList();

                  // Call the print function with filtered logs
                  if (logs.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('لا توجد سجلات للطباعة.')),
                    );
                    return;
                  }

                  await PrintHistoryLogs(logs, widget.chestId);
                } catch (e) {
                  print("Error printing logs: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('حدث خطأ أثناء الطباعة.')),
                  );
                }
              },
              tooltip: 'طباعة السجل',
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _startDate = picked.start;
                            _endDate = picked.end;
                          });
                        }
                      },
                      child: Text(
                        _startDate == null || _endDate == null
                            ? 'تحديد الفترة الزمنية'
                            : 'من ${intl.DateFormat('yyyy-MM-dd').format(_startDate!)} '
                                'إلى ${intl.DateFormat('yyyy-MM-dd').format(_endDate!)}',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chest_log')
                    .where('chest_id', isEqualTo: widget.chestId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final logs = snapshot.data?.docs ?? [];
                  final filteredLogs = logs.where((log) {
                    final data = log.data() as Map<String, dynamic>;
                    final createdAt = DateTime.parse(data['created_at']);
                    return _startDate == null ||
                        _endDate == null ||
                        (createdAt.isAfter(_startDate!) &&
                            createdAt.isBefore(
                                _endDate!.add(const Duration(days: 1))));
                  }).toList();

                  if (filteredLogs.isEmpty) {
                    return const Center(child: Text('لا توجد سجلات.'));
                  }

                  return ListView.builder(
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      final data =
                          filteredLogs[index].data() as Map<String, dynamic>;
                      final docId = filteredLogs[index].id;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        child: ListTile(
                          title: Text("المبلغ: ${data['amount']}"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "الحالة: ${data['status'] == 'in' ? 'إضافة' : 'سحب'}"),
                              Text("قبل العملية: ${data['before_amount']}"),
                              Text("بعد العملية: ${data['after_amount']}"),
                              Text(
                                  "التاريخ: ${formatDateTime(data['created_at'])}"),
                              if (data.containsKey('donor_name'))
                                Text("المتبرع: ${data['donor_name']}"),
                              if (data.containsKey('case_name'))
                                Text("الحالة: ${data['case_name']}"),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.print, color: Colors.teal),
                                onPressed: () => _printSingleLog(data),
                                tooltip: 'طباعة',
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editLog(docId, data),
                                tooltip: 'تعديل',
                              ),
                              
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
}
