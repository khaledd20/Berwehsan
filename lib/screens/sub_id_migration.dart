import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:berwehsan/core/print_style.dart';
import 'dart:html' as html;

/// Migration tool to backfill sub_id into legacy finance_log receipts.
///
/// Phase 1: Dry-run analysis — matches receipt names to subs collection,
///          outputs matched/unmatched lists for manual review.
/// Phase 2: Execution — after user confirmation, writes the sub_id to
///          each matched receipt document.
class SubIdMigrationPage extends StatefulWidget {
  const SubIdMigrationPage({super.key});

  @override
  State<SubIdMigrationPage> createState() => _SubIdMigrationPageState();
}

class _SubIdMigrationPageState extends State<SubIdMigrationPage> {
  bool _isAnalyzing = false;
  bool _isExecuting = false;
  bool _analysisComplete = false;
  bool _executionComplete = false;

  // Phase 1 results
  List<_MatchResult> _matchedResults = [];
  List<_UnmatchedResult> _unmatchedResults = [];
  int _alreadyHasSubId = 0;
  int _totalSponsorship = 0;

  // Manual mapping overrides for unmatched items
  // Key: finance_log doc ID, Value: selected subs doc ID
  final Map<String, String> _manualMappings = {};

  // All subs for dropdown selection
  List<Map<String, dynamic>> _allSubs = [];

  /// Normalize a name for fuzzy matching:
  /// - Strip common prefixes (د/, أ/, م/)
  /// - Trim whitespace
  /// - Normalize Arabic characters (ة→ه, أإآ→ا, ى→ي)
  static String _normalizeName(String name) {
    String normalized = name.trim();

    // Remove common Arabic title prefixes
    normalized = normalized.replaceAll(RegExp(r'^(د/|أ/|م/|أ\.د/|د\.\s*)'), '');
    normalized = normalized.trim();

    // Normalize Arabic characters for comparison
    normalized = normalized
        .replaceAll('ة', 'ه')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي');

    // Remove diacritics/tashkeel
    normalized = normalized.replaceAll(
        RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670]'), '');

    // Collapse multiple spaces
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();

    return normalized;
  }

