import 'package:berwehsan/widgets/app_drawer.dart';
import 'package:berwehsan/core/user_session.dart';
import 'package:berwehsan/core/age_calculator.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html; // For printing
import 'caseProfile.dart';
import 'edit_full _case.dart';
import 'insertCase.dart';
import 'package:berwehsan/core/print_style.dart';

class CasesPage extends StatefulWidget {
  const CasesPage({super.key});

  @override
  _CasesPageState createState() => _CasesPageState();
}

class _CasesPageState extends State<CasesPage> {
  String searchQuery = '';
  String motherSearchQuery = '';
  String gradeSearchQuery = '';
  String sizeSearchQuery = '';
  String socialStatusSearchQuery = '';
  bool _sortByDate = false; // false = sort by ID, true = sort by date

  List<QueryDocumentSnapshot> _currentFilteredCases = [];

  String _normalizeArabic(String text) {
    if (text.isEmpty) return '';
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[\u064B-\u0652\u0640]'), '') // Remove Tashkeel & Tatweel
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll(RegExp(r'ة'), 'ه')
        .replaceAll(RegExp(r'ى'), 'ي')
        .replaceAll(RegExp(r'ؤ'), 'و')
        .replaceAll(RegExp(r'ئ'), 'ي')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('جدول الحالات'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () => _printAllCases(_currentFilteredCases),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(280.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Row 1: Main Search
                      TextField(
                        onChanged: (value) => setState(() => searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'ابحث بالاسم أو الرقم',
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Row 2: Mother & Grade
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: (value) =>
                                  setState(() => motherSearchQuery = value),
                              decoration: InputDecoration(
                                hintText: 'اسم الأم',
                                prefixIcon: const Icon(Icons.person_outline),
                                isDense: true,
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              onChanged: (value) =>
                                  setState(() => gradeSearchQuery = value),
                              decoration: InputDecoration(
                                hintText: 'المرحلة',
                                prefixIcon: const Icon(Icons.school),
                                isDense: true,
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Row 3: Size & Social Status
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: (value) =>
                                  setState(() => sizeSearchQuery = value),
                              decoration: InputDecoration(
                                hintText: 'المقاس',
                                prefixIcon: const Icon(Icons.straighten),
                                isDense: true,
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              onChanged: (value) =>
                                  setState(() => socialStatusSearchQuery = value),
                              decoration: InputDecoration(
                                hintText: 'الحالة الاجتماعية',
                                prefixIcon: const Icon(Icons.family_restroom),
                                isDense: true,
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Row 4: Sorting
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ترتيب حسب:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, color: Colors.white)),
                          ToggleButtons(
                            isSelected: [!_sortByDate, _sortByDate],
                            onPressed: (index) =>
                                setState(() => _sortByDate = index == 1),
                            borderRadius: BorderRadius.circular(10),
                            selectedColor: Colors.white,
                            fillColor: Theme.of(context).primaryColor,
                            color: Colors.black54, // Changed from white70 for visibility
                            constraints: const BoxConstraints(
                              minHeight: 32,
                              minWidth: 80,
                            ),
                            children: const [
                              Text('الرقم'),
                              Text('التاريخ'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        drawer: const AppDrawer(),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('cases')
              .orderBy('id')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              _currentFilteredCases = [];
              return const Center(
                child: Text('لا توجد بيانات', style: TextStyle(fontSize: 18)),
              );
            }

            final cases = snapshot.data!.docs;

            var filteredCases = cases.where((doc) {
              final caseData = doc.data() as Map<String, dynamic>;
              
              // Apply Main Search (Name/ID)
              if (searchQuery.isNotEmpty) {
                final name = _normalizeArabic(caseData['name']?.toString() ?? '');
                final id = caseData['id']?.toString() ?? '';
                final normalizedQuery = _normalizeArabic(searchQuery);
                
                if (RegExp(r'^\d+$').hasMatch(searchQuery)) {
                  if (id != searchQuery) return false;
                } else {
                  // If searching for 1 character, match from the start of the name only
                  if (normalizedQuery.length == 1) {
                    if (!name.startsWith(normalizedQuery)) return false;
                  } else {
                    if (!name.contains(normalizedQuery)) return false;
                  }
                }
              }

              // Apply Mother Search
              if (motherSearchQuery.isNotEmpty) {
                final motherName = _normalizeArabic(caseData['mother_name']?.toString() ?? '');
                final normalizedQuery = _normalizeArabic(motherSearchQuery);
                if (normalizedQuery.length == 1) {
                  if (!motherName.startsWith(normalizedQuery)) return false;
                } else {
                  if (!motherName.contains(normalizedQuery)) return false;
                }
              }

              // Apply Grade Search
              if (gradeSearchQuery.isNotEmpty) {
                final grade = _normalizeArabic(caseData['grade_id']?.toString() ?? '');
                final normalizedQuery = _normalizeArabic(gradeSearchQuery);
                if (normalizedQuery.length == 1) {
                  if (!grade.startsWith(normalizedQuery)) return false;
                } else {
                  if (!grade.contains(normalizedQuery)) return false;
                }
              }

              // Apply Size Search
              if (sizeSearchQuery.isNotEmpty) {
                final size = _normalizeArabic(caseData['c_size']?.toString() ?? '');
                final normalizedQuery = _normalizeArabic(sizeSearchQuery);
                if (normalizedQuery.length == 1) {
                  if (!size.startsWith(normalizedQuery)) return false;
                } else {
                  if (!size.contains(normalizedQuery)) return false;
                }
              }

              // Apply Social Status Search
              if (socialStatusSearchQuery.isNotEmpty) {
                final status = _normalizeArabic(caseData['social_status']?.toString() ?? '');
                final normalizedQuery = _normalizeArabic(socialStatusSearchQuery);
                if (normalizedQuery.length == 1) {
                  if (!status.startsWith(normalizedQuery)) return false;
                } else {
                  if (!status.contains(normalizedQuery)) return false;
                }
              }

              return true;
            }).toList();

            // Apply sort
            if (_sortByDate) {
              filteredCases.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aDate = aData['created_at']?.toString() ?? '';
                final bDate = bData['created_at']?.toString() ?? '';
                return bDate.compareTo(aDate); // newest first
              });
            } else {
              filteredCases.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aIdRaw = aData['id']?.toString() ?? '0';
                final bIdRaw = bData['id']?.toString() ?? '0';
                final aId =
                    int.tryParse(aIdRaw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                final bId =
                    int.tryParse(bIdRaw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                return aId.compareTo(bId);
              });
            }

            // Store filtered cases for printing
            _currentFilteredCases = filteredCases;

            return ListView.builder(
              itemCount: filteredCases.length,
              itemBuilder: (context, index) {
                final caseData =
                    filteredCases[index].data() as Map<String, dynamic>;
                final docId = filteredCases[index].id;

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(caseData['name'] ?? 'غير معروف'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('رقم الحالة: ${caseData['id'] ?? 'غير معروف'}'),
                        if (caseData['mother_name'] != null)
                           Text('اسم الأم: ${caseData['mother_name']}'),
                        if (caseData['grade_id'] != null)
                           Text('المرحلة: ${caseData['grade_id']}'),
                        if (caseData['c_size'] != null)
                           Text('المقاس: ${caseData['c_size']}'),
                        if (caseData['social_status'] != null)
                           Text('الحالة الاجتماعية: ${caseData['social_status']}'),
                        Text(
                            'رقم التليفون: ${caseData['number'] ?? 'غير معروف'}'),
                        if (UserSession().isAdmin && caseData.containsKey('userName'))
                          Text('بواسطة: ${caseData['userName']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Edit for Admin and Moderator, Delete only for Admin
                        if (UserSession().isAdmin || UserSession().isModerator)
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Color.fromARGB(255, 0, 255, 204)),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditFullCase(docId: docId),
                                ),
                              );
                            },
                          ),
                        if (UserSession().isAdmin)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _confirmDeleteCase(context, docId);
                            },
                          ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CaseProfile(
                                    caseId: int.parse(caseData['id']
                                        .toString()
                                        .replaceAll(RegExp(r'[^0-9]'), ''))),
                              ),
                            );
                          },
                          child: const Text('عرض الملف'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        // Add Case for Admin (3) and Moderator (2)
        floatingActionButton: UserSession().isAdmin ||
                UserSession().isModerator ||
                UserSession().isAccounting
            ? FloatingActionButton(
                backgroundColor: Colors.green,
                tooltip: 'إضافة حالة جديدة',
                child: const Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InsertCase(),
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }

  /// Function to confirm deletion of a case
  void _confirmDeleteCase(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('حذف الحالة'),
            content: const Text('هل أنت متأكد من حذف هذه الحالة؟ سيتم حذف جميع سجلاتها المالية المرتبطة أيضاً.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  try {
                    final caseDoc = await FirebaseFirestore.instance.collection('cases').doc(docId).get();
                    if (!caseDoc.exists) return;
                    
                    final caseData = caseDoc.data()!;
                    final caseId = caseData['id'];
                    final subIds = List<dynamic>.from(caseData['sub_ids'] ?? []);

                    // 1. Delete all finance logs for this case
                    final logsSnapshot = await FirebaseFirestore.instance
                        .collection('finance_log')
                        .where('case_id', isEqualTo: caseId)
                        .get();
                    
                    final batch = FirebaseFirestore.instance.batch();
                    for (var doc in logsSnapshot.docs) {
                      batch.delete(doc.reference);
                    }
                    await batch.commit();

                    // 2. Clean up subs entries (optional but requested: "delete from sub")
                    // Note: Removing actual payment records from subs might affect total balances
                    // but following user instruction to reflect delete action.
                    for (var subId in subIds) {
                      final subsSnapshot = await FirebaseFirestore.instance
                          .collection('subs')
                          .where('id', isEqualTo: subId)
                          .get();
                      
                      for (var subDoc in subsSnapshot.docs) {
                        Map<String, dynamic> data = subDoc.data();
                        bool changed = false;
                        
                        // Iterate through years and months to find and remove entries with this caseId
                        data.forEach((key, value) {
                          if (int.tryParse(key) != null && value is Map) {
                            // This is a year
                            value.forEach((month, receipts) {
                              if (receipts is List) {
                                int initialLen = receipts.length;
                                receipts.removeWhere((r) => r is Map && r['case_id'] == caseId);
                                if (receipts.length != initialLen) changed = true;
                              }
                            });
                          }
                        });

                        if (changed) {
                          await subDoc.reference.set(data);
                        }
                      }
                    }

                    // 3. Finally delete the case document
                    await FirebaseFirestore.instance
                        .collection('cases')
                        .doc(docId)
                        .delete();

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم حذف الحالة وجميع سجلاتها بنجاح')),
                    );
                  } catch (e) {
                    print('Error deleting case: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطأ أثناء الحذف: $e')),
                    );
                  }
                },
                child: const Text('حذف'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Function to edit a case

  /// Helper function to provide Arabic labels for each field
  String _getArabicFieldLabel(String key) {
    switch (key) {
      case 'name':
        return 'الاسم';
      case 'location':
        return 'العنوان';
      case 'social_status':
        return 'الحالة الاجتماعية';
      case 'in_come':
        return 'الدخل';
      case 'family_count':
        return 'عدد أفراد الأسرة';
      case 'ID_Number':
        return 'الرقم القومي';
      case 'number':
        return 'رقم الهاتف';
      case 'c_size':
        return 'مقاس الملابس';
      case 'S_size':
        return 'مقاس جهاز الحذاء';
      case 'age':
        return 'العمر';
      case 'grade_id':
        return 'المرحلة الدراسية';
      case 'balance':
        return 'القبض';
      case 'area_id':
        return 'رقم المنطقة';
      case 'chest_ids':
        return 'الصناديق';
      case 'sub_ids':
        return 'المشتركين';
      default:
        return key; // Fallback for unknown fields
    }
  }

  /// Function to print all cases
  /// Function to print all cases
  Future<void> _printAllCases(List<QueryDocumentSnapshot> sortedDocs) async {
    try {
      if (sortedDocs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد بيانات للطباعة')),
        );
        return;
      }

      final buffer = StringBuffer();
      buffer.writeln('<html>');
      buffer.writeln('<head>');
      buffer.writeln('<meta charset="UTF-8">'); // Ensures proper text encoding
      buffer.writeln(PrintStyle.htmlHead);
      buffer.writeln('</head>');
      buffer.writeln(
          '<body style="direction: rtl; font-family: Arial, sans-serif;">');
      buffer.writeln(PrintStyle.getHeader('جدول الحالات'));
      buffer.writeln('<table>');
      buffer.writeln('<tr>'
          '<th>رقم الحالة</th>'
          '<th>الاسم</th>'
          '<th>اسم الأم</th>'
          '<th>عدد الأفراد</th>'
          '<th>العنوان</th>'
          '<th>الحالة الاجتماعية</th>'
          '<th>العمر</th>'
          '<th>المقاس</th>'
          '<th>رقم التليفون</th>'
          '</tr>');

      for (final doc in sortedDocs) {
        final data = doc.data() as Map<String, dynamic>;
        buffer.writeln('<tr>'
            '<td>${data['id'] ?? '-'}</td>'
            '<td>${data['name'] ?? '-'}</td>'
            '<td>${data['mother_name'] ?? '-'}</td>'
            '<td>${data['family_count'] ?? '-'}</td>'
            '<td>${data['location'] ?? '-'}</td>'
            '<td>${data['social_status'] ?? '-'}</td>'
            '<td>${AgeCalculator.calculateAge(data['birth_date']?.toString(), data['age'])}</td>'
            '<td>${data['c_size'] ?? '-'}</td>'
            '<td>${data['number'] ?? '-'}</td>'
            '</tr>');
      }

      buffer.writeln('</table>');
      buffer.writeln('</body>');
      buffer.writeln('</html>');

      final blob = html.Blob([buffer.toString()], 'text/html');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, '_blank');
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء جدول الطباعة بنجاح')),
      );
    } catch (error) {
      print('Error printing cases: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الطباعة: $error')),
      );
    }
  }

  /// Generate user-friendly labels for fields
  String _getFieldLabel(String key) {
    switch (key) {
      case 'name':
        return 'اسم الحالة';
      case 'number':
        return 'رقم التليفون';
      default:
        return key;
    }
  }
}
