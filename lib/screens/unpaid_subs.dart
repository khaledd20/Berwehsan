import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:berwehsan/widgets/app_drawer.dart';
import 'dart:html' as html;
import 'package:berwehsan/core/print_style.dart';

class UnpaidSubsPage extends StatefulWidget {
  const UnpaidSubsPage({super.key});

  @override
  _UnpaidSubsPageState createState() => _UnpaidSubsPageState();
}

class _UnpaidSubsPageState extends State<UnpaidSubsPage> {
  List<Map<String, dynamic>> allUnpaidSubs = [];
  bool isLoading = true;
  String _filter = 'All'; // 'All', 'ThisMonthOnly', 'Disconnected'

  @override
  void initState() {
    super.initState();
    fetchUnpaidSubs();
  }

  Future<void> fetchUnpaidSubs() async {
    try {
      final currentYear = DateTime.now().year;
      final currentMonth = DateTime.now().month;

      // 1. Fetch all finance_log entries for this year and month
      final financeSnapshot = await FirebaseFirestore.instance
          .collection('finance_log')
          .where('category', isEqualTo: 'الكفالات')
          .get();

      Map<String, Set<int>> paidAbsoluteMonthsById = {};
      Map<String, Set<int>> paidAbsoluteMonthsByName = {};

      for (final doc in financeSnapshot.docs) {
        final data = doc.data();
        final subIdStr = data['sub_id']?.toString() ?? '';
        final subName = data['name']?.toString().trim() ?? '';

        final periods = data['selected_periods'];
        if (periods != null && periods is List) {
          for (final period in periods) {
            if (period is Map) {
              var pYear = period['year'];
              var pMonth = period['month'];

              if (pYear is String) pYear = int.tryParse(pYear) ?? 0;
              if (pMonth is String) pMonth = int.tryParse(pMonth) ?? 0;

              if (pYear is int && pMonth is int && pYear > 0 && pMonth > 0) {
                int absoluteMonth = (pYear * 12) + pMonth;
                if (subIdStr.isNotEmpty) {
                  paidAbsoluteMonthsById
                      .putIfAbsent(subIdStr, () => {})
                      .add(absoluteMonth);
                }
                if (subName.isNotEmpty) {
                  paidAbsoluteMonthsByName
                      .putIfAbsent(subName, () => {})
                      .add(absoluteMonth);
                }
              }
            }
          }
        }
      }

      // 2. Fetch all subs
      final subsSnapshot = await FirebaseFirestore.instance
          .collection('subs')
          .orderBy('name')
          .get();

      List<Map<String, dynamic>> unpaid = [];
      final currentAbsoluteMonth = (currentYear * 12) + currentMonth;

      for (final doc in subsSnapshot.docs) {
        final docId = doc.id;
        final subData = doc.data();
        final subName = subData['name']?.toString().trim() ?? '';

        Set<int> paidAbsoluteMonths = {};
        if (paidAbsoluteMonthsById.containsKey(docId)) {
          paidAbsoluteMonths.addAll(paidAbsoluteMonthsById[docId]!);
        }
        if (paidAbsoluteMonthsByName.containsKey(subName)) {
          paidAbsoluteMonths.addAll(paidAbsoluteMonthsByName[subName]!);
        }

        // If they haven't paid THIS month, we consider them for this list
        if (!paidAbsoluteMonths.contains(currentAbsoluteMonth)) {
          // Check disconnected status: unpaid for current and previous 3 months (> 3 months total)
          bool isDisconnected = true;
          for (int i = 0; i <= 3; i++) {
            if (paidAbsoluteMonths.contains(currentAbsoluteMonth - i)) {
              isDisconnected = false;
              break;
            }
          }

          // Compute unpaid months for past and current year (for display/print)
          List<String> unpaidMonthsDisplay = [];

          // Past year
          for (int m = 1; m <= 12; m++) {
            if (!paidAbsoluteMonths.contains(((currentYear - 1) * 12) + m)) {
              unpaidMonthsDisplay.add('$m/${currentYear - 1}');
            }
          }

          // Current year
          for (int m = 1; m <= currentMonth; m++) {
            if (!paidAbsoluteMonths.contains((currentYear * 12) + m)) {
              unpaidMonthsDisplay
                  .add('$m'); // display just the month for the current year
            }
          }

          unpaid.add({
            'docId': docId,
            'unpaid_months': unpaidMonthsDisplay,
            'is_disconnected': isDisconnected,
            ...subData
          });
        }
      }

      if (mounted) {
        setState(() {
          allUnpaidSubs = unpaid;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching unpaid subs: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء جلب البيانات: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredSubs {
    if (_filter == 'ThisMonthOnly') {
      return allUnpaidSubs
          .where((sub) => sub['is_disconnected'] == false)
          .toList();
    } else if (_filter == 'Disconnected') {
      return allUnpaidSubs
          .where((sub) => sub['is_disconnected'] == true)
          .toList();
    }
    return allUnpaidSubs;
  }

  Future<void> printUnpaidSubs(BuildContext context) async {
    final buffer = StringBuffer();
    final currentYear = DateTime.now().year;
    final currentMonth = DateTime.now().month;

    final subsToPrint = _filteredSubs;

    buffer.writeln('<html>');
    buffer.writeln(PrintStyle.htmlHead);
    buffer.writeln('<body>');
    String filterTitle = '';
    if (_filter == 'ThisMonthOnly') filterTitle = ' - غير مسدد هذا الشهر';
    if (_filter == 'Disconnected') filterTitle = ' - منقطع';

    buffer.writeln(PrintStyle.getHeader(
        'كفالات غير مسددة لشهر $currentMonth / $currentYear$filterTitle'));
    buffer.writeln('<table>');
    buffer.writeln(
        '<tr><th>رقم التعريف</th><th>الاسم</th><th>الموقع</th><th>رقم الهاتف</th><th>الأشهر غير المسددة</th><th>المبلغ</th></tr>');

    if (subsToPrint.isEmpty) {
      buffer.writeln('<tr><td colspan="6">لا توجد كفالات مطابقة</td></tr>');
    } else {
      for (var subData in subsToPrint) {
        String unpaidMonthsStr =
            (subData['unpaid_months'] as List<String>).join(', ');
        String nameStr = subData['name'] ?? 'غير معروف';
        if (subData['is_disconnected'] == true) {
          nameStr +=
              ' <span style="color:red; font-weight:bold;">(منقطع)</span>';
        }
        buffer.writeln(
            '<tr><td>${subData['id'] ?? 'غير معروف'}</td><td>$nameStr</td><td>${subData['location'] ?? 'غير معروف'}</td><td>${subData['number'] ?? 'غير معروف'}</td><td>$unpaidMonthsStr</td><td>${subData['unite'] ?? 'غير معروف'}</td></tr>');
      }
    }

    buffer.writeln('</table>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    final blob = html.Blob([buffer.toString()], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم طباعة الكفالات غير المسددة بنجاح')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('كفالات غير مسددة لهذا الشهر'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () => printUnpaidSubs(context),
              tooltip: 'طباعة القائمة',
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        DropdownButton<String>(
                          value: _filter,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                                value: 'All',
                                child: Text(
                                    'الكل (عرض جميع الكفالات غير المسددة)')),
                            DropdownMenuItem(
                                value: 'ThisMonthOnly',
                                child: Text('غير مسدد هذا الشهر (غير منقطع)')),
                            DropdownMenuItem(
                                value: 'Disconnected',
                                child: Text('منقطع (أكثر من 3 أشهر)')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _filter = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'إجمالي الكفالات المطابقة: ${_filteredSubs.length}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  if (_filteredSubs.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          'لا توجد كفالات مطابقة للفلتر المحدد!',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: _filteredSubs.length,
                        itemBuilder: (context, index) {
                          final sub = _filteredSubs[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            child: ListTile(
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      sub['name'] ?? 'لا يوجد',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (sub['is_disconnected'] == true) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'منقطع',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Text(
                                  'الموقع: ${sub['location']}\nالأشهر غير المسددة: ${(sub['unpaid_months'] as List<String>).join(', ')}'),
                              trailing: Text(
                                'المبلغ: ${sub['unite'] ?? 0}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
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
}