  /// Phase 1: Analyze all sponsorship receipts and attempt matching
  Future<void> _runAnalysis() async {
    setState(() {
      _isAnalyzing = true;
      _analysisComplete = false;
      _matchedResults = [];
      _unmatchedResults = [];
      _alreadyHasSubId = 0;
      _totalSponsorship = 0;
      _manualMappings.clear();
    });

    try {
      // Step 1: Fetch all sponsors from subs collection
      final subsSnapshot =
          await FirebaseFirestore.instance.collection('subs').get();

      _allSubs = subsSnapshot.docs
          .map((doc) => {
                'docId': doc.id,
                'name': doc.data()['name'] as String? ?? '',
                'id': doc.data()['id'],
              })
          .toList();

      // Build a normalized-name → docId lookup map
      // Also keep a list for partial matching
      final Map<String, Map<String, dynamic>> normalizedSubsMap = {};
      for (final sub in _allSubs) {
        final normalizedName = _normalizeName(sub['name'] as String);
        normalizedSubsMap[normalizedName] = sub;
      }

      // Step 2: Fetch all sponsorship receipts from finance_log
      final receiptsSnapshot = await FirebaseFirestore.instance
          .collection('finance_log')
          .where('category', isEqualTo: 'الكفالات')
          .get()
          .timeout(const Duration(seconds: 15));

      _totalSponsorship = receiptsSnapshot.docs.length;

      // Step 3: Analyze each receipt
      for (final doc in receiptsSnapshot.docs) {
        final data = doc.data();
        final existingSubId = data['sub_id'];
        final receiptName = data['name']?.toString() ?? '';
        final receiptNumber = data['receipt_number']?.toString() ?? '?';
        final amount = data['amount'] ?? 0;

        // Skip if already has a valid sub_id
        if (existingSubId != null &&
            existingSubId.toString().isNotEmpty &&
            existingSubId.toString() != 'null') {
          _alreadyHasSubId++;
          continue;
        }

        // Try to match by normalized name
        final normalizedReceipt = _normalizeName(receiptName);
        Map<String, dynamic>? matchedSub;

        // 1. Exact normalized match
        if (normalizedSubsMap.containsKey(normalizedReceipt)) {
          matchedSub = normalizedSubsMap[normalizedReceipt];
        }

        // 2. If no exact match, try contains-based matching
        if (matchedSub == null) {
          final candidates = normalizedSubsMap.entries.where((entry) {
            return entry.key.contains(normalizedReceipt) ||
                normalizedReceipt.contains(entry.key);
          }).toList();

          if (candidates.length == 1) {
            matchedSub = candidates.first.value;
          }
        }

        // 3. If still no match, try word-level fuzzy matching
        if (matchedSub == null) {
          final receiptWords = normalizedReceipt.split(' ');
          if (receiptWords.length >= 2) {
            final candidates = normalizedSubsMap.entries.where((entry) {
              final subWords = entry.key.split(' ');
              // At least 2 words must match
              int matchCount = 0;
              for (final word in receiptWords) {
                if (word.length > 1 && subWords.contains(word)) {
                  matchCount++;
                }
              }
              return matchCount >= 2;
            }).toList();

            if (candidates.length == 1) {
              matchedSub = candidates.first.value;
            }
          }
        }

        if (matchedSub != null) {
          _matchedResults.add(_MatchResult(
            financeDocId: doc.id,
            originalName: receiptName,
            matchedSubName: matchedSub['name'] as String,
            matchedSubDocId: matchedSub['id'].toString(),
            receiptNumber: receiptNumber,
            amount: amount,
          ));
        } else {
          _unmatchedResults.add(_UnmatchedResult(
            financeDocId: doc.id,
            originalName: receiptName,
            receiptNumber: receiptNumber,
            amount: amount,
          ));
        }
      }

      setState(() {
        _isAnalyzing = false;
        _analysisComplete = true;
      });
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء التحليل: $e')),
        );
      }
    }
  }

  /// Phase 2: Execute the migration (write sub_id to matched documents)
  Future<void> _executeMigration() async {
    // Combine auto-matched + manually mapped
    final allMappings = <String, String>{}; // financeDocId → subsDocId

    for (final match in _matchedResults) {
      allMappings[match.financeDocId] = match.matchedSubDocId;
    }

    // Add manual mappings for previously unmatched items
    allMappings.addAll(_manualMappings);

    if (allMappings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد عناصر للتحديث')),
      );
      return;
    }

    setState(() => _isExecuting = true);

    try {
      // Use WriteBatch for efficiency (max 500 per batch per Firestore rules)
      final firestore = FirebaseFirestore.instance;
      int processed = 0;
      int batchCount = 0;
      WriteBatch batch = firestore.batch();

      for (final entry in allMappings.entries) {
        final docRef = firestore.collection('finance_log').doc(entry.key);
        batch.update(docRef, {'sub_id': entry.value});
        batchCount++;
        processed++;

        // Commit every 400 docs (staying under the 500 limit)
        if (batchCount >= 400) {
          await batch.commit();
          batch = firestore.batch();
          batchCount = 0;
        }
      }

      // Commit remaining
      if (batchCount > 0) {
        await batch.commit();
      }

      setState(() {
        _isExecuting = false;
        _executionComplete = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('تم تحديث $processed إيصال بنجاح بمعرف الكفيل')),
        );
      }
    } catch (e) {
      setState(() => _isExecuting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء التنفيذ: $e')),
        );
      }
    }
  }

  /// Export the analysis report as an HTML printable page
  void _exportReport() {
    final buffer = StringBuffer();
    buffer.writeln('<html>');
    buffer.writeln(PrintStyle.htmlHead);
    buffer.writeln('<body>');
    buffer.writeln(
        PrintStyle.getHeader('تقرير تحليل ربط الإيصالات بمعرفات الكفلاء'));

    // Summary
    buffer.writeln('<h3>ملخص التحليل</h3>');
    buffer.writeln('<table>');
    buffer.writeln(
        '<tr><td>إجمالي إيصالات الكفالات</td><td>$_totalSponsorship</td></tr>');
    buffer.writeln(
        '<tr><td>لديها sub_id بالفعل</td><td>$_alreadyHasSubId</td></tr>');
    buffer.writeln(
        '<tr><td>تم مطابقتها تلقائياً</td><td>${_matchedResults.length}</td></tr>');
    buffer.writeln(
        '<tr><td>تحتاج مراجعة يدوية</td><td>${_unmatchedResults.length}</td></tr>');
    buffer.writeln('</table>');

    // Matched table
    if (_matchedResults.isNotEmpty) {
      buffer.writeln('<h3>✅ المطابقات الناجحة</h3>');
      buffer.writeln('<table>');
      buffer.writeln(
          '<tr><th>رقم الإيصال</th><th>الاسم الأصلي</th><th>➡️</th><th>اسم الكفيل المطابق</th><th>المبلغ</th></tr>');
      for (final m in _matchedResults) {
        buffer.writeln(
            '<tr><td>${m.receiptNumber}</td><td>${m.originalName}</td><td>➡️</td><td>${m.matchedSubName}</td><td>${m.amount}</td></tr>');
      }
      buffer.writeln('</table>');
    }

    // Unmatched table
    if (_unmatchedResults.isNotEmpty) {
      buffer.writeln('<h3>❌ تحتاج مراجعة يدوية</h3>');
      buffer.writeln('<table>');
      buffer.writeln(
          '<tr><th>رقم الإيصال</th><th>الاسم الأصلي</th><th>المبلغ</th></tr>');
      for (final u in _unmatchedResults) {
        buffer.writeln(
            '<tr><td>${u.receiptNumber}</td><td>${u.originalName}</td><td>${u.amount}</td></tr>');
      }
      buffer.writeln('</table>');
    }

    buffer.writeln('</body>');
    buffer.writeln('</html>');

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
          title: const Text('أداة ربط معرفات الكفلاء'),
          centerTitle: true,
          actions: [
            if (_analysisComplete)
              IconButton(
                icon: const Icon(Icons.print),
                onPressed: _exportReport,
                tooltip: 'طباعة التقرير',
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Phase 1: Analysis ───
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.search,
                              color: _analysisComplete
                                  ? Colors.green
                                  : Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'المرحلة 1: تحليل البيانات (Dry Run)',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'يقوم بفحص جميع إيصالات الكفالات في finance_log ومحاولة '
                        'مطابقة أسماء الكفلاء مع مجموعة subs بدون أي تعديل على البيانات.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _isAnalyzing ? null : _runAnalysis,
                        icon: _isAnalyzing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.play_arrow),
                        label: Text(
                            _isAnalyzing ? 'جاري التحليل...' : 'بدء التحليل'),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Analysis Results ───
              if (_analysisComplete) ...[
                const SizedBox(height: 16),

                // Summary Card
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('📊 ملخص التحليل',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _summaryRow(
                            'إجمالي إيصالات الكفالات', '$_totalSponsorship'),
                        _summaryRow(
                            'لديها sub_id بالفعل ✅', '$_alreadyHasSubId'),
                        _summaryRow('تم مطابقتها تلقائياً ✅',
                            '${_matchedResults.length}'),
                        _summaryRow('تحتاج مراجعة يدوية ⚠️',
                            '${_unmatchedResults.length}',
                            isWarning: _unmatchedResults.isNotEmpty),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ─── Matched Results Table ───
                if (_matchedResults.isNotEmpty) ...[
                  const Text('✅ المطابقات الناجحة (سيتم تحديثها تلقائياً)',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildMatchedTable(),
                ],

                const SizedBox(height: 16),

                // ─── Unmatched Results Table ───
                if (_unmatchedResults.isNotEmpty) ...[
                  const Text('⚠️ تحتاج مراجعة يدوية (اختر الكفيل الصحيح)',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange)),
                  const SizedBox(height: 8),
                  _buildUnmatchedTable(),
                ],

                const SizedBox(height: 24),

                // ─── Phase 2: Execute ───
                Card(
                  elevation: 3,
                  color: _executionComplete
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                                _executionComplete
                                    ? Icons.check_circle
                                    : Icons.warning_amber,
                                color: _executionComplete
                                    ? Colors.green
                                    : Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              _executionComplete
                                  ? 'المرحلة 2: تم التنفيذ بنجاح ✅'
                                  : 'المرحلة 2: تنفيذ التحديث',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _executionComplete
                              ? 'تم تحديث جميع الإيصالات المطابقة بمعرف الكفيل.'
                              : 'سيتم تحديث ${_matchedResults.length + _manualMappings.length} '
                                  'إيصال بمعرف الكفيل (sub_id). '
                                  'هذا الإجراء غير قابل للتراجع.',
                          style: TextStyle(
                              color: _executionComplete
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700),
                        ),
                        if (!_executionComplete) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _isExecuting ? null : _executeMigration,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              foregroundColor: Colors.white,
                            ),
                            icon: _isExecuting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.play_arrow),
                            label: Text(_isExecuting
                                ? 'جاري التنفيذ...'
                                : '🚀 تنفيذ التحديث'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isWarning ? Colors.orange : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchedTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        headingRowColor: WidgetStateProperty.all(Colors.green.shade50),
        columns: const [
          DataColumn(label: Text('رقم الإيصال')),
          DataColumn(label: Text('الاسم في الإيصال')),
          DataColumn(label: Text('➡️')),
          DataColumn(label: Text('الكفيل المطابق')),
          DataColumn(label: Text('المبلغ')),
        ],
        rows: _matchedResults
            .map((m) => DataRow(cells: [
                  DataCell(Text(m.receiptNumber)),
                  DataCell(Text(m.originalName)),
                  DataCell(
                      const Icon(Icons.arrow_forward, color: Colors.green)),
                  DataCell(Text(m.matchedSubName,
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold))),
                  DataCell(Text(m.amount.toString())),
                ]))
            .toList(),
      ),
    );
  }

  Widget _buildUnmatchedTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        headingRowColor: WidgetStateProperty.all(Colors.orange.shade50),
        columns: const [
          DataColumn(label: Text('رقم الإيصال')),
          DataColumn(label: Text('الاسم في الإيصال')),
          DataColumn(label: Text('المبلغ')),
          DataColumn(label: Text('اختر الكفيل يدوياً')),
        ],
        rows: _unmatchedResults
            .map((u) => DataRow(cells: [
                  DataCell(Text(u.receiptNumber)),
                  DataCell(Text(u.originalName,
                      style: const TextStyle(color: Colors.red))),
                  DataCell(Text(u.amount.toString())),
                  DataCell(
                    _buildSearchableSubPicker(u),
                  ),
                ]))
            .toList(),
      ),
    );
  }

  /// A tappable button that opens a searchable dialog to pick a sponsor
  Widget _buildSearchableSubPicker(_UnmatchedResult item) {
    final selectedDocId = _manualMappings[item.financeDocId];
    String? selectedName;
    if (selectedDocId != null) {
      final match = _allSubs.where((s) => s['id'].toString() == selectedDocId);
      if (match.isNotEmpty) {
        selectedName = match.first['name'] as String;
      }
    }

    return SizedBox(
      width: 280,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _showSearchableSubDialog(item),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: selectedName != null
                        ? Colors.green
                        : Colors.grey.shade400,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  color: selectedName != null
                      ? Colors.green.shade50
                      : Colors.white,
                ),
                child: Row(
                  children: [
                    Icon(
                      selectedName != null
                          ? Icons.check_circle
                          : Icons.person_search,
                      size: 16,
                      color: selectedName != null ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        selectedName ?? 'اختر الكفيل...',
                        style: TextStyle(
                          fontSize: 12,
                          color: selectedName != null
                              ? Colors.green.shade800
                              : Colors.grey,
                          fontWeight: selectedName != null
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 18),
                  ],
                ),
              ),
            ),
          ),
          if (selectedName != null)
            IconButton(
              icon: const Icon(Icons.clear, size: 16, color: Colors.red),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                setState(() {
                  _manualMappings.remove(item.financeDocId);
                });
              },
              tooltip: 'إزالة الاختيار',
            ),
        ],
      ),
    );
  }

  /// Opens a searchable dialog to select a sponsor
  Future<void> _showSearchableSubDialog(_UnmatchedResult item) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _SearchableSubDialog(
        allSubs: _allSubs,
        currentSelection: _manualMappings[item.financeDocId],
        receiptName: item.originalName,
      ),
    );

    if (result != null) {
      setState(() {
        _manualMappings[item.financeDocId] = result;
      });
    }
  }
}

