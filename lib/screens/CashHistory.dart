import 'package:berwehsan/core/user_session.dart';
import 'package:berwehsan/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:berwehsan/core/print_style.dart';
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
  bool _sortByDate = true;
  List<DocumentSnapshot> cashHistory = [];
  Map<int, String> caseNames = {};

  @override
  void initState() {
    super.initState();
    _fetchCashHistory();
  }

  /// Fetch all cash entries and apply filters manually
  Future<void> _fetchCashHistory() async {
    final snapshot = await FirebaseFirestore.instance.collection('cashs').get();

    List<DocumentSnapshot> allCash = snapshot.docs;

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      allCash = allCash
          .where((doc) => doc['case_id'].toString() == searchQuery.trim())
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

    // Apply sorting
    if (_sortByDate) {
      allCash.sort((a, b) {
        final aDate = _parseDate(a['created_at']);
        final bDate = _parseDate(b['created_at']);
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate); // newest first
      });
    } else {
      allCash.sort((a, b) {
        final aId = int.tryParse(a.id) ?? a.hashCode;
        final bId = int.tryParse(b.id) ?? b.hashCode;
        // Or if the user meant sorting by case_id:
        // final aId = a['case_id'] as int;
        // final bId = b['case_id'] as int;
        return aId.compareTo(bId);
      });
    }

    if (!mounted) return;
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
    Set<int> caseIds = cashHistory.map((doc) => doc['case_id'] as int).toSet();
    final missingIds =
        caseIds.where((id) => !caseNames.containsKey(id)).toList();

    if (missingIds.isEmpty) return;

    final newNames = <int, String>{};
    final chunks = <List<int>>[];

    for (var i = 0; i < missingIds.length; i += 30) {
      chunks.add(missingIds.sublist(
          i, i + 30 > missingIds.length ? missingIds.length : i + 30));
    }

    await Future.wait(chunks.map((chunk) async {
      final caseSnapshot = await FirebaseFirestore.instance
          .collection('cases')
          .where('id', whereIn: chunk)
          .get();

      for (var doc in caseSnapshot.docs) {
        final data = doc.data();
        final id = data['id'] as int;
        newNames[id] = data['name'] ?? 'غير معروف';
      }
    }));

    if (!mounted) return;
    setState(() {
      caseNames.addAll(newNames);
    });
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

  /// Delete a cash entry (Admin only)
  Future<void> _deleteCashEntry(DocumentSnapshot doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت متأكد من حذف هذا السجل؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('cashs').doc(doc.id).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف السجل بنجاح')),
      );
      _fetchCashHistory();
    }
  }

  /// Edit a cash entry (Admin only)
  void _editCashEntry(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final creditController =
        TextEditingController(text: data['credit']?.toString() ?? '');
    final dateController =
        TextEditingController(text: data['created_at'] ?? '');

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تعديل سجل القبض'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: creditController,
                  decoration: const InputDecoration(labelText: 'المبلغ'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dateController,
                  decoration:
                      const InputDecoration(labelText: 'التاريخ (dd/MM/yyyy)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final newCredit =
                      num.tryParse(creditController.text.trim()) ??
                          data['credit'];
                  await FirebaseFirestore.instance
                      .collection('cashs')
                      .doc(doc.id)
                      .update({
                    'credit': newCredit,
                    'created_at': dateController.text.trim(),
                  });

                  Navigator.pop(context);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تحديث السجل بنجاح')),
                  );
                  _fetchCashHistory();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('حدث خطأ أثناء التحديث: $e')),
                  );
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
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
    buffer.writeln('<html>');
    buffer.writeln(PrintStyle.htmlHead);
    buffer.writeln('<body>');
    buffer.writeln(PrintStyle.getHeader('سجل القبض - $dateRangeTitle'));

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
        drawer: const AppDrawer(),
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
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('الترتيب',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold)),
                      ToggleButtons(
                        isSelected: [_sortByDate, !_sortByDate],
                        onPressed: (index) {
                          setState(() => _sortByDate = index == 0);
                          _fetchCashHistory();
                        },
                        borderRadius: BorderRadius.circular(8),
                        selectedColor: Colors.white,
                        fillColor: Theme.of(context).primaryColor,
                        constraints:
                            const BoxConstraints(minHeight: 34, minWidth: 58),
                        children: const [
                          Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('التاريخ',
                                  style: TextStyle(fontSize: 12))),
                          Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('الرقم',
                                  style: TextStyle(fontSize: 12))),
                        ],
                      ),
                    ],
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
                        final doc = cashHistory[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final caseId = data['case_id'];
                        final caseName = caseNames[caseId] ?? 'تحميل...';
                        return Card(
                          child: ListTile(
                            title: Text('رقم الحالة: $caseId'),
                            subtitle: Text(
                                'الاسم: $caseName\nالتاريخ: ${data['created_at']} | المبلغ: ${data['credit']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (UserSession().isModerator ||
                                    UserSession().isAdmin ||
                                    UserSession().isAccountingModerator)
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () => _editCashEntry(doc),
                                    tooltip: 'تعديل',
                                  ),
                                if (UserSession().isAdmin)
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteCashEntry(doc),
                                    tooltip: 'حذف',
                                  ),
                              ],
                            ),
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
