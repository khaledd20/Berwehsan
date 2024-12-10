import 'package:berwehsan/widgets/admin_drawer.dart';
import 'package:berwehsan/widgets/user_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html;

class CashHistoryPage extends StatefulWidget {
  const CashHistoryPage({super.key});

  @override
  State<CashHistoryPage> createState() => _CashHistoryPageState();
}

class _CashHistoryPageState extends State<CashHistoryPage> {
  String searchQuery = '';
  DateTime? startDate;
  DateTime? endDate;
  List<DocumentSnapshot> cashHistory = [];
  Map<int, String> caseNames = {};

  @override
  void initState() {
    super.initState();
    _fetchCashHistory();
  }

  /// Fetch all cash entries and apply filters manually
  Future<void> _fetchCashHistory() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('cashs').get();

    List<DocumentSnapshot> allCash = snapshot.docs;

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      allCash = allCash
          .where((doc) =>
              doc['case_id'].toString() == searchQuery.trim())
          .toList();
    }

    // Apply date range filter manually
    if (startDate != null && endDate != null) {
      allCash = allCash.where((doc) {
        final docDate = _parseDate(doc['created_at']);
        return docDate != null &&
            docDate.isAfter(startDate!.subtract(const Duration(days: 1))) &&
            docDate.isBefore(endDate!.add(const Duration(days: 1)));
      }).toList();
    }

    setState(() {
      cashHistory = allCash;
    });

    // Fetch case names
    await _fetchCaseNames();
  }

  /// Parse the string date in 'dd/MM/yyyy' format
  DateTime? _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      return DateTime(
        int.parse(parts[2]), // Year
        int.parse(parts[1]), // Month
        int.parse(parts[0]), // Day
      );
    } catch (e) {
      return null;
    }
  }

  /// Fetch case names for displayed case IDs
  Future<void> _fetchCaseNames() async {
    Set<int> caseIds =
        cashHistory.map((doc) => doc['case_id'] as int).toSet();

    for (var caseId in caseIds) {
      if (!caseNames.containsKey(caseId)) {
        final caseSnapshot = await FirebaseFirestore.instance
            .collection('cases')
            .where('id', isEqualTo: caseId)
            .limit(1)
            .get();

        if (caseSnapshot.docs.isNotEmpty) {
          setState(() {
            caseNames[caseId] =
                caseSnapshot.docs.first.data()['name'] ?? 'غير معروف';
          });
        }
      }
    }
  }

  /// Show date range picker
  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      _fetchCashHistory();
    }
  }

  /// Print cash history
  void _printCashHistory() {
  final buffer = StringBuffer();

  // Calculate total credits
  double totalCredit = cashHistory.fold(0, (sum, doc) {
    final credit = doc['credit'] ?? 0;
    return sum + (credit is num ? credit : 0);
  });

  // Format the date range title in Arabic
  String dateRangeTitle = '';
  if (startDate != null && endDate != null) {
    if (startDate == endDate) {
      dateRangeTitle = 'للتاريخ ${_formatDateArabic(startDate!)}';
    } else {
      dateRangeTitle =
          'من ${_formatDateArabic(startDate!)} إلى ${_formatDateArabic(endDate!)}';
    }
  } else {
    dateRangeTitle = 'لجميع التواريخ';
  }

  // HTML Content
  buffer.writeln('<html><head><meta charset="UTF-8">');
  buffer.writeln('<style>'
      'body {direction: rtl; font-family: Arial, sans-serif;}'
      'table {width: 100%; border-collapse: collapse; margin-top: 20px;}'
      'th, td {border: 1px solid black; text-align: center; padding: 8px;}'
      'th {background-color: #f2f2f2;}'
      'h1, h2 {text-align: center;}'
      '</style></head><body>');

  buffer.writeln('<h1>سجل القبض</h1>');
  buffer.writeln('<h2>$dateRangeTitle</h2>'); // Add date filter in the title

  buffer.writeln(
      '<table><tr><th>رقم الحالة</th><th>الاسم</th><th>التاريخ</th><th>المبلغ</th></tr>');

  // Generate table rows
  for (var doc in cashHistory) {
    final data = doc.data() as Map<String, dynamic>;
    final caseId = data['case_id'];
    final caseName = caseNames[caseId] ?? 'غير معروف';
    final createdAt = data['created_at'];
    final credit = data['credit'] ?? 0;

    buffer.writeln(
        '<tr><td>$caseId</td><td>$caseName</td><td>$createdAt</td><td>$credit</td></tr>');
  }

  // Add total credits row
  buffer.writeln(
      '<tr><td colspan="3" style="font-weight:bold">الإجمالي</td><td style="font-weight:bold">$totalCredit</td></tr>');

  buffer.writeln('</table></body></html>');

  // Generate the HTML Blob and open it
  final blob = html.Blob([buffer.toString()], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  html.Url.revokeObjectUrl(url);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('تم طباعة السجل بنجاح')),
  );
}

/// Helper method to format date into Arabic
String _formatDateArabic(DateTime date) {
  final months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر'
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}


  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سجل القبض'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _printCashHistory,
            ),
          ],
        ),
        drawer:userDrawer(),
        body: Column(
          children: [
            // Search and filter
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'ابحث برقم الحالة',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                        _fetchCashHistory();
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.date_range),
                    onPressed: _pickDateRange,
                  ),
                ],
              ),
            ),
            if (startDate != null && endDate != null)
              Text(
                'من ${_formatDate(startDate!)} إلى ${_formatDate(endDate!)}',
                style: const TextStyle(fontSize: 14),
              ),
            const SizedBox(height: 8),
            // Display cash history
            Expanded(
              child: cashHistory.isEmpty
                  ? const Center(child: Text('لا توجد بيانات'))
                  : ListView.builder(
                      itemCount: cashHistory.length,
                      itemBuilder: (context, index) {
                        final data =
                            cashHistory[index].data() as Map<String, dynamic>;
                        final caseId = data['case_id'];
                        final caseName = caseNames[caseId] ?? 'تحميل...';
                        return Card(
                          child: ListTile(
                            title: Text('رقم الحالة: $caseId'),
                            subtitle: Text(
                                'الاسم: $caseName\nالتاريخ: ${data['created_at']} | المبلغ: ${data['credit']}'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