/// A dialog with a search bar and a filtered list of sponsors
class _SearchableSubDialog extends StatefulWidget {
  final List<Map<String, dynamic>> allSubs;
  final String? currentSelection;
  final String receiptName;

  const _SearchableSubDialog({
    required this.allSubs,
    required this.currentSelection,
    required this.receiptName,
  });

  @override
  State<_SearchableSubDialog> createState() => _SearchableSubDialogState();
}

class _SearchableSubDialogState extends State<_SearchableSubDialog> {
  late TextEditingController _searchController;
  List<Map<String, dynamic>> _filteredSubs = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredSubs = List.from(widget.allSubs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterSubs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSubs = List.from(widget.allSubs);
      } else {
        _filteredSubs = widget.allSubs
            .where((sub) => (sub['name'] as String)
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('اختر الكفيل'),
            const SizedBox(height: 4),
            Text(
              'للإيصال: ${widget.receiptName}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          height: 450,
          child: Column(
            children: [
              // Search bar
              TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'بحث بالاسم',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterSubs('');
                          },
                        )
                      : null,
                ),
                onChanged: _filterSubs,
              ),
              const SizedBox(height: 8),
              Text(
                '${_filteredSubs.length} كفيل',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const Divider(),
              // Sponsors list
              Expanded(
                child: _filteredSubs.isEmpty
                    ? const Center(
                        child: Text('لا توجد نتائج',
                            style: TextStyle(color: Colors.grey)),
                      )
                    : ListView.builder(
                        itemCount: _filteredSubs.length,
                        itemBuilder: (context, index) {
                          final sub = _filteredSubs[index];
                          final subId = sub['id'].toString();
                          final name = sub['name'] as String;
                          final isSelected = widget.currentSelection == subId;

                          return ListTile(
                            dense: true,
                            selected: isSelected,
                            selectedTileColor: Colors.green.shade50,
                            leading: Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.person_outline,
                              color: isSelected ? Colors.green : Colors.grey,
                              size: 20,
                            ),
                            title: Text(
                              name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color:
                                    isSelected ? Colors.green.shade800 : null,
                              ),
                            ),
                            onTap: () => Navigator.pop(context, subId),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }
}

/// Represents a successful auto-match between a receipt name and a sponsor
class _MatchResult {
  final String financeDocId;
  final String originalName;
  final String matchedSubName;
  final String matchedSubDocId;
  final String receiptNumber;
  final dynamic amount;

  _MatchResult({
    required this.financeDocId,
    required this.originalName,
    required this.matchedSubName,
    required this.matchedSubDocId,
    required this.receiptNumber,
    required this.amount,
  });
}

/// Represents a receipt name that could not be auto-matched
class _UnmatchedResult {
  final String financeDocId;
  final String originalName;
  final String receiptNumber;
  final dynamic amount;

  _UnmatchedResult({
    required this.financeDocId,
    required this.originalName,
    required this.receiptNumber,
    required this.amount,
  });
}
