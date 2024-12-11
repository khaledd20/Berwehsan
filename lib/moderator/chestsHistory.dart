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
    final formattedDate =
        intl.DateFormat('dd MMMM yyyy', 'ar').format(dateTime);
    final formattedTime = intl.DateFormat('HH:mm').format(dateTime);
    return "$formattedDate - $formattedTime";
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
        'th, td { border: 1px solid black; padding: 8px; text-align: center; }');
    buffer.writeln('th { background-color: #f2f2f2; font-size: 18px; }');
    buffer.writeln('</style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('<h1 style="text-align:center;">تفاصيل العملية</h1>');
    buffer.writeln('<table>');
    buffer.writeln(
        '<tr><td>التاريخ</td><td>${formatDateTime(data['created_at'])}</td></tr>');
    buffer.writeln('<tr><td>المبلغ</td><td>${data['amount']}</td></tr>');
    buffer.writeln(
        '<tr><td>الحالة</td><td>${data['status'] == 'in' ? 'إضافة' : 'سحب'}</td></tr>');
    buffer.writeln(
        '<tr><td>قبل العملية</td><td>${data['before_amount']}</td></tr>');
    buffer.writeln(
        '<tr><td>بعد العملية</td><td>${data['after_amount']}</td></tr>');
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

  

  Future<void> _printAllLogs(List<Map<String, dynamic>> logs) async {
    PrintHistoryLogs(logs: logs).generateAndPrint();
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
                final snapshot = await FirebaseFirestore.instance
                    .collection('chest_log')
                    .where('chest_id', isEqualTo: widget.chestId)
                    .get();
                final logs = snapshot.docs
                    .map((doc) => doc.data() as Map<String, dynamic>)
                    .toList();
                await _printAllLogs(logs);
              },
              tooltip: 'طباعة السجل',
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chest_log')
              .where('chest_id', isEqualTo: widget.chestId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final logs = snapshot.data?.docs ?? [];

            return ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final data = logs[index].data() as Map<String, dynamic>;
                final docId = logs[index].id;

                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text("المبلغ: ${data['amount']}"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            "الحالة: ${data['status'] == 'in' ? 'إضافة' : 'سحب'}"),
                        Text("قبل العملية: ${data['before_amount']}"),
                        Text("بعد العملية: ${data['after_amount']}"),
                        Text("التاريخ: ${formatDateTime(data['created_at'])}"),
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
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class PrintHistoryLogs {
  final List<Map<String, dynamic>> logs;

  PrintHistoryLogs({required this.logs});

  void generateAndPrint() {
    final buffer = StringBuffer();

    buffer.writeln('<html>');
    buffer.writeln('<head><meta charset="UTF-8"><style>'
        'table { width: 100%; border: 1px solid black; border-collapse: collapse; }'
        'th, td { border: 1px solid black; padding: 8px; text-align: center; }'
        'th { background-color: #f2f2f2; }'
        '</style></head>');
    buffer.writeln('<body><h1>سجل العمليات للصندوق</h1>');
    buffer.writeln(
        '<table><tr><th>التاريخ</th><th>المبلغ</th><th>الحالة</th><th>قبل العملية</th><th>بعد العملية</th></tr>');

    for (var log in logs) {
      buffer.writeln(
          '<tr><td>${log['created_at']}</td><td>${log['amount']}</td><td>${log['status'] == 'in' ? 'إضافة' : 'سحب'}</td><td>${log['before_amount']}</td><td>${log['after_amount']}</td></tr>');
    }

    buffer.writeln('</table></body></html>');

    final blob = html.Blob([buffer.toString()], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);
  }
}
