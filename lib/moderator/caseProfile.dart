import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:html' as html; // For web-based printing

class CaseProfile extends StatelessWidget {
  final int caseId; // Ensure `caseId` is defined as an int

  const CaseProfile({super.key, required this.caseId});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ملف الحالة'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () async {
                final snapshot = await FirebaseFirestore.instance
                    .collection('cases')
                    .where('id', isEqualTo: caseId)
                    .get();
                if (snapshot.docs.isNotEmpty) {
                  final caseData = snapshot.docs.first.data();
                  _printCaseProfile(context, caseData);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('لا توجد بيانات للطباعة')),
                  );
                }
              },
            ),
          ],
        ),
        body: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('cases')
              .where('id', isEqualTo: caseId) // Query by numeric ID
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text('لا توجد بيانات لهذه الحالة',
                    style: TextStyle(fontSize: 18)),
              );
            }

            final caseData =
                snapshot.data!.docs.first.data() as Map<String, dynamic>;

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCaseDetailsSection(caseData),
                    const SizedBox(height: 16),
                    _buildQrCodeSection(context, caseData['id'].toString(),
                        caseData), // Pass caseData for receipt
                    const SizedBox(height: 16),
                    _buildChestDetailsSection(caseData['chest_ids'] ?? []),
                    const SizedBox(height: 16),
                    _buildSubDetailsSection(caseData['sub_ids'] ?? []),
                    const SizedBox(height: 16),
                    _buildFamilyDetailsSection(caseData['family_id']),
                    const SizedBox(height: 16),
                    _buildMonthlyPaymentsSection(caseData[
                        'id']), // Pass numeric `id` to payments section
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build the case details section
  /// Build the case details section
  /// Build the case details section
  Widget _buildCaseDetailsSection(Map<String, dynamic> caseData) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.end, // Align content to the right
          children: [
            Align(
              alignment: Alignment.centerRight, // Align the title to the right
              child: const Text(
                'بيانات الحالة',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign:
                    TextAlign.right, // Explicitly align text to the right
              ),
            ),
            const SizedBox(height: 8),
            ..._buildDetails(caseData),
          ],
        ),
      ),
    );
  }

  /// Helper method to generate detail rows with labels and values side by side
  List<Widget> _buildDetails(Map<String, dynamic> caseData) {
    final details = [
      {
        'label': 'رقم الحالة:',
        'value': caseData['id']?.toString() ?? 'غير معروف'
      },
      {'label': 'الاسم:', 'value': caseData['name'] ?? 'غير معروف'},
      {
        'label': 'الرقم القومي:',
        'value': caseData['ID_Number']?.toString() ?? 'غير معروف'
      },
      {
        'label': 'رقم الهاتف:',
        'value': caseData['number']?.toString() ?? 'غير معروف'
      },
      {'label': 'العنوان:', 'value': caseData['location'] ?? 'غير معروف'},
      {
        'label': 'الحالة الاجتماعية:',
        'value': caseData['social_status'] ?? 'غير معروف'
      },
      {
        'label': 'الدخل:',
        'value': caseData['in_come']?.toString() ?? 'غير معروف'
      },
      {
        'label': 'عدد أعضاء الأسرة:',
        'value': caseData['family_count']?.toString() ?? 'غير معروف'
      },
      {'label': 'مقاس الملابس:', 'value': caseData['c_size'] ?? 'غير معروف'},
      {
        'label': 'مقاس الحذاء:',
        'value': caseData['S_size'] ?? 'غير معروف'
      },
      {'label': 'العمر:', 'value': caseData['age']?.toString() ?? 'غير معروف'},
      {
        'label': 'المرحلة الدراسية:',
        'value': caseData['grade_id']?.toString() ?? 'غير معروف'
      },
      {
        'label': 'المنطقة:',
        'value': caseData['area_id']?.toString() ?? 'غير معروف'
      },
      {
        'label': 'القبض:',
        'value': caseData['balance']?.toString() ?? 'غير معروف'
      },
    ];

    return details
        .map((detail) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                textDirection: TextDirection.rtl, // Ensure RTL alignment
                children: [
                  Flexible(
                    flex: 1,
                    child: Text(
                      detail['label']!,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 2,
                    child: Text(
                      detail['value']!,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ))
        .toList();
  }

  Widget _buildQrCodeSection(
      BuildContext context, String id, Map<String, dynamic> caseData) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'رمز الاستجابة السريعة (QR Code)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Center(
              child: QrImageView(
                data: id, // Data to encode in the QR code
                version:
                    QrVersions.auto, // Automatically determine QR code version
                size: 200.0, // Size of the QR code
                gapless: true, // Ensures QR code is continuous
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await _addCash(
                    context, int.parse(id)); // Call the `_addCash` method
              },
              child: const Text('إضافة قبض'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final isCashAdded =
                    await _isCashAddedToday(context, int.parse(id));
                if (isCashAdded) {
                  _printReceipt(context, caseData);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('لا يوجد قبض لإتمام الطباعة.')),
                  );
                }
              },
              child: const Text('طباعة الإيصال'),
            ),
          ],
        ),
      ),
    );
  }

  /// Method to check if cash was added today
  Future<bool> _isCashAddedToday(BuildContext context, int caseId) async {
    final now = DateTime.now();
    final today = "${now.day}/${now.month}/${now.year}";

    final cashCollection = FirebaseFirestore.instance.collection('cashs');

    try {
      // Check if a cash entry already exists for today
      final existingEntry = await cashCollection
          .where('case_id', isEqualTo: caseId)
          .where('created_at', isEqualTo: today)
          .get();

      return existingEntry.docs.isNotEmpty;
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء التحقق من القبض: $error')),
      );
      return false;
    }
  }

  /// Method to add a cash entry with `credit` equal to the `balance`
  Future<void> _addCash(BuildContext context, int caseId) async {
    final now = DateTime.now();
    final today = "${now.day}/${now.month}/${now.year}";

    final cashCollection = FirebaseFirestore.instance.collection('cashs');
    final caseCollection = FirebaseFirestore.instance.collection('cases');

    try {
      // Check if a cash entry already exists for today
      final existingEntry = await cashCollection
          .where('case_id', isEqualTo: caseId)
          .where('created_at', isEqualTo: today)
          .get();

      if (existingEntry.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('قبض اليوم تم إضافته بالفعل.')),
        );
        return;
      }

      // Fetch the case to get the current balance
      final caseSnapshot =
          await caseCollection.where('id', isEqualTo: caseId).get();

      if (caseSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الحالة غير موجودة.')),
        );
        return;
      }

      final caseData = caseSnapshot.docs.first.data() as Map<String, dynamic>;
      final balance = caseData['balance'] ?? 0;

      // Add a new cash entry
      await cashCollection.add({
        'case_id': caseId,
        'created_at': today,
        'credit': balance,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إضافة القبض بنجاح.')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء إضافة القبض: $error')),
      );
    }
  }

  /// Method to print the receipt
  void _printReceipt(
      BuildContext context, Map<String, dynamic> caseData) async {
    final qrData = caseData['id'].toString(); // Data for the QR code
    final buffer = StringBuffer();

    try {
      // Start HTML structure
      buffer.writeln('<html>');
      buffer.writeln('<head>');
      buffer.writeln('<meta charset="UTF-8">'); // Ensure proper encoding
      buffer.writeln('<style>');
      buffer.writeln(
          'body { direction: rtl; font-family: Arial, sans-serif; margin: 20px; }');
      buffer.writeln(
          'table { width: 100%; border-collapse: collapse; margin-top: 20px; }');
      buffer.writeln(
          'th, td { border: 1px solid black; padding: 8px; text-align: right; }');
      buffer.writeln('th { background-color: #f2f2f2; }');
      buffer.writeln('h1 { text-align: center; }');
      buffer.writeln(
          '.qr-container { display: flex; flex-direction: column; align-items: center; justify-content: center; margin-top: 20px; }');
      buffer.writeln('</style>');
      buffer.writeln('</head>');
      buffer.writeln('<body>');

      // Receipt Title
      buffer.writeln('<h1>إيصال القبض</h1>');

      // Receipt Details Table
      buffer.writeln('<table>');
      buffer.writeln('<tr><th>الوصف</th><th>القيمة</th></tr>');
      buffer.writeln('<tr><td>رقم الحالة</td><td>${caseData['id']}</td></tr>');
      buffer.writeln('<tr><td>الاسم</td><td>${caseData['name']}</td></tr>');
      buffer.writeln(
          '<tr><td>القبض</td><td>${caseData['balance'] ?? 'غير معروف'}</td></tr>');
      buffer.writeln(
          '<tr><td>التاريخ</td><td>${DateTime.now().toLocal().toString().split(' ')[0]}</td></tr>');
      buffer.writeln('</table>');

      // QR Code Section
      buffer.writeln('<div class="qr-container">');
      buffer.writeln('<h2>(QR Code)</h2>');
      buffer.writeln(
          '<img src="https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=$qrData" alt="QR Code">');
      buffer.writeln('</div>');

      // Close HTML structure
      buffer.writeln('</body>');
      buffer.writeln('</html>');

      // Generate the HTML Blob and open it in a new tab
      final blob = html.Blob([buffer.toString()], 'text/html');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, '_blank');
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم طباعة الإيصال بنجاح.')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الطباعة: $error')),
      );
    }
  }

  /// Build the chest details section
  Widget _buildChestDetailsSection(List<dynamic> chestIds) {
    if (chestIds.isEmpty) {
      return const Center(
        child: Text('لا توجد صناديق مضافة', style: TextStyle(fontSize: 16)),
      );
    }

    // Split chestIds into chunks of 10 (Firestore `whereIn` limit)
    final List<List<dynamic>> idChunks = [];
    for (int i = 0; i < chestIds.length; i += 10) {
      idChunks.add(chestIds.sublist(
          i, i + 10 > chestIds.length ? chestIds.length : i + 10));
    }

    return FutureBuilder<List<QuerySnapshot>>(
      future: Future.wait(idChunks.map((chunk) => FirebaseFirestore.instance
          .collection('chests')
          .where('id',
              whereIn: chunk
                  .map((id) => id as int)
                  .toList()) // Ensure `id` is treated as a number
          .get())),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final chests = snapshot.data
                ?.expand((querySnapshot) => querySnapshot.docs)
                .toList() ??
            [];

        if (chests.isEmpty) {
          return const Center(
            child: Text('لا توجد صناديق مضافة', style: TextStyle(fontSize: 16)),
          );
        }

        return Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الصناديق المرتبطة',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                ...chests.map((chest) {
                  final chestData = chest.data() as Map<String, dynamic>;
                  return Text('• ${chestData['name'] ?? 'غير معروف'}');
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build the sub details section
  Widget _buildSubDetailsSection(List<dynamic> subIds) {
    if (subIds.isEmpty) {
      return const Center(
        child: Text('لا توجد اشتراكات مضافة', style: TextStyle(fontSize: 16)),
      );
    }

    // Split subIds into chunks of 10 (Firestore `whereIn` limit)
    final List<List<dynamic>> idChunks = [];
    for (int i = 0; i < subIds.length; i += 10) {
      idChunks.add(
          subIds.sublist(i, i + 10 > subIds.length ? subIds.length : i + 10));
    }

    return FutureBuilder<List<QuerySnapshot>>(
      future: Future.wait(idChunks.map((chunk) => FirebaseFirestore.instance
          .collection('subs')
          .where('id',
              whereIn: chunk
                  .map((id) => id as int)
                  .toList()) // Ensure `id` is treated as a number
          .get())),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final subs = snapshot.data
                ?.expand((querySnapshot) => querySnapshot.docs)
                .toList() ??
            [];

        if (subs.isEmpty) {
          return const Center(
            child:
                Text('لا توجد اشتراكات مضافة', style: TextStyle(fontSize: 16)),
          );
        }

        return Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الاشتراكات المرتبطة',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                ...subs.map((sub) {
                  final subData = sub.data() as Map<String, dynamic>;
                  return Text('• ${subData['name'] ?? 'غير معروف'}');
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build the family details section
  Widget _buildFamilyDetailsSection(int? familyId) {
    if (familyId == null || familyId == 0) {
      return const Center(
        child: Text('لا توجد بيانات أفراد لهذه العائلة',
            style: TextStyle(fontSize: 16)),
      );
    }

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('cases')
          .where('family_id', isEqualTo: familyId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final familyMembers = snapshot.data?.docs ?? [];

        return Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('بيانات أولاد الحالة',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                if (familyMembers.isEmpty)
                  const Center(
                      child: Text('لا يوجد أفراد في الأسرة',
                          style: TextStyle(fontSize: 16))),
                if (familyMembers.isNotEmpty)
                  ...familyMembers.map((member) {
                    final memberData = member.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(memberData['name'] ?? 'غير معروف'),
                      subtitle: Text('العمر: ${memberData['age']}'),
                    );
                  }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build the monthly payments section
  Widget _buildMonthlyPaymentsSection(int caseId) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('cashs')
          .where('case_id', isEqualTo: caseId) // Numeric `case_id`
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final payments = snapshot.data?.docs ?? [];

        return Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الدفع الشهري',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                if (payments.isEmpty)
                  const Center(
                      child: Text('لا توجد بيانات دفع لهذه الحالة',
                          style: TextStyle(fontSize: 16))),
                if (payments.isNotEmpty)
                  ...payments.map((payment) {
                    final paymentData = payment.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(
                          'التاريخ: ${paymentData['created_at'] ?? 'غير معروف'}'),
                      subtitle: Text(
                          'المبلغ: ${paymentData['credit'] ?? 'غير معروف'}'),
                    );
                  }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Helper for detail rows
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}

Future<void> _printCaseProfile(
    BuildContext context, Map<String, dynamic> caseData) async {
  final buffer = StringBuffer();
  final paymentsCollection = FirebaseFirestore.instance.collection('cashs');
  final caseId = caseData['id'];

  buffer.writeln('<html>');
  buffer.writeln('<head>');
  buffer.writeln('<meta charset="UTF-8">'); // Ensure proper encoding
  buffer.writeln('<style>');
  buffer.writeln(
      'body { direction: rtl; font-family: Arial, sans-serif; margin: 20px; background-color: #f9f9f9; }');
  buffer.writeln(
      'h1 { text-align: center; font-size: 24px; margin-bottom: 20px; color: #333; }');
  buffer.writeln(
      '.section { background-color: #fff; border-radius: 8px; margin-bottom: 20px; padding: 20px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }');
  buffer.writeln(
      '.title { font-size: 18px; font-weight: bold; margin-bottom: 10px; border-bottom: 2px solid #ddd; padding-bottom: 5px; color: #555; }');
  buffer
      .writeln('.detail { margin-bottom: 8px; font-size: 16px; color: #666; }');
  buffer.writeln('.qr-container { text-align: center; margin-top: 20px; }');
  buffer
      .writeln('.payments { margin-top: 20px; font-size: 16px; color: #444; }');
  buffer.writeln('</style>');
  buffer.writeln('</head>');
  buffer.writeln('<body>');

  buffer.writeln('<h1>ملف الحالة</h1>');

  // Case details section
  buffer.writeln('<div class="section">');
  buffer.writeln('<div class="title">بيانات الحالة</div>');
  buffer.writeln(
      '<div class="detail">رقم الحالة: ${caseData['id'] ?? 'غير معروف'}</div>');
  buffer.writeln(
      '<div class="detail">الاسم: ${caseData['name'] ?? 'غير معروف'}</div>');
  buffer.writeln(
      '<div class="detail">الرقم القومي: ${caseData['ID_Number'] ?? 'غير معروف'}</div>');
  buffer.writeln(
      '<div class="detail">رقم الهاتف: ${caseData['number'] ?? 'غير معروف'}</div>');
  buffer.writeln(
      '<div class="detail">العنوان: ${caseData['location'] ?? 'غير معروف'}</div>');
  buffer.writeln(
      '<div class="detail">الحالة الاجتماعية: ${caseData['social_status'] ?? 'غير معروف'}</div>');
  buffer.writeln(
      '<div class="detail">الدخل: ${caseData['in_come'] ?? 'غير معروف'}</div>');
  buffer.writeln(
      '<div class="detail">عدد أعضاء الأسرة: ${caseData['family_count'] ?? 'غير معروف'}</div>');
  buffer.writeln('</div>');

  // QR Code section
  buffer.writeln('<div class="section">');
  buffer.writeln('<div class="title">رمز الاستجابة السريعة (QR Code)</div>');
  buffer.writeln('<div class="qr-container">');
  buffer.writeln(
      '<img src="https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${caseData['id']}" alt="QR Code">');
  buffer.writeln('</div>');
  buffer.writeln('</div>');
  // Payments section
  buffer.writeln('<div class="section">');
  buffer.writeln('<div class="title">الدفع الشهري</div>');

  try {
    final querySnapshot =
        await paymentsCollection.where('case_id', isEqualTo: caseId).get();

    if (querySnapshot.docs.isEmpty) {
      buffer
          .writeln('<div class="detail">لا توجد بيانات دفع لهذه الحالة</div>');
    } else {
      for (var payment in querySnapshot.docs) {
        final paymentData = payment.data() as Map<String, dynamic>;
        buffer.writeln(
            '<div class="detail">• ${paymentData['created_at'] ?? 'غير معروف'}: ${paymentData['credit'] ?? 'غير معروف'}</div>');
      }
    }
  } catch (error) {
    buffer.writeln(
        '<div class="detail">حدث خطأ أثناء استرجاع بيانات الدفع: $error</div>');
  }

  buffer.writeln('</div>');

  // End of HTML
  buffer.writeln('</body>');
  buffer.writeln('</html>');

  // Create the HTML Blob and open it for printing
  final blob = html.Blob([buffer.toString()], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  html.Url.revokeObjectUrl(url);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('تم طباعة الملف بنجاح')),
  );
}
